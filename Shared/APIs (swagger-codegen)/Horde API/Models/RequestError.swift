//
// RequestError.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

public struct RequestError: Codable {
    /** The error message for this status code. */
    public var message: String?

    public init(message: String? = nil) {
        self.message = message
    }
}
