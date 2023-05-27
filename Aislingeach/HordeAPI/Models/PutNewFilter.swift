//
// PutNewFilter.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation



public struct PutNewFilter: Codable {

    /** The regex for this filter. */
    public var regex: String
    /** The integer defining this filter type */
    public var filterType: Int
    /** Description about this regex */
    public var _description: String?
    /** The replacement string for this regex */
    public var replacement: String?

    public init(regex: String, filterType: Int, _description: String? = nil, replacement: String? = nil) {
        self.regex = regex
        self.filterType = filterType
        self._description = _description
        self.replacement = replacement
    }

    public enum CodingKeys: String, CodingKey { 
        case regex
        case filterType = "filter_type"
        case _description = "description"
        case replacement
    }

}
