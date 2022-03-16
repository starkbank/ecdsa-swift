//
//  PublicKeyTests.swift
//  MyAppTests
//
//  Created by Felipe Sueto on 28/10/21.
//  Copyright © 2021 Stark Bank. All rights reserved.
//

import XCTest

@testable import starkbank_ecdsa

class PublicKeyTests: XCTestCase {
    
    func testPemConversion() throws {
        let privateKey = PrivateKey()
        let publicKey1 = privateKey.publicKey()
        let pem = publicKey1.toPem()
        let publicKey2 = try PublicKey.fromPem(pem)
        XCTAssertTrue(publicKey1.point.x == publicKey2.point.x)
        XCTAssertTrue(publicKey1.point.y == publicKey2.point.y)
        XCTAssertTrue(publicKey1.curve.A == publicKey2.curve.A &&
                      publicKey1.curve.B == publicKey2.curve.B &&
                      publicKey1.curve.P == publicKey2.curve.P &&
                      publicKey1.curve.N == publicKey2.curve.N &&
                      publicKey1.curve.name == publicKey2.curve.name &&
                      publicKey1.curve.oid == publicKey2.curve.oid &&
                      publicKey1.curve.G.x == publicKey2.curve.G.x &&
                      publicKey1.curve.G.y == publicKey2.curve.G.y &&
                      publicKey1.curve.G.z == publicKey2.curve.G.z)
    }
    
    func testDerConversion() throws {
        let privateKey = PrivateKey()
        let publicKey1 = privateKey.publicKey()
        let der = publicKey1.toDer()
        let publicKey2 = try PublicKey.fromDer(der)
        XCTAssertTrue(publicKey1.point.x == publicKey2.point.x)
        XCTAssertTrue(publicKey1.point.y == publicKey2.point.y)
        XCTAssertTrue(publicKey1.curve.A == publicKey2.curve.A &&
                      publicKey1.curve.B == publicKey2.curve.B &&
                      publicKey1.curve.P == publicKey2.curve.P &&
                      publicKey1.curve.N == publicKey2.curve.N &&
                      publicKey1.curve.name == publicKey2.curve.name &&
                      publicKey1.curve.oid == publicKey2.curve.oid &&
                      publicKey1.curve.G.x == publicKey2.curve.G.x &&
                      publicKey1.curve.G.y == publicKey2.curve.G.y &&
                      publicKey1.curve.G.z == publicKey2.curve.G.z)
    }

    func testStringConversion() throws {
        let privateKey = PrivateKey()
        let publicKey1 = privateKey.publicKey()
        var string = publicKey1.toString()
        let publicKey2 = try PublicKey.fromString(string: &string)
        XCTAssertTrue(publicKey1.point.x == publicKey2.point.x)
        XCTAssertTrue(publicKey1.point.y == publicKey2.point.y)
        XCTAssertTrue(publicKey1.curve.A == publicKey2.curve.A &&
                      publicKey1.curve.B == publicKey2.curve.B &&
                      publicKey1.curve.P == publicKey2.curve.P &&
                      publicKey1.curve.N == publicKey2.curve.N &&
                      publicKey1.curve.name == publicKey2.curve.name &&
                      publicKey1.curve.oid == publicKey2.curve.oid &&
                      publicKey1.curve.G.x == publicKey2.curve.G.x &&
                      publicKey1.curve.G.y == publicKey2.curve.G.y &&
                      publicKey1.curve.G.z == publicKey2.curve.G.z)
    }
}
