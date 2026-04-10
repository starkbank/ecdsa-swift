import Foundation


public class Benchmark {

    public static let rounds = 100

    public static func run() {
        let privateKey = PrivateKey()
        let publicKey = privateKey.publicKey()
        let message = "This is a benchmark test message"

        // Warmup
        var sig = Ecdsa.sign(message: message, privateKey: privateKey)
        let _ = Ecdsa.verify(message: message, signature: sig, publicKey: publicKey)

        // Benchmark sign
        var start = Date()
        for _ in 0..<rounds {
            sig = Ecdsa.sign(message: message, privateKey: privateKey)
        }
        let signTime = Date().timeIntervalSince(start) / Double(rounds) * 1000.0

        // Benchmark verify
        start = Date()
        for _ in 0..<rounds {
            let _ = Ecdsa.verify(message: message, signature: sig, publicKey: publicKey)
        }
        let verifyTime = Date().timeIntervalSince(start) / Double(rounds) * 1000.0

        print("")
        print("starkbank-ecdsa benchmark (\(rounds) rounds)")
        print("---------------------------------------")
        print(String(format: "sign:    %.1fms", signTime))
        print(String(format: "verify:  %.1fms", verifyTime))
        print("")
    }
}
