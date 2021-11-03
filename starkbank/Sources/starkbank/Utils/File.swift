//
//  File.swift
//  
//
//  Created by Felipe Sueto on 03/11/21.
//

import Foundation

public class File {
    
    public static func read(_ path: String, _ fileExtension: String) throws -> String {
        let bundle = Bundle(for: self)
        if let filePath = bundle.url(forResource: path, withExtension: fileExtension) {
            let data = try Data(contentsOf: filePath)
            let content = String(data: data, encoding: .utf8)
            if content == nil {
                return BinaryAscii.base64FromData(data)
            }
            return content!
        }
        throw Error.invalidPath("File not found.")
    }
}
    
