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
    
    public func toString(encoded: Bool = false) ->  String {
        let baseLength = Int(2 * self.curve.length())
        let xHex = BinaryAscii.hexFromInt(self.point.x).zfill(baseLength)
        let yHex = BinaryAscii.hexFromInt(self.point.y).zfill(baseLength)
        let string = xHex + yHex
        if encoded {
            return "0004" + string
        }
        return string
    }
    
    public func toDer() -> Data {
        let hexadecimal = Der.encodeConstructed(
            Der.encodeConstructed(
                Der.encodeObject([1, 2, 840, 10045, 2, 1]),
                Der.encodeObject(curve.oid)
            ),
            Der.encodeBitString(toString(encoded: true))
        )
        return BinaryAscii.dataFromHex(hexadecimal)
    }
    
    public func toPem() -> String {
        let der = toDer()
        return createPem(content: BinaryAscii.base64FromData(der), template: publicKeyPemTemplate)
    }
    
    public static func fromPem(_ pem: String) throws -> PublicKey {
        let publicKeyPem = getPemContent(pem: pem)
        return try fromDer(BinaryAscii.dataFromBase64(publicKeyPem))

    }
    
    public static func fromDer(_ data: Data) throws -> PublicKey{
        var hexadecimal = BinaryAscii.hexFromData(data)
        
        let parsed = try Der.parse(hexadecimal: &hexadecimal)[0] as! [Any]
        let publicKeyOid = (parsed[0] as! [Any])[0] as! [Int]
        let curveOid = (parsed[0] as! [Any])[1] as! [Int]
        var pointString = parsed[1] as! String
        
        if (publicKeyOid != [1, 2, 840, 10045, 2, 1]) {
            throw Error.matchError("The Public Key Object Identifier (OID) should be [1, 2, 840, 10045, 2, 1], but {actualOid} was found instead"
                                    .replacingOccurrences(of: "{actualOid}", with: publicKeyOid.description))
        }
        let curve = try getCurveByOid(curveOid)
        return try fromString(string: &pointString, curve: curve)
    }
    
    public static func fromString(string: inout String, curve: CurveFp = secp256k1, validatePoint: Bool = true) throws -> PublicKey {
        let baseLength = 2 * curve.length()
        if (string.count > 2 * baseLength && String(string.prefix(4)) == "0004") {
            string = String(string.suffix(string.count - 4))
        }
        let xs = String(string.prefix(Int(baseLength)))
        let ys = String(string.suffix(Int(baseLength)))
        
        let point = Point(BinaryAscii.intFromHex(xs), BinaryAscii.intFromHex(ys))
        
        if (validatePoint && !curve.contains(p: point)) {
            throw Error.pointError("Point ({x},{y}) is not valid for curve {name}"
                                    .replacingOccurrences(of: "{x}", with: String(point.x))
                                    .replacingOccurrences(of:"{y}", with: String(point.y))
                                    .replacingOccurrences(of:"{name}", with: curve.name))
        }
        return PublicKey(point: point, curve: curve)
    }
}

let publicKeyPemTemplate = """
-----BEGIN PUBLIC KEY-----
{content}
-----END PUBLIC KEY-----
"""
