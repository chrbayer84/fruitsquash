import SwiftUI
import Combine

public enum GamePhase {
    case ready
    case playing
    case gameOver
}

public final class GameState: ObservableObject {
    private let highScoreKey = "FruitMerge_HighScore"
    private let muteKey = "FruitMerge_IsMuted"
    private let hapticsKey = "FruitMerge_IsHapticsEnabled"

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
        addScore(4096)
    }

    public func startNewGame() {
        score = 0
        mergeCount = 0
        maxFruitTierAchieved = .redCurrant
        prepareNextFruits()
        phase = .playing
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
}
