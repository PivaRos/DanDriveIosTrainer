
import SwiftUI

struct ContentView: View {
    @StateObject private var motionManager = CoreMotionManager()
    @State private var isDriving = false
    @State private var sessionId: Int?

    // Computed property to map internal labels to user-friendly labels
    var currentLabel: String {
        switch motionManager.label {
        case "normal":
            return "Normal Driving"
        case "hard_braking":
            return "Hard Braking"
        case "hard_acceleration":
            return "Hard Acceleration"
        case "hard_turning":
            return "Hard Turning"
        default:
            return "Normal Driving"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            if let sessionId = sessionId {
                    Text("Session ID: \(sessionId)")
                        .font(.headline)
                        .padding()
                }
            Text("Current Label: \(currentLabel)")
                .font(.headline)

            Text("Acceleration: x=\(motionManager.acceleration.x), y=\(motionManager.acceleration.y), z=\(motionManager.acceleration.z)")
                .font(.subheadline)

            Text("Rotation: x=\(motionManager.rotation.x), y=\(motionManager.rotation.y), z=\(motionManager.rotation.z)")
                .font(.subheadline)

            Button(action: {
                isDriving.toggle()
                if isDriving {
                    motionManager.startUpdates()
                } else {
                    motionManager.stopUpdates()
                    uploadData()
                }
            }) {
                Text(isDriving ? "Stop Drive" : "Start Drive")
                    .padding()
                    .background(isDriving ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            HStack {
                LabelButton(
                    title: "Hard Braking",
                    color: .blue,
                    onPress: { motionManager.label = "hard_braking" },
                    onRelease: { motionManager.label = "normal" }
                )
                LabelButton(
                    title: "Hard Acceleration",
                    color: .orange,
                    onPress: { motionManager.label = "hard_acceleration" },
                    onRelease: { motionManager.label = "normal" }
                )
                LabelButton(
                    title: "Hard Turning",
                    color: .purple,
                    onPress: { motionManager.label = "hard_turning" },
                    onRelease: { motionManager.label = "normal" }
                )
            }
            .padding()
        }
        .padding()
    }

    private func uploadData() {
        let data = DatabaseManager.shared.fetchAllData()
        NetworkManager.shared.uploadData(data, to: "https://api.dandrive.eu/train/") { success, sessionId in
            DispatchQueue.main.async {
                if success, let sessionId = sessionId {
                    print(data)
                    DatabaseManager.shared.clearData()
                    print("Data uploaded successfully! Session ID: \(sessionId)")
                    // Update the UI with the session ID
                    self.sessionId = sessionId
                } else {
                    print("Failed to upload data.")
                }
            }
        }
    }

}

struct LabelButton: View {
    let title: String
    let color: Color
    let onPress: () -> Void
    let onRelease: () -> Void

    var body: some View {
        Button(action: {}) {
            Text(title)
                .padding()
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { isPressing in
            if isPressing {
                onPress()
            } else {
                onRelease()
            }
        }, perform: {})
    }
}
