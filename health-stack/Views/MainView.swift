//
//  MainView.swift
//  health-stack
//

import SwiftUI

struct MainView: View {
    @StateObject private var viewModel: MainViewModel
    @State private var showingSettings = false
    @State private var showingHistory = false
    
    private let configurationManager: ConfigurationManagerProtocol
    private let healthKitManager: HealthKitManager
    private let gatewayService: GatewayServiceProtocol
    private let storageManager: StorageManagerProtocol
    private let syncManager: SyncManagerProtocol
    
    init(
        viewModel: MainViewModel,
        configurationManager: ConfigurationManagerProtocol,
        healthKitManager: HealthKitManager,
        gatewayService: GatewayServiceProtocol,
        storageManager: StorageManagerProtocol,
        syncManager: SyncManagerProtocol
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.configurationManager = configurationManager
        self.healthKitManager = healthKitManager
        self.gatewayService = gatewayService
        self.storageManager = storageManager
        self.syncManager = syncManager
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Sync Status Card
                    syncStatusCard
                    
                    // Last Sync Info
                    lastSyncCard
                    
                    // Data Type Summary
                    dataTypeSummaryCard
                    
                    // Manual Sync Button
                    syncButton
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Health Sync")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            HapticFeedback.light.generate()
                            showingSettings = true
                        }) {
                            Label("Settings", systemImage: "gear")
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.MainView.settingsButton)
                        
                        Button(action: {
                            HapticFeedback.light.generate()
                            showingHistory = true
                        }) {
                            Label("Sync History", systemImage: "clock")
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.MainView.historyButton)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .accessibilityLabel("Menu")
                            .accessibilityHint("Opens menu with settings and sync history options")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    configurationManager: configurationManager,
                    healthKitManager: healthKitManager,
                    gatewayService: gatewayService,
                    storageManager: storageManager,
                    syncManager: syncManager
                )
            }
            .sheet(isPresented: $showingHistory) {
                NavigationStack {
                    SyncHistoryView(syncManager: syncManager)
                }
            }
            .errorAlert(error: $viewModel.errorInfo) {
                viewModel.performManualSync()
            }
            .overlay(alignment: .top) {
                if viewModel.showNetworkWarning {
                    NetworkWarningBanner()
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .accessibilityIdentifier(AccessibilityIdentifiers.MainView.networkWarningBanner)
                }
            }
            .onAppear {
                viewModel.refreshData()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - View Components
    
    private var syncStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                    .accessibilityHidden(true)
                
                Text("Status")
                    .font(.headline)
                
                Spacer()
            }
            
            HStack {
                Text(viewModel.syncStatusText)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier(AccessibilityIdentifiers.MainView.syncStatusText)
                
                Spacer()
                
                if case .syncing = viewModel.syncStatus {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .accessibilityLabel("Syncing in progress")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sync status: \(viewModel.syncStatusText)")
        .accessibilityIdentifier(AccessibilityIdentifiers.MainView.syncStatusCard)
    }
    
    private var lastSyncCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)
                
                Text("Last Sync")
                    .font(.headline)
                
                Spacer()
            }
            
            HStack {
                Text(viewModel.lastSyncText)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier(AccessibilityIdentifiers.MainView.lastSyncText)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Last sync: \(viewModel.lastSyncText)")
        .accessibilityIdentifier(AccessibilityIdentifiers.MainView.lastSyncCard)
    }
    
    private var dataTypeSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square")
                    .foregroundColor(.red)
                    .accessibilityHidden(true)
                
                Text("Data Types")
                    .font(.headline)
                
                Spacer()
            }
            
            HStack {
                Text(viewModel.dataTypeSummaryText)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier(AccessibilityIdentifiers.MainView.dataTypeSummaryText)
                
                Spacer()
                
                Button(action: {
                    HapticFeedback.light.generate()
                    showingSettings = true
                }) {
                    Text("Configure")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("Configure data types")
                .accessibilityHint("Opens settings to select which health data types to sync")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifiers.MainView.dataTypeSummaryCard)
    }
    
    private var syncButton: some View {
        Button(action: {
            HapticFeedback.medium.generate()
            viewModel.performManualSync()
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .accessibilityLabel("Syncing")
                } else {
                    Image(systemName: "arrow.clockwise")
                        .accessibilityHidden(true)
                }
                
                Text(viewModel.isLoading ? "Syncing..." : "Sync Now")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.canSync ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.canSync)
        .accessibilityLabel(viewModel.isLoading ? "Syncing in progress" : "Sync now")
        .accessibilityHint(viewModel.canSync ? "Manually triggers health data synchronization" : "Sync is currently unavailable")
        .accessibilityIdentifier(AccessibilityIdentifiers.MainView.syncButton)
    }
    
    private var statusColor: Color {
        switch viewModel.syncStatusColor {
        case "gray":
            return .gray
        case "blue":
            return .blue
        case "green":
            return .green
        case "red":
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    let configManager = PreviewMockConfigurationManager()
    let healthKitManager = HealthKitManager()
    let networkClient = NetworkClient()
    let gatewayService = GatewayService(networkClient: networkClient, configurationManager: configManager)
    let storageManager = StorageManager.shared
    let syncManager = PreviewMockSyncManager()
    
    MainView(
        viewModel: MainViewModel(
            syncManager: syncManager,
            configurationManager: configManager
        ),
        configurationManager: configManager,
        healthKitManager: healthKitManager,
        gatewayService: gatewayService,
        storageManager: storageManager,
        syncManager: syncManager
    )
}

// MARK: - Network Warning Banner

struct NetworkWarningBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
                .foregroundColor(.white)
                .accessibilityHidden(true)
            
            Text("No Internet Connection")
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .background(Color.orange)
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Warning: No internet connection")
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Mock Classes for Preview

private class PreviewMockSyncManager: SyncManagerProtocol {
    func startAutoSync() {}
    func stopAutoSync() {}
    func performManualSync() async throws {}
    func getSyncStatus() -> SyncStatus { .idle }
    func getSyncHistory() async throws -> [SyncRecord] { [] }
    func setSyncStatusCallback(_ callback: @escaping (SyncStatus) -> Void) {}
}

private class PreviewMockConfigurationManager: ConfigurationManagerProtocol {
    func saveGatewayConfig(_ config: GatewayConfig) throws {}
    func getGatewayConfig() throws -> GatewayConfig? { nil }
    func saveDataTypePreferences(_ preferences: [HealthDataType: Bool]) {}
    func getDataTypePreferences() -> [HealthDataType: Bool] {
        Dictionary(uniqueKeysWithValues: HealthDataType.allCases.map { ($0, true) })
    }
    func saveSyncFrequency(_ frequency: SyncFrequency) {}
    func getSyncFrequency() -> SyncFrequency { .manual }
    func saveUserId(_ userId: String) {}
    func getUserId() -> String? { nil }
    func clearConfigurationCache() {}
}
