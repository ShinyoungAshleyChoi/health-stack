//
//  SyncHistoryView.swift
//  health-stack
//

import SwiftUI

struct SyncHistoryView: View {
    @StateObject private var viewModel: SyncHistoryViewModel
    
    init(syncManager: SyncManagerProtocol) {
        _viewModel = StateObject(wrappedValue: SyncHistoryViewModel(syncManager: syncManager))
    }
    
    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.syncRecords.isEmpty {
                ProgressView("Loading sync history...")
                    .accessibilityLabel("Loading sync history")
            } else if viewModel.syncRecords.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    
                    Text("No Sync History")
                        .font(.headline)
                    
                    Text("Sync history will appear here after your first sync")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("No sync history. Sync history will appear here after your first sync")
                .accessibilityIdentifier(AccessibilityIdentifiers.SyncHistoryView.emptyState)
            } else {
                List {
                    ForEach(viewModel.syncRecords) { record in
                        SyncRecordRow(
                            record: record,
                            isExpanded: viewModel.isExpanded(recordId: record.id),
                            viewModel: viewModel
                        )
                        .onTapGesture {
                            HapticFeedback.light.generate()
                            withAnimation {
                                viewModel.toggleExpanded(recordId: record.id)
                            }
                        }
                    }
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.SyncHistoryView.historyList)
                .refreshable {
                    HapticFeedback.light.generate()
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle("Sync History")
        .navigationBarTitleDisplayMode(.inline)
        .errorAlert(error: $viewModel.errorInfo) {
            Task {
                await viewModel.loadSyncHistory()
            }
        }
        .task {
            await viewModel.loadSyncHistory()
        }
    }
}

struct SyncRecordRow: View {
    let record: SyncRecord
    let isExpanded: Bool
    let viewModel: SyncHistoryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main row content
            HStack(spacing: 12) {
                // Status icon
                Image(systemName: viewModel.statusIcon(for: record.status))
                    .font(.system(size: 24))
                    .foregroundColor(statusColor)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Status text
                    Text(viewModel.statusText(for: record.status))
                        .font(.headline)
                    
                    // Timestamp
                    Text(viewModel.formattedTimestamp(record.timestamp))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Synced count
                    Text("\(record.syncedCount) items")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Duration
                    Text(viewModel.formattedDuration(record.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Expand indicator
                if record.errorMessage != nil {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
            }
            
            // Expanded error details
            if isExpanded, let errorMessage = record.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    Text("Error Details")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Error details: \(errorMessage)")
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(record.errorMessage != nil ? "Double tap to \(isExpanded ? "collapse" : "expand") error details" : "")
        .accessibilityIdentifier("\(AccessibilityIdentifiers.SyncHistoryView.recordRow)_\(record.id)")
    }
    
    private var accessibilityLabel: String {
        var label = "\(viewModel.statusText(for: record.status)), \(viewModel.formattedTimestamp(record.timestamp)), \(record.syncedCount) items synced, duration \(viewModel.formattedDuration(record.duration))"
        if isExpanded, let errorMessage = record.errorMessage {
            label += ", Error: \(errorMessage)"
        }
        return label
    }
    
    private var statusColor: Color {
        switch record.status {
        case .success:
            return .green
        case .partialSuccess:
            return .orange
        case .failed:
            return .red
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SyncHistoryView(syncManager: MockSyncManager())
    }
}

// MARK: - Mock for Preview

class MockSyncManager: SyncManagerProtocol {
    func startAutoSync() {}
    func stopAutoSync() {}
    
    func performManualSync() async throws {}
    
    func getSyncStatus() -> SyncStatus {
        return .idle
    }
    
    func getSyncHistory() async throws -> [SyncRecord] {
        return [
            SyncRecord(
                timestamp: Date(),
                status: .success,
                syncedCount: 150,
                duration: 2.5
            ),
            SyncRecord(
                timestamp: Date().addingTimeInterval(-3600),
                status: .partialSuccess,
                syncedCount: 75,
                errorMessage: "Some data types failed to sync",
                duration: 5.2
            ),
            SyncRecord(
                timestamp: Date().addingTimeInterval(-7200),
                status: .failed,
                syncedCount: 0,
                errorMessage: "Network connection failed: The request timed out",
                duration: 30.0
            ),
            SyncRecord(
                timestamp: Date().addingTimeInterval(-86400),
                status: .success,
                syncedCount: 200,
                duration: 1.8
            )
        ]
    }
    
    func setSyncStatusCallback(_ callback: @escaping (SyncStatus) -> Void) {}
}
