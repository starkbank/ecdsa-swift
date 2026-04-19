import XCTest
@testable import starkbank_ecdsa

class PrivateKeyTests: XCTestCase {

    func testPemConversion() throws {
        let privateKey1 = PrivateKey()
        let pem = privateKey1.toPem()
        let privateKey2 = try PrivateKey.fromPem(pem)
        XCTAssertEqual(privateKey1.secret, privateKey2.secret)
        XCTAssertEqual(privateKey1.curve.name, privateKey2.curve.name)
    }

    func testDerConversion() throws {
        let privateKey1 = PrivateKey()
        let der = privateKey1.toDer()
        let privateKey2 = try PrivateKey.fromDer(der)
        XCTAssertEqual(privateKey1.secret, privateKey2.secret)
        XCTAssertEqual(privateKey1.curve.name, privateKey2.curve.name)
    }

    func testStringConversion() throws {
        let privateKey1 = PrivateKey()
        let string = privateKey1.toString()
        let privateKey2 = try PrivateKey.fromString(string: string)
        XCTAssertEqual(privateKey1.secret, privateKey2.secret)
        XCTAssertEqual(privateKey1.curve.name, privateKey2.curve.name)
    }
}
