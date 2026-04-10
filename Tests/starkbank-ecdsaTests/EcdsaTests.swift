import XCTest
@testable import starkbank_ecdsa

class EcdsaTests: XCTestCase {

    func testVerifyRightMessage() throws {
        let privateKey = PrivateKey()
        let publicKey = privateKey.publicKey()
        let message = "This is the right message"

        let signature = Ecdsa.sign(message: message, privateKey: privateKey)

        XCTAssertTrue(Ecdsa.verify(message: message, signature: signature, publicKey: publicKey))
    }

    func testVerifyWrongMessage() throws {
        let privateKey = PrivateKey()
        let publicKey = privateKey.publicKey()

        let message1 = "This is the right message"
        let message2 = "This is the wrong message"

        let signature = Ecdsa.sign(message: message1, privateKey: privateKey)

        XCTAssertFalse(Ecdsa.verify(message: message2, signature: signature, publicKey: publicKey))
    }

    func testZeroSignature() throws {
        let privateKey = PrivateKey()
        let publicKey = privateKey.publicKey()
        let message2 = "This is the wrong message"

        XCTAssertFalse(Ecdsa.verify(message: message2, signature: Signature(0, 0), publicKey: publicKey))
    }
}
