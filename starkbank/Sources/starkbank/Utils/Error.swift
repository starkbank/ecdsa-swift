//
//  File.swift
//  
//
//  Created by Felipe Sueto on 27/10/21.
//

import Foundation

enum Error: Swift.Error {
    case flagError(String)
    case parserError(String)
    case matchError(String)
    case invalidOidError(String)
    case pointError(String)
}
