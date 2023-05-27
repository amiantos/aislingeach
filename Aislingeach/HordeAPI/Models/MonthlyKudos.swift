//
// MonthlyKudos.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation



public struct MonthlyKudos: Codable {

    /** How much recurring Kudos this user receives monthly. */
    public var amount: Int?
    /** Last date this user received monthly Kudos. */
    public var lastReceived: Date?

    public init(amount: Int? = nil, lastReceived: Date? = nil) {
        self.amount = amount
        self.lastReceived = lastReceived
    }

    public enum CodingKeys: String, CodingKey { 
        case amount
        case lastReceived = "last_received"
    }

}
