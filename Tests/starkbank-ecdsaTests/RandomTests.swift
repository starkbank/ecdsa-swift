import XCTest
@testable import starkbank_ecdsa

class RandomTests: XCTestCase {

    func testMany() throws {
        for _ in 0..<100 {
            let privateKey1 = PrivateKey()
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
    }
}
