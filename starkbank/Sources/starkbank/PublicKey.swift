//
//  File.swift
//  
//
//  Created by Rafael Stark on 2/15/21.
//

import Foundation


public class PublicKey {
    
    public var point: Point
    public var curve: CurveFp
    
    public init(point: Point, curve: CurveFp) {
        self.point = point
        self.curve = curve
    }
    
    public func toString(encoded: Bool = false) ->  String {
        let xString = BinaryAscii.stringFromNumber(number: self.point.x, length: self.curve.length())
        print(xString)
        let yString = BinaryAscii.stringFromNumber(number: self.point.y, length: self.curve.length())
        if (encoded) {
            return "\\x00\\x04" + xString + yString;
        }
        return xString + yString
    }
    
    public func toDer() -> Data {
        do {
            let a = Der()
            let encodeEcAndOid = try a.encodedSequence(encodedPieces:
                                                        [a.encodeOid(pieces: [1, 2, 840, 10045, 2, 1])])
            return a.encodedSequence(encodedPieces: [encodeEcAndOid, a.encodeBitstring(t: self.toString(encoded: true))])
        }
        catch {
            print(error)
        }
        
        return Data()
    }
    
    public func toPem() -> String {
        return Der().toPem(der: self.toDer(), name: "PUBLIC KEY")
    }
    
    static func fromPem(pem: String) {
        
    }
    
    static func fromDer(der: Data) {
        
    }
    
    static func fromString(string: String) {
        
    }
}


extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}
