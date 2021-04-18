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
        let numberMessage = BinaryAscii.numberFromString(hashMessage)
        let curve = privateKey.curve
        let randNum = RandomInteger.between(BigInt(1), curve.N)
        let randomSignPoint = Math.multiply(curve.G, randNum, curve.N, curve.A, curve.P)
        let r = randomSignPoint.x % curve.N
        let s = ((numberMessage + r * privateKey.secret) * (Math.inv(randNum, curve.N))) % curve.N
        return Signature(r, s)
    }
    
    public static func verify(message: String, signature: Signature, publicKey: PublicKey, hashfunc: Hash = Sha256()) -> Bool {
        let hashMessage = hashfunc.digest(message)
        let numberMessage = BinaryAscii.numberFromString(hashMessage)
        let curve = publicKey.curve
        let r = signature.r
        let s = signature.s
        if (r < BigInt(1) || r > curve.N - BigInt(1)) { return false }
        if (s < BigInt(1) || s > curve.N - BigInt(1)) { return false }
        let inv = Math.inv(s, curve.N)
        let u1 = Math.multiply(curve.G, (numberMessage * inv) % curve.N, curve.A, curve.P, curve.N)
        let u2 = Math.multiply(publicKey.point, (r * inv) % curve.N, curve.A, curve.P, curve.N)
        let add = Math.add(u1, u2, curve.P, curve.A)
        let modX = add.x % curve.N
        return r == modX
    }
}
