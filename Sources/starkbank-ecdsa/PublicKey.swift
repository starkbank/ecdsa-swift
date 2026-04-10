import BigInt
import Foundation


public class PublicKey {

    public var point: Point
    public var curve: CurveFp

    public init(point: Point, curve: CurveFp) {
        self.point = point
        self.curve = curve
    }

    public func toPem() -> String {
        let der = toDer()
        return createPem(content: BinaryAscii.base64FromData(der), template: _publicKeyPemTemplate)
    }

    public static func fromPem(_ string: String) throws -> PublicKey {
        ensureCurvesRegistered()
        let publicKeyPem = try getPemContent(pem: string, template: _publicKeyPemTemplate)
        return try fromDer(BinaryAscii.dataFromBase64(publicKeyPem))
    }

    public func toDer() -> Data {
        let hexadecimal = Der.encodeConstructed(
            Der.encodeConstructed(
                Der.encodeObject(_ecdsaPublicKeyOid),
                Der.encodeObject(curve.oid)
            ),
            Der.encodeBitString(toString(encoded: true))
        )
        return BinaryAscii.dataFromHex(hexadecimal)
    }

    public static func fromDer(_ string: Data) throws -> PublicKey {
        ensureCurvesRegistered()
        var hexadecimal = BinaryAscii.hexFromData(string)

        let parsed = try Der.parse(&hexadecimal)[0] as! [Any]
        let publicKeyOid = (parsed[0] as! [Any])[0] as! [Int]
        let curveOid = (parsed[0] as! [Any])[1] as! [Int]
        var pointString = parsed[1] as! String

        if publicKeyOid != _ecdsaPublicKeyOid {
            throw Error.matchError("The Public Key Object Identifier (OID) should be \(_ecdsaPublicKeyOid), but \(publicKeyOid) was found instead")
        }
        let curve = try getByOid(curveOid)
        return try fromString(string: &pointString, curve: curve)
    }

    public func toString(encoded: Bool = false) -> String {
        let baseLength = 2 * self.curve.length()
        let xHex = StringHelper.zfill(BinaryAscii.hexFromInt(self.point.x), baseLength)
        let yHex = StringHelper.zfill(BinaryAscii.hexFromInt(self.point.y), baseLength)
        let string = xHex + yHex
        if encoded {
            return "0004" + string
        }
        return string
    }

    public func toCompressed() -> String {
        let baseLength = 2 * self.curve.length()
        let parityTag = self.point.y % 2 == 0 ? _evenTag : _oddTag
        let xHex = StringHelper.zfill(BinaryAscii.hexFromInt(self.point.x), baseLength)
        return parityTag + xHex
    }

    public static func fromString(string: inout String, curve: CurveFp = secp256k1, validatePoint: Bool = true) throws -> PublicKey {
        let baseLength = 2 * curve.length()
        if string.count > 2 * baseLength && String(string.prefix(4)) == "0004" {
            string = String(string.suffix(string.count - 4))
        }
        let xs = String(string.prefix(baseLength))
        let ys = String(string.suffix(baseLength))

        let point = Point(BinaryAscii.intFromHex(xs), BinaryAscii.intFromHex(ys))

        let publicKey = PublicKey(point: point, curve: curve)
        if !validatePoint {
            return publicKey
        }
        if point.isAtInfinity() {
            throw Error.infinityError("Public Key point is at infinity")
        }
        if !curve.contains(p: point) {
            throw Error.pointError("Point (\(point.x),\(point.y)) is not valid for curve \(curve.name)")
        }
        if !Math.multiply(point, curve.N, curve.N, curve.A, curve.P).isAtInfinity() {
            throw Error.pointError("Point (\(point.x),\(point.y)) * \(curve.name).N is not at infinity")
        }
        return publicKey
    }

    public static func fromCompressed(_ string: String, curve: CurveFp = secp256k1) throws -> PublicKey {
        let parityTag = String(string.prefix(2))
        let xHex = String(string.suffix(string.count - 2))
        if parityTag != _evenTag && parityTag != _oddTag {
            throw Error.pointError("Compressed string should start with 02 or 03")
        }
        let x = BinaryAscii.intFromHex(xHex)
        let y = curve.y(x: x, isEven: parityTag == _evenTag)
        return PublicKey(point: Point(x, y), curve: curve)
    }
}

private let _evenTag = "02"
private let _oddTag = "03"
private let _ecdsaPublicKeyOid = [1, 2, 840, 10045, 2, 1]

private let _publicKeyPemTemplate = "\n-----BEGIN PUBLIC KEY-----\n{content}\n-----END PUBLIC KEY-----\n"
