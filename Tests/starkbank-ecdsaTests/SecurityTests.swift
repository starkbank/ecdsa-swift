import XCTest
import BigInt
@testable import starkbank_ecdsa

// MARK: - Prime256v1 Public Key Derivation Tests

class Prime256v1PublicKeyDerivationTests: XCTestCase {
    /// RFC 6979 A.2.5 public key derivation. Signatures are hedged, so r/s
    /// no longer match fixed test vectors, but pubkey derivation is unchanged.

    var privateKey: PrivateKey!
    var publicKey: PublicKey!

    override func setUp() {
        privateKey = PrivateKey(
            curve: prime256v1,
            secret: BigInt("C9AFA9D845BA75166B5C215767B1D6934E50C3DB36E89B127B8A622B120F6721", radix: 16)!
        )
        publicKey = privateKey.publicKey()
    }

    func testPublicKeyMatchesRfc() {
        XCTAssertEqual(
            publicKey.point.x,
            BigInt("60FED4BA255A9D31C961EB74C6356D68C049B8923B61FA6CE669622E60F29FB6", radix: 16)!
        )
        XCTAssertEqual(
            publicKey.point.y,
            BigInt("7903FE1008B8BC99A41AE9E95628BC64F2F1B20C2D7E9F5177A3C294D4462299", radix: 16)!
        )
    }

    func testSampleMessageRoundTrip() {
        let sig = Ecdsa.sign(message: "sample", privateKey: privateKey)
        XCTAssertTrue(sig.s <= prime256v1.N / 2)
        XCTAssertTrue(Ecdsa.verify(message: "sample", signature: sig, publicKey: publicKey))
    }

    func testTestMessageRoundTrip() {
        let sig = Ecdsa.sign(message: "test", privateKey: privateKey)
        XCTAssertTrue(sig.s <= prime256v1.N / 2)
        XCTAssertTrue(Ecdsa.verify(message: "test", signature: sig, publicKey: publicKey))
    }
}

// MARK: - Secp256k1 Public Key Derivation Tests

class Secp256k1PublicKeyDerivationTests: XCTestCase {
    /// secp256k1 with secret=1 (pubkey = generator G).

    var privateKey: PrivateKey!
    var publicKey: PublicKey!

    override func setUp() {
        privateKey = PrivateKey(curve: secp256k1, secret: BigInt(1))
        publicKey = privateKey.publicKey()
    }

    func testPublicKeyIsGenerator() {
        XCTAssertEqual(publicKey.point.x, secp256k1.G.x)
        XCTAssertEqual(publicKey.point.y, secp256k1.G.y)
    }

    func testSampleMessageRoundTrip() {
        let sig = Ecdsa.sign(message: "sample", privateKey: privateKey)
        XCTAssertTrue(Ecdsa.verify(message: "sample", signature: sig, publicKey: publicKey))
    }

    func testTestMessageRoundTrip() {
        let sig = Ecdsa.sign(message: "test", privateKey: privateKey)
        XCTAssertTrue(Ecdsa.verify(message: "test", signature: sig, publicKey: publicKey))
    }
}

// MARK: - Malleability Tests

class MalleabilityTests: XCTestCase {

    func testSignAlwaysProducesLowS() {
        for _ in 0..<100 {
            let privateKey = PrivateKey()
            let signature = Ecdsa.sign(message: "test message", privateKey: privateKey)
            XCTAssertTrue(signature.s <= privateKey.curve.N / 2)
        }
    }

    func testHighSSignatureStillVerifies() {
        /// verify() accepts high-s for OpenSSL compatibility; sign() prevents malleability
        let privateKey = PrivateKey()
        let publicKey = privateKey.publicKey()
        let message = "test message"

        let signature = Ecdsa.sign(message: message, privateKey: privateKey)
        let highS = Signature(signature.r, privateKey.curve.N - signature.s)

        XCTAssertTrue(Ecdsa.verify(message: message, signature: signature, publicKey: publicKey))
        XCTAssertTrue(Ecdsa.verify(message: message, signature: highS, publicKey: publicKey))
    }
}

// MARK: - Public Key Validation Tests

class PublicKeyValidationTests: XCTestCase {

    func testRejectOffCurvePublicKey() {
        let privateKey = PrivateKey()
        let publicKey = privateKey.publicKey()
        let message = "test message"

        let signature = Ecdsa.sign(message: message, privateKey: privateKey)

        let offCurvePoint = Point(publicKey.point.x, publicKey.point.y + 1)
        let offCurveKey = PublicKey(point: offCurvePoint, curve: publicKey.curve)

        XCTAssertFalse(Ecdsa.verify(message: message, signature: signature, publicKey: offCurveKey))
    }

    func testFromStringRejectsOffCurvePoint() {
        let p = PrivateKey().publicKey()
        let badY = StringHelper.zfill(BinaryAscii.hexFromInt(p.point.y + 1), 2 * p.curve.length())
        let badHex = StringHelper.zfill(BinaryAscii.hexFromInt(p.point.x), 2 * p.curve.length()) + badY
        var mutableBadHex = badHex
        XCTAssertThrowsError(try PublicKey.fromString(string: &mutableBadHex, curve: p.curve))
    }

    func testFromStringRejectsInfinityPoint() {
        let zeroHex = String(repeating: "0", count: 2 * 2 * secp256k1.length())
        var mutableZeroHex = zeroHex
        XCTAssertThrowsError(try PublicKey.fromString(string: &mutableZeroHex, curve: secp256k1))
    }
}

// MARK: - Forgery Attempt Tests

class ForgeryAttemptTests: XCTestCase {

    var privateKey: PrivateKey!
    var publicKey: PublicKey!
    var message: String!
    var signature: Signature!

    override func setUp() {
        privateKey = PrivateKey()
        publicKey = privateKey.publicKey()
        message = "authentic message"
        signature = Ecdsa.sign(message: message, privateKey: privateKey)
    }

    func testRejectZeroSignature() {
        XCTAssertFalse(Ecdsa.verify(message: message, signature: Signature(0, 0), publicKey: publicKey))
    }

    func testRejectREqualsZero() {
        XCTAssertFalse(Ecdsa.verify(message: message, signature: Signature(0, signature.s), publicKey: publicKey))
    }

    func testRejectSEqualsZero() {
        XCTAssertFalse(Ecdsa.verify(message: message, signature: Signature(signature.r, 0), publicKey: publicKey))
    }

    func testRejectREqualsN() {
        let N = publicKey.curve.N
        XCTAssertFalse(Ecdsa.verify(message: message, signature: Signature(N, signature.s), publicKey: publicKey))
    }

    func testRejectSEqualsN() {
        let N = publicKey.curve.N
        XCTAssertFalse(Ecdsa.verify(message: message, signature: Signature(signature.r, N), publicKey: publicKey))
    }

    func testRejectRExceedsN() {
        let N = publicKey.curve.N
        XCTAssertFalse(Ecdsa.verify(message: message, signature: Signature(N + 1, signature.s), publicKey: publicKey))
    }

    func testRejectArbitrarySignature() {
        XCTAssertFalse(Ecdsa.verify(message: message, signature: Signature(1, 1), publicKey: publicKey))
    }

    func testRejectBoundarySignature() {
        let N = publicKey.curve.N
        XCTAssertFalse(Ecdsa.verify(message: message, signature: Signature(N - 1, N - 1), publicKey: publicKey))
    }

    func testWrongKeyRejected() {
        let otherKey = PrivateKey().publicKey()
        XCTAssertFalse(Ecdsa.verify(message: message, signature: signature, publicKey: otherKey))
    }
}

// MARK: - Hedged Signature Tests

class HedgedSignatureTests: XCTestCase {

    func testSameInputsProduceDifferentSignatures() {
        let privateKey = PrivateKey()
        let message = "test message"

        let signature1 = Ecdsa.sign(message: message, privateKey: privateKey)
        let signature2 = Ecdsa.sign(message: message, privateKey: privateKey)

        XCTAssertTrue(signature1.r != signature2.r || signature1.s != signature2.s)
    }

    func testDifferentMessagesDifferentSignatures() {
        let privateKey = PrivateKey()

        let signature1 = Ecdsa.sign(message: "message 1", privateKey: privateKey)
        let signature2 = Ecdsa.sign(message: "message 2", privateKey: privateKey)

        XCTAssertTrue(signature1.r != signature2.r || signature1.s != signature2.s)
    }

    func testDifferentKeysDifferentSignatures() {
        let message = "test message"

        let signature1 = Ecdsa.sign(message: message, privateKey: PrivateKey())
        let signature2 = Ecdsa.sign(message: message, privateKey: PrivateKey())

        XCTAssertTrue(signature1.r != signature2.r || signature1.s != signature2.s)
    }
}

// MARK: - Edge Case Message Tests

class EdgeCaseMessageTests: XCTestCase {

    var privateKey: PrivateKey!
    var publicKey: PublicKey!

    override func setUp() {
        privateKey = PrivateKey()
        publicKey = privateKey.publicKey()
    }

    private func signAndVerify(_ message: String) {
        let sig = Ecdsa.sign(message: message, privateKey: privateKey)
        XCTAssertTrue(Ecdsa.verify(message: message, signature: sig, publicKey: publicKey))
        XCTAssertFalse(Ecdsa.verify(message: message + "x", signature: sig, publicKey: publicKey))
    }

    func testEmptyMessage() {
        signAndVerify("")
    }

    func testSingleCharMessage() {
        signAndVerify("a")
    }

    func testUnicodeMessage() {
        signAndVerify("\u{00e9}\u{00e8}\u{00ea}\u{00eb}")
    }

    func testEmojiMessage() {
        signAndVerify("\u{1f512}\u{1f511}")
    }

    func testNullByteMessage() {
        signAndVerify("before\0after")
    }

    func testLongMessage() {
        signAndVerify(String(repeating: "a", count: 10000))
    }

    func testNewlinesAndWhitespace() {
        signAndVerify("  line1\n\tline2\r\n  ")
    }
}

// MARK: - Serialization Round Trip Tests

class SerializationRoundTripTests: XCTestCase {

    var privateKey: PrivateKey!
    var publicKey: PublicKey!
    var message: String!
    var signature: Signature!

    override func setUp() {
        privateKey = PrivateKey()
        publicKey = privateKey.publicKey()
        message = "round-trip test"
        signature = Ecdsa.sign(message: message, privateKey: privateKey)
    }

    func testSignatureDerRoundTrip() throws {
        let der = signature.toDer()
        let restored = try Signature.fromDer(der)
        XCTAssertEqual(restored.r, signature.r)
        XCTAssertEqual(restored.s, signature.s)
        XCTAssertTrue(Ecdsa.verify(message: message, signature: restored, publicKey: publicKey))
    }

    func testSignatureBase64RoundTrip() throws {
        let b64 = signature.toBase64()
        let restored = try Signature.fromBase64(b64)
        XCTAssertEqual(restored.r, signature.r)
        XCTAssertEqual(restored.s, signature.s)
        XCTAssertTrue(Ecdsa.verify(message: message, signature: restored, publicKey: publicKey))
    }

    func testSignatureDerWithRecoveryIdRoundTrip() throws {
        let der = signature.toDer(withRecoveryId: true)
        let restored = try Signature.fromDer(der, recoveryByte: true)
        XCTAssertEqual(restored.r, signature.r)
        XCTAssertEqual(restored.s, signature.s)
        XCTAssertEqual(restored.recoveryId, signature.recoveryId)
    }

    func testPrivateKeyPemRoundTrip() throws {
        let pem = privateKey.toPem()
        let restored = try PrivateKey.fromPem(pem)
        XCTAssertEqual(restored.secret, privateKey.secret)
        XCTAssertEqual(restored.curve.name, privateKey.curve.name)
    }

    func testPrivateKeyDerRoundTrip() throws {
        let der = privateKey.toDer()
        let restored = try PrivateKey.fromDer(der)
        XCTAssertEqual(restored.secret, privateKey.secret)
    }

    func testPublicKeyPemRoundTrip() throws {
        let pem = publicKey.toPem()
        let restored = try PublicKey.fromPem(pem)
        XCTAssertEqual(restored.point.x, publicKey.point.x)
        XCTAssertEqual(restored.point.y, publicKey.point.y)
    }

    func testPublicKeyCompressedRoundTrip() throws {
        let compressed = publicKey.toCompressed()
        let restored = try PublicKey.fromCompressed(compressed, curve: publicKey.curve)
        XCTAssertEqual(restored.point.x, publicKey.point.x)
        XCTAssertEqual(restored.point.y, publicKey.point.y)
        XCTAssertTrue(Ecdsa.verify(message: message, signature: signature, publicKey: restored))
    }

    func testPublicKeyCompressedEvenAndOdd() throws {
        /// Ensure both even-y and odd-y keys round-trip through compression
        for _ in 0..<20 {
            let pk = PrivateKey()
            let pub = pk.publicKey()
            let compressed = pub.toCompressed()
            let restored = try PublicKey.fromCompressed(compressed, curve: pub.curve)
            XCTAssertEqual(restored.point.x, pub.point.x)
            XCTAssertEqual(restored.point.y, pub.point.y)
        }
    }

    func testPrime256v1KeyRoundTrip() throws {
        let pk = PrivateKey(curve: prime256v1)
        let pem = pk.toPem()
        let restored = try PrivateKey.fromPem(pem)
        XCTAssertEqual(restored.secret, pk.secret)
        XCTAssertEqual(restored.curve.name, "prime256v1")
    }
}

// MARK: - Tonelli-Shanks Tests

class TonelliShanksTests: XCTestCase {

    func testPrimeCongruent1Mod4() {
        // P = 17: 17 - 1 = 16 = 2^4, S = 4, exercises full Tonelli-Shanks
        let P = BigInt(17)
        for value in 1..<Int(P) {
            let v = BigInt(value)
            if v.power((P - 1) / 2, modulus: P) == 1 {
                let root = Math.modularSquareRoot(v, P)
                XCTAssertEqual((root * root) % P, v)
            }
        }
    }

    func testPrimeCongruent5Mod8() {
        // P = 13: 13 - 1 = 12 = 3 * 2^2, S = 2
        let P = BigInt(13)
        for value in 1..<Int(P) {
            let v = BigInt(value)
            if v.power((P - 1) / 2, modulus: P) == 1 {
                let root = Math.modularSquareRoot(v, P)
                XCTAssertEqual((root * root) % P, v)
            }
        }
    }

    func testPrimeCongruent3Mod4() {
        // P = 7: fast path (S = 1)
        let P = BigInt(7)
        for value in 1..<Int(P) {
            let v = BigInt(value)
            if v.power((P - 1) / 2, modulus: P) == 1 {
                let root = Math.modularSquareRoot(v, P)
                XCTAssertEqual((root * root) % P, v)
            }
        }
    }

    func testZeroValue() {
        XCTAssertEqual(Math.modularSquareRoot(BigInt(0), BigInt(17)), BigInt(0))
    }
}

// MARK: - Hash Truncation Tests

class HashTruncationTests: XCTestCase {

    func testSignVerifyWithSha512() {
        let privateKey = PrivateKey()
        let publicKey = privateKey.publicKey()
        let message = "test message"

        let signature = Ecdsa.sign(message: message, privateKey: privateKey, hashfunc: Sha512())

        XCTAssertTrue(Ecdsa.verify(message: message, signature: signature, publicKey: publicKey, hashfunc: Sha512()))
        XCTAssertFalse(Ecdsa.verify(message: "wrong message", signature: signature, publicKey: publicKey, hashfunc: Sha512()))
    }

    func testSha512SignaturesAreHedged() {
        let privateKey = PrivateKey()
        let message = "test message"

        let signature1 = Ecdsa.sign(message: message, privateKey: privateKey, hashfunc: Sha512())
        let signature2 = Ecdsa.sign(message: message, privateKey: privateKey, hashfunc: Sha512())

        XCTAssertTrue(signature1.r != signature2.r || signature1.s != signature2.s)
    }

    func testHashMismatchFails() {
        let privateKey = PrivateKey()
        let publicKey = privateKey.publicKey()
        let message = "test message"

        let signature = Ecdsa.sign(message: message, privateKey: privateKey, hashfunc: Sha256())
        XCTAssertFalse(Ecdsa.verify(message: message, signature: signature, publicKey: publicKey, hashfunc: Sha512()))
    }
}

// MARK: - Prime256v1 Security Tests

class Prime256v1SecurityTests: XCTestCase {

    func testSignVerify() {
        let privateKey = PrivateKey(curve: prime256v1)
        let publicKey = privateKey.publicKey()
        let message = "test message"

        let signature = Ecdsa.sign(message: message, privateKey: privateKey)

        XCTAssertTrue(signature.s <= prime256v1.N / 2)
        XCTAssertTrue(Ecdsa.verify(message: message, signature: signature, publicKey: publicKey))
    }

    func testSignaturesAreHedged() {
        let privateKey = PrivateKey(curve: prime256v1)
        let message = "test message"

        let signature1 = Ecdsa.sign(message: message, privateKey: privateKey)
        let signature2 = Ecdsa.sign(message: message, privateKey: privateKey)

        XCTAssertTrue(signature1.r != signature2.r || signature1.s != signature2.s)
    }

    func testWrongCurveKeyFails() {
        /// A signature made with secp256k1 should not verify with a prime256v1 key
        let k1Key = PrivateKey(curve: secp256k1)
        let p256Key = PrivateKey(curve: prime256v1)
        let message = "cross-curve test"

        let sig = Ecdsa.sign(message: message, privateKey: k1Key)
        XCTAssertFalse(Ecdsa.verify(message: message, signature: sig, publicKey: p256Key.publicKey()))
    }
}
