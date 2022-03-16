//
//  OpenSSLTests.swift
//  MyAppTests
//
//  Created by Felipe Sueto on 03/11/21.
//  Copyright © 2021 Stark Bank. All rights reserved.
//

import XCTest

@testable import starkbank_ecdsa

class OpenSSLTests: XCTestCase {
    
    func testSign() throws {
        let privateKeyPem = """
-----BEGIN EC PARAMETERS-----
BgUrgQQACg==
-----END EC PARAMETERS-----
-----BEGIN EC PRIVATE KEY-----
MHQCAQEEIODvZuS34wFbt0X53+P5EnSj6tMjfVK01dD1dgDH02RzoAcGBSuBBAAK
oUQDQgAE/nvHu/SQQaos9TUljQsUuKI15Zr5SabPrbwtbfT/408rkVVzq8vAisbB
RmpeRREXj5aog/Mq8RrdYy75W9q/Ig==
-----END EC PRIVATE KEY-----
"""
        let privateKey = try PrivateKey.fromPem(privateKeyPem)
        let message = "This is a text message"
        let signature = Ecdsa.sign(message: message, privateKey: privateKey)
        let publicKey = privateKey.publicKey()

        XCTAssertTrue(Ecdsa.verify(message: message, signature: signature, publicKey: publicKey))
    }
    
    func testVerifySignature() throws {
        let publicKeyPem = """
-----BEGIN PUBLIC KEY-----
MFYwEAYHKoZIzj0CAQYFK4EEAAoDQgAEPyoJVvN9AX5tREfx0RswXJrCD7OIyRyL
r486ERyOjzaz0cdnJt6IfVvgRvxgZc9aidSx1FcA8qTBvEhji3f9NA==
-----END PUBLIC KEY-----
"""
        let publicKey = try PublicKey.fromPem(publicKeyPem)
        let message = "This is a text message"
        let signature = try Signature.fromBase64("MEYCIQDOoyupIwoDHkgFnpAF6FANj2OVokPiDaZdLW16Pc1y4gIhAL4WcGXjqbgSGN8L9C2pxHFPY01Cp+CQmc80TE1jyuti")
        
        XCTAssertTrue(Ecdsa.verify(message: message, signature: signature, publicKey: publicKey))
    }
}
