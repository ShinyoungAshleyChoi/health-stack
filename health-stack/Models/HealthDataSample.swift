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
        createdAt: Date = Date()
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
    }
}
