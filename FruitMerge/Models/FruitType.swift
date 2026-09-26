import SwiftUI
import SpriteKit

public enum FruitType: Int, CaseIterable, Identifiable, Comparable {
    case redCurrant = 0
    case blueberry
    case lemon
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
        case .lemon: return "Lemon"
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
        case .lemon: return "fruit_lemon"
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
        case .lemon: return "🍋"
        case .purpleGrapeBunch: return "🍇"
        case .orange: return "🍊"
        case .apple: return "🍎"
        case .peach: return "🍑"
        case .coconut: return "🥥"
        case .dragonfruit: return "🐉"
        case .pineapple: return "🍍"
        case .watermelon: return "🍉"
        }
    }

    /// Base radius in points for SpriteKit physics and visual bounds (Portrait base)
    public var radius: CGFloat {
        switch self {
        case .redCurrant: return 13.2
        case .blueberry: return 18.7
        case .lemon: return 25.3
        case .purpleGrapeBunch: return 33.0
        case .orange: return 41.8
        case .apple: return 51.7
        case .peach: return 62.7
        case .coconut: return 74.8
        case .dragonfruit: return 84.0
        case .pineapple: return 98.0
        case .watermelon: return 118.8
        }
    }

    /// Aspect ratio (width / height) - Dragonfruit, Pineapple, and Watermelon slice are oblong ellipses
    public var aspectRatio: CGFloat {
        switch self {
        case .dragonfruit: return 0.80
        case .pineapple: return 0.78
        case .watermelon: return 1.18
        default: return 1.0
        }
    }

    /// Dynamic physical dimensions (width, height) accounting for elliptical shapes
    public func size(scale: CGFloat = 1.0) -> CGSize {
        let baseR = radius(scale: scale)
        switch self {
        case .dragonfruit:
            let h = baseR * 2.25
            let w = h * aspectRatio
            return CGSize(width: w, height: h)
        case .pineapple:
            let h = baseR * 2.28
            let w = h * aspectRatio
            return CGSize(width: w, height: h)
        case .watermelon:
            let h = baseR * 1.95
            let w = h * aspectRatio
            return CGSize(width: w, height: h)
        default:
            let d = baseR * 2
            return CGSize(width: d, height: d)
        }
    }

    /// Dynamic radius scaling factor based on orientation (1.20 in landscape, 1.0 in portrait)
    public func radius(scale: CGFloat = 1.0) -> CGFloat {
        radius * scale
    }

    /// Primary SKColor for particle effects and accents
    public var skPrimaryColor: SKColor {
        switch self {
        case .redCurrant: return SKColor(red: 0.92, green: 0.10, blue: 0.18, alpha: 1.0)
        case .blueberry: return SKColor(red: 0.20, green: 0.35, blue: 0.92, alpha: 1.0)
        case .lemon: return SKColor(red: 1.00, green: 0.88, blue: 0.12, alpha: 1.0)
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
        case .lemon: return Color(red: 0.85, green: 0.70, blue: 0.05)
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

    /// Score awarded when merging into this fruit type (Tier 1 gives 0; Tier 2+ awards points)
    public var scoreValue: Int {
        switch self {
        case .redCurrant: return 0 // Tier 1 fruit does not count for score
        case .blueberry: return 4  // Tier 2 fruit awards initial points
        case .lemon: return 8
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
        [.redCurrant, .blueberry, .lemon, .purpleGrapeBunch, .orange]
    }

    public static func randomSpawn() -> FruitType {
        spawnPool.randomElement() ?? .redCurrant
    }
}
