import SwiftUI
import SpriteKit

public struct ContentView: View {
    @StateObject private var gameState = GameState()
    @State private var scene: GameScene?
    private let hudWidth: CGFloat = 210

    public init() {}

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.07, green: 0.08, blue: 0.13),
                        Color(red: 0.03, green: 0.04, blue: 0.07)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Fullscreen SpriteKit Game View
                if let scene = scene {
                    SpriteView(
                        scene: scene,
                        options: [.allowsTransparency]
                    )
                    .ignoresSafeArea()
                }

                // Left HUD Sidebar (Scores, Next Fruit, Evolution Guide, Shake, Controls)
                HUDView(
                    gameState: gameState,
                    onShake: {
                        scene?.shakeBoard()
                    },
                    onRestart: {
                        restartGame()
                    }
                )
                .ignoresSafeArea(edges: [.leading, .top, .bottom])

                // Start Screen Overlay
                if gameState.phase == .ready {
                    readyOverlay
                }

                // Game Over Overlay
                if gameState.phase == .gameOver {
                    GameOverOverlay(
                        gameState: gameState,
                        onRestart: {
                            restartGame()
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .onAppear {
                setupScene(size: geometry.size)
                configureMotionShake()
            }
            .onChange(of: geometry.size) { newSize in
                setupScene(size: newSize)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    private func configureMotionShake() {
        MotionManager.shared.onShakeDetected = { [weak scene] in
            scene?.shakeBoard()
        }
    }

    private var readyOverlay: some View {
        ZStack {
            Color.black.opacity(0.70)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("🍉 FRUIT MERGE 🍇")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text("Drag anywhere to aim horizontally and release to drop fruits.\nCombine matching fruits to evolve them all the way to a Watermelon!\nShake your iPad or tap SHAKE BOARD anytime to jiggle the fruits.")
                    .font(.system(size: 13.5, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 20)

                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    AudioManager.shared.playButtonTap(isMuted: gameState.isMuted)
                    startGame()
                }) {
                    Text("START GAME")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(18)
                        .shadow(color: Color.orange.opacity(0.4), radius: 10, y: 4)
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.11, green: 0.13, blue: 0.20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                    )
            )
            .padding(.horizontal, 40)
        }
    }

    private func setupScene(size: CGSize) {
        guard size.width > 0 && size.height > 0 else { return }

        if let existing = scene {
            existing.updateLayout(size: size, leftOffset: hudWidth)
        } else {
            let newScene = GameScene(size: size)
            newScene.scaleMode = .resizeFill
            newScene.gameState = gameState
            newScene.leftHudOffset = hudWidth
            self.scene = newScene
        }
    }

    private func startGame() {
        gameState.startNewGame()
        scene?.resetScene()
    }

    private func restartGame() {
        gameState.startNewGame()
        scene?.resetScene()
    }
}
