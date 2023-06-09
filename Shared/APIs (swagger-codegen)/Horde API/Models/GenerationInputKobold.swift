//
// GenerationInputKobold.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

public struct GenerationInputKobold: Codable {
    /** The prompt which will be sent to KoboldAI to generate text */
    public var prompt: String?
    public var params: ModelGenerationInputKobold?
    /** Specify which softpompt needs to be used to service this request */
    public var softprompt: String?
    /** When true, only trusted workers will serve this request. When False, Evaluating workers will also be used which can increase speed but adds more risk! */
    public var trustedWorkers: Bool?
    /** When True, allows slower workers to pick up this request. Disabling this incurs an extra kudos cost. */
    public var slowWorkers: Bool?
    public var workers: [String]?
    /** If true, the worker list will be treated as a blacklist instead of a whitelist. */
    public var workerBlacklist: Bool?
    public var models: [String]?
    /** When false, the endpoint will simply return the cost of the request in kudos and exit. */
    public var dryRun: Bool?

    public init(prompt: String? = nil, params: ModelGenerationInputKobold? = nil, softprompt: String? = nil, trustedWorkers: Bool? = nil, slowWorkers: Bool? = nil, workers: [String]? = nil, workerBlacklist: Bool? = nil, models: [String]? = nil, dryRun: Bool? = nil) {
        self.prompt = prompt
        self.params = params
        self.softprompt = softprompt
        self.trustedWorkers = trustedWorkers
        self.slowWorkers = slowWorkers
        self.workers = workers
        self.workerBlacklist = workerBlacklist
        self.models = models
        self.dryRun = dryRun
    }

    public enum CodingKeys: String, CodingKey {
        case prompt
        case params
        case softprompt
        case trustedWorkers = "trusted_workers"
        case slowWorkers = "slow_workers"
        case workers
        case workerBlacklist = "worker_blacklist"
        case models
        case dryRun = "dry_run"
    }
}
