import SwiftUI
import SpriteKit

public enum FruitType: Int, CaseIterable, Identifiable, Comparable {
    case redCurrant = 0
    case blueberry
    case lime
    case purpleGrapeBunch
    case orange
    case apple
    case peach
    case coconut
    case dragonfruit
    case pineapple
    case watermelon

    public var id: Int { rawValue }

    public static func < (lhs: FruitType, rhs: FruitType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var displayName: String {
        switch self {
        case .redCurrant: return "Red Currant"
        case .blueberry: return "Blueberry"
        case .lime: return "Lime"
        case .purpleGrapeBunch: return "Purple Grapes"
        case .orange: return "Orange"
        case .apple: return "Apple"
        case .peach: return "Peach"
        case .coconut: return "Coconut"
        case .dragonfruit: return "Dragonfruit"
        case .pineapple: return "Pineapple"
        case .watermelon: return "Watermelon"
        }
    }

    /// Corresponding PNG asset image file name for custom sprite art
    public var assetName: String {
        switch self {
        case .redCurrant: return "fruit_red_currant"
        case .blueberry: return "fruit_blueberry"
        case .lime: return "fruit_lime"
        case .purpleGrapeBunch: return "fruit_grape_bunch"
        case .orange: return "fruit_orange"
        case .apple: return "fruit_apple"
        case .peach: return "fruit_peach"
        case .coconut: return "fruit_coconut"
        case .dragonfruit: return "fruit_dragonfruit"
        case .pineapple: return "fruit_pineapple"
        case .watermelon: return "fruit_watermelon"
        }
    }

    /// Character or emoji representation for fallback/HUD preview
    public var emoji: String {
        switch self {
        case .redCurrant: return "🔴"
        case .blueberry: return "🫐"
        case .lime: return "🍈"
        case .purpleGrapeBunch: return "🍇"
        case .orange: return "🍊"
        case .apple: return "🍎"
        case .peach: return "🍑"
        case .coconut: return "🥥"
        case .dragonfruit: return "🌺"
        case .pineapple: return "🍍"
        case .watermelon: return "🍉"
        }
    }

    /// Base radius in points for SpriteKit physics and visual bounds
    public var radius: CGFloat {
        switch self {
        case .redCurrant: return 12
        case .blueberry: return 17
        case .lime: return 23
        case .purpleGrapeBunch: return 30
        case .orange: return 38
        case .apple: return 47
        case .peach: return 57
        case .coconut: return 68
        case .dragonfruit: return 80
        case .pineapple: return 93
        case .watermelon: return 108
        }
    }

    /// Primary SKColor for particle effects and accents
    public var skPrimaryColor: SKColor {
        switch self {
        case .redCurrant: return SKColor(red: 0.92, green: 0.10, blue: 0.18, alpha: 1.0)
        case .blueberry: return SKColor(red: 0.20, green: 0.35, blue: 0.92, alpha: 1.0)
        case .lime: return SKColor(red: 0.40, green: 0.85, blue: 0.15, alpha: 1.0)
        case .purpleGrapeBunch: return SKColor(red: 0.60, green: 0.22, blue: 0.82, alpha: 1.0)
        case .orange: return SKColor(red: 1.00, green: 0.52, blue: 0.08, alpha: 1.0)
        case .apple: return SKColor(red: 0.92, green: 0.16, blue: 0.18, alpha: 1.0)
        case .peach: return SKColor(red: 1.00, green: 0.62, blue: 0.70, alpha: 1.0)
        case .coconut: return SKColor(red: 0.58, green: 0.40, blue: 0.28, alpha: 1.0)
        case .dragonfruit: return SKColor(red: 0.92, green: 0.18, blue: 0.58, alpha: 1.0)
        case .pineapple: return SKColor(red: 0.98, green: 0.80, blue: 0.10, alpha: 1.0)
        case .watermelon: return SKColor(red: 0.16, green: 0.72, blue: 0.30, alpha: 1.0)
        }
    }

    /// Primary color for SwiftUI preview
    public var primaryColor: Color {
        Color(skPrimaryColor)
    }

    /// Secondary highlight / accent color
    public var secondaryColor: Color {
        switch self {
        case .redCurrant: return Color(red: 0.65, green: 0.05, blue: 0.12)
        case .blueberry: return Color(red: 0.12, green: 0.20, blue: 0.65)
        case .lime: return Color(red: 0.25, green: 0.65, blue: 0.10)
        case .purpleGrapeBunch: return Color(red: 0.40, green: 0.12, blue: 0.60)
        case .orange: return Color(red: 0.85, green: 0.38, blue: 0.05)
        case .apple: return Color(red: 0.70, green: 0.08, blue: 0.10)
        case .peach: return Color(red: 0.90, green: 0.42, blue: 0.52)
        case .coconut: return Color(red: 0.40, green: 0.25, blue: 0.16)
        case .dragonfruit: return Color(red: 0.70, green: 0.08, blue: 0.40)
        case .pineapple: return Color(red: 0.85, green: 0.62, blue: 0.05)
        case .watermelon: return Color(red: 0.08, green: 0.48, blue: 0.18)
        }
    }

    /// Score awarded when merging two fruits into this type
    public var scoreValue: Int {
        switch self {
        case .redCurrant: return 2
        case .blueberry: return 4
        case .lime: return 8
        case .purpleGrapeBunch: return 16
        case .orange: return 32
        case .apple: return 64
        case .peach: return 128
        case .coconut: return 256
        case .dragonfruit: return 512
        case .pineapple: return 1024
        case .watermelon: return 2048
        }
    }

    /// Next fruit tier upon merge
    public var nextTier: FruitType? {
        guard let next = FruitType(rawValue: rawValue + 1) else {
            return nil
        }
        return next
    }

    /// Pool of fruits that can be spawned for the player drop queue (Tiers 1 to 5)
    public static var spawnPool: [FruitType] {
        [.redCurrant, .blueberry, .lime, .purpleGrapeBunch, .orange]
    }

    public static func randomSpawn() -> FruitType {
        spawnPool.randomElement() ?? .redCurrant
    }
}
