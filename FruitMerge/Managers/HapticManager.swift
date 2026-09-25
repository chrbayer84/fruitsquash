import UIKit

public final class HapticManager {
    public static let shared = HapticManager()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private init() {
        prepareAll()
    }

    public func prepareAll() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }

    public func dropFeedback(enabled: Bool = true) {
        guard enabled else { return }
        lightImpact.impactOccurred(intensity: 0.6)
    }

    public func mergeFeedback(tier: FruitType, enabled: Bool = true) {
        guard enabled else { return }
        switch tier.rawValue {
        case 0...2:
            lightImpact.impactOccurred(intensity: 0.8)
        case 3...6:
            mediumImpact.impactOccurred(intensity: 0.9)
        default:
            heavyImpact.impactOccurred(intensity: 1.0)
        }
    }

    public func buttonTapFeedback(enabled: Bool = true) {
        guard enabled else { return }
        selectionFeedback.selectionChanged()
    }

    public func gameOverFeedback(enabled: Bool = true) {
        guard enabled else { return }
        notificationFeedback.notificationOccurred(.error)
    }

    public func celebrationFeedback(enabled: Bool = true) {
        guard enabled else { return }
        notificationFeedback.notificationOccurred(.success)
    }
}
