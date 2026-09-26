import SwiftUI

public struct GameWonOverlay: View {
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
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 6) {
                    Text("🎆 YOU WON! 🎆")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                        .tracking(1.5)

                    Text("🍉 Double Watermelon Fusion Master! 🍉")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))

                    if isNewHighScore {
                        Text("🏆 NEW HIGH SCORE! 🏆")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.yellow.opacity(0.25))
                            )
                    }
                }

                // Stats Grid
                VStack(spacing: 8) {
                    StatRow(title: "Final Score", value: "\(gameState.score)", valueColor: .yellow)
                    Divider().background(Color.white.opacity(0.12))
                    StatRow(title: "Best Score", value: "\(gameState.highScore)", valueColor: .orange)
                    Divider().background(Color.white.opacity(0.12))
                    StatRow(title: "Total Merges", value: "\(gameState.mergeCount)", valueColor: .white)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(red: 0.16, green: 0.18, blue: 0.26))
                )

                // Play Again Button
                Button(action: {
                    HapticManager.shared.celebrationFeedback(enabled: gameState.isHapticsEnabled)
                    AudioManager.shared.playButtonTap(isMuted: gameState.isMuted)
                    onRestart()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .bold))
                        Text("PLAY AGAIN")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.green.opacity(0.4), radius: 8, y: 4)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.11, green: 0.13, blue: 0.20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.yellow.opacity(0.4), lineWidth: 2)
                    )
            )
            .frame(maxWidth: 340)
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
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(valueColor)
        }
    }
}
