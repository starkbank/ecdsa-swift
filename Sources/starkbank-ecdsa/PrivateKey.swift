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
        if (secret == nil) {
            self.secret = RandomInteger.between(min: BigInt(1), max: curve.N - BigInt(1))
            return
        }
        self.secret = secret!
    }
    
    public func publicKey() -> PublicKey {
        let publicPoint = Math.multiply(
            curve.G,
            secret,
            curve.N,
            curve.A,
            curve.P
        )
        return PublicKey(point: publicPoint, curve: curve)
    }
            
    public func toPem() -> String {
        let der = self.toDer()
        let base64 = BinaryAscii.base64FromData(der)
        return createPem(content: base64, template: pemTemplate)
    }
    
    public static func fromPem(_ string: String) throws -> PrivateKey {
        let privateKeyPem = try getPemContent(pem: string, template: pemTemplate)
        return try fromDer(BinaryAscii.dataFromBase64(privateKeyPem))
    }
    
    public func toDer() -> Data {
        let publicKeyString = publicKey().toString(encoded: true)
        let hexadecimal = Der.encodeConstructed(
            Der.encodeInteger(1),
            Der.encodeOctetString(BinaryAscii.hexFromInt(self.secret)),
            Der.encodeOidContainer(
                Der.encodeObject(self.curve.oid)),
            Der.encodePublicKeyPointContainer(
                Der.encodeBitString(publicKeyString))
        )
                
        return BinaryAscii.dataFromHex(hexadecimal)
    }
    
    public static func fromDer(_ string: Data) throws -> PrivateKey {
        var hexadecimal = BinaryAscii.hexFromData(string)

        let parsed = try Der.parse(&hexadecimal)[0] as! [Any]
        let privateKeyFlag = parsed[0] as! BigInt
        let secretHex = parsed[1] as! String
        let curveData = (parsed[2] as! [Any])[0] as! [Int]
        let publicKeyString = (parsed[3] as! [Any])[0] as! String
        
        if (privateKeyFlag != 1) {
            throw Error.flagError("Private keys should start with a '1' flag, but a '{flag}' was found instead".replacingOccurrences(of: "{flag}", with: String(privateKeyFlag)))
        }
        
        let curve = try getCurveByOid(curveData)
        let privateKey = try fromString(string: secretHex, curve: curve)
        
        if (privateKey.publicKey().toString(encoded: true) != publicKeyString) {
            throw Error.matchError("The public key described inside the private key file doesn't match the actual public key of the pair")
        }
        return privateKey
    }
    
    public func toString() ->  String {
        return BinaryAscii.hexFromInt(self.secret)
    }
    
    public static func fromString(string: String, curve: CurveFp = secp256k1) throws -> PrivateKey {
        return try PrivateKey(curve: curve, secret: BinaryAscii.intFromHex(string))
    }
}

let pemTemplate = """
-----BEGIN EC PRIVATE KEY-----
{content}
-----END EC PRIVATE KEY-----
"""
