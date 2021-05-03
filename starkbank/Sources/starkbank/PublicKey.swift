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
    
    public func toString(encoded: Bool = false) ->  String{
        let xString = BinaryAscii.stringFromNumber(number: self.point.x, length: self.curve.length())
        let yString = BinaryAscii.stringFromNumber(number: self.point.y, length: self.curve.length())
        if (encoded) {
            return "\\x00\\x04" + xString + yString;
        }
        return xString + yString
    }
    
    public func toDer() -> Data {
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
