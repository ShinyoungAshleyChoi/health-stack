//
//  GatewayServiceProtocol.swift
//  health-stack
//

import Foundation

protocol GatewayServiceProtocol {
    func configure(config: GatewayConfig) throws
    func sendHealthData(_ data: [HealthDataSample]) async throws -> SyncResponse
    func testConnection() async throws -> Bool
    func validateSecureConnection() throws
}
