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
    
    public func toString(encoded: Bool = false) ->  Data {
        var data = Data()
        let xString = BinaryAscii.stringFromNumber(number: self.point.x, length: self.curve.length())
        let yString = BinaryAscii.stringFromNumber(number: self.point.y, length: self.curve.length())
        
        print(xString)
        var byteArray = [UInt8]()
        for char in xString.utf8{
            byteArray += [char]
        }

        return data
//            return withUnsafeBytes(of: "\\x00\\x04") { Data($0) } + xString + yString;
        }
//        return xString + yString
    
    public func toDer() -> Data {
        do {
            let a = Der()
            let encodeEcAndOid = try a.encodedSequence(encodedPieces:
                                                        [a.encodeOid(pieces: [1, 2, 840, 10045, 2, 1])])
            self.toString(encoded: true)

            return a.encodedSequence(encodedPieces: [encodeEcAndOid])
//            return a.encodedSequence(encodedPieces: [encodeEcAndOid, a.encodeBitstring(t: self.toString(encoded: true))])
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
