//
// RequestAccepted.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

public struct RequestAccepted: Codable {
    /** The message for this status code. */
    public var message: String?

    public init(message: String? = nil) {
        self.message = message
    }
}
