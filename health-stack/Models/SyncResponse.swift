//
//  SyncResponse.swift
//  health-stack
//

import Foundation

struct SyncResponse: Codable {
    let success: Bool
    let syncedCount: Int
    let failedCount: Int
    let message: String?
    let timestamp: Date
    
    init(success: Bool, syncedCount: Int, failedCount: Int = 0, message: String? = nil, timestamp: Date = Date()) {
        self.success = success
        self.syncedCount = syncedCount
        self.failedCount = failedCount
        self.message = message
        self.timestamp = timestamp
    }
}
