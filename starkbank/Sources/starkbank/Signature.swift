//
//  File.swift
//  
//
//  Created by Rafael Stark on 2/15/21.
//

import BigInt
import Foundation


public class Signature {
    
    public var r: BigInt
    public var s: BigInt
    
    public init(_ r: BigInt, _ s: BigInt) {
        self.r = r
        self.s = s
    }
    
    public func toDer() -> Data {
        let hexadecimal = self.toString()
        let encodedSequence = BinaryAscii.binaryFromHex(hexadecimal)
        return encodedSequence
    }
    
    public static func fromDer(_ data: Data) throws -> Signature {
        var hexadecimal = BinaryAscii.hexFromString(data)
        return try fromString(string: &hexadecimal)
    }
    
    public func toBase64() -> String {
        return BinaryAscii.base64FromString(self.toDer())
    }
    
    public static func fromBase64(_ string: String) throws -> Signature {
        let der = BinaryAscii.stringFromBase64(string)
        return try fromDer(der)
    }
    
    public func toString() -> String {
        return Der.encodeConstructed(
            Der.encodePrimitive(tagType: integer, value: self.r as AnyObject),
            Der.encodePrimitive(tagType: integer, value: self.s as AnyObject)
        )
    }
    
    public static func fromString(string: inout String) throws -> Signature {
        let parsed = try Der.parse(hexadecimal: &string)[0] as! [Any]
        let r = parsed[0] as! BigInt
        let s = parsed[1] as! BigInt
        return Signature(r, s)
    }
}
