//
//  SignatureTests.swift
//  MyAppTests
//
//  Created by Felipe Sueto on 28/10/21.
//  Copyright © 2021 Stark Bank. All rights reserved.
//

import XCTest

@testable import starkbank_ecdsa

class SignatureTests: XCTestCase {
    
    func testDerConversion() throws {
        let privateKey = PrivateKey()
        let message = "This is a text message"
        let signature1 = Ecdsa.sign(message: message, privateKey: privateKey)
        
        let der = signature1.toDer()
        let signature2 = try Signature.fromDer(der)
        
        XCTAssertTrue(signature1.r == signature2.r)
        XCTAssertTrue(signature1.s == signature2.s)
    }

    func testBase64Conversion() throws {
        let privateKey = PrivateKey()
        let message = "This is a text message"
        let signature1 = Ecdsa.sign(message: message, privateKey: privateKey)
        
        let base64 = signature1.toBase64()
        let signature2 = try Signature.fromBase64(base64)
        
        XCTAssertTrue(signature1.r == signature2.r)
        XCTAssertTrue(signature1.s == signature2.s)
    }
}
