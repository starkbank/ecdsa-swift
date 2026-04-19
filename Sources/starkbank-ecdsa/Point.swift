import BigInt
import Foundation


public class Point {

    public var x: BigInt
    public var y: BigInt
    public var z: BigInt

    public init(_ x: BigInt = BigInt(0), _ y: BigInt = BigInt(0), _ z: BigInt = BigInt(0)) {
        self.x = x
        self.y = y
        self.z = z
    }

    public func isAtInfinity() -> Bool {
        return self.y == BigInt(0)
    }

    public var description: String {
        return "(\(x), \(y), \(z))"
    }
}
