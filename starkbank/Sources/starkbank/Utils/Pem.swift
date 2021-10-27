//
//  File.swift
//  
//
//  Created by Felipe Sueto on 21/10/21.
//

import Foundation

func getPemContent(pem: String) -> String {
    let regex = "(?i)(\n)?-* ?(BEGIN|END) ((PRIVATE EC|PUBLIC EC)|(EC PRIVATE|EC PUBLIC)|(PRIVATE|PUBLIC)) KEY ?-*(\n)?"
    return pem.replacingOccurrences(of: regex, with: "", options: [.regularExpression]).split(whereSeparator: \.isNewline).joined(separator: "")
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
