//
//  Der.swift
//
//
//  Created by Paulo Pereira on 25/04/21.
//

import Foundation
import BigInt

let hexAt = 0x00
let hexB = 0x02
let hexC = 0x03
let hexD = 0x04
let hexF = 0x06
let hex0 = 0x30

let hex31 = 0x1f
let hex127 = 0x7f
let hex129 = 0xa0
let hex160 = 0x80
let hex224 = 0xe0

//let bytesHexAt = BinaryAscii.binaryFromHex(hexAt)
//let bytesHexB = BinaryAscii.binaryFromHex(hexB)
//let bytesHexC = BinaryAscii.binaryFromHex(hexC)
//let bytesHexD = BinaryAscii.binaryFromHex(hexD)
//let bytesHexF = BinaryAscii.binaryFromHex(hexF)
//let bytesHex0 = BinaryAscii.binaryFromHex(hex0)


class Der {
    
    //METODO VALIDADO EM OUTRO SDK
    func encodedSequence(encodedPieces: [NSData]) -> NSData {
        var sequence: [NSData] = []
        var totalLengthLen = 0;
        for i in stride(from: 0, to: encodedPieces.count, by: 1) {
            sequence.append(encodedPieces[i])
            totalLengthLen += encodedPieces[i].count
        }
        let joinedData = NSMutableData()
        joinedData.append(Data([UInt8(hex0)]))
        joinedData.append(_encodeLength(totalLengthLen).data as Data)
        let combinedData = NSMutableData()
        for item in sequence {
            combinedData.append(item as Data)
        }
        joinedData.append(combinedData.copy() as! Data)
        return joinedData.copy() as! NSData
    }
    
    func encodeInteger(x: BigInt) {
        if(x < 0) {
            return print("x cannot be negative")
        }
        
        var t = String(x)
        
        if((t.count % 2) != 0) {
            t = "0" + t
        }
        
//        var x = BinaryAscii.binaryFromHex(hex: t)
        
    }
   
    func encodeOid(pieces: [Int]) throws -> NSData {
        var array = pieces
        let first = array.removeFirst()
        let second = array.removeFirst()
//        if(first > 2) {
//            throw Error.moreOrEqualTwo
//        }
//
//        if(second > 39) {
//            throw Error.moreOrEqualTwo
//        }
//
//
        let body =  NSMutableData()
        body.append(String(UnicodeScalar(UInt8(40 * first + second))).data as Data)
        array.forEach { (d) in
            body.append(encodeNumber(number: d) as Data)
        }
                
        let result = NSMutableData()
        result.append(Data([UInt8(hexF)]))
        result.append(_encodeLength(body.length).data as Data)
        result.append(body.copy() as! Data)
        
        return result.copy() as! NSData
    }
        
    func toPem(der: Data, name: String) -> String {
        let b64 = Base64.encode(data: der)
        var lines = [("-----BEGIN " + name + "-----\n")]
        for start in stride(from: 0, to: b64.count, by: 64) {
            lines.append(b64[start..<start+64] + "\n")
        }
        lines.append("-----END " + name + "-----\n");
        return lines.joined()
    }
    
    func fromPem(pem: String) -> String {
        let split = pem.split(separator: "\n")
        var stripped = ""
        for i in stride(from: 0, to: split.count, by: 1) {
            if(!split[i].starts(with: "-----")) {
                stripped += split[i].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return Base64.decode(string: stripped)
    }
    
    private func encodeNumber(number: Int) -> NSData {
        var n = number
        var b128Digits: [Int] = []
        while n > 0 {
            b128Digits.insert((n & hex127) | hex160, at: 0)
            n >>= 7
        }
        
        if ((b128Digits.count == 0)) {
            b128Digits.append(0);
        }
        
        b128Digits[b128Digits.count - 1] &= hex127;
        
        let encodedDigits = NSMutableData()
        b128Digits.forEach { (d) in
            encodedDigits.append(String(UnicodeScalar(UInt8(d))).data)
        }
        return encodedDigits.copy() as! NSData
    }
    
    
    private func _encodeLength(_ length: Int) -> String {
        assert(length >= 0)

        if (length < hex160) {
            return String(UnicodeScalar(UInt8(length)))
        }

        var hexString = String(length, radix: 16)
        if hexString.count % 2 == 1 {
            hexString = "0" + hexString
        }

        let s = BinaryAscii.binaryFromHex(hexString)
        let lengthLen = s.count

        return String(UnicodeScalar(UInt8(hex160 | lengthLen))) + String(lengthLen)
    }
    
    private func checkSequenceError(string: String, start: String, expected: String) throws {
        if(!string.starts(with: start)) {
            return print("wanted sequence (0x" + expected + "), got 0x")
        }
    }
    
    func encodeBitstring(t: String) -> NSData {
        let combinedData = NSMutableData()
        combinedData.append( Data([UInt8(hexC)]))
        combinedData.append(_encodeLength(t.count).data as Data)
        combinedData.append(t.data as Data)
        return combinedData
    }
}

enum Error: Swift.Error {
    case negative
    case algorithmsFailed
    case parserError
    case moreOrEqualTwo
    case moreOrEqual39
}

extension String {
    var data: Data {
        return Data(self.utf8)
    }
}


extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}


extension StringProtocol {
    var asciiValues: [UInt8] { compactMap(\.asciiValue) }
}
