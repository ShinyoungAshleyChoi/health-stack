//
//  SyncHistoryViewModel.swift
//  health-stack
//

import Foundation
import Combine
import os.log

@MainActor
class SyncHistoryViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var syncRecords: [SyncRecord] = []
    @Published var isLoading = false
    @Published var errorInfo: ErrorInfo?
    @Published var expandedRecordId: UUID?
    
    // MARK: - Dependencies
    
    private let syncManager: SyncManagerProtocol
    private let errorHandler = ErrorHandler.shared
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "health-stack", category: "SyncHistoryViewModel")
    
    // MARK: - Initialization
    
    init(syncManager: SyncManagerProtocol) {
        self.syncManager = syncManager
    }
    
    // MARK: - Public Methods
    
    func loadSyncHistory() async {
        isLoading = true
        errorInfo = nil
        
        logger.info("Loading sync history")
        
        do {
            syncRecords = try await syncManager.getSyncHistory()
            isLoading = false
            logger.info("Loaded \(self.syncRecords.count) sync records")
        } catch {
            errorInfo = ErrorInfo.from(error, context: "Load Sync History")
            isLoading = false
        }
    }
    
    func refresh() async {
        await loadSyncHistory()
    }
    
    func toggleExpanded(recordId: UUID) {
        if expandedRecordId == recordId {
            expandedRecordId = nil
        } else {
            expandedRecordId = recordId
        }
    }
    
    func isExpanded(recordId: UUID) -> Bool {
        return expandedRecordId == recordId
    }
    
    // MARK: - Helper Methods
    
    func statusIcon(for status: SyncRecordStatus) -> String {
        switch status {
        case .success:
            return "checkmark.circle.fill"
        case .partialSuccess:
            return "exclamationmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
    
    func statusColor(for status: SyncRecordStatus) -> String {
        switch status {
        case .success:
            return "green"
        case .partialSuccess:
            return "orange"
        case .failed:
            return "red"
        }
    }
    
    func formattedTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func formattedDuration(_ duration: TimeInterval) -> String {
        if duration < 1 {
            return String(format: "%.0fms", duration * 1000)
        } else if duration < 60 {
            return String(format: "%.1fs", duration)
        } else {
            let minutes = Int(duration / 60)
            let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
            return String(format: "%dm %ds", minutes, seconds)
        }
    }
    
    func statusText(for status: SyncRecordStatus) -> String {
        switch status {
        case .success:
            return "Success"
        case .partialSuccess:
            return "Partial Success"
        case .failed:
            return "Failed"
        }
    }
}
