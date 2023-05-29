//
// DeletedTeam.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

public struct DeletedTeam: Codable {
    /** The ID of the deleted team */
    public var deletedId: String?
    /** The Name of the deleted team */
    public var deletedName: String?

    public init(deletedId: String? = nil, deletedName: String? = nil) {
        self.deletedId = deletedId
        self.deletedName = deletedName
    }

    public enum CodingKeys: String, CodingKey {
        case deletedId = "deleted_id"
        case deletedName = "deleted_name"
    }
}
