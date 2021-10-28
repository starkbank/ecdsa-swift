//
//  SignatureTests.swift
//  MyAppTests
//
//  Created by Felipe Sueto on 28/10/21.
//  Copyright © 2021 Stark Bank. All rights reserved.
//

import XCTest

@testable import starkbank

class SignatureTests: XCTestCase {

    var privateKey = PrivateKey()
    
    func testDerConversion() throws {
        let message = "This is a text message"
        let signature1 = Ecdsa.sign(message: message, privateKey: privateKey)
        
        let der = signature1.toDer()
        let signature2 = try Signature.fromDer(der)
        
        let test1 = signature1.r == signature2.r
        let test2 = signature1.s == signature2.s
        XCTAssertTrue(test1)
        XCTAssertTrue(test2)
    }

    func testBase64Conversion() throws {
        let message = "This is a text message"
        let signature1 = Ecdsa.sign(message: message, privateKey: privateKey)
        
        let base64 = signature1.toBase64()
        let signature2 = try Signature.fromBase64(base64)
        
        let test1 = signature1.r == signature2.r
        let test2 = signature1.s == signature2.s
        XCTAssertTrue(test1)
        XCTAssertTrue(test2)
    }
}
