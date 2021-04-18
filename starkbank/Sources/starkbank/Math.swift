//
//  File.swift
//  
//
//  Created by Rafael Stark on 2/15/21.
//

import BigInt
import Foundation


class Math {
    
    /**
    Fast way to multily point and scalar in elliptic curves
    - Parameter p: First Point to mutiply
    - Parameter n: Scalar to mutiply
    - Parameter N: Order of the elliptic curve
    - Parameter P: Prime number in the module of the equation Y^2 = X^3 + A*X + B (mod p)
    - Parameter A: Coefficient of the first-order term of the equation Y^2 = X^3 + A*X + B (mod p)
    - Returns: Point that represents the sum of First and Second Point
    */
    static func multiply(_ p: Point, _ n: BigInt, _ N: BigInt, _ A: BigInt, _ P: BigInt) -> Point {
        return self._fromJacobian(
            self._jacobianMultiply(self._toJacobian(p), n, N, A, P), P
        )
    }
    
    /**
    Fast way to add two points in elliptic curves
    - Parameter p: First Point you want to add
    - Parameter q: Second Point you want to add
    - Parameter P: Prime number in the module of the equation Y^2 = X^3 + A*X + B (mod p)
    - Parameter A: Coefficient of the first-order term of the equation Y^2 = X^3 + A*X + B (mod p)
    - Returns: Point that represents the sum of First and Second Point
    */
    static func add(_ p: Point, _ q: Point, _ A: BigInt, _ P: BigInt) -> Point {
        return self._fromJacobian(
            self._jacobianAdd(self._toJacobian(p), self._toJacobian(q), A, P), P
        )
    }
    
    /**
    Extended Euclidean Algorithm. It's the 'division' in elliptic curves
    - Parameter x: Divisor
    - Parameter n: Mod for division
    - Returns: Value representing the division
    */
    static func inv(_ x: BigInt, _ n: BigInt) -> BigInt {
        if x == BigInt(0) {
            return BigInt(0)
        }
        
        var lm = BigInt(1)
        var hm = BigInt(0)
        var low = x % n
        var high = n
        var r: BigInt, nm: BigInt, new: BigInt
        
        while low > BigInt(1) {
            r = high / low
            nm = hm - lm * r
            new = high - low * r
            high = low
            hm = lm
            low = new
            lm = nm
        }
        return lm > BigInt(0) ? lm : n + lm
    }
    
    /**
    Convert point to Jacobian coordinates
    - Parameter p: First Point you want to add
    - Returns: Point in Jacobian coordinates
    */
    static func _toJacobian(_ p: Point) -> Point {
        return Point(p.x, p.y, 1)
    }
    
    /**
    Convert point back from Jacobian coordinates
    - Parameter p: First Point you want to add
    - Parameter P: Prime number in the module of the equation Y^2 = X^3 + A*X + B (mod p)
    - Returns: Point in default coordinates
    */
    static func _fromJacobian(_ p: Point, _ P: BigInt) -> Point {
        let z = self.inv(p.z, P)

        return Point(
            (p.x * z.power(2)) % P,
            (p.y * z.power(3)) % P
        )
    }
    
    /**
    Double a point in elliptic curves
    - Parameter p: Point you want to double
    - Parameter P: Prime number in the module of the equation Y^2 = X^3 + A*X + B (mod p)
    - Parameter A: Coefficient of the first-order term of the equation Y^2 = X^3 + A*X + B (mod p)
    - Returns: Point that represents the sum of First and Second Point
    */
    static func _jacobianDouble(_ p: Point, _ A: BigInt, _ P: BigInt) -> Point {
        if p.y == 0 {
            return Point(0, 0, 0)
        }
        let ysq = (p.y.power(2)) % P
        let S = (4 * p.x * ysq) % P
        let M = (3 * p.x.power(2) + A * p.z.power(4)) % P
        let nx = (M.power(2) - 2 * S) % P
        let ny = (M * (S - nx) - 8 * ysq.power(2)) % P
        let nz = (2 * p.y * p.z) % P
        return Point(nx, ny, nz)
    }
    
    /**
    Add two points in elliptic curves
    - Parameter p: First Point you want to add
    - Parameter q: Second Point you want to add
    - Parameter P: Prime number in the module of the equation Y^2 = X^3 + A*X + B (mod p)
    - Parameter A: Coefficient of the first-order term of the equation Y^2 = X^3 + A*X + B (mod p)
    - Returns: Point that represents the sum of First and Second Point
    */
    static func _jacobianAdd(_ p: Point, _ q: Point, _ A: BigInt, _ P: BigInt) -> Point {
        if p.y == 0 {
            return q
        }
        if q.y == 0 {
            return p
        }

        let U1 = (p.x * q.z.power(2)) % P
        let U2 = (q.x * p.z.power(2)) % P
        let S1 = (p.y * q.z.power(3)) % P
        let S2 = (q.y * p.z.power(3)) % P

        if U1 == U2 {
            if S1 != S2 {
                return Point(0, 0, 1)
            }
            return self._jacobianDouble(p, A, P)
        }

        let H = U2 - U1
        let R = S2 - S1
        let H2 = (H * H) % P
        let H3 = (H * H2) % P
        let U1H2 = (U1 * H2) % P
        let nx = (R.power(2) - H3 - 2 * U1H2) % P
        let ny = (R * (U1H2 - nx) - S1 * H3) % P
        let nz = (H * p.z * q.z) % P

        return Point(nx, ny, nz)
    }
    
    /**
    Multily point and scalar in elliptic curves
    - Parameter p: First Point to mutiply
    - Parameter n: Scalar to mutiply
    - Parameter N: Order of the elliptic curve
    - Parameter P: Prime number in the module of the equation Y^2 = X^3 + A*X + B (mod p)
    - Parameter A: Coefficient of the first-order term of the equation Y^2 = X^3 + A*X + B (mod p)
    - Returns: Point that represents the sum of First and Second Point
    */
    static func  _jacobianMultiply(_ p: Point, _ n: BigInt, _ N: BigInt, _ A: BigInt, _ P: BigInt) -> Point {
        if p.y == 0 || n == 0 {
            return Point(0, 0, 1)
        }
        if n == 1 {
            return p
        }
        if n < 0 || n >= N {
            return self._jacobianMultiply(p, n % N, N, A, P)
        }
        if (n % 2) == 0 {
            return self._jacobianDouble(self._jacobianMultiply(p, n / 2, N, A, P), A, P)
        }
        return self._jacobianAdd(
            self._jacobianDouble(self._jacobianMultiply(p, n / 2, N, A, P), A, P), p, A, P
        )
    }
}
