import BigInt
import Foundation


public struct GLVParams {
    public let beta: BigInt
    public let lambda: BigInt
    public let a1: BigInt
    public let b1: BigInt
    public let a2: BigInt
    public let b2: BigInt

    public init(beta: BigInt, lambda: BigInt, a1: BigInt, b1: BigInt, a2: BigInt, b2: BigInt) {
        self.beta = beta
        self.lambda = lambda
        self.a1 = a1
        self.b1 = b1
        self.a2 = a2
        self.b2 = b2
    }
}

public class CurveFp {

    public var A: BigInt
    public var B: BigInt
    public var P: BigInt
    public var N: BigInt
    public var G: Point
    public var name: String
    public var nistName: String?
    public var oid: [Int]
    public var nBitLength: Int
    /// GLV endomorphism parameters (only for curves that support one,
    /// e.g. secp256k1). nil means no endomorphism; fall back to Shamir+JSF.
    public let glvParams: GLVParams?
    /// Lazily-initialized precomputed powers-of-two multiples of G in affine
    /// form for the width-2 NAF fixed-base multiplication path.
    internal lazy var generatorTable: [Point] = Math.computeGeneratorTable(curve: self)

    public init(name: String, A: BigInt, B: BigInt, P: BigInt, N: BigInt, Gx: BigInt, Gy: BigInt, oid: [Int], nistName: String? = nil, glvParams: GLVParams? = nil) {
        self.A = A
        self.B = B
        self.P = P
        self.N = N
        self.G = Point(Gx, Gy)
        self.name = name
        self.nistName = nistName
        self.oid = oid
        self.nBitLength = N.bitLength
        self.glvParams = glvParams
    }

    /// Verify if the point `p` is on the curve
    ///
    /// - Parameter p: Point p = Point(x, y)
    /// - Returns: boolean
    public func contains(p: Point) -> Bool {
        if p.x < 0 || p.x > self.P - 1 {
            return false
        }
        if p.y < 0 || p.y > self.P - 1 {
            return false
        }
        if (p.y.power(2) - (p.x.power(3) + self.A * p.x + self.B)).modulus(self.P) != 0 {
            return false
        }
        return true
    }

    public func length() -> Int {
        return (1 + String(N, radix: 16).count) / 2
    }

    public func y(x: BigInt, isEven: Bool) -> BigInt {
        let ySquared = (x.power(3, modulus: P) + A * x + B).modulus(P)
        var y = Math.modularSquareRoot(ySquared, P)
        if isEven != (y % 2 == 0) {
            y = P - y
        }
        return y
    }
}

private var _curvesByOid = [Array<Int>: CurveFp]()

public func curveAdd(_ curve: CurveFp) {
    _curvesByOid[curve.oid] = curve
}

public func getByOid(_ oid: Array<Int>) throws -> CurveFp {
    guard let curve = _curvesByOid[oid] else {
        let names = _curvesByOid.values.map { $0.name }.joined(separator: ", ")
        let oidStr = oid.map { String($0) }.joined(separator: ".")
        throw Error.invalidOidError("Unknown curve with oid \(oidStr); The following are registered: \(names)")
    }
    return curve
}

public let secp256k1 = CurveFp(
    name: "secp256k1",
    A: BigInt("0000000000000000000000000000000000000000000000000000000000000000", radix: 16)!,
    B: BigInt("0000000000000000000000000000000000000000000000000000000000000007", radix: 16)!,
    P: BigInt("fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f", radix: 16)!,
    N: BigInt("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141", radix: 16)!,
    Gx: BigInt("79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798", radix: 16)!,
    Gy: BigInt("483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8", radix: 16)!,
    oid: [1, 3, 132, 0, 10],
    // GLV endomorphism phi((x,y)) = (beta*x, y), equivalent to lambda*P.
    // Basis vectors from Gauss reduction; used to split a 256-bit scalar k
    // into two ~128-bit scalars (k1, k2) with k = k1 + k2*lambda (mod N).
    glvParams: GLVParams(
        beta: BigInt("7ae96a2b657c07106e64479eac3434e99cf0497512f58995c1396c28719501ee", radix: 16)!,
        lambda: BigInt("5363ad4cc05c30e0a5261c028812645a122e22ea20816678df02967c1b23bd72", radix: 16)!,
        a1: BigInt("3086d221a7d46bcde86c90e49284eb15", radix: 16)!,
        b1: -BigInt("e4437ed6010e88286f547fa90abfe4c3", radix: 16)!,
        a2: BigInt("114ca50f7a8e2f3f657c1108d9d44cfd8", radix: 16)!,
        b2: BigInt("3086d221a7d46bcde86c90e49284eb15", radix: 16)!
    )
)

public let prime256v1 = CurveFp(
    name: "prime256v1",
    A: BigInt("ffffffff00000001000000000000000000000000fffffffffffffffffffffffc", radix: 16)!,
    B: BigInt("5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b", radix: 16)!,
    P: BigInt("ffffffff00000001000000000000000000000000ffffffffffffffffffffffff", radix: 16)!,
    N: BigInt("ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551", radix: 16)!,
    Gx: BigInt("6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296", radix: 16)!,
    Gy: BigInt("4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5", radix: 16)!,
    oid: [1, 2, 840, 10045, 3, 1, 7],
    nistName: "P-256"
)

public let p256 = prime256v1

private let _initCurves: Void = {
    curveAdd(secp256k1)
    curveAdd(prime256v1)
}()

public func ensureCurvesRegistered() {
    _ = _initCurves
}
