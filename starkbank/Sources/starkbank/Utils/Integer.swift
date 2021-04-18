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
        - Parameter min: minimum value of the integer
        - Parameter max: maximum value of the integer
        - Returns: integer x in the range: min <= x <= max
    */
    static func between(_ min: BigInt, _ max: BigInt) -> BigInt {
        return min + BigInt(BigUInt.randomInteger(lessThan: BigUInt(max + 1 - min)))
    }
}
