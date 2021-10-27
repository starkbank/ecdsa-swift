//
//  File.swift
//  
//
//  Created by Rafael Stark on 5/3/21.
//

import Foundation


extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(self.count - range.lowerBound, range.upperBound - range.lowerBound))
        return String(self[start..<end])
    }
    
    func zfill(_ length: Int) -> String {
        return String(String(self.reversed()).padding(toLength: length, withPad: "0", startingAt: 0).reversed())
    }
}
