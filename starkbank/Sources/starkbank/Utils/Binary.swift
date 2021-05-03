//
//  File 2.swift
//  
//
//  Created by Rafael Stark on 2/17/21.
//

import BigInt
import Foundation


class BinaryAscii {
    
    static func hexFromBinary(_ data: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: data.length)
        data.getBytes(&bytes, length: data.length)
        
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }
        
        return hexString
    }
    
    static func numberFromString(_ data: NSData) -> BigInt {
        return BigInt(self.hexFromBinary(data), radix: 16)!
    }
}