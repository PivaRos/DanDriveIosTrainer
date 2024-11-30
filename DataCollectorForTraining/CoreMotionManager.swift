import Foundation
import CoreMotion
import Combine

class CoreMotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let updateInterval = 1.0 / 50.0 // 50 Hz
    private let deviceMotionQueue = OperationQueue()

    // Published properties for real-time updates
    @Published var acceleration: CMAcceleration = CMAcceleration(x: 0, y: 0, z: 0)
    @Published var rotation: CMRotationRate = CMRotationRate(x: 0, y: 0, z: 0)
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0
    @Published var gravity: CMAcceleration = CMAcceleration(x: 0, y: 0, z: 0)

    // Add a label property if needed
    @Published var label: String = "normal"

    // Timer for data collection
    private var dataTimer: Timer?

    func startUpdates() {
        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.gyroUpdateInterval = updateInterval

        // Start accelerometer and gyroscope updates
        if motionManager.isAccelerometerAvailable && motionManager.isGyroAvailable {
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
                guard let self = self, let data = data else { return }
                DispatchQueue.main.async {
                    self.acceleration = data.acceleration
                }
            }
            motionManager.startGyroUpdates(to: .main) { [weak self] data, _ in
                guard let self = self, let data = data else { return }
                DispatchQueue.main.async {
                    self.rotation = data.rotationRate
                }
            }
        }

        // Start device motion updates for pitch, roll, and gravity
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = updateInterval
            motionManager.startDeviceMotionUpdates(to: deviceMotionQueue) { [weak self] data, _ in
                guard let self = self, let data = data else { return }
                DispatchQueue.main.async {
                    self.pitch = data.attitude.pitch
                    self.roll = data.attitude.roll
                    self.gravity = data.gravity
                }
            }
        }

        // Start the data collection timer
        DispatchQueue.main.async {
            self.dataTimer = Timer.scheduledTimer(withTimeInterval: self.updateInterval, repeats: true) { [weak self] _ in
                self?.collectAndInsertData()
            }
        }
    }

    func stopUpdates() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopDeviceMotionUpdates()

        // Invalidate the timer
        dataTimer?.invalidate()
        dataTimer = nil
    }

    private func collectAndInsertData() {
        let timestamp = Date()
        let acceleration = self.acceleration
        let rotation = self.rotation
        let pitch = self.pitch
        let roll = self.roll
        let gravity = self.gravity
        let label = self.label

        DatabaseManager.shared.insertData(
            timestamp: timestamp,
            acceleration: acceleration,
            rotation: rotation,
            pitch: pitch,
            roll: roll,
            gravity: gravity,
            label: label
        )
    }
}
