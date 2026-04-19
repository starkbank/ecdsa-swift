import Foundation
import CommonCrypto


public protocol Hash {
    var digestLength: Int { get }
    func digest(_ string: String) -> Data
    func digest(_ data: Data) -> Data
}

public class Sha256: Hash {

    public var digestLength: Int { return Int(CC_SHA256_DIGEST_LENGTH) }

    public init() {}

    public func digest(_ string: String) -> Data {
        let data = string.data(using: .utf8)!
        return digest(data)
    }

    public func digest(_ data: Data) -> Data {
        let length = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: length)
        data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            _ = CC_SHA256(ptr.baseAddress, UInt32(data.count), &hash)
        }
        return Data(hash)
    }
}

public class Sha512: Hash {

    public var digestLength: Int { return Int(CC_SHA512_DIGEST_LENGTH) }

    public init() {}

    public func digest(_ string: String) -> Data {
        let data = string.data(using: .utf8)!
        return digest(data)
    }

    public func digest(_ data: Data) -> Data {
        let length = Int(CC_SHA512_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: length)
        data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            _ = CC_SHA512(ptr.baseAddress, UInt32(data.count), &hash)
        }
        return Data(hash)
    }
}
