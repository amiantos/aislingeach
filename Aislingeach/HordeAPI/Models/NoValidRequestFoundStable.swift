//
// NoValidRequestFoundStable.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation



public struct NoValidRequestFoundStable: Codable {

    /** How many waiting requests were skipped because they demanded a specific worker */
    public var workerId: Int?
    /** How many waiting requests were skipped because they required higher performance */
    public var performance: Int?
    /** How many waiting requests were skipped because they demanded a nsfw generation which this worker does not provide. */
    public var nsfw: Int?
    /** How many waiting requests were skipped because they demanded a generation with a word that this worker does not accept. */
    public var blacklist: Int?
    /** How many waiting requests were skipped because they demanded a trusted worker which this worker is not. */
    public var untrusted: Int?
    /** How many waiting requests were skipped because they demanded a different model than what this worker provides. */
    public var models: Int?
    /** How many waiting requests were skipped because they require a higher version of the bridge than this worker is running (upgrade if you see this in your skipped list). */
    public var bridgeVersion: Int?
    /** How many waiting requests were skipped because the user didn&#x27;t have enough kudos when this worker requires upfront kudos */
    public var kudos: Int?
    /** How many waiting requests were skipped because they demanded a higher size than this worker provides */
    public var maxPixels: Int?
    /** How many waiting requests were skipped because they came from an unsafe IP */
    public var unsafeIp: Int?
    /** How many waiting requests were skipped because they requested img2img */
    public var img2img: Int?
    /** How many waiting requests were skipped because they requested inpainting/outpainting */
    public var painting: Int?
    /** How many waiting requests were skipped because they requested post-processing */
    public var postProcessing: Int?
    /** How many waiting requests were skipped because they requested loras */
    public var lora: Int?
    /** How many waiting requests were skipped because they requested a controlnet */
    public var controlnet: Int?

    public init(workerId: Int? = nil, performance: Int? = nil, nsfw: Int? = nil, blacklist: Int? = nil, untrusted: Int? = nil, models: Int? = nil, bridgeVersion: Int? = nil, kudos: Int? = nil, maxPixels: Int? = nil, unsafeIp: Int? = nil, img2img: Int? = nil, painting: Int? = nil, postProcessing: Int? = nil, lora: Int? = nil, controlnet: Int? = nil) {
        self.workerId = workerId
        self.performance = performance
        self.nsfw = nsfw
        self.blacklist = blacklist
        self.untrusted = untrusted
        self.models = models
        self.bridgeVersion = bridgeVersion
        self.kudos = kudos
        self.maxPixels = maxPixels
        self.unsafeIp = unsafeIp
        self.img2img = img2img
        self.painting = painting
        self.postProcessing = postProcessing
        self.lora = lora
        self.controlnet = controlnet
    }

    public enum CodingKeys: String, CodingKey { 
        case workerId = "worker_id"
        case performance
        case nsfw
        case blacklist
        case untrusted
        case models
        case bridgeVersion = "bridge_version"
        case kudos
        case maxPixels = "max_pixels"
        case unsafeIp = "unsafe_ip"
        case img2img
        case painting
        case postProcessing = "post-processing"
        case lora
        case controlnet
    }

}
