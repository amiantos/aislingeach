//
// GenerationStable.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

public struct GenerationStable: Codable {
    public enum State: String, Codable {
        case ok
        case censored
    }

    /** The UUID of the worker which generated this image */
    public var workerId: String?
    /** The name of the worker which generated this image */
    public var workerName: String?
    /** The model which generated this image */
    public var model: String?
    /** The state of this generation. */
    public var state: State
    /** The generated image as a Base64-encoded .webp file */
    public var img: String?
    /** The seed which generated this image */
    public var seed: String?
    /** The ID for this image */
    public var _id: String?
    /** When true this image has been censored by the worker&#x27;s safety filter. */
    public var censored: Bool?

    public init(workerId: String? = nil, workerName: String? = nil, model: String? = nil, state: State, img: String? = nil, seed: String? = nil, _id: String? = nil, censored: Bool? = nil) {
        self.workerId = workerId
        self.workerName = workerName
        self.model = model
        self.state = state
        self.img = img
        self.seed = seed
        self._id = _id
        self.censored = censored
    }

    public enum CodingKeys: String, CodingKey {
        case workerId = "worker_id"
        case workerName = "worker_name"
        case model
        case state
        case img
        case seed
        case _id = "id"
        case censored
    }
}