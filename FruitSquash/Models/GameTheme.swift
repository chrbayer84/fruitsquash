import SwiftUI
import SpriteKit

public enum GameTheme: String, CaseIterable, Identifiable {
    case dark = "Dark"
    case light = "Light"
    case greenHills = "Green Hills"

    public var id: String { rawValue }

    public var displayName: String { rawValue }

    public var iconName: String {
        switch self {
        case .dark: return "moon.stars.fill"
        case .light: return "sun.max.fill"
        case .greenHills: return "leaf.fill"
        }
    }

    // MARK: - SpriteKit Container Styling

    public var skContainerFill: SKColor {
        switch self {
        case .dark:
            return SKColor(red: 0.11, green: 0.13, blue: 0.19, alpha: 0.95)
        case .light:
            return SKColor(red: 0.96, green: 0.97, blue: 1.0, alpha: 0.88)
        case .greenHills:
            return SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.72)
        }
    }

    public var skContainerStroke: SKColor {
        switch self {
        case .dark:
            return SKColor.white.withAlphaComponent(0.18)
        case .light:
            return SKColor(red: 0.75, green: 0.80, blue: 0.88, alpha: 0.8)
        case .greenHills:
            return SKColor.white.withAlphaComponent(0.65)
        }
    }

    public var skDangerLineColor: SKColor {
        switch self {
        case .dark:
            return SKColor.systemRed.withAlphaComponent(0.55)
        case .light:
            return SKColor.systemRed.withAlphaComponent(0.65)
        case .greenHills:
            return SKColor.systemRed.withAlphaComponent(0.60)
        }
    }

    public var skDropGuideColor: SKColor {
        switch self {
        case .dark:
            return SKColor.white.withAlphaComponent(0.28)
        case .light:
            return SKColor.black.withAlphaComponent(0.22)
        case .greenHills:
            return SKColor.white.withAlphaComponent(0.45)
        }
    }

    // MARK: - SwiftUI HUD & UI Styling

    public var hudBackground: Color {
        switch self {
        case .dark:
            return Color(red: 0.08, green: 0.10, blue: 0.15).opacity(0.92)
        case .light:
            return Color(red: 0.98, green: 0.98, blue: 1.0).opacity(0.94)
        case .greenHills:
            return Color(red: 0.96, green: 0.99, blue: 0.96).opacity(0.90)
        }
    }

    public var cardBackground: Color {
        switch self {
        case .dark:
            return Color(red: 0.13, green: 0.15, blue: 0.22).opacity(0.9)
        case .light:
            return Color(red: 0.90, green: 0.92, blue: 0.96).opacity(0.95)
        case .greenHills:
            return Color(red: 0.86, green: 0.94, blue: 0.88).opacity(0.85)
        }
    }

    public var cardBorder: Color {
        switch self {
        case .dark:
            return Color.white.opacity(0.12)
        case .light:
            return Color.black.opacity(0.08)
        case .greenHills:
            return Color.green.opacity(0.20)
        }
    }

    public var textColor: Color {
        switch self {
        case .dark:
            return .white
        case .light:
            return Color(red: 0.10, green: 0.14, blue: 0.22)
        case .greenHills:
            return Color(red: 0.08, green: 0.24, blue: 0.12)
        }
    }

    public var subtitleColor: Color {
        switch self {
        case .dark:
            return Color.white.opacity(0.6)
        case .light:
            return Color.black.opacity(0.55)
        case .greenHills:
            return Color(red: 0.18, green: 0.40, blue: 0.24).opacity(0.8)
        }
    }
}
