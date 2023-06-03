//
// ModifyUser.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

public struct ModifyUser: Codable {
    /** The new total Kudos this user has after this request */
    public var newKudos: Decimal?
    /** The request concurrency this user has after this request */
    public var concurrency: Int?
    /** Multiplies the amount of kudos lost when generating images. */
    public var usageMultiplier: Decimal?
    /** Whether this user has been invited to join a worker to the horde and how many of them. When 0, this user cannot add (new) workers to the horde. */
    public var workerInvited: Int?
    /** The user&#x27;s new moderator status. */
    public var moderator: Bool?
    /** The user&#x27;s new public_workers status. */
    public var publicWorkers: Bool?
    /** The user&#x27;s new username. */
    public var username: String?
    /** The user&#x27;s new monthly kudos total */
    public var monthlyKudos: Int?
    /** The user&#x27;s new trusted status */
    public var trusted: Bool?
    /** The user&#x27;s new flagged status */
    public var flagged: Bool?
    /** The user&#x27;s new customizer status */
    public var customizer: Bool?
    /** The user&#x27;s new vpn status */
    public var vpn: Bool?
    /** The user&#x27;s new suspiciousness rating */
    public var newSuspicion: Int?
    /** The new contact details */
    public var contact: String?

    public init(newKudos: Decimal? = nil, concurrency: Int? = nil, usageMultiplier: Decimal? = nil, workerInvited: Int? = nil, moderator: Bool? = nil, publicWorkers: Bool? = nil, username: String? = nil, monthlyKudos: Int? = nil, trusted: Bool? = nil, flagged: Bool? = nil, customizer: Bool? = nil, vpn: Bool? = nil, newSuspicion: Int? = nil, contact: String? = nil) {
        self.newKudos = newKudos
        self.concurrency = concurrency
        self.usageMultiplier = usageMultiplier
        self.workerInvited = workerInvited
        self.moderator = moderator
        self.publicWorkers = publicWorkers
        self.username = username
        self.monthlyKudos = monthlyKudos
        self.trusted = trusted
        self.flagged = flagged
        self.customizer = customizer
        self.vpn = vpn
        self.newSuspicion = newSuspicion
        self.contact = contact
    }

    public enum CodingKeys: String, CodingKey {
        case newKudos = "new_kudos"
        case concurrency
        case usageMultiplier = "usage_multiplier"
        case workerInvited = "worker_invited"
        case moderator
        case publicWorkers = "public_workers"
        case username
        case monthlyKudos = "monthly_kudos"
        case trusted
        case flagged
        case customizer
        case vpn
        case newSuspicion = "new_suspicion"
        case contact
    }
}