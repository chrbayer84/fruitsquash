import SwiftUI
import SpriteKit
import UIKit

public struct ContentView: View {
    @StateObject private var gameState = GameState()
    @State private var scene: GameScene?

    private let landscapeHudWidth: CGFloat = 210
    private let portraitHudHeight: CGFloat = 85

    private static let privacyPolicyURL = URL(string: "https://chrbayer84.github.io/fruitsquash/PRIVACY.html")!

    private var isPhone: Bool { UIDevice.current.userInterfaceIdiom == .phone }

    /// Top inset required on iPhones whose camera is integrated into the display
    /// (notch / Dynamic Island). Returns 0 on devices without a top cutout.
    private func topSafeAreaInset(_ geometry: GeometryProxy, isPortrait: Bool) -> CGFloat {
        guard isPortrait, isPhone else { return 0 }
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return max(geometry.safeAreaInsets.top, window?.safeAreaInsets.top ?? 0)
    }

    private func hudIgnoredEdges(isPortrait: Bool) -> Edge.Set {
        if isPortrait {
            // iPhone: keep the top HUD out of the sensor-housing area.
            return isPhone ? [.horizontal] : [.top, .horizontal]
        }
        return [.leading, .top, .bottom]
    }

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
                .ignoresSafeArea(edges: hudIgnoredEdges(isPortrait: isPortrait))

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
                setupScene(
                    size: geometry.size,
                    isPortrait: isPortrait,
                    safeAreaTop: topSafeAreaInset(geometry, isPortrait: isPortrait)
                )
                configureMotionShake()
            }
            .onChange(of: geometry.size) { newSize in
                let newIsPortrait = newSize.width < newSize.height
                setupScene(
                    size: newSize,
                    isPortrait: newIsPortrait,
                    safeAreaTop: topSafeAreaInset(geometry, isPortrait: newIsPortrait)
                )
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

                Link(destination: Self.privacyPolicyURL) {
                    Text("Privacy Policy")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .underline()
                }
                .padding(.top, 2)
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

    private func setupScene(size: CGSize, isPortrait: Bool, safeAreaTop: CGFloat) {
        guard size.width > 0 && size.height > 0 else { return }
        let hudOffset = isPortrait ? portraitHudHeight : landscapeHudWidth

        if let existing = scene {
            existing.updateLayout(
                size: size,
                isPortrait: isPortrait,
                hudOffset: hudOffset,
                safeAreaTop: safeAreaTop
            )
            existing.applyTheme(gameState.theme)
        } else {
            let newScene = GameScene(size: size)
            newScene.scaleMode = .resizeFill
            newScene.gameState = gameState
            newScene.isPortrait = isPortrait
            newScene.hudOffset = hudOffset
            newScene.safeAreaTop = safeAreaTop
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
