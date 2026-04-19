import BigInt
import Foundation


public class Signature {

    public var r: BigInt
    public var s: BigInt
    public var recoveryId: Int?

    public init(_ r: BigInt, _ s: BigInt, recoveryId: Int? = nil) {
        self.r = r
        self.s = s
        self.recoveryId = recoveryId
    }

    public func toDer(withRecoveryId: Bool = false) -> Data {
        let hexadecimal = self._toString()
        let encodedSequence = BinaryAscii.dataFromHex(hexadecimal)
        if !withRecoveryId {
            return encodedSequence
        }
        var result = Data([UInt8(27 + (self.recoveryId ?? 0))])
        result.append(encodedSequence)
        return result
    }

    public static func fromDer(_ data: Data, recoveryByte: Bool = false) throws -> Signature {
        var recoveryId: Int? = nil
        var data = data
        if recoveryByte {
            recoveryId = Int(data[0]) - 27
            data = data.subdata(in: 1..<data.count)
        }
        var hexadecimal = BinaryAscii.hexFromData(data)
        return try _fromString(string: &hexadecimal, recoveryId: recoveryId)
    }

    public func toBase64(withRecoveryId: Bool = false) -> String {
        return BinaryAscii.base64FromData(self.toDer(withRecoveryId: withRecoveryId))
    }

    public static func fromBase64(_ string: String, recoveryByte: Bool = false) throws -> Signature {
        let der = BinaryAscii.dataFromBase64(string)
        return try fromDer(der, recoveryByte: recoveryByte)
    }

    func _toString() -> String {
        return Der.encodeConstructed(
            Der.encodeInteger(self.r),
            Der.encodeInteger(self.s)
        )
    }

    static func _fromString(string: inout String, recoveryId: Int? = nil) throws -> Signature {
        let parsed = try Der.parse(&string)[0] as! [Any]
        let r = parsed[0] as! BigInt
        let s = parsed[1] as! BigInt
        return Signature(r, s, recoveryId: recoveryId)
    }
}
