import Foundation
import CoreMotion
import Combine
import UIKit

public final class MotionManager: ObservableObject {
    public static let shared = MotionManager()

    private let motionManager = CMMotionManager()
    private var lastShakeTime: Date = Date.distantPast
    private let shakeThreshold: Double = 1.9 // Calibrated for both iPad and iPhone
    private let debounceInterval: TimeInterval = 0.75

    public var onShakeDetected: (() -> Void)?

    private init() {
        startMonitoring()
    }

    public func startMonitoring() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.05
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let acceleration = data?.acceleration, error == nil else { return }

            let totalAcceleration = sqrt(
                acceleration.x * acceleration.x +
                acceleration.y * acceleration.y +
                acceleration.z * acceleration.z
            )

            if totalAcceleration > self.shakeThreshold {
                let now = Date()
                if now.timeIntervalSince(self.lastShakeTime) > self.debounceInterval {
                    self.lastShakeTime = now
                    self.onShakeDetected?()
                }
            }
        }
    }

    public func stopMonitoring() {
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
    }

    deinit {
        stopMonitoring()
    }
}
