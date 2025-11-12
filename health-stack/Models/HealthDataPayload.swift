//
//  HealthDataPayload.swift
//  health-stack
//

import Foundation
import UIKit

struct HealthDataPayload: Codable {
    let deviceId: String
    let userId: String
    let samples: [HealthDataSample]
    let timestamp: Date
    let appVersion: String
    
    init(
        deviceId: String = UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
        userId: String,
        samples: [HealthDataSample],
        timestamp: Date = Date(),
        appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    ) {
        self.deviceId = deviceId
        self.userId = userId
        self.samples = samples
        self.timestamp = timestamp
        self.appVersion = appVersion
    }
}
