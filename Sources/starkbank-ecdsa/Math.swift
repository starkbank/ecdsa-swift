import BigInt
import Foundation


private let _generatorWindowBits = 4


class Math {

    /// Tonelli-Shanks algorithm for modular square root. Works for all odd primes.
    static func modularSquareRoot(_ value: BigInt, _ prime: BigInt) -> BigInt {
        if value == 0 {
            return 0
        }
        if prime == 2 {
            return value % 2
        }

        // Factor out powers of 2: prime - 1 = Q * 2^S
        var Q = prime - 1
        var S = 0
        while Q % 2 == 0 {
            Q /= 2
            S += 1
        }

        if S == 1 {  // prime = 3 (mod 4)
            return value.power((prime + 1) / 4, modulus: prime)
        }

        // Find a quadratic non-residue z
        var z = BigInt(2)
        while z.power((prime - 1) / 2, modulus: prime) != prime - 1 {
            z += 1
        }

        var M = S
        var c = z.power(Q, modulus: prime)
        var t = value.power(Q, modulus: prime)
        var R = value.power((Q + 1) / 2, modulus: prime)

        while true {
            if t == 1 {
                return R
            }

            // Find the least i such that t^(2^i) = 1 (mod prime)
            var i = 1
            var temp = (t * t) % prime
            while temp != 1 {
                temp = (temp * temp) % prime
                i += 1
            }

            let b = c.power(BigInt(1) << (M - i - 1), modulus: prime)
            M = i
            c = (b * b) % prime
            t = (t * c) % prime
            R = (R * b) % prime
        }
    }

    /// Fast way to multiply point and scalar in elliptic curves
    ///
    /// - Parameter p: First Point to multiply
    /// - Parameter n: Scalar to multiply
    /// - Parameter N: Order of the elliptic curve
    /// - Parameter A: Coefficient of the first-order term of the equation Y^2 = X^3 + A*X + B (mod p)
    /// - Parameter P: Prime number in the module of the equation Y^2 = X^3 + A*X + B (mod p)
    /// - Returns: Point that represents the scalar multiplication
    static func multiply(_ p: Point, _ n: BigInt, _ N: BigInt, _ A: BigInt, _ P: BigInt) -> Point {
        return _fromJacobian(
            _jacobianMultiply(_toJacobian(p), n, N, A, P), P
        )
    }

    /// Fast scalar multiplication n*G where G is the curve generator, using a
    /// precomputed window table (2^w-ary method). Roughly 2-3x faster than
    /// variable-base multiplication because doublings stay cheap and additions
    /// use pre-stored multiples of G.
    ///
    /// - Parameter curve: Elliptic curve with generator G
    /// - Parameter n: Scalar multiplier
    /// - Returns: Point n*G
    static func multiplyGenerator(curve: CurveFp, n: BigInt) -> Point {
        var n = n
        if n < 0 || n >= curve.N {
            n = n.modulus(curve.N)
        }
        if n == 0 {
            return Point(BigInt(0), BigInt(0), BigInt(0))
        }

        let table = curve.generatorTable
        let w = _generatorWindowBits
        let mask = BigInt((1 << w) - 1)
        let A = curve.A
        let P = curve.P

        // Jacobian infinity (y=0 triggers early-return in _jacobianAdd)
        var r = Point(BigInt(0), BigInt(0), BigInt(1))
        let startBit = ((curve.nBitLength - 1) / w) * w
        var bit = startBit
        while bit >= 0 {
            for _ in 0..<w {
                r = _jacobianDouble(r, A, P)
            }
            let window = (n >> bit) & mask
            if window != 0 {
                r = _jacobianAdd(r, table[Int(window)], A, P)
            }
            bit -= w
        }
        return _fromJacobian(r, P)
    }

    /// Build the precomputed window table of [O, G, 2G, ..., (2^w - 1)G] in
    /// Jacobian coordinates. Called once per curve via the `generatorTable`
    /// lazy property on `CurveFp`.
    static func computeGeneratorTable(curve: CurveFp) -> [Point] {
        let w = _generatorWindowBits
        let size = 1 << w
        let A = curve.A
        let P = curve.P
        let G = Point(curve.G.x, curve.G.y, BigInt(1))
        var table = [Point]()
        table.reserveCapacity(size)
        table.append(Point(BigInt(0), BigInt(0), BigInt(1)))
        table.append(G)
        for _ in 0..<(size - 2) {
            table.append(_jacobianAdd(table.last!, G, A, P))
        }
        return table
    }

    /// Fast way to add two points in elliptic curves
    ///
    /// - Parameter p: First Point you want to add
    /// - Parameter q: Second Point you want to add
    /// - Parameter A: Coefficient of the first-order term of the equation Y^2 = X^3 + A*X + B (mod p)
    /// - Parameter P: Prime number in the module of the equation Y^2 = X^3 + A*X + B (mod p)
    /// - Returns: Point that represents the sum of First and Second Point
    static func add(_ p: Point, _ q: Point, _ A: BigInt, _ P: BigInt) -> Point {
        return _fromJacobian(
            _jacobianAdd(_toJacobian(p), _toJacobian(q), A, P), P
        )
    }

    /// Compute n1*p1 + n2*p2 using Shamir's trick (simultaneous double-and-add).
    /// Not constant-time -- use only with public scalars (e.g. verification).
    ///
    /// - Parameter p1: First point
    /// - Parameter n1: First scalar
    /// - Parameter p2: Second point
    /// - Parameter n2: Second scalar
    /// - Parameter N: Order of the elliptic curve
    /// - Parameter A: Coefficient of the first-order term of the equation Y^2 = X^3 + A*X + B (mod p)
    /// - Parameter P: Prime number in the module of the equation Y^2 = X^3 + A*X + B (mod p)
    /// - Returns: Point n1*p1 + n2*p2
    static func multiplyAndAdd(
        _ p1: Point, _ n1: BigInt,
        _ p2: Point, _ n2: BigInt,
        _ N: BigInt, _ A: BigInt, _ P: BigInt
    ) -> Point {
        return _fromJacobian(
            _shamirMultiply(
                _toJacobian(p1), n1,
                _toJacobian(p2), n2,
                N, A, P
            ), P
        )
    }

    /// Modular inverse via extended Euclidean algorithm.
    /// Roughly 2-3x faster than Fermat's little theorem for 256-bit operands.
    ///
    /// - Parameter x: Divisor (must be coprime to n)
    /// - Parameter n: Mod for division
    /// - Returns: Value representing the division
    static func inv(_ x: BigInt, _ n: BigInt) -> BigInt {
        precondition(x.modulus(n) != 0, "0 has no modular inverse")
        // Invariant: t * x ≡ r (mod n),  newt * x ≡ newr (mod n)
        var r = n
        var newr = x.modulus(n)
        var t = BigInt(0)
        var newt = BigInt(1)
        while newr != 0 {
            let q = r / newr
            let nextR = r - q * newr
            r = newr
            newr = nextR
            let nextT = t - q * newt
            t = newt
            newt = nextT
        }
        return t.modulus(n)
    }

    /// Convert point to Jacobian coordinates
    static func _toJacobian(_ p: Point) -> Point {
        return Point(p.x, p.y, BigInt(1))
    }

    /// Convert point back from Jacobian coordinates
    static func _fromJacobian(_ p: Point, _ P: BigInt) -> Point {
        if p.y == 0 {
            return Point(BigInt(0), BigInt(0), BigInt(0))
        }
        let z = inv(p.z, P)
        let x = (p.x * z * z).modulus(P)
        let y = (p.y * z * z * z).modulus(P)
        return Point(x, y, BigInt(0))
    }

    /// Double a point in elliptic curves
    static func _jacobianDouble(_ p: Point, _ A: BigInt, _ P: BigInt) -> Point {
        let py = p.y
        if py == 0 {
            return Point(BigInt(0), BigInt(0), BigInt(0))
        }
        let px = p.x
        let pz = p.z
        let ysq = (py * py).modulus(P)
        let S = (BigInt(4) * px * ysq).modulus(P)
        let pz2 = (pz * pz).modulus(P)
        let M: BigInt
        if A == 0 {
            M = (BigInt(3) * px * px).modulus(P)
        } else if A == -3 || A == P - 3 {
            M = (BigInt(3) * (px - pz2) * (px + pz2)).modulus(P)
        } else {
            M = (BigInt(3) * px * px + A * pz2 * pz2).modulus(P)
        }
        let nx = (M * M - BigInt(2) * S).modulus(P)
        let ny = (M * (S - nx) - BigInt(8) * ysq * ysq).modulus(P)
        let nz = (BigInt(2) * py * pz).modulus(P)
        return Point(nx, ny, nz)
    }

    /// Add two points in elliptic curves
    static func _jacobianAdd(_ p: Point, _ q: Point, _ A: BigInt, _ P: BigInt) -> Point {
        if p.y == 0 {
            return q
        }
        if q.y == 0 {
            return p
        }
        let px = p.x, py = p.y, pz = p.z
        let qx = q.x, qy = q.y, qz = q.z

        let pz2 = (pz * pz).modulus(P)
        let U2 = (qx * pz2).modulus(P)
        let S2 = (qy * pz2 * pz).modulus(P)

        let U1: BigInt
        let S1: BigInt
        if qz == 1 {
            // Mixed affine+Jacobian add: qz²=qz³=1 saves four multiplications.
            U1 = px
            S1 = py
        } else {
            let qz2 = (qz * qz).modulus(P)
            U1 = (px * qz2).modulus(P)
            S1 = (py * qz2 * qz).modulus(P)
        }

        if U1 == U2 {
            if S1 != S2 {
                return Point(BigInt(0), BigInt(0), BigInt(1))
            }
            return _jacobianDouble(p, A, P)
        }

        let H = U2 - U1
        let R = S2 - S1
        let H2 = (H * H).modulus(P)
        let H3 = (H * H2).modulus(P)
        let U1H2 = (U1 * H2).modulus(P)
        let nx = (R * R - H3 - BigInt(2) * U1H2).modulus(P)
        let ny = (R * (U1H2 - nx) - S1 * H3).modulus(P)
        let nz = qz == 1 ? (H * pz).modulus(P) : (H * pz * qz).modulus(P)
        return Point(nx, ny, nz)
    }

    /// Multiply point and scalar in elliptic curves using Montgomery ladder
    /// for constant-time execution.
    static func _jacobianMultiply(_ p: Point, _ n: BigInt, _ N: BigInt, _ A: BigInt, _ P: BigInt) -> Point {
        if p.y == 0 || n == 0 {
            return Point(BigInt(0), BigInt(0), BigInt(1))
        }

        var n = n
        if n < 0 || n >= N {
            n = n.modulus(N)
        }

        if n == 0 {
            return Point(BigInt(0), BigInt(0), BigInt(1))
        }

        // Montgomery ladder: always performs one add and one double per bit
        var r0 = Point(BigInt(0), BigInt(0), BigInt(1))
        var r1 = Point(p.x, p.y, p.z)

        let bitLen = n.bitLength
        for i in stride(from: bitLen - 1, through: 0, by: -1) {
            if (n >> i) & 1 == 0 {
                r1 = _jacobianAdd(r0, r1, A, P)
                r0 = _jacobianDouble(r0, A, P)
            } else {
                r0 = _jacobianAdd(r0, r1, A, P)
                r1 = _jacobianDouble(r1, A, P)
            }
        }

        return r0
    }

    /// Compute n1*p1 + n2*p2 using Shamir's trick (simultaneous double-and-add).
    /// Not constant-time -- use only with public scalars (e.g. verification).
    static func _shamirMultiply(
        _ jp1: Point, _ n1: BigInt,
        _ jp2: Point, _ n2: BigInt,
        _ N: BigInt, _ A: BigInt, _ P: BigInt
    ) -> Point {
        var n1 = n1
        var n2 = n2
        if n1 < 0 || n1 >= N {
            n1 = n1.modulus(N)
        }
        if n2 < 0 || n2 >= N {
            n2 = n2.modulus(N)
        }

        let jp1p2 = _jacobianAdd(jp1, jp2, A, P)

        let l = max(n1.bitLength, n2.bitLength)
        var r = Point(BigInt(0), BigInt(0), BigInt(1))

        for i in stride(from: l - 1, through: 0, by: -1) {
            r = _jacobianDouble(r, A, P)
            let b1 = (n1 >> i) & 1
            let b2 = (n2 >> i) & 1
            if b1 == 1 {
                r = _jacobianAdd(r, b2 == 1 ? jp1p2 : jp1, A, P)
            } else if b2 == 1 {
                r = _jacobianAdd(r, jp2, A, P)
            }
        }

        return r
    }
}
