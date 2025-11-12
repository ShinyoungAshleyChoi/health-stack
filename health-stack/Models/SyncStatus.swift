//
//  SyncStatus.swift
//  health-stack
//

import Foundation

enum SyncStatus: Equatable {
    case idle
    case syncing(progress: Double)
    case success(syncedCount: Int, timestamp: Date)
    case error(ErrorInfo, timestamp: Date)
    
    struct ErrorInfo: Equatable {
        let message: String
        let underlyingError: String?
        
        init(message: String, underlyingError: String? = nil) {
            self.message = message
            self.underlyingError = underlyingError
        }
        
        init(from error: Error) {
            self.message = error.localizedDescription
            self.underlyingError = "\(error)"
        }
    }
    
    static func == (lhs: SyncStatus, rhs: SyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.syncing(let lProgress), .syncing(let rProgress)):
            return lProgress == rProgress
        case (.success(let lCount, let lTime), .success(let rCount, let rTime)):
            return lCount == rCount && lTime == rTime
        case (.error(let lError, let lTime), .error(let rError, let rTime)):
            return lError == rError && lTime == rTime
        default:
            return false
        }
    }
}
