//
//  File.swift
//  
//
//  Created by Rafael Stark on 2/15/21.
//

import BigInt
import Foundation


public class PrivateKey {
    
    public var curve: CurveFp
    public var secret: BigInt
    
    public init(curve: CurveFp = secp256k1, secret: BigInt? = nil) {
        self.curve = curve
        self.secret = secret ?? RandomInteger.between(BigInt(1), curve.N - BigInt(1))
    }
    
    public func publicKey() -> PublicKey {
        let publicPoint = Math.multiply(curve.G, secret, curve.N, curve.A, curve.P)
        return PublicKey(point: publicPoint, curve: curve)
    }
    
    public func toString(encoded: Bool) ->  String{
        return BinaryAscii.stringFromNumber(number: self.secret, length: self.curve.length());
    }
    
    public func toPem() -> String {
        return Der().toPem(der: self.toDer(), name: "EC PRIVATE KEY")
    }
    
    public func toDer() -> Data {
        return Data()
    }
    
    static func fromPem(pem: String) {
        
    }
    
    static func fromDer(der: Data) {
        
    }
    
    static func fromString(string: String) {
        
    }
}
