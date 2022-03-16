//
//  File.swift
//  
//
//  Created by Felipe Sueto on 21/10/21.
//

import Foundation

func getPemContent(pem: String, template: String) throws -> String {
    let parsedPem = String(pem.filter { !"\n\r".contains($0) })
    let parsedTemplate = String(template.filter { !"\n\r".contains($0) })
        .replacingOccurrences(of: "{content}", with: "(.*)")
    
    let captureRegex = try! NSRegularExpression(pattern: parsedTemplate, options: [])
    let matches = captureRegex.matches(in: parsedPem, options: [], range: NSRange(parsedTemplate.startIndex..<parsedPem.endIndex, in: parsedPem))
    
    guard let match = matches.first else {
        throw Error.matchError("PEM not found")
    }
    return (parsedPem as NSString).substring(with: match.range(at: 1)) as String
}

func createPem(content: String, template: String) -> String {
    var lines = Array<String>()
    for start in stride(from: 0, to: content.count, by: 64) {
        let begin = content.index(content.startIndex, offsetBy: start)
        let limit = Int(start.description)! + 64
        let end = content.index(content.startIndex, offsetBy: limit <= content.count ? limit : content.count)
        lines.append(String(content[begin..<end]))
    }
    return template.replacingOccurrences(of: "{content}", with: lines.joined(separator: "\n"))
}
