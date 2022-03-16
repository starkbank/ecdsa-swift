//
//  File.swift
//  
//
//  Created by Rafael Stark on 2/15/21.
//

import BigInt
import Foundation


public class Ecdsa {
    
    public static func sign(message: String, privateKey: PrivateKey, hashfunc: Hash = Sha256()) -> Signature {
        let hashMessage = hashfunc.digest(message)
        let numberMessage = BinaryAscii.intFromHex(BinaryAscii.hexFromData(hashMessage as Data))
        let curve = privateKey.curve
        let randNum = RandomInteger.between(min: BigInt(1), max: curve.N)
        let randomSignPoint = Math.multiply(curve.G, randNum, curve.N, curve.A, curve.P)
        let r = randomSignPoint.x.modulus(curve.N)
        let s = ((numberMessage + r * privateKey.secret) * (Math.inv(randNum, curve.N))).modulus(curve.N)
        return Signature(r, s)
    }
    
    public static func verify(message: String, signature: Signature, publicKey: PublicKey, hashfunc: Hash = Sha256()) -> Bool {
        let hashMessage = hashfunc.digest(message)
        let numberMessage = BinaryAscii.intFromHex(BinaryAscii.hexFromData(hashMessage as Data))
        let curve = publicKey.curve
        let r = signature.r
        let s = signature.s
        
        if (r < 1 || r >= curve.N) {
            return false
        }
        if (s < 1 || s >= curve.N) {
            return false
        }
        
        let inv = Math.inv(s, curve.N)
        let u1 = Math.multiply(curve.G, (numberMessage * inv).modulus(curve.N), curve.N, curve.A, curve.P)
        let u2 = Math.multiply(publicKey.point, (r * inv).modulus(curve.N), curve.N, curve.A, curve.P)
        let v = Math.add(u1, u2, curve.A, curve.P)
        if (v.isAtInfinity()) {
            return false
        }
        return v.x.modulus(curve.N) == r
    }
}
