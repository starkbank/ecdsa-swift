//
//  Der.swift
//  
//
//  Created by Paulo Pereira on 25/04/21.
//

import Foundation
import BigInt

class Der {

    static let hexAt = "\\x00"
    static let hexB = "\\x02"
    static let hexC = "\\x03"
    static let hexD = "\\x04"
    static let hexF = "\\x06"
    static let hex0 = "\\x30"

    private let hex31 = 0x1f
    private let hex127 = 0x7f
    private let hex129 = 0xa0
    private let hex160 = 0x80
    private let hex224 = 0xe0
    
    private let bytesHex0 = Base64.encode(string: hex0)
    private let bytesHexB = Base64.encode(string: hexB)
    private let bytesHexC = Base64.encode(string: hexC)
    private let bytesHexD = Base64.encode(string: hexD)
    private let bytesHexF = Base64.encode(string: hexF)
    
    
    func encodedSequence(encodedPieces: [NSData]) -> NSData {
        var sequence: [NSData] = []
        var totalLengthLen = 0;
        for i in stride(from: 0, to: encodedPieces.count, by: 1) {
            print(i)
            sequence.append(encodedPieces[i])
            totalLengthLen += encodedPieces[i].count
        }
        
        let joinedData = NSMutableData()
        joinedData.append(Der.hex0.data as Data)
        joinedData.append(try! encodeLength(length: totalLengthLen).data as Data)
        for item in sequence {
            joinedData.append(item as Data)
        }
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
        
        var x = BinaryAscii.binaryFromHex(hex: t)
        
    }
   
    func encodeOid(pieces: [Int]) throws -> NSData {
        var array = pieces
        let first = array.removeFirst()
        let second = array.removeFirst()
        if(first > 2) {
            throw Error.moreOrEqualTwo
        }

        if(second > 39) {
            throw Error.moreOrEqualTwo
        }
        
        let encodedPieces = NSMutableData()
        pieces.forEach { (d) in
            encodedPieces.append(encodeNumber(number: d) as Data)
        }
        
        let body =  NSMutableData()
        body.append(String(UnicodeScalar(UInt8(40 * first + second))).data as Data)
        body.append(encodedPieces as Data)
        
        let result = NSMutableData()
        result.append(Der.hexF.data as Data)
        result.append(try encodeLength(length: body.length).data as Data)
        result.append(body as Data)
        return result
    }
        
    func toPem(der: Data, name: String) -> String {
        var b64 = Base64.encode(data: der)
        var lines = [("-----BEGIN " + name + "-----\n")]
        while(b64.count > 64) {
            lines.append(b64[0..<64] + "\n")
            b64 = b64.replacingOccurrences(of: b64[0..<64], with: "")
        }
        lines.append(b64 + "\n")
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
            b128Digits.append((n & hex127) | hex160)
            n >>= 7
        }
        
        if ((b128Digits.count == 0)) {
            b128Digits.append(0);
        }
        
        b128Digits[b128Digits.count - 1] &= hex127;
        let encodedDigits = NSMutableData()
        b128Digits.forEach { (d) in
            encodedDigits.append(String(UnicodeScalar(UInt8(d))).data as Data)
        }
        
        return encodedDigits.copy() as! NSData
    }
    
    private func encodeLength(length: Int) throws -> String {
        if(length < 0) {
            throw Error.negative
        }
        
        if(length < hex160) {
            return String(UnicodeScalar(UInt8(length)))
        }
        
        var s = String(length)
        
        if(s.count.isMultiple(of: 2)) {
            s = "0" + s
        }
        
        let sBinary = BinaryAscii.binaryFromHex(hex: s)
        
        let lengthLen = sBinary.count
        
        return String(UnicodeScalar(UInt8(hex160 | lengthLen))) + String(lengthLen)
    }
    
    private func checkSequenceError(string: String, start: String, expected: String) throws {
        if(!string.starts(with: start)) {
            return print("wanted sequence (0x" + expected + "), got 0x")
        }
    }
    
    func encodeBitstring(t: String) -> NSData {
        let combinedData = NSMutableData()
        combinedData.append(Der.hexC.data as Data)
        combinedData.append(try! encodeLength(length: t.count).data as Data)
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
    
    var data: NSData {
        if let data = self.data(using: String.Encoding.utf8) {
            return data as NSData
        } else {
            return NSData()
        }
    }
    
}
