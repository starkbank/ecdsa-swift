//
//  Der.swift
//
//
//  Created by Paulo Pereira on 25/04/21.
//

import Foundation
import BigInt

let integer = "integer"
let bitString = "bitString"
let octetString = "octetString"
let null = "null"
let object = "object"
let printableString = "printableString"
let utcTime = "utcTime"
let sequence = "sequence"
let set = "set"
let oidContainer = "oidContainer"
let publicKeyPointContainer = "publicKeyPointContainer"
let certificateCustom = "certificateCustom"

enum typeToHexTag: String {
    case integer = "02"
    case bitString = "03"
    case octetString = "04"
    case null = "05"
    case object = "06"
    case printableString = "13"
    case utcTime = "17"
    case sequence = "30"
    case set = "31"
    case oidContainer = "a0"
    case publicKeyPointContainer = "a1"
    case certificateCustom = "a3"
}

let hexTagtoType = [
    "02": integer,
    "03": bitString,
    "04": octetString,
    "05": null,
    "06": object,
    "13": printableString,
    "17": utcTime,
    "30": sequence,
    "31": set,
    "a0": oidContainer,
    "a1": publicKeyPointContainer,
    "a3": certificateCustom
]

public class Der {
    
    public static func encodeConstructed(_ components: String...) -> String {
        return encodeSequence(components.joined(separator: ""))
    }
    
    private static func addPrefix(_ tag: String, _ data: String) -> String {
        return String(format: "%@%@%@", tag, generateLengthBytes(hexadecimal: data), data)
    }
    
    internal static func encodeInteger(number: BigInt) -> String {
        var hexadecimal = BinaryAscii.hexFromInt(abs(number))
        if (number < 0) {
            let bitCount = 4 * hexadecimal.count
            let twosComplement = BigInt(pow(Double(2), Double(bitCount))) + number
            return BinaryAscii.hexFromInt(twosComplement)
        }
        let bits = BinaryAscii.bitsFromHex(String(hexadecimal.prefix(1)))
        if (bits.prefix(1) == "1") {
            hexadecimal = "00" + hexadecimal
        }
        return addPrefix(typeToHexTag.integer.rawValue, hexadecimal)
    }
    
    internal static func encodeObject(_ oid: Array<Int>) -> String {
        let hexadecimal = Oid.oidToHex(oid: oid)
        return addPrefix(typeToHexTag.object.rawValue, hexadecimal)
    }
    
    internal static func encodeSequence(_ sequence: String) -> String {
        return addPrefix(typeToHexTag.sequence.rawValue, sequence)
    }
    
    internal static func encodeBitString(_ bitString: String) -> String {
        return addPrefix(typeToHexTag.bitString.rawValue, bitString)
    }
    
    internal static func encodePublicKeyPointContainer(_ publicKeyPoint: String) -> String {
        return addPrefix(typeToHexTag.publicKeyPointContainer.rawValue, publicKeyPoint)
    }
    
    internal static func encodeOctetString(_ string: String) -> String {
        return addPrefix(typeToHexTag.octetString.rawValue, string)
    }
    
    internal static func encodeOidContainer(_ string: String) -> String {
        return addPrefix(typeToHexTag.oidContainer.rawValue, string)
    }
    
    static func parse(hexadecimal: inout String) throws -> Array<Any> {
        if (hexadecimal == "") {
            return []
        }
        let typeByte = String(hexadecimal.prefix(2))
        var hexEnd = hexadecimal.count - 2
        hexadecimal = hexEnd > 0 ? String(hexadecimal.suffix(hexEnd)) : String(hexadecimal.suffix(hexadecimal.count))
        
        let lengthResult = try readLengthBytes(hexadecimal: &hexadecimal)
        let length = lengthResult.0
        let lengthBytes = lengthResult.1
                
        let start = hexadecimal.index(hexadecimal.startIndex, offsetBy: lengthBytes)
        let endOffset = lengthBytes + length - 1
        let isEndOfHexadecimal = endOffset <= hexadecimal.count
        let end = isEndOfHexadecimal ?
            hexadecimal.index(hexadecimal.startIndex, offsetBy: endOffset) :
            hexadecimal.index(hexadecimal.startIndex, offsetBy: hexadecimal.count - 1)
        var content = endOffset != 1 ? String(hexadecimal[start...end]) : ""
        hexEnd = hexadecimal.count - lengthBytes - length
        hexadecimal = hexEnd > 0 ? String(hexadecimal.suffix(hexEnd)) : ""
                
        if (content.count < length) {
            throw Error.parserError("missing bytes in DER parse")
        }
        
        var contentArray: Array<Any> = [content]
        let tagData = getTagData(tag: typeByte)
        if (tagData["isConstructed"] as! Bool) {
            contentArray = try parse(hexadecimal: &content)
            return [contentArray] + (try parse(hexadecimal: &hexadecimal))
        }
        
        switch tagData["type"]! as! String {
        case null:
            contentArray = [parseNull(hexadecimal: content)]
        case object:
            contentArray = [parseOid(hexadecimal: content)]
        case utcTime:
            contentArray = [parseTime(hexadecimal: content)]
        case integer:
            contentArray = [parseInteger(hexadecimal: content)]
        case printableString:
            contentArray = [parseString(hexadecimal: content)]
        default:
            break
        }
        return contentArray + (try parse(hexadecimal: &hexadecimal))
    }
    
    static func parseAny(contentArray: Array<Any>) -> Array<Any> {
        return contentArray
    }
    
    static func parseOid(hexadecimal: String) -> [Int] {
        return Oid.oidFromHex(hexadecimal: hexadecimal)
    }
    
    static func parseTime(hexadecimal: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMddHHmmssZ"
        return dateFormatter.date(from: parseString(hexadecimal: hexadecimal)) ?? Date()
    }
    
    static func parseString(hexadecimal: String) -> String {
        return String(data: BinaryAscii.dataFromHex(hexadecimal), encoding: .utf8)!
    }
    
    static func parseNull(hexadecimal: String) -> String {
        return ""
    }
    
    static func parseInteger(hexadecimal: String) -> BigInt {
        let integer = BinaryAscii.intFromHex(hexadecimal)
        let bits = BinaryAscii.bitsFromHex(String(hexadecimal.prefix(1)))
        if (String(bits.prefix(1)) == "0") {
            return BigInt(integer)
        }
        let bitCount = 4 * hexadecimal.count
        return BigInt(integer - BigInt(NSDecimalNumber(decimal: pow(2, bitCount)).intValue))
    }
    
    static func readLengthBytes(hexadecimal: inout String) throws -> (Int, Int) {
        var lengthBytes = 2
        let lengthIndicator = BinaryAscii.intFromHex(String(hexadecimal.prefix(lengthBytes)))
        let isShortForm = lengthIndicator < 128 // checks if first bit of byte is 1 (a.k.a. short-form)
        if (isShortForm) {
            let length = lengthIndicator * 2
            return (Int(length), lengthBytes)
        }
        let lengthLength = lengthIndicator - 128 // nullifies first bit of byte (only used as long-form flag)
        if (lengthLength == 0) {
            throw Error.parserError("indefinite length encoding located in DER")
        }
        lengthBytes += 2 * Int(lengthLength)
        let start = hexadecimal.index(hexadecimal.startIndex, offsetBy: 2)
        let end = hexadecimal.index(hexadecimal.startIndex,
                                    offsetBy: hexadecimal.count > lengthBytes ? lengthBytes - 1 : hexadecimal.count - 1)
        let range = start...end
        
        let length = Int(BinaryAscii.intFromHex(String(hexadecimal[range])) * 2)
        return (length, lengthBytes)
    }
    
    static func generateLengthBytes(hexadecimal: String) -> String {
        let size = BigInt(floor(Double(hexadecimal.count) / 2))
        let length = BinaryAscii.hexFromInt(size)
        if size < 128 {
            return length.zfill(2)
        }
        let lengthLength = 128 + BigInt(floor(Double(length.count) / 2))
        return BinaryAscii.hexFromInt(lengthLength) + length
    }
    
    static func getTagData(tag: String) -> Dictionary<String, AnyObject> {
        let bits = BinaryAscii.bitsFromHex(tag)
        let bit8 = bits[bits.index(bits.startIndex, offsetBy: 0)]
        let bit7 = bits[bits.index(bits.startIndex, offsetBy: 1)]
        let bit6 = bits[bits.index(bits.startIndex, offsetBy: 2)]
        
        var tagClass: String
        switch (bit8, bit7) {
        case ("0", "0"):
            tagClass = "universal"
        case ("0", "1"):
            tagClass = "application"
        case ("1", "0"):
            tagClass = "context-specific"
        case ("1", "1"):
            tagClass = "private"
        default:
            tagClass = ""
        }
        
        let isConstructed = bit6 == "1"
        
        let type = hexTagtoType[tag]
        
        return [
            "class": tagClass as AnyObject,
            "isConstructed": isConstructed as AnyObject,
            "type": type != nil ? type as AnyObject : "None" as AnyObject
        ]
    }
}

extension String {
    var data: Data {
        return Data(self.utf8)
    }
}
