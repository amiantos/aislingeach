//
// UserRecords.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

public struct UserRecords: Codable {
    public var usage: UserThingRecords?
    public var contribution: UserThingRecords?
    public var fulfillment: UserAmountRecords?
    public var request: UserAmountRecords?

    public init(usage: UserThingRecords? = nil, contribution: UserThingRecords? = nil, fulfillment: UserAmountRecords? = nil, request: UserAmountRecords? = nil) {
        self.usage = usage
        self.contribution = contribution
        self.fulfillment = fulfillment
        self.request = request
    }
}
