//
// StatusModesBody.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation



public struct StatusModesBody: Codable {

    public var maintenance: Bool?
    public var inviteOnly: Bool?
    public var raid: Bool?

    public init(maintenance: Bool? = nil, inviteOnly: Bool? = nil, raid: Bool? = nil) {
        self.maintenance = maintenance
        self.inviteOnly = inviteOnly
        self.raid = raid
    }

    public enum CodingKeys: String, CodingKey { 
        case maintenance
        case inviteOnly = "invite_only"
        case raid
    }

}
