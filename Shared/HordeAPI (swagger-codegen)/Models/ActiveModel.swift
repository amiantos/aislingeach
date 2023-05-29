//
// ActiveModel.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

public struct ActiveModel: Codable {
    public enum ModelType: String, Codable {
        case image
        case text
    }

    /** The Name of a model available by workers in this horde. */
    public var name: String?
    /** How many of workers in this horde are running this model. */
    public var count: Int?
    /** The average speed of generation for this model */
    public var performance: Decimal?
    /** The amount waiting to be generated by this model */
    public var queued: Decimal?
    /** The job count waiting to be generated by this model */
    public var jobs: Decimal?
    /** Estimated time in seconds for this model&#x27;s queue to be cleared */
    public var eta: Int?
    /** The model type (text or image) */
    public var type: ModelType?

    public init(name: String? = nil, count: Int? = nil, performance: Decimal? = nil, queued: Decimal? = nil, jobs: Decimal? = nil, eta: Int? = nil, type: ModelType? = nil) {
        self.name = name
        self.count = count
        self.performance = performance
        self.queued = queued
        self.jobs = jobs
        self.eta = eta
        self.type = type
    }
}
