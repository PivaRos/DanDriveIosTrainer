import CoreMotion
import Foundation
import SQLite

final class DatabaseManager {
    // Singleton instance
    static let shared = DatabaseManager()

    // Database properties
    private let db: Connection
    private let table: Table

    // Table columns with explicit argument labels
    private enum Columns {
        static let id = SQLite.Expression<Int64>("id")
        static let timestamp = SQLite.Expression<Double>("timestamp")
        static let accX = SQLite.Expression<Double>("acc_x")
        static let accY = SQLite.Expression<Double>("acc_y")
        static let accZ = SQLite.Expression<Double>("acc_z")
        static let gyroX = SQLite.Expression<Double>("gyro_x")
        static let gyroY = SQLite.Expression<Double>("gyro_y")
        static let gyroZ = SQLite.Expression<Double>("gyro_z")
        static let pitch = SQLite.Expression<Double>("pitch")
        static let roll = SQLite.Expression<Double>("roll")
        static let gravityX = SQLite.Expression<Double>("gravity_x")
        static let gravityY = SQLite.Expression<Double>("gravity_y")
        static let gravityZ = SQLite.Expression<Double>("gravity_z")
        static let label = SQLite.Expression<String>("label")
    }

    private init() {
        // Set up the database connection
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("SensorData.sqlite")

        self.db = try! Connection(fileURL.path)
        self.table = Table("sensor_data")

        createTableIfNeeded()
    }

    private func createTableIfNeeded() {
        // Create the table if it doesn't exist
        do {
            try db.run(table.create(ifNotExists: true) { t in
                t.column(Columns.id, primaryKey: true)
                t.column(Columns.timestamp)
                t.column(Columns.accX)
                t.column(Columns.accY)
                t.column(Columns.accZ)
                t.column(Columns.gyroX)
                t.column(Columns.gyroY)
                t.column(Columns.gyroZ)
                t.column(Columns.pitch)
                t.column(Columns.roll)
                t.column(Columns.gravityX)
                t.column(Columns.gravityY)
                t.column(Columns.gravityZ)
                t.column(Columns.label)
            })
        } catch {
            print("Error creating table: \(error)")
        }
    }

    func insertData(timestamp: Date, acceleration: CMAcceleration, rotation: CMRotationRate, pitch: Double, roll: Double, gravity: CMAcceleration, label: String) {
        let timestampValue = timestamp.timeIntervalSince1970

        let insert = table.insert(
            Columns.timestamp <- timestampValue,
            Columns.accX <- acceleration.x,
            Columns.accY <- acceleration.y,
            Columns.accZ <- acceleration.z,
            Columns.gyroX <- rotation.x,
            Columns.gyroY <- rotation.y,
            Columns.gyroZ <- rotation.z,
            Columns.pitch <- pitch,
            Columns.roll <- roll,
            Columns.gravityX <- gravity.x,
            Columns.gravityY <- gravity.y,
            Columns.gravityZ <- gravity.z,
            Columns.label <- label
        )

        do {
            try db.run(insert)
            print("Data inserted successfully.")
        } catch {
            print("Error inserting data: \(error)")
        }
    }

    func fetchAllData() -> [[String: Any]] {
        var results: [[String: Any]] = []

        do {
            for row in try db.prepare(table) {
                results.append([
                    "id": row[Columns.id],
                    "timestamp": row[Columns.timestamp], // Keep as Double
                    "acc_x": row[Columns.accX],
                    "acc_y": row[Columns.accY],
                    "acc_z": row[Columns.accZ],
                    "gyro_x": row[Columns.gyroX],
                    "gyro_y": row[Columns.gyroY],
                    "gyro_z": row[Columns.gyroZ],
                    "pitch": row[Columns.pitch],
                    "roll": row[Columns.roll],
                    "gravity_x": row[Columns.gravityX],
                    "gravity_y": row[Columns.gravityY],
                    "gravity_z": row[Columns.gravityZ],
                    "label": row[Columns.label]
                ])
            }
        } catch {
            print("Error fetching data: \(error)")
        }

        return results
    }

    func clearData() {
        do {
            try db.run(table.delete())
            print("Data cleared successfully.")
        } catch {
            print("Error clearing data: \(error)")
        }
    }
}
