import XCTest
@testable import starkbank_ecdsa

class SignatureWithRecoveryIdTests: XCTestCase {

    func testDerConversion() throws {
        let privateKey = PrivateKey()
        let message = "This is a text message"

        let signature1 = Ecdsa.sign(message: message, privateKey: privateKey)

        let der = signature1.toDer(withRecoveryId: true)
        let signature2 = try Signature.fromDer(der, recoveryByte: true)

        XCTAssertEqual(signature1.r, signature2.r)
        XCTAssertEqual(signature1.s, signature2.s)
        XCTAssertEqual(signature1.recoveryId, signature2.recoveryId)
    }

    func testBase64Conversion() throws {
        let privateKey = PrivateKey()
        let message = "This is a text message"

        let signature1 = Ecdsa.sign(message: message, privateKey: privateKey)

        let base64 = signature1.toBase64(withRecoveryId: true)
        let signature2 = try Signature.fromBase64(base64, recoveryByte: true)

        XCTAssertEqual(signature1.r, signature2.r)
        XCTAssertEqual(signature1.s, signature2.s)
        XCTAssertEqual(signature1.recoveryId, signature2.recoveryId)
    }
}
