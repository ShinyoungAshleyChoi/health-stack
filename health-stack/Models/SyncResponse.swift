//
//  SyncResponse.swift
//  health-stack
//

import Foundation

struct SyncResponse: Codable {
    let status: String
    let requestId: String?
    let timestamp: String
    let samplesReceived: Int
    
    enum CodingKeys: String, CodingKey {
        case status
        case requestId
        case timestamp
        case samplesReceived
    }
    
    init(status: String, requestId: String? = nil, timestamp: String, samplesReceived: Int) {
        self.status = status
        self.requestId = requestId
        self.timestamp = timestamp
        self.samplesReceived = samplesReceived
    }
}
