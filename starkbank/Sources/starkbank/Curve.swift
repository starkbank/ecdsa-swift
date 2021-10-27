//
//  File.swift
//  
//
//  Created by Rafael Stark on 2/14/21.
//

import BigInt
import Foundation


public class CurveFp {
    
    public var A: BigInt
    public var B: BigInt
    public var P: BigInt
    public var N: BigInt
    public var G: Point
    public var name: String
    public var oid: [Int]
    
    init(name: String, A: BigInt, B: BigInt, P: BigInt, N: BigInt, Gx: BigInt, Gy: BigInt, oid: [Int]) {
        self.A = A
        self.B = B
        self.P = P
        self.N = N
        self.G = Point(Gx, Gy)
        self.name = name
        self.oid = oid
    }
    
    /**
    Verify if the point `p` is on the curve
    - Parameter p: Point p = Point(x, y)
    - Returns: boolean
    */
    func contains(p: Point) -> Bool {
        return (p.y.power(2) - (p.x.power(3) + self.A * p.x + self.B)) % self.P == 0
    }
    
    func length() -> BigInt {
        return BigInt((1 + String(N, radix: 16).count) / 2)
    }
}

public let secp256k1 = CurveFp(
    name: "secp256k1",
    A: BigInt("0000000000000000000000000000000000000000000000000000000000000000", radix: 16)!,
    B: BigInt("0000000000000000000000000000000000000000000000000000000000000007", radix: 16)!,
    P: BigInt("fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f", radix: 16)!,
    N: BigInt("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141", radix: 16)!,
    Gx: BigInt("79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798", radix: 16)!,
    Gy: BigInt("483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8", radix: 16)!,
    oid: [1, 3, 132, 0, 10]
)

let supportedCurves = [
    secp256k1
]

let curvesByOid = supportedCurves.reduce([Array<Int>: CurveFp]()) { (dict, curve) -> [Array<Int>: CurveFp] in
    var dict = dict
    dict[curve.oid] = curve
    return dict
}

public func getCurveByOid(_ oid: Array<Int>) throws -> CurveFp {
    if (curvesByOid[oid] == nil) {
        throw Error.invalidOidError("Unknown curve with oid {receivedOid}; The following are registered: {registeredOids}".replacingOccurrences(of: "{receivedOid}", with: oid.description).replacingOccurrences(of: "{registeredOids}", with: supportedCurves.description))
    }
    return curvesByOid[oid]!
}
