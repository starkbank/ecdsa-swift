import XCTest
@testable import starkbank_ecdsa

class CompPubKeyTests: XCTestCase {

    func testBatch() throws {
        for _ in 0..<100 {
            let privateKey = PrivateKey()
            let publicKey = privateKey.publicKey()
            let publicKeyString = publicKey.toCompressed()

            let recoveredPublicKey = try PublicKey.fromCompressed(publicKeyString, curve: publicKey.curve)

            XCTAssertEqual(publicKey.point.x, recoveredPublicKey.point.x)
            XCTAssertEqual(publicKey.point.y, recoveredPublicKey.point.y)
        }
    }

    func testFromCompressedEven() throws {
        let publicKeyCompressed = "0252972572d465d016d4c501887b8df303eee3ed602c056b1eb09260dfa0da0ab2"
        let publicKey = try PublicKey.fromCompressed(publicKeyCompressed)
        XCTAssertEqual(publicKey.toPem(), "\n-----BEGIN PUBLIC KEY-----\nMFYwEAYHKoZIzj0CAQYFK4EEAAoDQgAEUpclctRl0BbUxQGIe43zA+7j7WAsBWse\nsJJg36DaCrKIdC9NyX2e22/ZRrq8AC/fsG8myvEXuUBe15J1dj/bHA==\n-----END PUBLIC KEY-----\n")
    }

    func testFromCompressedOdd() throws {
        let publicKeyCompressed = "0318ed2e1ec629e2d3dae7be1103d4f911c24e0c80e70038f5eb5548245c475f50"
        let publicKey = try PublicKey.fromCompressed(publicKeyCompressed)
        XCTAssertEqual(publicKey.toPem(), "\n-----BEGIN PUBLIC KEY-----\nMFYwEAYHKoZIzj0CAQYFK4EEAAoDQgAEGO0uHsYp4tPa574RA9T5EcJODIDnADj1\n61VIJFxHX1BMIg0B4cpBnLG6SzOTthXpndIKpr8HEHj3D9lJAI50EQ==\n-----END PUBLIC KEY-----\n")
    }

    func testToCompressedEven() throws {
        let publicKey = try PublicKey.fromPem("-----BEGIN PUBLIC KEY-----\nMFYwEAYHKoZIzj0CAQYFK4EEAAoDQgAEUpclctRl0BbUxQGIe43zA+7j7WAsBWse\nsJJg36DaCrKIdC9NyX2e22/ZRrq8AC/fsG8myvEXuUBe15J1dj/bHA==\n-----END PUBLIC KEY-----")
        let publicKeyCompressed = publicKey.toCompressed()
        XCTAssertEqual(publicKeyCompressed, "0252972572d465d016d4c501887b8df303eee3ed602c056b1eb09260dfa0da0ab2")
    }

    func testToCompressedOdd() throws {
        let publicKey = try PublicKey.fromPem("-----BEGIN PUBLIC KEY-----\nMFYwEAYHKoZIzj0CAQYFK4EEAAoDQgAEGO0uHsYp4tPa574RA9T5EcJODIDnADj1\n61VIJFxHX1BMIg0B4cpBnLG6SzOTthXpndIKpr8HEHj3D9lJAI50EQ==\n-----END PUBLIC KEY-----")
        let publicKeyCompressed = publicKey.toCompressed()
        XCTAssertEqual(publicKeyCompressed, "0318ed2e1ec629e2d3dae7be1103d4f911c24e0c80e70038f5eb5548245c475f50")
    }
}
