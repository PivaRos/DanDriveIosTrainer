import Foundation

class NetworkManager {
    static let shared = NetworkManager()

    func uploadData(_ rawData: [[String: Any]], to url: String, completion: @escaping (Bool, Int?) -> Void) {
        guard let apiUrl = URL(string: url) else { return }

        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("09ac3bb7-d865-4ff1-92a2-159d08a19e84", forHTTPHeaderField: "Authorization")

        // Transform rawData into the server-required structure
        let formattedData = rawData.compactMap { item -> [String: Any]? in
            guard
                let timestamp = item["timestamp"] as? Double,
                let acc_x = item["acc_x"] as? Double,
                let acc_y = item["acc_y"] as? Double,
                let acc_z = item["acc_z"] as? Double,
                let gyro_x = item["gyro_x"] as? Double,
                let gyro_y = item["gyro_y"] as? Double,
                let gyro_z = item["gyro_z"] as? Double,
                let pitch = item["pitch"] as? Double,
                let roll = item["roll"] as? Double,
                let gravity_x = item["gravity_x"] as? Double,
                let gravity_y = item["gravity_y"] as? Double,
                let gravity_z = item["gravity_z"] as? Double,
                let label = item["label"] as? String
            else {
                // Debugging: Print the item that caused the failure
                print("Data format mismatch in item: \(item)")
                return nil
            }

            return [
                "timestamp": timestamp,
                "acc_x": acc_x,
                "acc_y": acc_y,
                "acc_z": acc_z,
                "gyro_x": gyro_x,
                "gyro_y": gyro_y,
                "gyro_z": gyro_z,
                "pitch": pitch,
                "roll": roll,
                "gravity_x": gravity_x,
                "gravity_y": gravity_y,
                "gravity_z": gravity_z,
                "label": label
            ]
        }

        // Check if formattedData is empty
        if formattedData.isEmpty {
            print("No valid data to upload.")
            completion(false, nil)
            return
        }

        let payload: [String: Any] = [
            "platform": "ios",
            "data": formattedData
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsonData

            // Debugging: Print JSON string
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("JSON Payload: \(jsonString)")
            }
        } catch {
            print("Error encoding JSON: \(error)")
            completion(false, nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error uploading data: \(error)")
                completion(false, nil)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    // Parse the response data to get the session ID
                    if let data = data {
                        do {
                            if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                               let isError = jsonResponse["isError"] as? Bool, !isError,
                               let responseData = jsonResponse["data"] as? [String: Any],
                               let sessionId = responseData["sessionId"] as? Int {
                                print("Session ID: \(sessionId)")
                                completion(true, sessionId)
                            } else {
                                print("Invalid response format")
                                completion(false, nil)
                            }
                        } catch {
                            print("Error parsing response: \(error)")
                            completion(false, nil)
                        }
                    } else {
                        print("No data received")
                        completion(false, nil)
                    }
                } else {
                    // Print server response for debugging
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("Server responded with status code \(httpResponse.statusCode): \(responseString)")
                    } else {
                        print("Server responded with status code \(httpResponse.statusCode)")
                    }
                    completion(false, nil)
                }
            } else {
                print("Unexpected response")
                completion(false, nil)
            }
        }.resume()
    }
}
