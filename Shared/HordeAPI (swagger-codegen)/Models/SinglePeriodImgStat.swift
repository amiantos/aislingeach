//
// SinglePeriodImgStat.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

public struct SinglePeriodImgStat: Codable {
    /** The amount of text requests generated during this period. */
    public var requests: Int?
    /** The amount of tokens generated during this period. */
    public var tokens: Int?

    public init(requests: Int? = nil, tokens: Int? = nil) {
        self.requests = requests
        self.tokens = tokens
    }
}
