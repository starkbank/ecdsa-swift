## A lightweight and fast pure Swift ECDSA

### Overview

Swift library plus bindings for ECDSA signatures and secret/public key operations.

<!-- ### Installation
-->

### Curves

We currently support `secp256k1`, but it's super easy to add more curves to the project. Just add them on `Curve.swift`

### Speed

We ran a test on a MAC Pro i5 2017. The libraries were run 100 times and the averages displayed bellow were obtained:

| Library            | sign          | verify  |
| ------------------ |:-------------:| -------:|
| starkbank-ecdsa    |     0.3ms     |  1.1ms  |

### Sample Code

How to sign a json message for [Stark Bank]:

```swift
import starkbank

// Generate privateKey from PEM string
let privateKey = try PrivateKey.fromPem("""
-----BEGIN EC PARAMETERS-----
BgUrgQQACg==
-----END EC PARAMETERS-----
-----BEGIN EC PRIVATE KEY-----
MHQCAQEEIODvZuS34wFbt0X53+P5EnSj6tMjfVK01dD1dgDH02RzoAcGBSuBBAAK
oUQDQgAE/nvHu/SQQaos9TUljQsUuKI15Zr5SabPrbwtbfT/408rkVVzq8vAisbB
RmpeRREXj5aog/Mq8RrdYy75W9q/Ig==
-----END EC PRIVATE KEY-----
""")

// Create message from json
let message = "This is a text message"

let signature = try Ecdsa.sign(message: message, privateKey: privateKey)

// Generate Signature in base64. This result can be sent to Stark Bank in the request header as the Digital-Signature parameter.
print(signature.toBase64())

// To double check if the message matches the signature, do this:
let publicKey = privateKey.publicKey()

print(Ecdsa.verify(message: message, signature: signature, publicKey: publicKey))

```

Simple use:

```swift
import starkbank

// Generate new Keys
let privateKey = try PrivateKey()
let publicKey = privateKey.publicKey()

let message = "My test message"

// Generate Signature
let signature = try Ecdsa.sign(message: message, privateKey: privateKey)

// To verify if the signature is valid
print(Ecdsa.verify(message: message, signature: signature, publicKey: publicKey))
```

### OpenSSL

This library is compatible with OpenSSL, so you can use it to generate keys:

```
openssl ecparam -name secp256k1 -genkey -out privateKey.pem
openssl ec -in privateKey.pem -pubout -out publicKey.pem
```

Create a message.txt file and sign it:

```
openssl dgst -sha256 -sign privateKey.pem -out signatureDer.txt message.txt
```

To verify, do this:

```swift
import starkbank

let publicKeyPem = try? NSString(contentsOfFile: NSString(string:"/path/to/your/public-key/publicKey.pem").expandingTildeInPath, encoding: String.Encoding.utf8.rawValue)
let signatureDer = try? NSString(contentsOfFile: NSString(string:"/path/to/your/signature/signatureDer.txt").expandingTildeInPath, encoding: String.Encoding.utf8.rawValue)
let message = try? NSString(contentsOfFile: NSString(string:"/path/to/your/message/message.txt").expandingTildeInPath, encoding: String.Encoding.utf8.rawValue)

let publicKey = try PrivateKey.fromPem(privateKeyPem! as String)
let signature = try Signature.fromDer(signatureDer)

print(Ecdsa.verify(message: message! as String, signature: signature, publicKey: publicKey))
```

You can also verify it on terminal:

```
openssl dgst -sha256 -verify publicKey.pem -signature signatureDer.txt message.txt
```

NOTE: If you want to create a Digital Signature to use with [Stark Bank], you need to convert the binary signature to base64.

```
openssl base64 -in signatureDer.txt -out signatureBase64.txt
```

You can do the same with this library:
 
```swift
import starkbank

let signatureDer = try? NSString(contentsOfFile: NSString(string:"/path/to/your/signature/signatureDer.txt").expandingTildeInPath, encoding: String.Encoding.utf8.rawValue)

let signature = try Signature.fromDer(signatureDer)

print(signature.toBase64())
```

[Stark Bank]: https://starkbank.com
