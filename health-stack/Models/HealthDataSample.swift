//
//  HealthDataSample.swift
//  health-stack
//

import Foundation

struct HealthDataSample: Identifiable, Codable {
    let id: UUID
    let type: HealthDataType
    let value: Double
    let unit: String
    let startDate: Date
    let endDate: Date
    let sourceBundle: String?
    let metadata: [String: String]?
    var isSynced: Bool
    let createdAt: Date
    let timezone: String
    let timezoneOffset: Int
    
    init(
        id: UUID = UUID(),
        type: HealthDataType,
        value: Double,
        unit: String,
        startDate: Date,
        endDate: Date,
        sourceBundle: String? = nil,
        metadata: [String: String]? = nil,
        isSynced: Bool = false,
        createdAt: Date = Date(),
        timezone: String? = nil,
        timezoneOffset: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.value = value
        self.unit = unit
        self.startDate = startDate
        self.endDate = endDate
        self.sourceBundle = sourceBundle
        self.metadata = metadata
        self.isSynced = isSynced
        self.createdAt = createdAt
        
        // Capture timezone at the time of sample creation
        let currentTimeZone = TimeZone.current
        self.timezone = timezone ?? currentTimeZone.identifier
        self.timezoneOffset = timezoneOffset ?? (currentTimeZone.secondsFromGMT() / 60)
    }
}
