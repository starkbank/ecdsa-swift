import BigInt
import Foundation


public class Ecdsa {

    public static func sign(message: String, privateKey: PrivateKey, hashfunc: Hash = Sha256()) -> Signature {
        let curve = privateKey.curve
        let byteMessage = hashfunc.digest(message)
        let numberMessage = BinaryAscii.numberFromByteString(byteMessage, bitLength: curve.nBitLength)

        var r = BigInt(0)
        var s = BigInt(0)
        var randSignPoint: Point? = nil
        let kIterator = RandomInteger.rfc6979(byteMessage, privateKey.secret, curve, hashfunc)
        while r == 0 || s == 0 {
            let randNum = kIterator.next()!
            randSignPoint = Math.multiplyGenerator(curve: curve, n: randNum)
            r = randSignPoint!.x.modulus(curve.N)
            s = ((numberMessage + r * privateKey.secret) * Math.inv(randNum, curve.N)).modulus(curve.N)
        }
        var recoveryId = randSignPoint!.y % 2 == 0 ? 0 : 1
        if randSignPoint!.y > curve.N {
            recoveryId += 2
        }
        // Low-S normalization
        if s > curve.N / 2 {
            s = curve.N - s
            recoveryId ^= 1
        }

        return Signature(r, s, recoveryId: recoveryId)
    }

    public static func verify(message: String, signature: Signature, publicKey: PublicKey, hashfunc: Hash = Sha256()) -> Bool {
        let curve = publicKey.curve
        let byteMessage = hashfunc.digest(message)
        let numberMessage = BinaryAscii.numberFromByteString(byteMessage, bitLength: curve.nBitLength)
        let r = signature.r
        let s = signature.s

        if r < 1 || r > curve.N - 1 {
            return false
        }
        if s < 1 || s > curve.N - 1 {
            return false
        }
        // Public key on-curve validation
        if !curve.contains(p: publicKey.point) {
            return false
        }
        let inv = Math.inv(s, curve.N)
        // Shamir's trick for ~2x faster verify
        let v = Math.multiplyAndAdd(
            curve.G, (numberMessage * inv).modulus(curve.N),
            publicKey.point, (r * inv).modulus(curve.N),
            curve.N, curve.A, curve.P,
            curve: curve
        )
        if v.isAtInfinity() {
            return false
        }
        return v.x.modulus(curve.N) == r
    }
}
