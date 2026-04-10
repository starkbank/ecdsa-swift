import XCTest
import BigInt
@testable import starkbank_ecdsa

class CurveTests: XCTestCase {

    func testSupportedCurve() throws {
        let newCurve = CurveFp(
            name: "secp256k1",
            A: BigInt("0000000000000000000000000000000000000000000000000000000000000000", radix: 16)!,
            B: BigInt("0000000000000000000000000000000000000000000000000000000000000007", radix: 16)!,
            P: BigInt("fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f", radix: 16)!,
            N: BigInt("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141", radix: 16)!,
            Gx: BigInt("79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798", radix: 16)!,
            Gy: BigInt("483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8", radix: 16)!,
            oid: [1, 3, 132, 0, 10]
        )
        let privateKey1 = PrivateKey(curve: newCurve)
        let publicKey1 = privateKey1.publicKey()

        let privateKeyPem = privateKey1.toPem()
        let publicKeyPem = publicKey1.toPem()

        let privateKey2 = try PrivateKey.fromPem(privateKeyPem)
        let publicKey2 = try PublicKey.fromPem(publicKeyPem)

        let message = "test"

        let signatureBase64 = Ecdsa.sign(message: message, privateKey: privateKey2).toBase64()
        let signature = try Signature.fromBase64(signatureBase64)

        XCTAssertTrue(Ecdsa.verify(message: message, signature: signature, publicKey: publicKey2))
    }

    func testAddNewCurve() throws {
        let newCurve = CurveFp(
            name: "frp256v1",
            A: BigInt("f1fd178c0b3ad58f10126de8ce42435b3961adbcabc8ca6de8fcf353d86e9c00", radix: 16)!,
            B: BigInt("ee353fca5428a9300d4aba754a44c00fdfec0c9ae4b1a1803075ed967b7bb73f", radix: 16)!,
            P: BigInt("f1fd178c0b3ad58f10126de8ce42435b3961adbcabc8ca6de8fcf353d86e9c03", radix: 16)!,
            N: BigInt("f1fd178c0b3ad58f10126de8ce42435b53dc67e140d2bf941ffdd459c6d655e1", radix: 16)!,
            Gx: BigInt("b6b3d4c356c139eb31183d4749d423958c27d2dcaf98b70164c97a2dd98f5cff", radix: 16)!,
            Gy: BigInt("6142e0f7c8b204911f9271f0f3ecef8c2701c307e8e4c9e183115a1554062cfb", radix: 16)!,
            oid: [1, 2, 250, 1, 223, 101, 256, 1]
        )
        curveAdd(newCurve)
        let privateKey1 = PrivateKey(curve: newCurve)
        let publicKey1 = privateKey1.publicKey()

        let privateKeyPem = privateKey1.toPem()
        let publicKeyPem = publicKey1.toPem()

        let privateKey2 = try PrivateKey.fromPem(privateKeyPem)
        let publicKey2 = try PublicKey.fromPem(publicKeyPem)

        let message = "test"

        let signatureBase64 = Ecdsa.sign(message: message, privateKey: privateKey2).toBase64()
        let signature = try Signature.fromBase64(signatureBase64)

        XCTAssertTrue(Ecdsa.verify(message: message, signature: signature, publicKey: publicKey2))
    }

    func testUnsupportedCurve() throws {
        let newCurve = CurveFp(
            name: "brainpoolP256t1",
            A: BigInt("a9fb57dba1eea9bc3e660a909d838d726e3bf623d52620282013481d1f6e5374", radix: 16)!,
            B: BigInt("662c61c430d84ea4fe66a7733d0b76b7bf93ebc4af2f49256ae58101fee92b04", radix: 16)!,
            P: BigInt("a9fb57dba1eea9bc3e660a909d838d726e3bf623d52620282013481d1f6e5377", radix: 16)!,
            N: BigInt("a9fb57dba1eea9bc3e660a909d838d718c397aa3b561a6f7901e0e82974856a7", radix: 16)!,
            Gx: BigInt("a3e8eb3cc1cfe7b7732213b23a656149afa142c47aafbc2b79a191562e1305f4", radix: 16)!,
            Gy: BigInt("2d996c823439c56d7f7b22e14644417e69bcb6de39d027001dabe8f35b25c9be", radix: 16)!,
            oid: [1, 3, 36, 3, 3, 2, 8, 1, 1, 8]
        )

        let privateKeyPem = PrivateKey(curve: newCurve).toPem()
        let publicKeyPem = PrivateKey(curve: newCurve).publicKey().toPem()

        XCTAssertThrowsError(try PrivateKey.fromPem(privateKeyPem)) { error in
            XCTAssertTrue(String(describing: error).contains("Unknown curve"))
        }

        XCTAssertThrowsError(try PublicKey.fromPem(publicKeyPem)) { error in
            XCTAssertTrue(String(describing: error).contains("Unknown curve"))
        }
    }
}
