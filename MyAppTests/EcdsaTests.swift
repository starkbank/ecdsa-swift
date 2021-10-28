//
//  EcdsaTests.swift
//  MyAppTests
//
//  Created by Felipe Sueto on 28/10/21.
//  Copyright © 2021 Stark Bank. All rights reserved.
//

import XCTest

@testable import starkbank

class EcdsaTests: XCTestCase {
    
    var privateKey = PrivateKey()

    func testVerifyRightMessage() throws {
        let publicKey = privateKey.publicKey()
        let message = "This is a text message"
        
        let signature = Ecdsa.sign(message: message, privateKey: privateKey)
        
        XCTAssertTrue(Ecdsa.verify(message: message, signature: signature, publicKey: publicKey))
    }

    func testVerifyWrongMessage() throws {
        let publicKey = privateKey.publicKey()
        
        let message1 = "This is the right message"
        let message2 = "This is the wrong message"
        
        let signature = Ecdsa.sign(message: message1, privateKey: privateKey)
        
        XCTAssertFalse(Ecdsa.verify(message: message2, signature: signature, publicKey: publicKey))
    }
}
