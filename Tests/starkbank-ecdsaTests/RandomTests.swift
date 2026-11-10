//
//  RandomTests.swift
//  MyAppTests
//
//  Created by Felipe Sueto on 29/10/21.
//  Copyright © 2021 Stark Bank. All rights reserved.
//

import BigInt
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

    func testFullRange() throws {
        let min = BigInt(0)
        let max = (BigInt(1) << 256) - BigInt(1)
        var highestBitWidth = 0
        for _ in 0..<32 {
            let value = RandomInteger.between(min: min, max: max)
            XCTAssertTrue(value >= min && value <= max)
            let bitLength = value.magnitude.bitWidth - value.magnitude.leadingZeroBitCount
            highestBitWidth = Swift.max(highestBitWidth, bitLength)
        }
        XCTAssertGreaterThan(highestBitWidth, 248)
    }
}
