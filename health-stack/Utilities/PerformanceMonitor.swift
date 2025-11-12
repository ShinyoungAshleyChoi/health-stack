//
//  PerformanceMonitor.swift
//  health-stack
//

import Foundation
import os.log

/// Monitors performance metrics for optimization
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "health-stack", category: "PerformanceMonitor")
    
    private init() {}
    
    // MARK: - Memory Monitoring
    
    func logMemoryUsage(context: String) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemoryMB = Double(info.resident_size) / 1024.0 / 1024.0
            logger.info("[\(context)] Memory usage: \(String(format: "%.2f", usedMemoryMB)) MB")
        }
    }
    
    // MARK: - Performance Timing
    
    func measureExecutionTime<T>(operation: String, block: () async throws -> T) async rethrows -> T {
        let startTime = Date()
        let result = try await block()
        let duration = Date().timeIntervalSince(startTime)
        
        logger.info("[\(operation)] Execution time: \(String(format: "%.3f", duration))s")
        
        return result
    }
    
    func measureExecutionTime<T>(operation: String, block: () throws -> T) rethrows -> T {
        let startTime = Date()
        let result = try block()
        let duration = Date().timeIntervalSince(startTime)
        
        logger.info("[\(operation)] Execution time: \(String(format: "%.3f", duration))s")
        
        return result
    }
    
    // MARK: - Batch Processing Metrics
    
    func logBatchMetrics(batchNumber: Int, totalBatches: Int, itemsInBatch: Int, processingTime: TimeInterval) {
        logger.info("Batch \(batchNumber)/\(totalBatches): \(itemsInBatch) items processed in \(String(format: "%.3f", processingTime))s")
    }
    
    // MARK: - Cache Metrics
    
    func logCacheHit(cache: String) {
        logger.debug("Cache hit: \(cache)")
    }
    
    func logCacheMiss(cache: String) {
        logger.debug("Cache miss: \(cache)")
    }
}
