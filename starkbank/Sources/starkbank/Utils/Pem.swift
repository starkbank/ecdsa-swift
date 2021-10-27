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

func createPem(content: Data, template: String) -> String {
    var lines = Array<Data>()
    for start in stride(from: 0, to: content.count, by: 64) {
        let begin = content.index(content.startIndex, offsetBy: start)
        let limit = Int(start.description)! + 64
        let end = content.index(content.startIndex, offsetBy: limit <= content.count ? limit : content.count)
        lines.append(content[begin..<end])
    }
    let stringLines = lines.map { String(data: $0, encoding: .utf8)! }
    return template.replacingOccurrences(of: "{content}", with: stringLines.joined(separator: "\n"))
}
