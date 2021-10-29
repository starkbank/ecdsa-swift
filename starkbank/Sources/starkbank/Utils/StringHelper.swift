//
//  File.swift
//  
//
//  Created by Felipe Sueto on 27/10/21.
//

import Foundation

class StringHelper {
    
    public static func zfill(_ string: String, _ length: Int) -> String {
        return String(String(string.reversed()).padding(toLength: length, withPad: "0", startingAt: 0).reversed())
    }
}
