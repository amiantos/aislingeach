//
// ModifyTeam.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

public struct ModifyTeam: Codable {
    /** The ID of the team */
    public var _id: String?
    /** The Name of the team */
    public var name: String?
    /** The Info of the team */
    public var info: String?

    public init(_id: String? = nil, name: String? = nil, info: String? = nil) {
        self._id = _id
        self.name = name
        self.info = info
    }

    public enum CodingKeys: String, CodingKey {
        case _id = "id"
        case name
        case info
    }
}
