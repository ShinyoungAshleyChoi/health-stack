//
//  IntegrationTestView.swift
//  health-stack
//
//  UI for running integration tests
//

import SwiftUI

struct IntegrationTestView: View {
    @StateObject private var tester: IntegrationTester
    @Environment(\.dismiss) private var dismiss
    
    init(
        healthKitManager: HealthKitManagerProtocol,
        gatewayService: GatewayServiceProtocol,
        storageManager: StorageManagerProtocol,
        syncManager: SyncManagerProtocol,
        configManager: ConfigurationManagerProtocol
    ) {
        _tester = StateObject(wrappedValue: IntegrationTester(
            healthKitManager: healthKitManager,
            gatewayService: gatewayService,
            storageManager: storageManager,
            syncManager: syncManager,
            configManager: configManager
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if tester.isRunning {
                runningHeader
            }
            
            if !tester.testResults.isEmpty {
                summarySection
            }
            
            testResultsList
        }
        .navigationTitle("Integration Tests")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await tester.runAllTests()
                    }
                }) {
                    Label("Run Tests", systemImage: "play.circle.fill")
                }
                .disabled(tester.isRunning)
            }
        }
    }
    
    private var runningHeader: some View {
        VStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            
            Text(tester.currentTest)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var summarySection: some View {
        let summary = tester.getTestSummary()
        
        return VStack(spacing: 12) {
            HStack(spacing: 20) {
                summaryItem(
                    title: "Total",
                    value: "\(summary.total)",
                    color: .blue
                )
                
                summaryItem(
                    title: "Passed",
                    value: "\(summary.passed)",
                    color: .green
                )
                
                summaryItem(
                    title: "Failed",
                    value: "\(summary.failed)",
                    color: .red
                )
                
                summaryItem(
                    title: "Warnings",
                    value: "\(summary.warnings)",
                    color: .orange
                )
            }
            
            HStack {
                Text("Pass Rate:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.1f%%", summary.passRate))
                    .font(.headline)
                    .foregroundColor(summary.passRate >= 80 ? .green : .orange)
                
                Spacer()
                
                Text("Duration:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.2fs", summary.duration))
                    .font(.headline)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    private func summaryItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var testResultsList: some View {
        List {
            ForEach(groupedResults.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { category in
                Section(header: Text(category.rawValue)) {
                    ForEach(groupedResults[category] ?? []) { result in
                        TestResultRow(result: result)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var groupedResults: [IntegrationTester.TestResult.TestCategory: [IntegrationTester.TestResult]] {
        Dictionary(grouping: tester.testResults, by: { $0.category })
    }
}

struct TestResultRow: View {
    let result: IntegrationTester.TestResult
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.status.icon)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(result.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(isExpanded ? nil : 2)
                }
                
                Spacer()
                
                Text(String(format: "%.2fs", result.duration))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if result.status == .failed || result.status == .warning {
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text(isExpanded ? "Show Less" : "Show More")
                            .font(.caption)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let healthKitManager = HealthKitManager()
    let networkClient = NetworkClient()
    let configManager = ConfigurationManager()
    let gatewayService = GatewayService(networkClient: networkClient, configurationManager: configManager)
    let storageManager = StorageManager.shared
    let syncManager = SyncManager(
        healthKitManager: healthKitManager,
        gatewayService: gatewayService,
        storageManager: storageManager,
        configurationManager: configManager
    )
    
    IntegrationTestView(
        healthKitManager: healthKitManager,
        gatewayService: gatewayService,
        storageManager: storageManager,
        syncManager: syncManager,
        configManager: configManager
    )
}
