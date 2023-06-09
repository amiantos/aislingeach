//
// InterrogationPopInput.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

public struct InterrogationPopInput: Codable {
    public enum Forms: String, Codable {
        case caption
        case interrogation
        case nsfw
        case gfpgan = "GFPGAN"
        case realesrganX4plus = "RealESRGAN_x4plus"
        case realesrganX2plus = "RealESRGAN_x2plus"
        case realesrganX4plusAnime6b = "RealESRGAN_x4plus_anime_6B"
        case nmkdSiax = "NMKD_Siax"
        case _4xAnimeSharp = "4x_AnimeSharp"
        case codeFormers = "CodeFormers"
        case stripBackground = "strip_background"
    }

    /** The Name of the Worker */
    public var name: String?
    public var priorityUsernames: [String]?
    public var forms: [Forms]?
    /** The amount of forms to pop at the same time */
    public var amount: Int?
    /** The version of the bridge used by this worker */
    public var bridgeVersion: Int?
    /** The worker name, version and website */
    public var bridgeAgent: String?
    /** How many threads this worker is running. This is used to accurately the current power available in the horde */
    public var threads: Int?
    /** The maximum amount of 512x512 tiles this worker can post-process */
    public var maxTiles: Int?

    public init(name: String? = nil, priorityUsernames: [String]? = nil, forms: [Forms]? = nil, amount: Int? = nil, bridgeVersion: Int? = nil, bridgeAgent: String? = nil, threads: Int? = nil, maxTiles: Int? = nil) {
        self.name = name
        self.priorityUsernames = priorityUsernames
        self.forms = forms
        self.amount = amount
        self.bridgeVersion = bridgeVersion
        self.bridgeAgent = bridgeAgent
        self.threads = threads
        self.maxTiles = maxTiles
    }

    public enum CodingKeys: String, CodingKey {
        case name
        case priorityUsernames = "priority_usernames"
        case forms
        case amount
        case bridgeVersion = "bridge_version"
        case bridgeAgent = "bridge_agent"
        case threads
        case maxTiles = "max_tiles"
    }
}
