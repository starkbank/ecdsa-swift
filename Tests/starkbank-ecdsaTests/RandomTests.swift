//
//  RandomTests.swift
//  MyAppTests
//
//  Created by Felipe Sueto on 29/10/21.
//  Copyright © 2021 Stark Bank. All rights reserved.
//

import XCTest

@testable import starkbank_ecdsa

class RandomTests: XCTestCase {

    func testMany() throws {
        let message = "This is a text message"
        for _ in repeatElement(0, count: 1) {
            let privateKey = PrivateKey()
            let publicKey = privateKey.publicKey()
            
            let signature = Ecdsa.sign(message: message, privateKey: privateKey)
            XCTAssertTrue(Ecdsa.verify(message: message, signature: signature, publicKey: publicKey))
        }
    }
}
