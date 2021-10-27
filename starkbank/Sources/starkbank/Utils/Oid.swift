//
//  File.swift
//  
//
//  Created by Felipe Sueto on 07/10/21.
//

import Foundation
import BigInt


public class Oid {
    
    public static func oidFromHex(hexadecimal: String) -> [Int] {
        let firstByte = String(hexadecimal.prefix(2))
        var remainingBytes = String(hexadecimal.suffix(hexadecimal.count - 2))
        let firstByteInt = BinaryAscii.intFromHex(firstByte)
        var oid = [Int(floor(Double(firstByteInt / 40))), Int(firstByteInt % 40)]
        var oidInt = 0
        while (remainingBytes.count > 0) {
            let byte = String(remainingBytes.prefix(2))
            remainingBytes = String(remainingBytes.suffix(remainingBytes.count - 2))
            let byteInt = Int(BinaryAscii.intFromHex(byte))
            if (byteInt >= 128) {
                oidInt = byteInt - 128
                continue
            }
            oidInt = oidInt * 128 + byteInt
            oid.append(oidInt)
            oidInt = 0
        }
        return oid
    }
    
    public static func oidToHex(oid: [Int]) -> String {
        var hexadecimal = BinaryAscii.hexFromInt(BigInt(40 * oid[0]) + BigInt(oid[1]))
        var byteArray = [Int]()
        for var oidInt in oid[2..<oid.count] {
            var endDelta = 0
            while true {
                let byteInt = oidInt % 128 + endDelta
                oidInt = Int(floor(Double(oidInt / 128)))
                endDelta = 128
                byteArray.append(byteInt)
                if (oidInt == 0) {
                    break
                }
            }
            byteArray.reverse()
            for byte in byteArray {
                hexadecimal += BinaryAscii.hexFromInt(BigInt(byte))
            }
            byteArray = []
        }
        return hexadecimal
    }
}
