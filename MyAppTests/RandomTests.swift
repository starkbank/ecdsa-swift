//
//  RandomTests.swift
//  MyAppTests
//
//  Created by Felipe Sueto on 29/10/21.
//  Copyright © 2021 Stark Bank. All rights reserved.
//

import XCTest

@testable import starkbank

class RandomTests: XCTestCase {

    func testMany() throws {
        var signDiff = [Double]()
        var verifyDiff = [Double]()
        for _ in repeatElement(0, count: 100) {
            let privateKey = try PrivateKey()
            let publicKey = privateKey.publicKey()
            let message = "This is a text message"
            
            var timestampInit = NSDate().timeIntervalSince1970
            let signature = try Ecdsa.sign(message: message, privateKey: privateKey)
            var timestampEnd = NSDate().timeIntervalSince1970
            signDiff.append(timestampEnd - timestampInit)
            
            timestampInit = NSDate().timeIntervalSince1970
            let _ = Ecdsa.verify(message: message, signature: signature, publicKey: publicKey)
            timestampEnd = NSDate().timeIntervalSince1970
            verifyDiff.append(timestampEnd - timestampInit)
        }
        
        var _ = signDiff.reduce(0, +)
        var _ = verifyDiff.reduce(0, +)
    }


}
