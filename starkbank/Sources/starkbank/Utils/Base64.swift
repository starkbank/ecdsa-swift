//
//  File.swift
//  
//
//  Created by Rafael Stark on 2/21/21.
//

import Foundation


public class Base64 {
    
    public static func encode(data: Data) -> String {
        return data.base64EncodedString()
    }
    
    public static func encode(string: String) -> String {
        return self.encode(data: Data(string.utf8))
    }
    
    public static func decode(string: String) -> Data {
        return Data(base64Encoded: string) ?? Data()
    }
    
    public static func decode(string: String) -> String {
        let data: Data = self.decode(string: string)
        return String(data: data, encoding: .utf8) ?? ""
    }
}
