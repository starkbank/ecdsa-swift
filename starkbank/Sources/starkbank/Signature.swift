//
//  File.swift
//  
//
//  Created by Rafael Stark on 2/15/21.
//

import BigInt
import Foundation


public class Signature {
    
    public var r: BigInt
    public var s: BigInt
    
    public init(_ r: BigInt, _ s: BigInt) {
        self.r = r
        self.s = s
    }
}
