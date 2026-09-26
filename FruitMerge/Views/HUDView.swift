import SwiftUI

public struct HUDView: View {
    @ObservedObject var gameState: GameState
    var isPortrait: Bool = false
    var onShake: () -> Void
    var onRestart: () -> Void

    public var body: some View {
        if isPortrait {
            portraitHUD
        } else {
            landscapeHUD
        }
    }

    // MARK: - Portrait Mode HUD (Top Horizontal Bar)

    private var portraitHUD: some View {
        VStack(spacing: 5) {
            // Top Row: Title, Scores, Next Fruit, Bomb, Shake, Quick Controls
            HStack(spacing: 6) {
                // Title
                HStack(spacing: 3) {
                    Text("🍉")
                        .font(.system(size: 15))
                    Text("LL MERGE")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer(minLength: 2)

                // Score Cards
                ScoreCard(title: "SCORE", value: "\(gameState.score)", color: .orange)
                ScoreCard(title: "BEST", value: "\(gameState.highScore)", color: .yellow)

                // Next Fruit preview
                HStack(spacing: 4) {
                    Text("NEXT")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    Text(gameState.nextFruit.emoji)
                        .font(.system(size: 17))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(red: 0.14, green: 0.16, blue: 0.24))
                )

                // Bomb Tool Button (requires 1000 points, deducts 1000 on click)
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    gameState.toggleBombMode()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "bomb.fill")
                            .font(.system(size: 10, weight: .black))
                        Text(gameState.isBombModeActive ? "ACTIVE" : "1K")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                    }
                    .foregroundColor(gameState.canUseBomb ? .white : .white.opacity(0.4))
                    .padding(.horizontal, 6)
                    .frame(height: 28)
                    .background(
                        gameState.isBombModeActive
                            ? AnyView(LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom))
                            : AnyView(gameState.canUseBomb ? Color(red: 0.85, green: 0.20, blue: 0.20) : Color(red: 0.16, green: 0.18, blue: 0.24))
                    )
                    .cornerRadius(7)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(gameState.isBombModeActive ? Color.yellow : (gameState.canUseBomb ? Color.red.opacity(0.4) : Color.white.opacity(0.08)), lineWidth: 1.5)
                    )
                }
                .disabled(!gameState.canUseBomb && !gameState.isBombModeActive)

                // Shake Board Button
                Button(action: onShake) {
                    Image(systemName: "waveform.path")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(7)
                }

                // Mute
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    gameState.toggleMute()
                }) {
                    Image(systemName: gameState.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(gameState.isMuted ? .red.opacity(0.8) : .white)
                        .frame(width: 26, height: 26)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color(red: 0.16, green: 0.18, blue: 0.26))
                        )
                }

                // Restart
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    AudioManager.shared.playButtonTap(isMuted: gameState.isMuted)
                    onRestart()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 26, height: 26)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.orange.opacity(0.85))
                        )
                }
            }

            // Bottom 2-Line Evolution Strip
            EvolutionTwoLinesView()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.15).opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }

    // MARK: - Landscape Mode HUD (Left Sidebar)

    private var landscapeHUD: some View {
        VStack(alignment: .leading, spacing: 7) {
            // App Title Header
            HStack(spacing: 5) {
                Text("🍉")
                    .font(.system(size: 16))
                Text("LL FRUIT MERGE")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.6)
            }
            .padding(.top, 3)

            // Score & Best Score Card
            HStack(spacing: 6) {
                ScoreCard(title: "SCORE", value: "\(gameState.score)", color: .orange)
                ScoreCard(title: "BEST", value: "\(gameState.highScore)", color: .yellow)
            }

            // Next Fruit Preview Card
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("NEXT")
                        .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    Text(gameState.nextFruit.displayName)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

                Spacer()

                Text(gameState.nextFruit.emoji)
                    .font(.system(size: 24))
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 0.13, green: 0.15, blue: 0.22).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            )

            // Evolution / Merge Chain Guide (Split into 2 lines, full width)
            VStack(alignment: .leading, spacing: 4) {
                Text("MERGE EVOLUTION")
                    .font(.system(size: 8.5, weight: .black, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                EvolutionTwoLinesView()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 0.10, green: 0.12, blue: 0.18).opacity(0.85))
            )

            Spacer()

            // Bomb Power-Up Button (Requires 1000 pts, deducts 1000 on click)
            Button(action: {
                HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                gameState.toggleBombMode()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "bomb.fill")
                        .font(.system(size: 13, weight: .black))
                    Text(gameState.isBombModeActive ? "SELECT FRUIT" : "BOMB (1000 PTS)")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                }
                .foregroundColor(gameState.canUseBomb ? .white : .white.opacity(0.4))
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(
                    gameState.isBombModeActive
                        ? AnyView(LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing))
                        : AnyView(gameState.canUseBomb
                            ? LinearGradient(colors: [Color(red: 0.85, green: 0.20, blue: 0.20), Color(red: 0.60, green: 0.08, blue: 0.08)], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color(red: 0.16, green: 0.18, blue: 0.24), Color(red: 0.12, green: 0.14, blue: 0.20)], startPoint: .leading, endPoint: .trailing))
                )
                .cornerRadius(9)
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(gameState.isBombModeActive ? Color.yellow : (gameState.canUseBomb ? Color.red.opacity(0.4) : Color.white.opacity(0.08)), lineWidth: 1.5)
                )
                .shadow(color: gameState.canUseBomb ? Color.red.opacity(0.35) : Color.clear, radius: 4, y: 2)
            }
            .disabled(!gameState.canUseBomb && !gameState.isBombModeActive)

            // Shake Board Action Button
            Button(action: onShake) {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path")
                        .font(.system(size: 13, weight: .black))
                    Text("SHAKE BOARD")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.indigo],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(9)
                .shadow(color: Color.purple.opacity(0.35), radius: 4, y: 2)
            }

            // Bottom Control Bar (Mute, Haptics, Restart)
            HStack(spacing: 5) {
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    gameState.toggleMute()
                }) {
                    Image(systemName: gameState.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(gameState.isMuted ? .red.opacity(0.8) : .white)
                        .frame(maxWidth: .infinity, minHeight: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color(red: 0.16, green: 0.18, blue: 0.26))
                        )
                }

                Button(action: {
                    gameState.toggleHaptics()
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                }) {
                    Image(systemName: gameState.isHapticsEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(gameState.isHapticsEnabled ? .white : .gray)
                        .frame(maxWidth: .infinity, minHeight: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color(red: 0.16, green: 0.18, blue: 0.26))
                        )
                }

                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    AudioManager.shared.playButtonTap(isMuted: gameState.isMuted)
                    onRestart()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.orange.opacity(0.85))
                        )
                }
            }
            .padding(.bottom, 2)
        }
        .padding(.horizontal, 8)
        .frame(width: 210)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.15).opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(.leading, 6)
        .padding(.vertical, 6)
    }
}

// MARK: - 2-Line Evolution Strip Component

private struct EvolutionTwoLinesView: View {
    // Split 11 fruits into 2 balanced rows (0...5 and 5...10)
    private let row1: [FruitType] = [.redCurrant, .blueberry, .lemon, .purpleGrapeBunch, .orange, .apple]
    private let row2: [FruitType] = [.apple, .peach, .coconut, .dragonfruit, .pineapple, .watermelon]

    var body: some View {
        VStack(spacing: 5) {
            // Row 1 (Scaled to full width)
            HStack(spacing: 0) {
                ForEach(0..<row1.count, id: \.self) { idx in
                    Text(row1[idx].emoji)
                        .font(.system(size: 15))
                    if idx < row1.count - 1 {
                        Spacer(minLength: 1)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 6.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.35))
                        Spacer(minLength: 1)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Row 2 (Scaled to full width)
            HStack(spacing: 0) {
                ForEach(0..<row2.count, id: \.self) { idx in
                    Text(row2[idx].emoji)
                        .font(.system(size: 15))
                    if idx < row2.count - 1 {
                        Spacer(minLength: 1)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 6.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.35))
                        Spacer(minLength: 1)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ScoreCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 7.5, weight: .black, design: .rounded))
                .foregroundColor(color.opacity(0.9))

            Text(value)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color(red: 0.13, green: 0.15, blue: 0.22).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
