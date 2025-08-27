//
// ModelPayloadTextualInversionStable.swift
//

import Foundation

public struct ModelPayloadTextualInversionStable: Codable {
    /** The exact name or CivitAI ID of the Textual Inversion. */
    public var name: String
    /** If set, Will automatically add this TI filename to the prompt or negative prompt accordingly using the provided strength. If this is set to None, then the user will have to manually add the embed to the prompt themselves. */
    public var injectTi: String?
    /** The strength with which to apply the TI to the prompt. Only used when inject_ti is not None */
    public var strength: Decimal?

    public init(name: String, injectTi: String? = nil, strength: Decimal? = nil) {
        self.name = name
        self.injectTi = injectTi
        self.strength = strength
    }

    public enum CodingKeys: String, CodingKey {
        case name
        case strength
        case injectTi = "inject_ti"
    }
}
