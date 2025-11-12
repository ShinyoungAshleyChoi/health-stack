//
//  MainViewModel.swift
//  health-stack
//

import Foundation
import Combine
import os.log

@MainActor
class MainViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncTimestamp: Date?
    @Published var isLoading: Bool = false
    @Published var errorInfo: ErrorInfo?
    @Published var enabledDataTypesCount: Int = 0
    @Published var totalDataTypesCount: Int = 0
    @Published var showNetworkWarning: Bool = false
    
    // MARK: - Dependencies
    
    private let syncManager: SyncManagerProtocol
    private let configurationManager: ConfigurationManagerProtocol
    private let networkMonitor = NetworkMonitor.shared
    private let storageMonitor = StorageMonitor.shared
    private let errorHandler = ErrorHandler.shared
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "health-stack", category: "MainViewModel")
    
    // MARK: - Computed Properties
    
    var syncStatusText: String {
        switch syncStatus {
        case .idle:
            return "Ready to sync"
        case .syncing(let progress):
            return "Syncing... \(Int(progress * 100))%"
        case .success(let count, _):
            return "Synced \(count) samples"
        case .error(let errorInfo, _):
            return "Error: \(errorInfo.message)"
        }
    }
    
    var syncStatusColor: String {
        switch syncStatus {
        case .idle:
            return "gray"
        case .syncing:
            return "blue"
        case .success:
            return "green"
        case .error:
            return "red"
        }
    }
    
    var lastSyncText: String {
        guard let timestamp = lastSyncTimestamp else {
            return "Never synced"
        }
        return formatRelativeTime(timestamp)
    }
    
    var dataTypeSummaryText: String {
        return "\(enabledDataTypesCount) of \(totalDataTypesCount) data types enabled"
    }
    
    var canSync: Bool {
        if case .syncing = syncStatus {
            return false
        }
        return !isLoading
    }
    
    // MARK: - Initialization
    
    init(
        syncManager: SyncManagerProtocol,
        configurationManager: ConfigurationManagerProtocol
    ) {
        self.syncManager = syncManager
        self.configurationManager = configurationManager
        
        setupSyncStatusObserver()
        setupNetworkMonitoring()
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    func performManualSync() {
        guard canSync else { return }
        
        // Check network connectivity
        guard networkMonitor.isConnected else {
            errorInfo = ErrorInfo(
                title: "No Internet Connection",
                message: "Cannot sync without an internet connection.",
                recoverySuggestion: "Connect to Wi-Fi or cellular data and try again.",
                isRetryable: true
            )
            return
        }
        
        // Check storage space
        guard storageMonitor.hasAvailableSpace() else {
            errorInfo = ErrorInfo(
                title: "Low Storage",
                message: "Your device is running low on storage space.",
                recoverySuggestion: "Free up some space and try again.",
                isRetryable: false
            )
            return
        }
        
        isLoading = true
        errorInfo = nil
        logger.info("Starting manual sync")
        
        Task {
            do {
                try await syncManager.performManualSync()
                isLoading = false
                logger.info("Manual sync completed successfully")
            } catch {
                isLoading = false
                errorInfo = ErrorInfo.from(error, context: "Manual Sync")
            }
        }
    }
    
    func refreshData() {
        loadInitialData()
    }
    
    // MARK: - Private Methods
    
    private func setupSyncStatusObserver() {
        syncManager.setSyncStatusCallback { [weak self] status in
            Task { @MainActor in
                self?.handleSyncStatusUpdate(status)
            }
        }
        
        // Get initial status
        let initialStatus = syncManager.getSyncStatus()
        handleSyncStatusUpdate(initialStatus)
    }
    
    private func handleSyncStatusUpdate(_ status: SyncStatus) {
        syncStatus = status
        
        switch status {
        case .syncing(let progress):
            isLoading = true
            errorInfo = nil
            logger.info("Sync progress: \(Int(progress * 100))%")
        case .success(let count, let timestamp):
            isLoading = false
            lastSyncTimestamp = timestamp
            errorInfo = nil
            logger.info("Sync completed successfully: \(count) samples")
            HapticFeedback.success.generate()
        case .error(let syncErrorInfo, let timestamp):
            isLoading = false
            lastSyncTimestamp = timestamp
            
            // Convert sync error to ErrorInfo
            errorInfo = ErrorInfo(
                title: "Sync Failed",
                message: syncErrorInfo.message,
                recoverySuggestion: "Check your internet connection and gateway configuration.",
                isRetryable: true
            )
            logger.error("Sync failed: \(syncErrorInfo.message)")
            HapticFeedback.error.generate()
        case .idle:
            isLoading = false
            logger.info("Sync status: idle")
        }
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .sink { [weak self] isConnected in
                self?.showNetworkWarning = !isConnected
                if !isConnected {
                    self?.logger.warning("Network connection lost")
                } else {
                    self?.logger.info("Network connection restored")
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        // Load data type preferences
        let preferences = configurationManager.getDataTypePreferences()
        enabledDataTypesCount = preferences.values.filter { $0 }.count
        totalDataTypesCount = preferences.count
        
        // Load last sync timestamp from sync history
        Task {
            do {
                let history = try await syncManager.getSyncHistory()
                if let lastSuccessfulSync = history.first(where: { $0.status == .success }) {
                    lastSyncTimestamp = lastSuccessfulSync.timestamp
                }
            } catch {
                // Ignore error, just won't show last sync time
            }
        }
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
