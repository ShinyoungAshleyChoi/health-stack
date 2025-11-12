//
//  SyncFrequency.swift
//  health-stack
//

import Foundation

enum SyncFrequency: String, CaseIterable, Codable {
    case realtime
    case hourly
    case daily
    case manual
    
    var displayName: String {
        switch self {
        case .realtime:
            return "Real-time"
        case .hourly:
            return "Hourly"
        case .daily:
            return "Daily"
        case .manual:
            return "Manual Only"
        }
    }
    
    var interval: TimeInterval? {
        switch self {
        case .realtime:
            return nil // Immediate sync on data change
        case .hourly:
            return 3600 // 1 hour
        case .daily:
            return 86400 // 24 hours
        case .manual:
            return nil // No automatic sync
        }
    }
}
