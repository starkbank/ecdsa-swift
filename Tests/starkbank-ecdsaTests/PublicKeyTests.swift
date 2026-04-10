import XCTest
@testable import starkbank_ecdsa

class PublicKeyTests: XCTestCase {

    func testPemConversion() throws {
        let privateKey = PrivateKey()
        let publicKey1 = privateKey.publicKey()
        let pem = publicKey1.toPem()
        let publicKey2 = try PublicKey.fromPem(pem)
        XCTAssertEqual(publicKey1.point.x, publicKey2.point.x)
        XCTAssertEqual(publicKey1.point.y, publicKey2.point.y)
        XCTAssertEqual(publicKey1.curve.name, publicKey2.curve.name)
    }

    func testDerConversion() throws {
        let privateKey = PrivateKey()
        let publicKey1 = privateKey.publicKey()
        let der = publicKey1.toDer()
        let publicKey2 = try PublicKey.fromDer(der)
        XCTAssertEqual(publicKey1.point.x, publicKey2.point.x)
        XCTAssertEqual(publicKey1.point.y, publicKey2.point.y)
        XCTAssertEqual(publicKey1.curve.name, publicKey2.curve.name)
    }

    func testStringConversion() throws {
        let privateKey = PrivateKey()
        let publicKey1 = privateKey.publicKey()
        var string = publicKey1.toString()
        let publicKey2 = try PublicKey.fromString(string: &string)
        XCTAssertEqual(publicKey1.point.x, publicKey2.point.x)
        XCTAssertEqual(publicKey1.point.y, publicKey2.point.y)
        XCTAssertEqual(publicKey1.curve.name, publicKey2.curve.name)
    }
}
