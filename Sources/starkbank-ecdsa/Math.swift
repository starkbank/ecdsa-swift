import BigInt
import Foundation


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

    /// Fast scalar multiplication n*G using a precomputed affine table of
    /// powers-of-two multiples of G and the width-2 NAF of n. Every non-zero
    /// NAF digit triggers one mixed add and zero doublings, trading the ~256
    /// doublings of a windowed method for ~86 adds on average -- a large net
    /// reduction in field multiplications for 256-bit scalars.
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
        let A = curve.A
        let P = curve.P

        var r = Point(BigInt(0), BigInt(0), BigInt(1))
        var i = 0
        var k = n
        while k > 0 {
            if (k & 1) != 0 {
                let digit = BigInt(2) - (k & 3)  // -1 or +1
                k -= digit
                let g = table[i]
                if digit == 1 {
                    r = _jacobianAdd(r, g, A, P)
                } else {
                    r = _jacobianAdd(r, Point(g.x, P - g.y, BigInt(1)), A, P)
                }
            }
            k >>= 1
            i += 1
        }
        return _fromJacobian(r, P)
    }

    /// Build [G, 2G, 4G, ..., 2^nBitLength * G] in affine (z=1) form, so each
    /// add in multiplyGenerator hits the mixed-add fast path.
    static func computeGeneratorTable(curve: CurveFp) -> [Point] {
        let A = curve.A
        let P = curve.P
        var current = Point(curve.G.x, curve.G.y, BigInt(1))
        var table = [Point]()
        table.reserveCapacity(curve.nBitLength + 1)
        table.append(current)
        // NAF of an nBitLength-bit scalar can be up to nBitLength+1 digits.
        for _ in 0..<curve.nBitLength {
            let doubled = _jacobianDouble(current, A, P)
            if doubled.y == 0 {
                current = doubled
            } else {
                let zInv = inv(doubled.z, P)
                let zInv2 = (zInv * zInv).modulus(P)
                let zInv3 = (zInv2 * zInv).modulus(P)
                current = Point(
                    (doubled.x * zInv2).modulus(P),
                    (doubled.y * zInv3).modulus(P),
                    BigInt(1)
                )
            }
            table.append(current)
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

    /// Compute n1*p1 + n2*p2. If ``curve`` is given and exposes ``glvParams``
    /// (e.g. secp256k1), uses the GLV endomorphism to split both scalars into
    /// ~128-bit halves and run a 4-scalar simultaneous multi-exponentiation.
    /// Otherwise falls back to Shamir's trick with JSF. Not constant-time --
    /// use only with public scalars (e.g. verification).
    ///
    /// - Parameter p1: First point
    /// - Parameter n1: First scalar
    /// - Parameter p2: Second point
    /// - Parameter n2: Second scalar
    /// - Parameter N: Order of the elliptic curve (ignored when ``curve`` is given)
    /// - Parameter A: Coefficient of the first-order term (ignored when ``curve`` is given)
    /// - Parameter P: Prime defining the field (ignored when ``curve`` is given)
    /// - Parameter curve: Optional curve; enables GLV if ``curve.glvParams`` is set
    /// - Returns: Point n1*p1 + n2*p2
    static func multiplyAndAdd(
        _ p1: Point, _ n1: BigInt,
        _ p2: Point, _ n2: BigInt,
        _ N: BigInt, _ A: BigInt, _ P: BigInt,
        curve: CurveFp? = nil
    ) -> Point {
        if let curve = curve {
            if curve.glvParams != nil {
                return _glvMultiplyAndAdd(p1, n1, p2, n2, curve)
            }
            return _fromJacobian(
                _shamirMultiply(
                    _toJacobian(p1), n1,
                    _toJacobian(p2), n2,
                    curve.N, curve.A, curve.P
                ), curve.P
            )
        }
        return _fromJacobian(
            _shamirMultiply(
                _toJacobian(p1), n1,
                _toJacobian(p2), n2,
                N, A, P
            ), P
        )
    }

    /// Compute n1*p1 + n2*p2 using the GLV endomorphism. Splits each 256-bit
    /// scalar into two ~128-bit scalars via k = k1 + k2*lambda (mod N), then
    /// runs a 4-scalar simultaneous double-and-add over (p1, phi(p1), p2,
    /// phi(p2)) with a 16-entry precomputed table of subset sums. Halves the
    /// loop length versus the plain Shamir path.
    static func _glvMultiplyAndAdd(
        _ p1: Point, _ n1: BigInt,
        _ p2: Point, _ n2: BigInt,
        _ curve: CurveFp
    ) -> Point {
        let glv = curve.glvParams!
        let N = curve.N
        let A = curve.A
        let P = curve.P
        let beta = glv.beta

        let (k1, k2) = _glvDecompose(n1.modulus(N), glv, N)
        let (k3, k4) = _glvDecompose(n2.modulus(N), glv, N)

        // Base points (affine, z=1) -- phi((x,y)) = (beta*x mod P, y).
        var bases: [Point] = [
            Point(p1.x, p1.y, BigInt(1)),
            Point((beta * p1.x).modulus(P), p1.y, BigInt(1)),
            Point(p2.x, p2.y, BigInt(1)),
            Point((beta * p2.x).modulus(P), p2.y, BigInt(1)),
        ]
        var scalars = [k1, k2, k3, k4]
        for i in 0..<4 {
            if scalars[i] < 0 {
                scalars[i] = -scalars[i]
                bases[i] = Point(bases[i].x, P - bases[i].y, BigInt(1))
            }
        }

        // Precompute table[idx] = sum of bases[i] selected by bits of idx.
        var table = [Point](repeating: Point(BigInt(0), BigInt(0), BigInt(1)), count: 16)
        for idx in 1..<16 {
            let low = idx & -idx
            var i = 0
            var l = low
            while l > 1 {
                l >>= 1
                i += 1
            }
            table[idx] = _jacobianAdd(table[idx ^ low], bases[i], A, P)
        }

        let maxLen = scalars.map { $0.bitLength }.max() ?? 0
        var r = Point(BigInt(0), BigInt(0), BigInt(1))
        let s0 = scalars[0], s1 = scalars[1], s2 = scalars[2], s3 = scalars[3]
        for bit in stride(from: maxLen - 1, through: 0, by: -1) {
            r = _jacobianDouble(r, A, P)
            let b0 = Int((s0 >> bit) & 1)
            let b1 = Int((s1 >> bit) & 1)
            let b2 = Int((s2 >> bit) & 1)
            let b3 = Int((s3 >> bit) & 1)
            let idx = b0 | (b1 << 1) | (b2 << 2) | (b3 << 3)
            if idx != 0 {
                r = _jacobianAdd(r, table[idx], A, P)
            }
        }

        return _fromJacobian(r, P)
    }

    /// Decompose k into (k1, k2) with k = k1 + k2*lambda (mod N) and
    /// |k1|, |k2| ~ sqrt(N). Babai rounding against the precomputed basis
    /// {(a1, b1), (a2, b2)}; k1 and k2 may be negative.
    static func _glvDecompose(_ k: BigInt, _ glv: GLVParams, _ N: BigInt) -> (BigInt, BigInt) {
        let a1 = glv.a1, b1 = glv.b1, a2 = glv.a2, b2 = glv.b2
        let halfN = N / 2
        // attaswift/BigInt division is truncated-toward-zero. Both numerators
        // below are non-negative (b1 < 0 so -b1*k >= 0), so /N equals floor.
        let c1 = (b2 * k + halfN) / N
        let c2 = (-b1 * k + halfN) / N
        let k1 = k - c1 * a1 - c2 * a2
        let k2 = -c1 * b1 - c2 * b2
        return (k1, k2)
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

    /// Compute n1*p1 + n2*p2 using Shamir's trick with Joint Sparse Form
    /// (Solinas 2001). JSF picks signed digits in {-1, 0, 1} so at most ~l/2
    /// digit pairs are non-zero, versus ~3l/4 for the raw binary form. Not
    /// constant-time -- use only with public scalars (e.g. verification).
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

        if n1 == 0 && n2 == 0 {
            return Point(BigInt(0), BigInt(0), BigInt(1))
        }

        func neg(_ pt: Point) -> Point {
            return Point(pt.x, pt.y == 0 ? BigInt(0) : P - pt.y, pt.z)
        }

        let jp1p2 = _jacobianAdd(jp1, jp2, A, P)
        let jp1mp2 = _jacobianAdd(jp1, neg(jp2), A, P)

        // Indexed by (u0+1)*3 + (u1+1) where u0, u1 in {-1, 0, 1}.
        // Only the 8 non-(0,0) combos are ever looked up.
        var addTable = [Point?](repeating: nil, count: 9)
        addTable[(1 + 1) * 3 + (0 + 1)] = jp1
        addTable[(-1 + 1) * 3 + (0 + 1)] = neg(jp1)
        addTable[(0 + 1) * 3 + (1 + 1)] = jp2
        addTable[(0 + 1) * 3 + (-1 + 1)] = neg(jp2)
        addTable[(1 + 1) * 3 + (1 + 1)] = jp1p2
        addTable[(-1 + 1) * 3 + (-1 + 1)] = neg(jp1p2)
        addTable[(1 + 1) * 3 + (-1 + 1)] = jp1mp2
        addTable[(-1 + 1) * 3 + (1 + 1)] = neg(jp1mp2)

        let digits = _jsfDigits(n1, n2)
        var r = Point(BigInt(0), BigInt(0), BigInt(1))
        for (u0, u1) in digits {
            r = _jacobianDouble(r, A, P)
            if u0 != 0 || u1 != 0 {
                r = _jacobianAdd(r, addTable[(u0 + 1) * 3 + (u1 + 1)]!, A, P)
            }
        }

        return r
    }

    /// Joint Sparse Form of (k0, k1): list of signed-digit pairs (u0, u1) in
    /// {-1, 0, 1}, ordered MSB-first. At most one of any two consecutive pairs
    /// is non-zero, giving density ~1/2 instead of ~3/4 from raw binary.
    static func _jsfDigits(_ k0In: BigInt, _ k1In: BigInt) -> [(Int, Int)] {
        var k0 = k0In
        var k1 = k1In
        var digits = [(Int, Int)]()
        var d0 = 0
        var d1 = 0
        while (k0 + BigInt(d0)) != 0 || (k1 + BigInt(d1)) != 0 {
            let a0 = k0 + BigInt(d0)
            let a1 = k1 + BigInt(d1)
            let u0: Int
            if (a0 & 1) != 0 {
                let a0_3 = Int(a0 & 3)
                var u = a0_3 == 1 ? 1 : -1
                let a0_7 = Int(a0 & 7)
                if (a0_7 == 3 || a0_7 == 5) && Int(a1 & 3) == 2 {
                    u = -u
                }
                u0 = u
            } else {
                u0 = 0
            }
            let u1: Int
            if (a1 & 1) != 0 {
                let a1_3 = Int(a1 & 3)
                var u = a1_3 == 1 ? 1 : -1
                let a1_7 = Int(a1 & 7)
                if (a1_7 == 3 || a1_7 == 5) && Int(a0 & 3) == 2 {
                    u = -u
                }
                u1 = u
            } else {
                u1 = 0
            }
            digits.append((u0, u1))
            if 2 * d0 == 1 + u0 {
                d0 = 1 - d0
            }
            if 2 * d1 == 1 + u1 {
                d1 = 1 - d1
            }
            k0 >>= 1
            k1 >>= 1
        }
        digits.reverse()
        return digits
    }
}
