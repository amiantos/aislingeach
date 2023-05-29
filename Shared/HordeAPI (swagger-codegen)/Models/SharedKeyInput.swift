//
// SharedKeyInput.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

public struct SharedKeyInput: Codable {
    /** The Kudos limit assigned to this key. If -1, then anyone with this key can use an unlimited amount of kudos from this account. */
    public var kudos: Int?
    /** The amount of days after which this key will expire. If -1, this key will not expire */
    public var expiry: Int?
    /** A descriptive name for this key */
    public var name: String?

    public init(kudos: Int? = nil, expiry: Int? = nil, name: String? = nil) {
        self.kudos = kudos
        self.expiry = expiry
        self.name = name
    }
}
