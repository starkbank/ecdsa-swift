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
    
    public func toPem() -> String {
        return Der().toPem(der: self.toDer(), name: "PUBLIC KEY")
    }
    
    public func toString(encoded: Bool) ->  String{
        let xString = BinaryAscii.stringFromNumber(number: self.point.x, length: self.curve.length());
        let yString = BinaryAscii.stringFromNumber(number: self.point.y, length: self.curve.length());
        if (encoded) {
            return "\\x00\\x04" + xString + yString;
        }
        return xString + yString;
    };
    
    public func toDer() -> Data {
        do {
            let a = Der()
            let encodeEcAndOid = try a.encodedSequence(encodedPieces:
                                                        [a.encodeOid(pieces: [1, 2, 840, 10045, 2, 1]),
                                                         a.encodeOid(pieces: curve.oid)])
//            let encodeEcAndOid = try Der().encodedSequence(encodedPieces: [Der().encodeOid(pieces: [1, 2, 840, 10045, 2, 1])])

//            return Der().encodedSequence(encodedPieces: [encodeEcAndOid, Der().encodeBitstring(t: self.toString(encoded: true))]) as Data
            return a.encodedSequence(encodedPieces: [encodeEcAndOid]) as Data
        } catch {
            print(error)
        }

        return Data()
    }
    
    public func fromPem(string: String) {
        
    }
    
    public func fromDer() {
        
    }
    
}
