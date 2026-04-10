import BigInt
import Foundation


/// Extension to match Python's int.bit_length() behavior.
/// Returns the number of bits necessary to represent self, not counting the sign.
/// For positive numbers: floor(log2(self)) + 1
extension BigInt {
    var bitLength: Int {
        if self <= 0 {
            return 0
        }
        // Use binary representation: String(self, radix: 2) gives the binary digits
        // without leading zeros, so its count is exactly bit_length
        return String(self, radix: 2).count
    }
}


class BinaryAscii {

    static func intFromHex(_ hexadecimal: String) -> BigInt {
        return BigInt(hexadecimal, radix: 16)!
    }

    static func hexFromInt(_ number: BigInt) -> String {
        var hexadecimal = String(number, radix: 16)
        if hexadecimal.count % 2 == 1 {
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

    static func hexFromData(_ data: Data) -> String {
        return data.map { String(format: "%02x", $0) }.joined()
    }

    static func dataFromHex(_ hexadecimal: String) -> Data {
        var hex = hexadecimal
        if hex.count % 2 != 0 {
            hex = "0" + hex
        }
        var data = Data(capacity: hex.count / 2)
        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            let byteString = String(hex[index..<nextIndex])
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
            index = nextIndex
        }
        return data
    }

    /// Convert a byte string (Data) to a number, with optional hash truncation.
    /// If bitLength is provided and the hash is larger, right-shift to curve order bit length.
    static func numberFromByteString(_ data: Data, bitLength: Int? = nil) -> BigInt {
        let hex = hexFromData(data)
        var number = intFromHex(hex)
        if let bitLength = bitLength {
            let hashBitLen = data.count * 8
            if hashBitLen > bitLength {
                number >>= (hashBitLen - bitLength)
            }
        }
        return number
    }
}
