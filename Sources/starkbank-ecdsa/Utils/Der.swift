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
]

public class Der {
    
    public static func encodeConstructed(_ encodedValues: String...) -> String {
        return encodeSequence(encodedValues.joined(separator: ""))
    }
        
    internal static func encodeInteger(_ number: BigInt) -> String {
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
        let hexadecimal = Oid.oidToHex(oid)
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
    
    internal static func addPrefix(_ tag: String, _ data: String) -> String {
        return String(format: "%@%@%@", tag, generateLengthBytes(hexadecimal: data), data)
    }
    
    static func parse(_ hexadecimal: inout String) throws -> Array<Any> {
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
        let tagData = getTagData(typeByte)
        if (tagData["isConstructed"] as! Bool) {
            contentArray = try parse(&content)
            return [contentArray] + (try parse(&hexadecimal))
        }
        
        switch tagData["type"]! as! String {
        case null:
            contentArray = [parseNull(content)]
        case object:
            contentArray = [parseOid(content)]
        case utcTime:
            contentArray = [parseTime(content)]
        case integer:
            contentArray = [parseInteger(content)]
        case printableString:
            contentArray = [parseString(content)]
        default:
            break
        }
        return contentArray + (try parse(&hexadecimal))
    }
    
    private static func parseOid(_ hexadecimal: String) -> [Int] {
        return Oid.oidFromHex(hexadecimal)
    }
    
    private static func parseTime(_ hexadecimal: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMddHHmmssZ"
        return dateFormatter.date(from: parseString(hexadecimal)) ?? Date()
    }
    
    private static func parseString(_ hexadecimal: String) -> String {
        return String(data: BinaryAscii.dataFromHex(hexadecimal), encoding: .utf8)!
    }
    
    private static func parseNull(_ content: String) -> String {
        return ""
    }
    
    private static func parseInteger(_ hexadecimal: String) -> BigInt {
        let integer = BinaryAscii.intFromHex(hexadecimal)
        let bits = BinaryAscii.bitsFromHex(String(hexadecimal.prefix(1)))
        if (String(bits.prefix(1)) == "0") {
            return BigInt(integer)
        }
        let bitCount = 4 * hexadecimal.count
        return BigInt(integer - BigInt(NSDecimalNumber(decimal: pow(2, bitCount)).intValue))
    }
    
    private static func readLengthBytes(hexadecimal: inout String) throws -> (Int, Int) {
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
    
    private static func generateLengthBytes(hexadecimal: String) -> String {
        let size = BigInt(floor(Double(hexadecimal.count) / 2))
        let length = BinaryAscii.hexFromInt(size)
        if size < 128 {
            return StringHelper.zfill(length, 2)
        }
        let lengthLength = 128 + BigInt(floor(Double(length.count) / 2))
        return BinaryAscii.hexFromInt(lengthLength) + length
    }
    
    private static func getTagData(_ tag: String) -> Dictionary<String, AnyObject> {
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
