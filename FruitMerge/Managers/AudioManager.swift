import Foundation
import AVFoundation
import AudioToolbox

public final class AudioManager {
    public static let shared = AudioManager()

    private var soundPlayers: [String: AVAudioPlayer] = [:]

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioSession setup error: \(error.localizedDescription)")
        }
    }

    public func playDropSound(isMuted: Bool) {
        guard !isMuted else { return }
        // System pop / tap sound fallback (sound ID 1104 or 1057)
        AudioServicesPlaySystemSound(1104)
    }

    public func playMergeSound(for tier: FruitType, isMuted: Bool) {
        guard !isMuted else { return }
        // Higher tiers trigger slightly different system chime sounds or custom bundled audio
        if tier == .watermelon {
            AudioServicesPlaySystemSound(1025) // Celebration chime
        } else {
            AudioServicesPlaySystemSound(1057) // Pop chime
        }
    }

    public func playBombKlaxonSound(isMuted: Bool) {
        guard !isMuted else { return }
        // Klaxon / Siren alarm sound (sound ID 1005 or 1033)
        AudioServicesPlaySystemSound(1005)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            AudioServicesPlaySystemSound(1073) // Explosion boom
        }
    }

    public func playGameOverSound(isMuted: Bool) {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1073)
    }

    public func playButtonTap(isMuted: Bool) {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1105)
    }

    /// Plays a custom audio file located in the main bundle if available
    public func playBundledSound(named name: String, fileExtension: String = "wav", isMuted: Bool) {
        guard !isMuted else { return }
        guard let url = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            soundPlayers[name] = player
        } catch {
            print("Failed to play sound: \(name), error: \(error)")
        }
    }
}
