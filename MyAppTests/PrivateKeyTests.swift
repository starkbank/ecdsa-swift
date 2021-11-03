//
//  PrivateKeyTests.swift
//  MyAppTests
//
//  Created by Felipe Sueto on 28/10/21.
//  Copyright © 2021 Stark Bank. All rights reserved.
//

import XCTest

@testable import starkbank

class PrivateKeyTests: XCTestCase {
    
    func testPemConversion() throws {
        let privateKey = try PrivateKey()
        let pem = privateKey.toPem()
        let privateKey2 = try PrivateKey.fromPem(pem)
        XCTAssertTrue(privateKey.secret == privateKey2.secret)
        XCTAssertTrue(privateKey.curve.A == privateKey2.curve.A &&
                      privateKey.curve.B == privateKey2.curve.B &&
                      privateKey.curve.P == privateKey2.curve.P &&
                      privateKey.curve.N == privateKey2.curve.N &&
                      privateKey.curve.name == privateKey2.curve.name &&
                      privateKey.curve.oid == privateKey2.curve.oid &&
                      privateKey.curve.G.x == privateKey2.curve.G.x &&
                      privateKey.curve.G.y == privateKey2.curve.G.y &&
                      privateKey.curve.G.z == privateKey2.curve.G.z)
    }
    
    func testDerConversion() throws {
        let privateKey = try PrivateKey()
        let der = privateKey.toDer()
        let privateKey2 = try PrivateKey.fromDer(der)
        XCTAssertTrue(privateKey.secret == privateKey2.secret)
        XCTAssertTrue(privateKey.curve.A == privateKey2.curve.A &&
                      privateKey.curve.B == privateKey2.curve.B &&
                      privateKey.curve.P == privateKey2.curve.P &&
                      privateKey.curve.N == privateKey2.curve.N &&
                      privateKey.curve.name == privateKey2.curve.name &&
                      privateKey.curve.oid == privateKey2.curve.oid &&
                      privateKey.curve.G.x == privateKey2.curve.G.x &&
                      privateKey.curve.G.y == privateKey2.curve.G.y &&
                      privateKey.curve.G.z == privateKey2.curve.G.z)
    }
    
    func testStringConversion() throws {
        let privateKey = try PrivateKey()
        let string = privateKey.toString()
        let privateKey2 = try PrivateKey.fromString(string)
        XCTAssertTrue(privateKey.secret == privateKey2.secret)
        XCTAssertTrue(privateKey.curve.A == privateKey2.curve.A &&
                      privateKey.curve.B == privateKey2.curve.B &&
                      privateKey.curve.P == privateKey2.curve.P &&
                      privateKey.curve.N == privateKey2.curve.N &&
                      privateKey.curve.name == privateKey2.curve.name &&
                      privateKey.curve.oid == privateKey2.curve.oid &&
                      privateKey.curve.G.x == privateKey2.curve.G.x &&
                      privateKey.curve.G.y == privateKey2.curve.G.y &&
                      privateKey.curve.G.z == privateKey2.curve.G.z)
    }
}
