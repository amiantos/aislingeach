//
// NoValidInterrogationsFound.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

public struct NoValidInterrogationsFound: Codable {
    /** How many waiting requests were skipped because they demanded a specific worker */
    public var workerId: Int?
    /** How many waiting requests were skipped because they demanded a trusted worker which this worker is not. */
    public var untrusted: Int?
    /** How many waiting requests were skipped because they require a higher version of the bridge than this worker is running (upgrade if you see this in your skipped list). */
    public var bridgeVersion: Int?

    public init(workerId: Int? = nil, untrusted: Int? = nil, bridgeVersion: Int? = nil) {
        self.workerId = workerId
        self.untrusted = untrusted
        self.bridgeVersion = bridgeVersion
    }

    public enum CodingKeys: String, CodingKey {
        case workerId = "worker_id"
        case untrusted
        case bridgeVersion = "bridge_version"
    }
}
