//
//  OpenSSLTests.swift
//  MyAppTests
//
//  Created by Felipe Sueto on 03/11/21.
//  Copyright © 2021 Stark Bank. All rights reserved.
//

import XCTest

@testable import starkbank

class OpenSSLTests: XCTestCase {
    
    func testAssign() throws {
        let privateKeyPem = try File.read("privateKey", "pem")
        
        let privateKey = try PrivateKey.fromPem(privateKeyPem)
        
        let message = try File.read("message", "txt")
        
        let signature = try Ecdsa.sign(message: message, privateKey: privateKey)
        
        let publicKey = privateKey.publicKey()
        
        XCTAssertTrue(Ecdsa.verify(message: message, signature: signature, publicKey: publicKey))
    }
    
//    func testVerifySignature() throws {
//        let publicKeyPem = try File.read("publicKey", "pem")
//        
//        let publicKey = try PublicKey.fromPem(publicKeyPem)
//        
//        let message = try File.read("message", "txt")
//        
//        let signatureDer = try File.read("signatureDer", "txt")
//        
//        let signature = try Signature.fromDer(signatureDer.data(using: .utf8)!)
//                
//        XCTAssertTrue(Ecdsa.verify(message: message, signature: signature, publicKey: publicKey))
//    }
}
