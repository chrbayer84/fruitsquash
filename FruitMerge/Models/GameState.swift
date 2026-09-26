import SwiftUI
import Combine

public enum GamePhase {
    case ready
    case playing
    case won
    case gameOver
}

public final class GameState: ObservableObject {
    private let highScoreKey = "FruitMerge_HighScore"
    private let muteKey = "FruitMerge_IsMuted"
    private let hapticsKey = "FruitMerge_IsHapticsEnabled"
    private let themeKey = "FruitMerge_Theme"

    @Published public var phase: GamePhase = .ready
    @Published public var score: Int = 0
    @Published public var highScore: Int = 0
    @Published public var currentFruit: FruitType = .redCurrant
    @Published public var nextFruit: FruitType = .blueberry
    @Published public var isMuted: Bool = false {
        didSet { UserDefaults.standard.set(isMuted, forKey: muteKey) }
    }
    @Published public var isHapticsEnabled: Bool = true {
        didSet { UserDefaults.standard.set(isHapticsEnabled, forKey: hapticsKey) }
    }
    @Published public var isBombModeActive: Bool = false
    @Published public var isUpgradeModeActive: Bool = false
    @Published public var theme: GameTheme = .dark {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: themeKey) }
    }

    /// Total merge count in current session
    @Published public var mergeCount: Int = 0
    /// Highest fruit tier evolved in current session
    @Published public var maxFruitTierAchieved: FruitType = .redCurrant

    public init() {
        self.highScore = UserDefaults.standard.integer(forKey: highScoreKey)
        self.isMuted = UserDefaults.standard.bool(forKey: muteKey)
        if UserDefaults.standard.object(forKey: hapticsKey) != nil {
            self.isHapticsEnabled = UserDefaults.standard.bool(forKey: hapticsKey)
        } else {
            self.isHapticsEnabled = true
        }

        if let savedTheme = UserDefaults.standard.string(forKey: themeKey),
           let parsedTheme = GameTheme(rawValue: savedTheme) {
            self.theme = parsedTheme
        } else {
            self.theme = .dark
        }

        prepareNextFruits()
    }

    public func prepareNextFruits() {
        currentFruit = FruitType.randomSpawn()
        nextFruit = FruitType.randomSpawn()
    }

    public func advanceFruit() -> FruitType {
        let fruitToDrop = currentFruit
        currentFruit = nextFruit
        nextFruit = FruitType.randomSpawn()
        return fruitToDrop
    }

    public func addScore(_ points: Int) {
        score += points
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: highScoreKey)
        }
    }

    public func recordMerge(resultFruit: FruitType) {
        mergeCount += 1
        addScore(resultFruit.scoreValue)
        if resultFruit.rawValue > maxFruitTierAchieved.rawValue {
            maxFruitTierAchieved = resultFruit
        }
    }

    public func recordWatermelonBurst() {
        mergeCount += 1
        addScore(5000)
    }

    public func triggerWin() {
        recordWatermelonBurst()
        phase = .won
    }

    public func startNewGame() {
        score = 0
        mergeCount = 0
        maxFruitTierAchieved = .redCurrant
        isBombModeActive = false
        isUpgradeModeActive = false
        prepareNextFruits()
        phase = .playing
    }

    public let bombCost: Int = 1000
    public let upgradeCost: Int = 2500

    public var canUseBomb: Bool {
        score >= bombCost || isBombModeActive
    }

    public var canUseUpgrade: Bool {
        score >= upgradeCost || isUpgradeModeActive
    }

    public func toggleBombMode() {
        guard phase == .playing else { return }
        isUpgradeModeActive = false
        if isBombModeActive {
            isBombModeActive = false
        } else {
            guard score >= bombCost else { return }
            score -= bombCost
            isBombModeActive = true
        }
    }

    public func deactivateBombMode() {
        isBombModeActive = false
    }

    public func toggleUpgradeMode() {
        guard phase == .playing else { return }
        isBombModeActive = false
        if isUpgradeModeActive {
            isUpgradeModeActive = false
        } else {
            guard score >= upgradeCost else { return }
            score -= upgradeCost
            isUpgradeModeActive = true
        }
    }

    public func deactivateUpgradeMode() {
        isUpgradeModeActive = false
    }

    public func triggerGameOver() {
        phase = .gameOver
    }

    public func toggleMute() {
        isMuted.toggle()
    }

    public func toggleHaptics() {
        isHapticsEnabled.toggle()
    }

    public func cycleTheme() {
        let allThemes = GameTheme.allCases
        if let idx = allThemes.firstIndex(of: theme) {
            let nextIdx = (idx + 1) % allThemes.count
            theme = allThemes[nextIdx]
        } else {
            theme = .dark
        }
    }
}
