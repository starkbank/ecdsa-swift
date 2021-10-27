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
        let publicPoint = Math.multiply(
            curve.G,
            secret,
            curve.N,
            curve.A,
            curve.P
        )
        return PublicKey(point: publicPoint, curve: curve)
    }
    
    public func toString() ->  String {
        return BinaryAscii.hexFromInt(self.secret)
    }
    
    public func toDer() -> Data {
        let publicKeyString = publicKey().toString(encoded: true)
        let hexadecimal = Der.encodeConstructed(
            Der.encodePrimitive(tagType: integer, value: 1 as AnyObject),
            Der.encodePrimitive(tagType: octetString, value: BinaryAscii.hexFromInt(self.secret) as AnyObject),
            Der.encodePrimitive(tagType: oidContainer, value: Der.encodePrimitive(tagType: object, value: self.curve.oid as AnyObject) as AnyObject),
            Der.encodePrimitive(tagType: publicKeyPointContainer, value: Der.encodePrimitive(tagType: bitString, value: publicKeyString as AnyObject) as AnyObject)
        )
                
        return BinaryAscii.dataFromHex(hexadecimal)
    }
    
    public func toPem() -> String {
        let der = self.toDer()
        let base64 = BinaryAscii.base64FromData(der)
        return createPem(content: base64, template: pemTemplate)
    }
    
    public static func fromPem(_ string: String) throws -> PrivateKey {
        let privateKeyPem = getPemContent(pem: string)
        return try fromDer(BinaryAscii.dataFromBase64(privateKeyPem))
    }
    
    public static func fromDer(_ data: Data) throws -> PrivateKey {
        var hexadecimal = BinaryAscii.hexFromData(data)

        let parsed = try Der.parse(hexadecimal: &hexadecimal)[0] as! [Any]
        let privateKeyFlag = parsed[0] as! BigInt
        let secretHex = parsed[1] as! String
        let curveData = (parsed[2] as! [Any])[0] as! [Int]
        let publicKeyString = (parsed[3] as! [Any])[0] as! String
        
        if (privateKeyFlag != 1) {
            throw Error.flagError("Private keys should start with a '1' flag, but a '{flag}' was found instead".replacingOccurrences(of: "{flag}", with: String(privateKeyFlag)))
        }
        
        let curve = try getCurveByOid(curveData)
        let privateKey = fromString(string: secretHex, curve: curve)
        
        if (privateKey.publicKey().toString(encoded: true) != publicKeyString) {
            throw Error.matchError("The public key described inside the private key file doesn't match the actual public key of the pair")
        }
        return privateKey
    }
    
    public static func fromString(string: String, curve: CurveFp = secp256k1) -> PrivateKey {
        return PrivateKey(curve: curve, secret: BinaryAscii.intFromHex(string))
    }
}

let pemTemplate = """
-----BEGIN EC PRIVATE KEY-----
{content}
-----END EC PRIVATE KEY-----
"""
