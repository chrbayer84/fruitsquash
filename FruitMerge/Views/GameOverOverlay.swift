import SwiftUI

public struct GameOverOverlay: View {
    @ObservedObject var gameState: GameState
    var onRestart: () -> Void

    private var isNewHighScore: Bool {
        gameState.score > 0 && gameState.score >= gameState.highScore
    }

    public var body: some View {
        ZStack {
            // Background Dim
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            // Modal Card
            HStack(spacing: 24) {
                // Left Column: Title & Result
                VStack(spacing: 12) {
                    Text("GAME OVER")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1.5)

                    if isNewHighScore {
                        Text("🎉 NEW HIGH SCORE! 🎉")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.yellow.opacity(0.2))
                            )
                    }

                    // Play Again Button
                    Button(action: {
                        HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                        AudioManager.shared.playButtonTap(isMuted: gameState.isMuted)
                        onRestart()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .bold))
                            Text("PLAY AGAIN")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Color.green.opacity(0.4), radius: 8, y: 4)
                    }
                }

                // Right Column: Stats Grid
                VStack(spacing: 8) {
                    StatRow(title: "Final Score", value: "\(gameState.score)", valueColor: .orange)
                    Divider().background(Color.white.opacity(0.12))
                    StatRow(title: "Best Score", value: "\(gameState.highScore)", valueColor: .yellow)
                    Divider().background(Color.white.opacity(0.12))
                    StatRow(title: "Total Merges", value: "\(gameState.mergeCount)", valueColor: .white)
                    Divider().background(Color.white.opacity(0.12))
                    StatRow(
                        title: "Best Fruit",
                        value: "\(gameState.maxFruitTierAchieved.emoji) \(gameState.maxFruitTierAchieved.displayName)",
                        valueColor: .white
                    )
                }
                .padding(14)
                .frame(width: 220)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(red: 0.16, green: 0.18, blue: 0.26))
                )
            }
            .padding(24)
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
}

private struct StatRow: View {
    let title: String
    let value: String
    let valueColor: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(valueColor)
        }
    }
}
