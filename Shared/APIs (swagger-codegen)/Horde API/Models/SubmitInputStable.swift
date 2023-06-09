//
// SubmitInputStable.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

public struct SubmitInputStable: Codable {
    public enum State: String, Codable {
        case ok
        case censored
        case faulted
        case csam
    }

    /** The UUID of this generation */
    public var _id: String
    /** R2 result was uploaded to R2, else the string of the result. */
    public var generation: String?
    /** The state of this generation. */
    public var state: State?
    /** The seed for this generation */
    public var seed: Int
    /** If True, this resulting image has been censored */
    public var censored: Bool?

    public init(_id: String, generation: String? = nil, state: State? = nil, seed: Int, censored: Bool? = nil) {
        self._id = _id
        self.generation = generation
        self.state = state
        self.seed = seed
        self.censored = censored
    }

    public enum CodingKeys: String, CodingKey {
        case _id = "id"
        case generation
        case state
        case seed
        case censored
    }
}
