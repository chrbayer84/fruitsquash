import SwiftUI

public struct HUDView: View {
    @ObservedObject var gameState: GameState
    var onRestart: () -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // App Title Header
            HStack(spacing: 6) {
                Text("🍉")
                    .font(.system(size: 20))
                Text("FRUIT MERGE")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1.0)
            }
            .padding(.top, 8)

            // Score & Best Score Card
            HStack(spacing: 8) {
                ScoreCard(title: "SCORE", value: "\(gameState.score)", color: .orange)
                ScoreCard(title: "BEST", value: "\(gameState.highScore)", color: .yellow)
            }

            // Next Fruit Preview Card
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEXT")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    Text(gameState.nextFruit.displayName)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

                Spacer()

                // Fruit Preview Icon
                ZStack {
                    Circle()
                        .fill(gameState.nextFruit.primaryColor.opacity(0.35))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(gameState.nextFruit.primaryColor, lineWidth: 1.5)
                        )

                    Text(gameState.nextFruit.emoji)
                        .font(.system(size: 22))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(red: 0.13, green: 0.15, blue: 0.22).opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )

            // Evolution / Merge Chain Guide
            VStack(alignment: .leading, spacing: 4) {
                Text("MERGE EVOLUTION")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(FruitType.allCases) { fruit in
                            HStack(spacing: 3) {
                                Text(fruit.emoji)
                                    .font(.system(size: 14))
                                if fruit != .watermelon {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.10, green: 0.12, blue: 0.18).opacity(0.8))
            )

            Spacer()

            // Bottom Control Bar (Mute, Haptics, Restart)
            HStack(spacing: 8) {
                // Mute Sound Toggle
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    gameState.toggleMute()
                }) {
                    Image(systemName: gameState.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(gameState.isMuted ? .red.opacity(0.8) : .white)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(red: 0.16, green: 0.18, blue: 0.26))
                        )
                }

                // Haptic Toggle
                Button(action: {
                    gameState.toggleHaptics()
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                }) {
                    Image(systemName: gameState.isHapticsEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(gameState.isHapticsEnabled ? .white : .gray)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(red: 0.16, green: 0.18, blue: 0.26))
                        )
                }

                // Restart Button
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    AudioManager.shared.playButtonTap(isMuted: gameState.isMuted)
                    onRestart()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.orange.opacity(0.85))
                        )
                }
            }
            .padding(.bottom, 6)
        }
        .padding(.horizontal, 12)
        .frame(width: 210)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.15).opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
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
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundColor(color.opacity(0.9))

            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.13, green: 0.15, blue: 0.22).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
