//
//  File 2.swift
//  
//
//  Created by Rafael Stark on 2/17/21.
//

import BigInt
import Foundation


class BinaryAscii {
    
    static func intFromHex(_ hex: String) -> BigInt {
        return BigInt(hex, radix: 16)!
    }
    
    static func hexFromInt(_ int: BigInt) -> String {
        var hexadecimal = String(int, radix: 16)
        if (hexadecimal.count % 2 == 1) {
            hexadecimal = "0" + hexadecimal
        }
        return hexadecimal
    }
    
    static func bitsFromHex(_ hex: String) -> String {
        let binary = String(BigInt(hex, radix: 16)!, radix: 2)
        return binary.zfill(hex.count * 4)
    }
    
    static func stringFromBase64(_ base64: String) -> Data {
        return Data(base64Encoded: base64)!
    }
    
    static func base64FromString(_ string: Data) -> String {
        return string.base64EncodedString()
    }
    
    static func hexFromString(_ string: Data) -> String {
        let data = Data(string)
        return data.map{ String(format:"%02x", $0) }.joined()
    }
    
    static func binaryFromHex(_ hex: String) -> Data {
        var data = Data(capacity: hex.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: hex, range: NSRange(hex.startIndex..., in: hex)) { match, _, _ in
            let byteString = (hex as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }
        guard data.count > 0 else { return Data() }
        return data

    }
}
