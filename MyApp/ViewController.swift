//
//  ViewController.swift
//  MyApp
//
//  Created by Rafael Stark on 2/14/21.
//  Copyright © 2021 Stark Bank. All rights reserved.
//

import BigInt
import starkbank
import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        PRIVATE KEY - testPemConversion
        do {
            let privateKeyTest = PrivateKey(secret: 123)
            let pem = privateKeyTest.toPem()
            let privateKeyTest2 = try PrivateKey.fromPem(pem)
            let teste1 = privateKeyTest.secret == privateKeyTest2.secret
            let teste2 = privateKeyTest.curve.A == privateKeyTest2.curve.A &&
                privateKeyTest.curve.B == privateKeyTest2.curve.B &&
                privateKeyTest.curve.P == privateKeyTest2.curve.P &&
                privateKeyTest.curve.N == privateKeyTest2.curve.N &&
                privateKeyTest.curve.name == privateKeyTest2.curve.name &&
                privateKeyTest.curve.oid == privateKeyTest2.curve.oid &&
                privateKeyTest.curve.G.x == privateKeyTest2.curve.G.x &&
                privateKeyTest.curve.G.y == privateKeyTest2.curve.G.y &&
                privateKeyTest.curve.G.z == privateKeyTest2.curve.G.z
            if (!teste1 && !teste2) {
                print("chaves divergentes")
            }
        } catch {
            print("deu ruim")
        }


//        PRIVATE KEY - testDerConversion
        do {
            let privateKeyTest = PrivateKey(secret: 123)
            let der = privateKeyTest.toDer()
            let privateKeyTest2 = try PrivateKey.fromDer(der)
            let teste1 = privateKeyTest.secret == privateKeyTest2.secret
            let teste2 = privateKeyTest.curve.A == privateKeyTest2.curve.A &&
                privateKeyTest.curve.B == privateKeyTest2.curve.B &&
                privateKeyTest.curve.P == privateKeyTest2.curve.P &&
                privateKeyTest.curve.N == privateKeyTest2.curve.N &&
                privateKeyTest.curve.name == privateKeyTest2.curve.name &&
                privateKeyTest.curve.oid == privateKeyTest2.curve.oid &&
                privateKeyTest.curve.G.x == privateKeyTest2.curve.G.x &&
                privateKeyTest.curve.G.y == privateKeyTest2.curve.G.y &&
                privateKeyTest.curve.G.z == privateKeyTest2.curve.G.z
            if (!teste1 && !teste2) {
                print("chaves divergentes")
            }
        } catch {
            print("deu ruim")
        }

//        PRIVATE KEY - testStringConversion
        do {
            let privateKeyTest = PrivateKey(secret: 123)
            let string = privateKeyTest.toString()
            let privateKeyTest2 = PrivateKey.fromString(string: string)

            let teste1 = privateKeyTest.secret == privateKeyTest2.secret
            let teste2 = privateKeyTest.curve.A == privateKeyTest2.curve.A &&
                privateKeyTest.curve.B == privateKeyTest2.curve.B &&
                privateKeyTest.curve.P == privateKeyTest2.curve.P &&
                privateKeyTest.curve.N == privateKeyTest2.curve.N &&
                privateKeyTest.curve.name == privateKeyTest2.curve.name &&
                privateKeyTest.curve.oid == privateKeyTest2.curve.oid &&
                privateKeyTest.curve.G.x == privateKeyTest2.curve.G.x &&
                privateKeyTest.curve.G.y == privateKeyTest2.curve.G.y &&
                privateKeyTest.curve.G.z == privateKeyTest2.curve.G.z
            if (!teste1 && !teste2) {
                print("chaves divergentes")
            }
        }

//        PUBLIC KEY - testPemConversion
        do {
            let privateKeyTest = PrivateKey(secret: 123)
            let publicKeyTest = privateKeyTest.publicKey()
            let pem = publicKeyTest.toPem()
            let publicKeyTest2 = try PublicKey.fromPem(pem)

            let teste1 = publicKeyTest.point.x == publicKeyTest2.point.x
            let teste2 = publicKeyTest.point.y == publicKeyTest2.point.y
            let teste3 = publicKeyTest.curve.A == publicKeyTest2.curve.A &&
                publicKeyTest.curve.B == publicKeyTest2.curve.B &&
                publicKeyTest.curve.P == publicKeyTest2.curve.P &&
                publicKeyTest.curve.N == publicKeyTest2.curve.N &&
                publicKeyTest.curve.name == publicKeyTest2.curve.name &&
                publicKeyTest.curve.oid == publicKeyTest2.curve.oid &&
                publicKeyTest.curve.G.x == publicKeyTest2.curve.G.x &&
                publicKeyTest.curve.G.y == publicKeyTest2.curve.G.y &&
                publicKeyTest.curve.G.z == publicKeyTest2.curve.G.z
            if (!teste1 && !teste2 && !teste3) {
                print("chaves divergentes")
            }
        } catch {
            print("deu ruim")
        }

//        PUBLIC KEY - testDerConversion
        do {
            let privateKeyTest = PrivateKey(secret: 123)
            let publicKeyTest = privateKeyTest.publicKey()
            let der = publicKeyTest.toDer()

            let publicKeyTest2 = try PublicKey.fromDer(der)

            let teste1 = publicKeyTest.point.x == publicKeyTest2.point.x
            let teste2 = publicKeyTest.point.y == publicKeyTest2.point.y
            let teste3 = publicKeyTest.curve.A == publicKeyTest2.curve.A &&
                publicKeyTest.curve.B == publicKeyTest2.curve.B &&
                publicKeyTest.curve.P == publicKeyTest2.curve.P &&
                publicKeyTest.curve.N == publicKeyTest2.curve.N &&
                publicKeyTest.curve.name == publicKeyTest2.curve.name &&
                publicKeyTest.curve.oid == publicKeyTest2.curve.oid &&
                publicKeyTest.curve.G.x == publicKeyTest2.curve.G.x &&
                publicKeyTest.curve.G.y == publicKeyTest2.curve.G.y &&
                publicKeyTest.curve.G.z == publicKeyTest2.curve.G.z
            if (!teste1 && !teste2 && !teste3) {
                print("chaves divergentes")
            }
        } catch {
            print("deu ruim")
        }

//        PUBLIC KEY - testStringConversion
        do {
            let privateKeyTest = PrivateKey(secret: 123)
            let publicKeyTest = privateKeyTest.publicKey()
            var string = publicKeyTest.toString()

            let publicKeyTest2 = try PublicKey.fromString(string: &string)

            let teste1 = publicKeyTest.point.x == publicKeyTest2.point.x
            let teste2 = publicKeyTest.point.y == publicKeyTest2.point.y
            let teste3 = publicKeyTest.curve.A == publicKeyTest2.curve.A &&
                publicKeyTest.curve.B == publicKeyTest2.curve.B &&
                publicKeyTest.curve.P == publicKeyTest2.curve.P &&
                publicKeyTest.curve.N == publicKeyTest2.curve.N &&
                publicKeyTest.curve.name == publicKeyTest2.curve.name &&
                publicKeyTest.curve.oid == publicKeyTest2.curve.oid &&
                publicKeyTest.curve.G.x == publicKeyTest2.curve.G.x &&
                publicKeyTest.curve.G.y == publicKeyTest2.curve.G.y &&
                publicKeyTest.curve.G.z == publicKeyTest2.curve.G.z
            if (!teste1 && !teste2 && !teste3) {
                print("chaves divergentes")
            }
        } catch {
            print("deu ruim")
        }

//        SIGNATURE - testDerConversion
        do {
            var hex = "30450220637a1b5db8b8c78af0b372282414d42df4cbd7b5f4489ace875465da2d3a15f3022100f7a92f2d2a67400e85f897c0f24a479b8e665ecff6785c21cc9dd2b81577514a"
            let sig = try Signature.fromString(string: &hex)
            let der = sig.toDer()
            let sig2 = try Signature.fromDer(der)
            let teste1 = sig.r == sig2.r
            let teste2 = sig.s == sig2.s
            if (!teste1 && !teste2) {
                print("assinaturas divergentes")
            }
        } catch {
            print("erro")
        }

//        SIGNATURE - testBase64Conversion
        do {
            var hex = "30450220637a1b5db8b8c78af0b372282414d42df4cbd7b5f4489ace875465da2d3a15f3022100f7a92f2d2a67400e85f897c0f24a479b8e665ecff6785c21cc9dd2b81577514a"
            let sig = try Signature.fromString(string: &hex)
            let base64 = sig.toBase64()
            let sig2 = try Signature.fromBase64(base64)
            let teste1 = sig.r == sig2.r
            let teste2 = sig.s == sig2.s
            if (!teste1 && !teste2) {
                print("assinaturas divergentes")
            }
        } catch {
            print("erro")
        }
        
//        ECDSA - testVerifyRightMessage
        let privateKey = PrivateKey()
        let publicKey = privateKey.publicKey()

        let message = "This is the right message"

        let signature = Ecdsa.sign(message: message, privateKey: privateKey)
        let isValid = Ecdsa.verify(message: message, signature: signature, publicKey: publicKey)
        
//
////        ECDSA - testVerifyWrongMessage
//        let privateKey = PrivateKey()
//        let publicKey = privateKey.publicKey()
//
//        let message1 = "This is the right message"
//        let message2 = "This is the wrong message"
//
//        let signature = Ecdsa.sign(message: message1, privateKey: privateKey)
//        let isValid = Ecdsa.verify(message: message2, signature: signature, publicKey: publicKey)

        self.textView.text = " r:\(signature.r)\n\n s:\(signature.s)\n\n v:\(isValid)"
    }
}

