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
        VStack(spacing: 6) {
            // Top Row: Title, Scores, Next Fruit, Shake, Quick Controls
            HStack(spacing: 8) {
                // Title
                HStack(spacing: 4) {
                    Text("🍉")
                        .font(.system(size: 16))
                    Text("MERGE")
                        .font(.system(size: 13, weight: .black, design: .rounded))
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
                        .font(.system(size: 18))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(red: 0.14, green: 0.16, blue: 0.24))
                )

                // Shake Board Button
                Button(action: onShake) {
                    Image(systemName: "waveform.path")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(8)
                }

                // Mute
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    gameState.toggleMute()
                }) {
                    Image(systemName: gameState.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(gameState.isMuted ? .red.opacity(0.8) : .white)
                        .frame(width: 28, height: 28)
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
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.orange.opacity(0.85))
                        )
                }
            }

            // Bottom Row: Evolution Strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    ForEach(FruitType.allCases) { fruit in
                        HStack(spacing: 2) {
                            Text(fruit.emoji)
                                .font(.system(size: 12))
                            if fruit != .watermelon {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
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
        VStack(alignment: .leading, spacing: 8) {
            // App Title Header
            HStack(spacing: 6) {
                Text("🍉")
                    .font(.system(size: 18))
                Text("FRUIT MERGE")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1.0)
            }
            .padding(.top, 4)

            // Score & Best Score Card
            HStack(spacing: 8) {
                ScoreCard(title: "SCORE", value: "\(gameState.score)", color: .orange)
                ScoreCard(title: "BEST", value: "\(gameState.highScore)", color: .yellow)
            }

            // Next Fruit Preview Card
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEXT")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    Text(gameState.nextFruit.displayName)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

                Spacer()

                Text(gameState.nextFruit.emoji)
                    .font(.system(size: 26))
                    .frame(width: 36, height: 36)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.13, green: 0.15, blue: 0.22).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            )

            // Evolution / Merge Chain Guide
            VStack(alignment: .leading, spacing: 3) {
                Text("MERGE EVOLUTION")
                    .font(.system(size: 8.5, weight: .black, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(FruitType.allCases) { fruit in
                            HStack(spacing: 2) {
                                Text(fruit.emoji)
                                    .font(.system(size: 13))
                                if fruit != .watermelon {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 6.5, weight: .bold))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 0.10, green: 0.12, blue: 0.18).opacity(0.8))
            )

            Spacer()

            // Shake Board Action Button
            Button(action: onShake) {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path")
                        .font(.system(size: 14, weight: .black))
                    Text("SHAKE BOARD")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.indigo],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
                .shadow(color: Color.purple.opacity(0.35), radius: 4, y: 2)
            }

            // Bottom Control Bar (Mute, Haptics, Restart)
            HStack(spacing: 6) {
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    gameState.toggleMute()
                }) {
                    Image(systemName: gameState.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(gameState.isMuted ? .red.opacity(0.8) : .white)
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(red: 0.16, green: 0.18, blue: 0.26))
                        )
                }

                Button(action: {
                    gameState.toggleHaptics()
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                }) {
                    Image(systemName: gameState.isHapticsEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(gameState.isHapticsEnabled ? .white : .gray)
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(red: 0.16, green: 0.18, blue: 0.26))
                        )
                }

                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    AudioManager.shared.playButtonTap(isMuted: gameState.isMuted)
                    onRestart()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.orange.opacity(0.85))
                        )
                }
            }
            .padding(.bottom, 4)
        }
        .padding(.horizontal, 10)
        .frame(width: 210)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.15).opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(.leading, 8)
        .padding(.vertical, 8)
    }
}

private struct ScoreCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundColor(color.opacity(0.9))

            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(red: 0.13, green: 0.15, blue: 0.22).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
