//
//  BackgroundTaskManager.swift
//  health-stack
//

import Foundation
import BackgroundTasks
import os.log

/// Manages background task registration, scheduling, and execution
class BackgroundTaskManager {
    // MARK: - Properties
    
    static let shared = BackgroundTaskManager()
    
    private let logger = Logger(subsystem: "com.healthstack", category: "BackgroundTaskManager")
    
    // Background task identifiers
    static let healthSyncTaskIdentifier = "com.healthstack.sync"
    
    // Task handlers
    private var syncHandler: (() async throws -> Void)?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Registration
    
    /// Register all background tasks
    /// Must be called before application finishes launching
    func registerBackgroundTasks() {
        registerHealthSyncTask()
    }
    
    private func registerHealthSyncTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.healthSyncTaskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let self = self else { return }
            self.handleHealthSyncTask(task as! BGProcessingTask)
        }
        
        logger.info("Registered background task: \(Self.healthSyncTaskIdentifier)")
    }
    
    // MARK: - Scheduling
    
    /// Schedule a background sync task
    /// - Parameter interval: Time interval from now when the task should run
    func scheduleHealthSyncTask(interval: TimeInterval) {
        let request = BGProcessingTaskRequest(identifier: Self.healthSyncTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Scheduled health sync task for \(interval)s from now")
        } catch {
            logger.error("Failed to schedule background task: \(error.localizedDescription)")
        }
    }
    
    /// Cancel all scheduled background tasks
    func cancelAllTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.healthSyncTaskIdentifier)
        logger.info("Cancelled all background tasks")
    }
    
    // MARK: - Task Handlers
    
    /// Set the handler for health sync background tasks
    func setSyncHandler(_ handler: @escaping () async throws -> Void) {
        self.syncHandler = handler
    }
    
    private func handleHealthSyncTask(_ task: BGProcessingTask) {
        logger.info("Background health sync task started")
        
        let startTime = Date()
        
        // Create async task for sync operation
        let syncTask = Task {
            do {
                // Execute the sync handler
                if let handler = self.syncHandler {
                    try await handler()
                    
                    let duration = Date().timeIntervalSince(startTime)
                    self.logger.info("Background sync completed successfully in \(duration)s")
                    task.setTaskCompleted(success: true)
                } else {
                    self.logger.warning("No sync handler registered")
                    task.setTaskCompleted(success: false)
                }
            } catch {
                let duration = Date().timeIntervalSince(startTime)
                self.logger.error("Background sync failed after \(duration)s: \(error.localizedDescription)")
                task.setTaskCompleted(success: false)
            }
        }
        
        // Handle task expiration
        task.expirationHandler = { [weak self] in
            self?.logger.warning("Background task expired, cancelling sync operation")
            syncTask.cancel()
        }
    }
}
