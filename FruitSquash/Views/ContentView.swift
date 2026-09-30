import SwiftUI
import SpriteKit

public struct ContentView: View {
    @StateObject private var gameState = GameState()
    @State private var scene: GameScene?

    private let landscapeHudWidth: CGFloat = 210
    private let portraitHudHeight: CGFloat = 85

    public init() {}

    public var body: some View {
        GeometryReader { geometry in
            let isPortrait = geometry.size.width < geometry.size.height

            ZStack(alignment: isPortrait ? .top : .leading) {
                // Dynamic Theme Background
                themeBackgroundView
                    .ignoresSafeArea()

                // Fullscreen SpriteKit Game View
                if let scene = scene {
                    SpriteView(
                        scene: scene,
                        options: [.allowsTransparency]
                    )
                    .ignoresSafeArea()
                }

                // HUD Bar (Top bar in Portrait, Left sidebar in Landscape)
                HUDView(
                    gameState: gameState,
                    isPortrait: isPortrait,
                    onShake: {
                        scene?.shakeBoard()
                    },
                    onRestart: {
                        restartGame()
                    }
                )
                .ignoresSafeArea(edges: isPortrait ? [.top, .horizontal] : [.leading, .top, .bottom])

                // Start Screen Overlay
                if gameState.phase == .ready {
                    readyOverlay
                }

                // Game Won Overlay
                if gameState.phase == .won {
                    GameWonOverlay(
                        gameState: gameState,
                        onRestart: {
                            restartGame()
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
                setupScene(size: geometry.size, isPortrait: isPortrait)
                configureMotionShake()
            }
            .onChange(of: geometry.size) { newSize in
                let newIsPortrait = newSize.width < newSize.height
                setupScene(size: newSize, isPortrait: newIsPortrait)
            }
            .onChange(of: gameState.theme) { newTheme in
                scene?.applyTheme(newTheme)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    @ViewBuilder
    private var themeBackgroundView: some View {
        switch gameState.theme {
        case .dark:
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.08, blue: 0.13),
                    Color(red: 0.03, green: 0.04, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .light:
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.88, green: 0.91, blue: 0.96)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .greenHills:
            GreenHillsBackgroundView()
        }
    }

    private func configureMotionShake() {
        MotionManager.shared.onShakeDetected = { [weak scene] in
            guard let scene = scene, !scene.isRotating else { return }
            scene.shakeBoard()
        }
    }

    private var readyOverlay: some View {
        ZStack {
            Color.black.opacity(0.70)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("🍉 LL FRUIT SQUASH 🍋")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text("Drag anywhere to aim horizontally and release to drop fruits.\nCombine matching fruits all the way up to Watermelons!\nFuse two Watermelons together to win the game.")
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
            .padding(26)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.11, green: 0.13, blue: 0.20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                    )
            )
            .padding(.horizontal, 32)
        }
    }

    private func setupScene(size: CGSize, isPortrait: Bool) {
        guard size.width > 0 && size.height > 0 else { return }
        let hudOffset = isPortrait ? portraitHudHeight : landscapeHudWidth

        if let existing = scene {
            existing.updateLayout(size: size, isPortrait: isPortrait, hudOffset: hudOffset)
            existing.applyTheme(gameState.theme)
        } else {
            let newScene = GameScene(size: size)
            newScene.scaleMode = .resizeFill
            newScene.gameState = gameState
            newScene.isPortrait = isPortrait
            newScene.hudOffset = hudOffset
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
