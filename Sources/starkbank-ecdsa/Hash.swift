//
//  File.swift
//  
//
//  Created by Rafael Stark on 2/15/21.
//

import Foundation
import CommonCrypto


public protocol Hash {
    func digest(_ string: String) -> NSData
    func digest(_ data: NSData) -> NSData
}

public class Sha256: Hash {
    
    public init() {}
    
    public func digest(_ string: String) -> NSData {
        let data = string.data(using: String.Encoding.utf8)!
        return digest(data as NSData)
    }
    
    public func digest(_ data : NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(data.bytes, UInt32(data.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }
}
