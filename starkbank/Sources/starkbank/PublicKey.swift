//
//  File.swift
//  
//
//  Created by Rafael Stark on 2/15/21.
//

import Foundation


public class PublicKey {
    
    public var point: Point
    public var curve: CurveFp
    
    public init(point: Point, curve: CurveFp) {
        self.point = point
        self.curve = curve
    }
}
