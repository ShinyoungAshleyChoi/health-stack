//
//  SyncRecord.swift
//  health-stack
//

import Foundation

struct SyncRecord: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let status: SyncRecordStatus
    let syncedCount: Int
    let errorMessage: String?
    let duration: TimeInterval
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        status: SyncRecordStatus,
        syncedCount: Int,
        errorMessage: String? = nil,
        duration: TimeInterval
    ) {
        self.id = id
        self.timestamp = timestamp
        self.status = status
        self.syncedCount = syncedCount
        self.errorMessage = errorMessage
        self.duration = duration
    }
}

enum SyncRecordStatus: String, Codable {
    case success
    case partialSuccess
    case failed
}
