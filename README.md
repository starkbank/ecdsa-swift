## A lightweight and fast pure Swift ECDSA

### Overview

This is a pure Swift implementation of the Elliptic Curve Digital Signature Algorithm. It is compatible with Swift 5.3 and later. It is also compatible with OpenSSL. It uses elegant math such as Jacobian Coordinates to speed up the ECDSA on pure Swift.

### Security

starkbank-ecdsa includes the following security features:

- **RFC 6979 deterministic nonces**: Eliminates the catastrophic risk of nonce reuse that leaks private keys
- **Low-S signature normalization**: Prevents signature malleability (BIP-62)
- **Public key on-curve validation**: Blocks invalid-curve attacks during verification
- **Montgomery ladder scalar multiplication**: Constant-operation point multiplication to mitigate timing side channels
- **Hash truncation**: Correctly handles hash functions larger than the curve order (e.g. SHA-512 with secp256k1)
- **Fermat's little theorem for modular inverse**: More uniform execution time than the extended Euclidean algorithm

### Curves

We currently support `secp256k1` and `prime256v1` (P-256), but you can add more curves to the project. Just use the `curveAdd()` function.

### Speed

We ran a test on Swift 6.3 on a MAC Pro (release build). The library was run 100 times and the averages displayed below were obtained:

| Library            | sign          | verify  |
| ------------------ |:-------------:| -------:|
| starkbank-ecdsa    |     7.0ms     |  5.7ms  |

The library uses Jacobian Coordinates, a Montgomery ladder for constant-time scalar multiplication, and Shamir's trick for fast signature verification.

### Sample Code

How to sign a json message for [Stark Bank]:

```swift
import starkbank_ecdsa

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

// Create message
let message = "My test message"

let signature = Ecdsa.sign(message: message, privateKey: privateKey)

// Generate Signature in base64. This result can be sent to Stark Bank in the request header as the Digital-Signature parameter.
print(signature.toBase64())

// To double check if the message matches the signature, do this:
let publicKey = privateKey.publicKey()

print(Ecdsa.verify(message: message, signature: signature, publicKey: publicKey))
```

Simple use:

```swift
import starkbank_ecdsa

// Generate new Keys
let privateKey = PrivateKey()
let publicKey = privateKey.publicKey()

let message = "My test message"

// Generate Signature
let signature = Ecdsa.sign(message: message, privateKey: privateKey)

// To verify if the signature is valid
print(Ecdsa.verify(message: message, signature: signature, publicKey: publicKey))
```

How to add more curves:

```swift
import starkbank_ecdsa
import BigInt

let newCurve = CurveFp(
    name: "frp256v1",
    A: BigInt("f1fd178c0b3ad58f10126de8ce42435b3961adbcabc8ca6de8fcf353d86e9c00", radix: 16)!,
    B: BigInt("ee353fca5428a9300d4aba754a44c00fdfec0c9ae4b1a1803075ed967b7bb73f", radix: 16)!,
    P: BigInt("f1fd178c0b3ad58f10126de8ce42435b3961adbcabc8ca6de8fcf353d86e9c03", radix: 16)!,
    N: BigInt("f1fd178c0b3ad58f10126de8ce42435b53dc67e140d2bf941ffdd459c6d655e1", radix: 16)!,
    Gx: BigInt("b6b3d4c356c139eb31183d4749d423958c27d2dcaf98b70164c97a2dd98f5cff", radix: 16)!,
    Gy: BigInt("6142e0f7c8b204911f9271f0f3ecef8c2701c307e8e4c9e183115a1554062cfb", radix: 16)!,
    oid: [1, 2, 250, 1, 223, 101, 256, 1]
)

curveAdd(newCurve)
```

How to generate compressed public key:

```swift
import starkbank_ecdsa

let privateKey = PrivateKey()
let publicKey = privateKey.publicKey()
let compressedPublicKey = publicKey.toCompressed()

print(compressedPublicKey)
```

How to recover a compressed public key:

```swift
import starkbank_ecdsa

let compressedPublicKey = "0252972572d465d016d4c501887b8df303eee3ed602c056b1eb09260dfa0da0ab2"
let publicKey = try PublicKey.fromCompressed(compressedPublicKey)

print(publicKey.toPem())
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
import starkbank_ecdsa

let publicKeyPem = try String(contentsOfFile: "publicKey.pem", encoding: .utf8)
let signatureDerData = try Data(contentsOf: URL(fileURLWithPath: "signatureDer.txt"))
let message = try String(contentsOfFile: "message.txt", encoding: .utf8)

let publicKey = try PublicKey.fromPem(publicKeyPem)
let signature = try Signature.fromDer(signatureDerData)

print(Ecdsa.verify(message: message, signature: signature, publicKey: publicKey))
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
import starkbank_ecdsa

let signatureDerData = try Data(contentsOf: URL(fileURLWithPath: "signatureDer.txt"))
let signature = try Signature.fromDer(signatureDerData)

print(signature.toBase64())
```

### Run unit tests

```
swift test
```

### Run benchmark

```swift
// In your code:
Benchmark.run()
```

[Stark Bank]: https://starkbank.com
