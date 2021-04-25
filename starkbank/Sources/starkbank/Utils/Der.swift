//
//  Der.swift
//  
//
//  Created by Paulo Pereira on 25/04/21.
//

import Foundation

class Der {
    
//    0x30 byte: header byte to indicate compound structure
//    one byte to encode the length of the following data
//    0x02: header byte indicating an integer
//    one byte to encode the length of the following r value
//    the r value as a big-endian integer
//    0x02: header byte indicating an integer
//    one byte to encode the length of the following s value
//    the s value as a big-endian integer

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
    
    
    func encodedSequence(encodedPieces: [NSData]) -> NSMutableData {
        var sequence: [NSData] = []
        var totalLengthLen = 0;
        for i in stride(from: 0, through: encodedPieces.count, by: 1) {
            sequence.append(encodedPieces[i])
            totalLengthLen += encodedPieces[i].count
        }
        
        let joinedData = NSMutableData()
        joinedData.append(Der.hex0.data as Data)
        joinedData.append(try! encodeLength(length: totalLengthLen).data as Data)
        for item in sequence {
            joinedData.append(item as Data)
        }
        return joinedData
    }
    
    func encodeInteger(x: Int) {
        if(x < 0) {
            return print("x cannot be negative")
        }
        
        var t = String(x)
        
        if((t.count % 2) != 0) {
            t = "0" + t
        }
        
        var binary = BinaryAscii.binaryFromHex(hex: t)
    }
   
    func encodeOid(pieces: [Int]) {
        var array = pieces
        let first = array.removeFirst()
        let second = array.removeFirst()
        if(first > 2) {
            return print("first has to be <= 2")
        }

        if(second > 39) {
            return print("second has to be <= 39")
        }
        
//        let encodedPieces = []
        
    }
        
    func toPem(der: Data, name: String) -> String {
        let b64 = Base64.encode(data: der)
        var lines = [("-----BEGIN " + name + "-----\n")]
        for start in stride(from: 0, through: b64.count, by: 1) {
            let range = NSRange(location: start, length: start + 64)
            lines.append(b64[range] + "\n")
        }
        lines.append("-----END " + name + "-----\n");
        return lines.joined()
    }
    
    func fromPem(pem: String) -> String {
        let split = pem.split(separator: "\n")
        var stripped = ""
        for i in stride(from: 0, through: split.count, by: 1) {
            if(!split[i].starts(with: "-----")) {
                stripped += split[i].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return Base64.decode(string: stripped)
    }
    
    private func encodeNumber(number: Int) -> Any {
        var n = number
        var b128Digits: [Int] = []
        while n > 0 {
            b128Digits.insert(0, at: (n & hex127) | hex160)
            n >>= 7
        }
        
        if ((b128Digits.count == 0)) {
            b128Digits.append(0);
        }
        
        b128Digits[b128Digits.count - 1] &= hex127;
        var encodedDigits: [Any] = [];
        b128Digits.forEach { (d) in
            encodedDigits.append(String(UnicodeScalar(UInt8(d))))
        }
        
        return encodedDigits
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
    
}

enum Error: Swift.Error {
    case negative
    case algorithmsFailed
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
