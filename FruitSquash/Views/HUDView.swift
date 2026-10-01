import SwiftUI

public struct FruitIconView: View {
    public let fruitType: FruitType
    public var size: CGFloat = 20

    public init(fruitType: FruitType, size: CGFloat = 20) {
        self.fruitType = fruitType
        self.size = size
    }

    public var body: some View {
        Image(uiImage: FruitNode.uiImage(for: fruitType))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}

public struct HUDView: View {
    @ObservedObject var gameState: GameState
    var isPortrait: Bool = false
    var onShake: () -> Void
    var onRestart: () -> Void

    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    private var theme: GameTheme {
        gameState.theme
    }

    public var body: some View {
        if isPhone {
            // iPhone Dedicated 2-Panel Layout
            if isPortrait {
                iphonePortraitHUD
            } else {
                iphoneLandscapeHUD
            }
        } else {
            // iPad Layout (Unchanged)
            if isPortrait {
                ipadPortraitHUD
            } else {
                ipadLandscapeHUD
            }
        }
    }

    // MARK: - iPhone Portrait Layout (Top Stats Panel + Bottom Controls Panel)

    private var iphonePortraitHUD: some View {
        VStack {
            // Panel 1: Title, Scores, Next Fruit, Evolution Strip
            IPhoneInfoPanel(gameState: gameState, theme: theme, isPortrait: true)
                .padding(.horizontal, 6)
                .padding(.top, 2)

            Spacer()

            // Panel 2: Action Buttons (Upgrade, Bomb, Shake, Theme, Mute, Restart)
            IPhoneControlsPanel(gameState: gameState, theme: theme, isPortrait: true, onShake: onShake, onRestart: onRestart)
                .padding(.horizontal, 6)
                .padding(.bottom, 4)
        }
    }

    // MARK: - iPhone Landscape Layout (Left Stats Panel + Right Controls Panel)

    private var iphoneLandscapeHUD: some View {
        HStack(alignment: .top) {
            // Panel 1: Stats & Info on the Left
            IPhoneInfoPanel(gameState: gameState, theme: theme, isPortrait: false)
                .frame(width: 155)
                .padding(.leading, 4)
                .padding(.vertical, 3)

            Spacer()

            // Panel 2: Controls & Actions on the Right
            IPhoneControlsPanel(gameState: gameState, theme: theme, isPortrait: false, onShake: onShake, onRestart: onRestart)
                .frame(width: 145)
                .padding(.trailing, 4)
                .padding(.vertical, 3)
        }
    }

    // MARK: - iPad Portrait Layout (Unchanged)

    private var ipadPortraitHUD: some View {
        VStack(spacing: 5) {
            HStack(spacing: 4) {
                HStack(spacing: 2) {
                    Text("🍉")
                        .font(.system(size: 14))
                    Text("LL SQUASH")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(theme.textColor)
                }

                Spacer(minLength: 1)

                ScoreCard(title: "SCORE", value: "\(gameState.score)", color: .orange, theme: theme)
                ScoreCard(title: "BEST", value: "\(gameState.highScore)", color: .yellow, theme: theme)

                HStack(spacing: 2) {
                    Text("NEXT")
                        .font(.system(size: 7, weight: .black, design: .rounded))
                        .foregroundColor(theme.subtitleColor)
                    FruitIconView(fruitType: gameState.nextFruit, size: 18)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(theme.cardBackground)
                )

                // Upgrade Button
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    gameState.toggleUpgradeMode()
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 9, weight: .black))
                        Text(gameState.isUpgradeModeActive ? "ACTIVE" : "2.5K")
                            .font(.system(size: 7.5, weight: .black, design: .rounded))
                    }
                    .foregroundColor(gameState.canUseUpgrade ? .white : .white.opacity(0.4))
                    .padding(.horizontal, 4)
                    .frame(height: 25)
                    .background(upgradeButtonBackground(isPortrait: true))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(upgradeButtonBorder, lineWidth: 1.5)
                    )
                }
                .disabled(!gameState.canUseUpgrade && !gameState.isUpgradeModeActive)

                // Bomb Button
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    gameState.toggleBombMode()
                }) {
                    HStack(spacing: 2) {
                        Text("💣")
                            .font(.system(size: 9))
                        Text(gameState.isBombModeActive ? "ACTIVE" : "1K")
                            .font(.system(size: 7.5, weight: .black, design: .rounded))
                    }
                    .foregroundColor(gameState.canUseBomb ? .white : .white.opacity(0.4))
                    .padding(.horizontal, 4)
                    .frame(height: 25)
                    .background(bombButtonBackground(isPortrait: true))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(bombButtonBorder, lineWidth: 1.5)
                    )
                }
                .disabled(!gameState.canUseBomb && !gameState.isBombModeActive)

                // Shake Button
                Button(action: onShake) {
                    Image(systemName: "waveform.path")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 25, height: 25)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(6)
                }

                // Theme
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    gameState.cycleTheme()
                }) {
                    Image(systemName: theme.iconName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(theme.textColor)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(theme.cardBackground)
                        )
                }

                // Mute
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    gameState.toggleMute()
                }) {
                    Image(systemName: gameState.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(gameState.isMuted ? .red.opacity(0.8) : theme.textColor)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(theme.cardBackground)
                        )
                }

                // Restart
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    AudioManager.shared.playButtonTap(isMuted: gameState.isMuted)
                    onRestart()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.orange.opacity(0.85))
                        )
                }
            }

            EvolutionTwoLinesView()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.hudBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(theme.cardBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, 6)
        .padding(.top, 4)
    }

    // MARK: - iPad Landscape Layout (Unchanged)

    private var ipadLandscapeHUD: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Text("🍉")
                    .font(.system(size: 15))
                Text("LL FRUIT SQUASH")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(theme.textColor)
                    .tracking(0.5)

                Spacer()

                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    gameState.cycleTheme()
                }) {
                    Image(systemName: theme.iconName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(theme.textColor)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(theme.cardBackground)
                        )
                }
            }
            .padding(.top, 2)

            HStack(spacing: 5) {
                ScoreCard(title: "SCORE", value: "\(gameState.score)", color: .orange, theme: theme)
                ScoreCard(title: "BEST", value: "\(gameState.highScore)", color: .yellow, theme: theme)
            }

            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("NEXT")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundColor(theme.subtitleColor)
                    Text(gameState.nextFruit.displayName)
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textColor)
                        .lineLimit(1)
                }

                Spacer()

                FruitIconView(fruitType: gameState.nextFruit, size: 28)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(theme.cardBorder, lineWidth: 1)
                    )
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("MERGE EVOLUTION")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundColor(theme.subtitleColor)

                EvolutionTwoLinesView()
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(theme.cardBorder, lineWidth: 1)
                    )
            )

            Spacer()

            // Upgrade Button
            Button(action: {
                HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                gameState.toggleUpgradeMode()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 12, weight: .black))
                    Text(gameState.isUpgradeModeActive ? "SELECT FRUIT" : "UPGRADE (2500 PTS)")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                }
                .foregroundColor(gameState.canUseUpgrade ? .white : .white.opacity(0.4))
                .frame(maxWidth: .infinity, minHeight: 30)
                .background(upgradeButtonBackground(isPortrait: false))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(upgradeButtonBorder, lineWidth: 1.5)
                )
                .shadow(color: gameState.canUseUpgrade ? Color.green.opacity(0.30) : Color.clear, radius: 3, y: 2)
            }
            .disabled(!gameState.canUseUpgrade && !gameState.isUpgradeModeActive)

            // Bomb Button
            Button(action: {
                HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                gameState.toggleBombMode()
            }) {
                HStack(spacing: 5) {
                    Text("💣")
                        .font(.system(size: 12))
                    Text(gameState.isBombModeActive ? "SELECT FRUIT" : "BOMB (1000 PTS)")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                }
                .foregroundColor(gameState.canUseBomb ? .white : .white.opacity(0.4))
                .frame(maxWidth: .infinity, minHeight: 30)
                .background(bombButtonBackground(isPortrait: false))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(bombButtonBorder, lineWidth: 1.5)
                )
                .shadow(color: gameState.canUseBomb ? Color.red.opacity(0.30) : Color.clear, radius: 3, y: 2)
            }
            .disabled(!gameState.canUseBomb && !gameState.isBombModeActive)

            // Shake Button
            Button(action: onShake) {
                HStack(spacing: 5) {
                    Image(systemName: "waveform.path")
                        .font(.system(size: 12, weight: .black))
                    Text("SHAKE BOARD")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 30)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.indigo],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
                .shadow(color: Color.purple.opacity(0.30), radius: 3, y: 2)
            }

            // Bottom Control Bar
            HStack(spacing: 4) {
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    gameState.toggleMute()
                }) {
                    Image(systemName: gameState.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(gameState.isMuted ? .red.opacity(0.8) : theme.textColor)
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(theme.cardBackground)
                        )
                }

                Button(action: {
                    gameState.toggleHaptics()
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                }) {
                    Image(systemName: gameState.isHapticsEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(gameState.isHapticsEnabled ? theme.textColor : theme.subtitleColor)
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(theme.cardBackground)
                        )
                }

                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    AudioManager.shared.playButtonTap(isMuted: gameState.isMuted)
                    onRestart()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.orange.opacity(0.85))
                        )
                }
            }
            .padding(.bottom, 2)
        }
        .padding(.horizontal, 7)
        .frame(width: 210)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.hudBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(theme.cardBorder, lineWidth: 1)
                )
        )
        .padding(.leading, 5)
        .padding(.vertical, 5)
    }

    // MARK: - Button Styling Helpers

    @ViewBuilder
    private func upgradeButtonBackground(isPortrait: Bool) -> some View {
        if gameState.isUpgradeModeActive {
            LinearGradient(colors: [.green, .mint], startPoint: isPortrait ? .top : .leading, endPoint: isPortrait ? .bottom : .trailing)
        } else if gameState.canUseUpgrade {
            LinearGradient(colors: [Color(red: 0.18, green: 0.62, blue: 0.38), Color(red: 0.10, green: 0.45, blue: 0.28)], startPoint: isPortrait ? .top : .leading, endPoint: isPortrait ? .bottom : .trailing)
        } else {
            LinearGradient(colors: [Color(red: 0.14, green: 0.20, blue: 0.16), Color(red: 0.10, green: 0.14, blue: 0.12)], startPoint: isPortrait ? .top : .leading, endPoint: isPortrait ? .bottom : .trailing)
        }
    }

    @ViewBuilder
    private func bombButtonBackground(isPortrait: Bool) -> some View {
        if gameState.isBombModeActive {
            LinearGradient(colors: [.red, .orange], startPoint: isPortrait ? .top : .leading, endPoint: isPortrait ? .bottom : .trailing)
        } else if gameState.canUseBomb {
            LinearGradient(colors: [Color(red: 0.85, green: 0.20, blue: 0.20), Color(red: 0.60, green: 0.08, blue: 0.08)], startPoint: isPortrait ? .top : .leading, endPoint: isPortrait ? .bottom : .trailing)
        } else {
            LinearGradient(colors: [Color(red: 0.16, green: 0.18, blue: 0.24), Color(red: 0.12, green: 0.14, blue: 0.20)], startPoint: isPortrait ? .top : .leading, endPoint: isPortrait ? .bottom : .trailing)
        }
    }

    private var upgradeButtonBorder: Color {
        if gameState.isUpgradeModeActive {
            return .yellow
        } else if gameState.canUseUpgrade {
            return Color.green.opacity(0.4)
        } else {
            return Color.white.opacity(0.08)
        }
    }

    private var bombButtonBorder: Color {
        if gameState.isBombModeActive {
            return .yellow
        } else if gameState.canUseBomb {
            return Color.red.opacity(0.4)
        } else {
            return Color.white.opacity(0.08)
        }
    }
}

// MARK: - iPhone Info & Stats Panel

public struct IPhoneInfoPanel: View {
    @ObservedObject var gameState: GameState
    let theme: GameTheme
    let isPortrait: Bool

    public var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                HStack(spacing: 2) {
                    Text("🍉")
                        .font(.system(size: 13))
                    Text(isPortrait ? "LL SQUASH" : "SQUASH")
                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                        .foregroundColor(theme.textColor)
                }

                Spacer(minLength: 2)

                ScoreCard(title: "SCORE", value: "\(gameState.score)", color: .orange, theme: theme)
                ScoreCard(title: "BEST", value: "\(gameState.highScore)", color: .yellow, theme: theme)

                HStack(spacing: 2) {
                    Text("NEXT")
                        .font(.system(size: 6.5, weight: .black, design: .rounded))
                        .foregroundColor(theme.subtitleColor)
                    FruitIconView(fruitType: gameState.nextFruit, size: 16)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(theme.cardBackground)
                )
            }

            EvolutionTwoLinesView()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(theme.hudBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(theme.cardBorder, lineWidth: 1)
                )
        )
    }
}

// MARK: - iPhone Controls & Actions Panel

public struct IPhoneControlsPanel: View {
    @ObservedObject var gameState: GameState
    let theme: GameTheme
    let isPortrait: Bool
    var onShake: () -> Void
    var onRestart: () -> Void

    public var body: some View {
        if isPortrait {
            // Horizontal bottom bar on iPhone portrait
            HStack(spacing: 4) {
                // Upgrade
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    gameState.toggleUpgradeMode()
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 9, weight: .black))
                        Text(gameState.isUpgradeModeActive ? "ACTIVE" : "2.5K")
                            .font(.system(size: 7.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(gameState.canUseUpgrade ? .white : .white.opacity(0.4))
                    .frame(maxWidth: .infinity, minHeight: 28)
                    .background(upgradeBackground)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(upgradeBorder, lineWidth: 1.5))
                }
                .disabled(!gameState.canUseUpgrade && !gameState.isUpgradeModeActive)

                // Bomb
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    gameState.toggleBombMode()
                }) {
                    HStack(spacing: 2) {
                        Text("💣").font(.system(size: 9))
                        Text(gameState.isBombModeActive ? "ACTIVE" : "1K")
                            .font(.system(size: 7.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(gameState.canUseBomb ? .white : .white.opacity(0.4))
                    .frame(maxWidth: .infinity, minHeight: 28)
                    .background(bombBackground)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(bombBorder, lineWidth: 1.5))
                }
                .disabled(!gameState.canUseBomb && !gameState.isBombModeActive)

                // Shake Board
                Button(action: onShake) {
                    HStack(spacing: 2) {
                        Image(systemName: "waveform.path").font(.system(size: 9, weight: .black))
                        Text("SHAKE").font(.system(size: 7.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 28)
                    .background(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(6)
                }

                // Theme
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    gameState.cycleTheme()
                }) {
                    Image(systemName: theme.iconName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(theme.textColor)
                        .frame(width: 28, height: 28)
                        .background(RoundedRectangle(cornerRadius: 6).fill(theme.cardBackground))
                }

                // Mute
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    gameState.toggleMute()
                }) {
                    Image(systemName: gameState.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(gameState.isMuted ? .red.opacity(0.8) : theme.textColor)
                        .frame(width: 28, height: 28)
                        .background(RoundedRectangle(cornerRadius: 6).fill(theme.cardBackground))
                }

                // Restart
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    AudioManager.shared.playButtonTap(isMuted: gameState.isMuted)
                    onRestart()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange.opacity(0.85)))
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(theme.hudBackground)
                    .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(theme.cardBorder, lineWidth: 1))
            )
        } else {
            // Vertical stacked controls for iPhone landscape on the right
            VStack(spacing: 4) {
                // Upgrade
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    gameState.toggleUpgradeMode()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.circle.fill").font(.system(size: 10, weight: .black))
                        Text(gameState.isUpgradeModeActive ? "SELECT" : "UP (2.5K)").font(.system(size: 8.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(gameState.canUseUpgrade ? .white : .white.opacity(0.4))
                    .frame(maxWidth: .infinity, minHeight: 26)
                    .background(upgradeBackground)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(upgradeBorder, lineWidth: 1.5))
                }
                .disabled(!gameState.canUseUpgrade && !gameState.isUpgradeModeActive)

                // Bomb
                Button(action: {
                    HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                    gameState.toggleBombMode()
                }) {
                    HStack(spacing: 3) {
                        Text("💣").font(.system(size: 9))
                        Text(gameState.isBombModeActive ? "SELECT" : "BOMB (1K)").font(.system(size: 8.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(gameState.canUseBomb ? .white : .white.opacity(0.4))
                    .frame(maxWidth: .infinity, minHeight: 26)
                    .background(bombBackground)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(bombBorder, lineWidth: 1.5))
                }
                .disabled(!gameState.canUseBomb && !gameState.isBombModeActive)

                // Shake Board
                Button(action: onShake) {
                    HStack(spacing: 3) {
                        Image(systemName: "waveform.path").font(.system(size: 10, weight: .black))
                        Text("SHAKE").font(.system(size: 8.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 26)
                    .background(LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(6)
                }

                Spacer()

                // Theme, Mute, Restart
                HStack(spacing: 3) {
                    Button(action: {
                        HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                        gameState.cycleTheme()
                    }) {
                        Image(systemName: theme.iconName).font(.system(size: 9, weight: .bold)).foregroundColor(theme.textColor)
                            .frame(maxWidth: .infinity, minHeight: 24)
                            .background(RoundedRectangle(cornerRadius: 5).fill(theme.cardBackground))
                    }
                    Button(action: {
                        HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                        gameState.toggleMute()
                    }) {
                        Image(systemName: gameState.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill").font(.system(size: 9, weight: .bold)).foregroundColor(gameState.isMuted ? .red.opacity(0.8) : theme.textColor)
                            .frame(maxWidth: .infinity, minHeight: 24)
                            .background(RoundedRectangle(cornerRadius: 5).fill(theme.cardBackground))
                    }
                    Button(action: {
                        HapticManager.shared.buttonTapFeedback(enabled: gameState.isHapticsEnabled)
                        AudioManager.shared.playButtonTap(isMuted: gameState.isMuted)
                        onRestart()
                    }) {
                        Image(systemName: "arrow.clockwise").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 24)
                            .background(RoundedRectangle(cornerRadius: 5).fill(Color.orange.opacity(0.85)))
                    }
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(theme.hudBackground)
                    .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(theme.cardBorder, lineWidth: 1))
            )
        }
    }

    @ViewBuilder
    private var upgradeBackground: some View {
        if gameState.isUpgradeModeActive {
            LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
        } else if gameState.canUseUpgrade {
            LinearGradient(colors: [Color(red: 0.18, green: 0.62, blue: 0.38), Color(red: 0.10, green: 0.45, blue: 0.28)], startPoint: .leading, endPoint: .trailing)
        } else {
            LinearGradient(colors: [Color(red: 0.14, green: 0.20, blue: 0.16), Color(red: 0.10, green: 0.14, blue: 0.12)], startPoint: .leading, endPoint: .trailing)
        }
    }

    @ViewBuilder
    private var bombBackground: some View {
        if gameState.isBombModeActive {
            LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
        } else if gameState.canUseBomb {
            LinearGradient(colors: [Color(red: 0.85, green: 0.20, blue: 0.20), Color(red: 0.60, green: 0.08, blue: 0.08)], startPoint: .leading, endPoint: .trailing)
        } else {
            LinearGradient(colors: [Color(red: 0.16, green: 0.18, blue: 0.24), Color(red: 0.12, green: 0.14, blue: 0.20)], startPoint: .leading, endPoint: .trailing)
        }
    }

    private var upgradeBorder: Color {
        if gameState.isUpgradeModeActive {
            return .yellow
        } else if gameState.canUseUpgrade {
            return Color.green.opacity(0.4)
        } else {
            return Color.white.opacity(0.08)
        }
    }

    private var bombBorder: Color {
        if gameState.isBombModeActive {
            return .yellow
        } else if gameState.canUseBomb {
            return Color.red.opacity(0.4)
        } else {
            return Color.white.opacity(0.08)
        }
    }
}

// MARK: - 2-Line Evolution Strip Component

private struct EvolutionTwoLinesView: View {
    private let row1: [FruitType] = [.redCurrant, .blueberry, .lemon, .purpleGrapeBunch, .orange, .apple]
    private let row2: [FruitType] = [.apple, .peach, .coconut, .dragonfruit, .pineapple, .watermelon]

    var body: some View {
        VStack(spacing: 3) {
            // Row 1
            HStack(spacing: 0) {
                ForEach(0..<row1.count, id: \.self) { idx in
                    FruitIconView(fruitType: row1[idx], size: 16)
                    if idx < row1.count - 1 {
                        Spacer(minLength: 1)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 5.5, weight: .bold))
                            .foregroundColor(.gray.opacity(0.5))
                        Spacer(minLength: 1)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Row 2
            HStack(spacing: 0) {
                ForEach(0..<row2.count, id: \.self) { idx in
                    FruitIconView(fruitType: row2[idx], size: 16)
                    if idx < row2.count - 1 {
                        Spacer(minLength: 1)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 5.5, weight: .bold))
                            .foregroundColor(.gray.opacity(0.5))
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
    var theme: GameTheme = .dark

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 7, weight: .black, design: .rounded))
                .foregroundColor(color.opacity(0.95))

            Text(value)
                .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                .foregroundColor(theme.textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(color.opacity(0.35), lineWidth: 1)
                )
        )
    }
}
