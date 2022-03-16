//
//  File 2.swift
//  
//
//  Created by Rafael Stark on 2/17/21.
//

import BigInt
import Foundation


class BinaryAscii {
    
    static func intFromHex(_ hexadecimal: String) -> BigInt {
        return BigInt(hexadecimal, radix: 16)!
    }
    
    static func hexFromInt(_ number: BigInt) -> String {
        var hexadecimal = String(number, radix: 16)
        if (hexadecimal.count % 2 == 1) {
            hexadecimal = "0" + hexadecimal
        }
        return hexadecimal
    }
    
    static func bitsFromHex(_ hexadecimal: String) -> String {
        let binary = String(BigInt(hexadecimal, radix: 16)!, radix: 2)
        return StringHelper.zfill(binary, hexadecimal.count * 4)
    }
    
    static func dataFromBase64(_ base64String: String) -> Data {
        return Data(base64Encoded: base64String)!
    }
    
    static func base64FromData(_ string: Data) -> String {
        return string.base64EncodedString()
    }
    
    static func hexFromData(_ string: Data) -> String {
        let data = Data(string)
        return data.map{ String(format:"%02x", $0) }.joined()
    }
    
    static func dataFromHex(_ hexadecimal: String) -> Data {
        var data = Data(capacity: hexadecimal.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: hexadecimal, range: NSRange(hexadecimal.startIndex..., in: hexadecimal)) { match, _, _ in
            let byteString = (hexadecimal as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }
        return data
    }
}
