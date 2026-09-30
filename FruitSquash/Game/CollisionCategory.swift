import Foundation

public struct CollisionCategory {
    public static let none: UInt32      = 0
    public static let fruit: UInt32     = 1 << 0 // 1
    public static let wall: UInt32      = 1 << 1 // 2
    public static let floor: UInt32     = 1 << 2 // 4
    public static let dangerLine: UInt32 = 1 << 3 // 8
    public static let all: UInt32       = UInt32.max
}
