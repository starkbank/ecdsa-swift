//
//  File.swift
//  
//
//  Created by Rafael Stark on 2/15/21.
//

import Foundation


public class PublicKey {
    
    fileprivate static let pemPrefix = "-----BEGIN PUBLIC KEY-----\n"
    fileprivate static let pemSuffix = "\n-----END PUBLIC KEY-----"

    public var point: Point
    public var curve: CurveFp
    
    public init(point: Point, curve: CurveFp) {
        self.point = point
        self.curve = curve
    }
    
    public func toPem() -> String {
        return Der().toPem(der: self.toDer(), name: "PUBLIC KEY")
    }
    
    public func toDer() -> Data {
        Der().encodeOid(pieces: [1, 2, 840, 10045, 2, 1])
//        let encodedEcAndOid = Der.encodedSequence()
        return Data()
    }
    
    public func fromPem(string: String) {
        
    }
    
    public func fromDer() {
        
    }
    
    fileprivate static func addHeader(_ base64: String) -> String {
            return pemPrefix + base64 + pemSuffix
    }
    
}
