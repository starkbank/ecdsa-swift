import BigInt
import Foundation
import CommonCrypto


class RandomInteger {

    /// Return integer x in the range: min <= x <= max
    ///
    /// - Parameter min: minimum value of the integer
    /// - Parameter max: maximum value of the integer
    /// - Returns: random integer in range
    public static func between(min: BigInt, max: BigInt) -> BigInt {
        let result = getBytesNeeded(max - min)
        let bytesNeeded = result.0
        let mask = result.1
        var bytes = [UInt8](repeating: 0, count: bytesNeeded)

        let _ = SecRandomCopyBytes(kSecRandomDefault, bytesNeeded, &bytes)

        var randomValue = BigInt(0)
        for i in 0..<bytesNeeded {
            randomValue |= BigInt(bytes[i]) << (8 * i)
        }
        randomValue &= mask

        if min + randomValue > max {
            return between(min: min, max: max)
        }
        return min + randomValue
    }

    /// Generate nonce values per hedged RFC 6979: deterministic k derivation
    /// with fresh random entropy mixed into K-init (RFC 6979 §3.6). Same message
    /// and key yield different signatures, while preserving RFC 6979's protection
    /// against RNG failures.
    public static func rfc6979(_ hashBytes: Data, _ secret: BigInt, _ curve: CurveFp, _ hashfunc: Hash) -> Rfc6979Iterator {
        return Rfc6979Iterator(hashBytes: hashBytes, secret: secret, curve: curve, hashfunc: hashfunc)
    }

    internal static func getBytesNeeded(_ request: BigInt) -> (Int, BigInt) {
        var range = request
        var bitsNeeded = 0
        var bytesNeeded = 0
        var mask = BigInt(1)

        while range > 0 {
            if bitsNeeded % 8 == 0 {
                bytesNeeded += 1
            }
            bitsNeeded += 1
            mask = (mask << 1) | BigInt(1)
            range = range >> 1
        }
        return (bytesNeeded, mask)
    }
}


/// Iterator that yields k values per hedged RFC 6979 §3.6
public class Rfc6979Iterator: IteratorProtocol {
    public typealias Element = BigInt

    private var V: Data
    private var K: Data
    private let orderBitLen: Int
    private let orderByteLen: Int
    private let curveN: BigInt
    private let hashfunc: Hash
    private var initialized: Bool

    init(hashBytes: Data, secret: BigInt, curve: CurveFp, hashfunc: Hash) {
        self.curveN = curve.N
        self.hashfunc = hashfunc
        self.orderBitLen = curve.nBitLength
        self.orderByteLen = (orderBitLen + 7) / 8

        let secretHex = StringHelper.zfill(BinaryAscii.hexFromInt(secret), orderByteLen * 2)
        let secretBytes = BinaryAscii.dataFromHex(secretHex)

        let hashReduced = BinaryAscii.numberFromByteString(hashBytes, bitLength: orderBitLen).modulus(curve.N)
        let hashHex = StringHelper.zfill(BinaryAscii.hexFromInt(hashReduced), orderByteLen * 2)
        let hashOctets = BinaryAscii.dataFromHex(hashHex)

        var extraEntropyBytes = [UInt8](repeating: 0, count: orderByteLen)
        let _ = SecRandomCopyBytes(kSecRandomDefault, orderByteLen, &extraEntropyBytes)
        let extraEntropy = Data(extraEntropyBytes)

        let hLen = hashfunc.digestLength
        self.V = Data(repeating: 0x01, count: hLen)
        self.K = Data(repeating: 0x00, count: hLen)

        // K = HMAC_K(V || 0x00 || secret || hashOctets || extraEntropy)
        self.K = Rfc6979Iterator.hmacSha(key: self.K, data: self.V + Data([0x00]) + secretBytes + hashOctets + extraEntropy, hashfunc: hashfunc)
        // V = HMAC_K(V)
        self.V = Rfc6979Iterator.hmacSha(key: self.K, data: self.V, hashfunc: hashfunc)
        // K = HMAC_K(V || 0x01 || secret || hashOctets || extraEntropy)
        self.K = Rfc6979Iterator.hmacSha(key: self.K, data: self.V + Data([0x01]) + secretBytes + hashOctets + extraEntropy, hashfunc: hashfunc)
        // V = HMAC_K(V)
        self.V = Rfc6979Iterator.hmacSha(key: self.K, data: self.V, hashfunc: hashfunc)

        self.initialized = true
    }

    public func next() -> BigInt? {
        while true {
            var T = Data()
            while T.count * 8 < orderBitLen {
                V = Rfc6979Iterator.hmacSha(key: K, data: V, hashfunc: hashfunc)
                T.append(V)
            }

            let k = BinaryAscii.numberFromByteString(T, bitLength: orderBitLen)

            if k >= 1 && k <= curveN - 1 {
                return k
            }

            K = Rfc6979Iterator.hmacSha(key: K, data: V + Data([0x00]), hashfunc: hashfunc)
            V = Rfc6979Iterator.hmacSha(key: K, data: V, hashfunc: hashfunc)
        }
    }

    private static func hmacSha(key: Data, data: Data, hashfunc: Hash) -> Data {
        // Determine the algorithm based on hashfunc type
        let algorithm: CCHmacAlgorithm
        let digestLength: Int
        if hashfunc is Sha512 {
            algorithm = CCHmacAlgorithm(kCCHmacAlgSHA512)
            digestLength = Int(CC_SHA512_DIGEST_LENGTH)
        } else {
            algorithm = CCHmacAlgorithm(kCCHmacAlgSHA256)
            digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        }

        var result = [UInt8](repeating: 0, count: digestLength)
        key.withUnsafeBytes { keyPtr in
            data.withUnsafeBytes { dataPtr in
                CCHmac(
                    algorithm,
                    keyPtr.baseAddress, key.count,
                    dataPtr.baseAddress, data.count,
                    &result
                )
            }
        }
        return Data(result)
    }
}
