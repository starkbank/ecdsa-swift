//
//  File.swift
//  
//
//  Created by Rafael Stark on 2/17/21.
//

import BigInt
import Foundation


class RandomInteger {
    
    /**
        - Parameter minimum: minimum value of the integer
        - Parameter maximum: maximum value of the integer
        - Returns: integer x in the range: minimum <= x <= maximum
    */
    public static func between(minimum: BigInt, maximum: BigInt) throws -> BigInt {
        let result = getBytesNeeded(maximum - minimum)
        let bytesNeeded = result.0
        let mask = result.1

        var bytes = [Int](repeating: 0, count: bytesNeeded)

        let status = SecRandomCopyBytes(
            kSecRandomDefault,
            bytesNeeded,
            &bytes
        )

        var randomValue = BigInt(0)

        if status != errSecSuccess {
            throw Error.generationError("Error to generate random Int")
        }
        
        (0..<bytesNeeded).forEach {
            randomValue |= BigInt(bytes[$0]) << (8 * $0)
        }
                    
        randomValue &= mask
                    
        if (randomValue > maximum - minimum) {
            return try between(minimum: minimum, maximum: maximum)
        }
        return minimum + randomValue
    }
    
    public static func getBytesNeeded(_ request: BigInt) -> (Int, BigInt) {
        var range = request
        var bitsNeeded = 0
        var bytesNeeded = 0
        var mask = BigInt(1)
        
        while (range > 0) {
            if (bitsNeeded % 8 == 0) {
                bytesNeeded += 1
            }
            bitsNeeded += 1
            mask = (mask << 1) | BigInt(1)
            range = range >> 1
        }
        return (bytesNeeded, mask)
    }
}
