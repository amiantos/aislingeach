//
// UserDetails.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

public struct UserDetails: Codable {
    /** The user&#x27;s unique Username. It is a combination of their chosen alias plus their ID. */
    public var username: String?
    /** The user unique ID. It is always an integer. */
    public var _id: Int?
    /** The amount of Kudos this user has. The amount of Kudos determines the priority when requesting image generations. */
    public var kudos: Decimal?
    /** (Privileged) The amount of Evaluating Kudos this untrusted user has from generations and uptime. When this number reaches a prespecified threshold, they automatically become trusted. */
    public var evaluatingKudos: Decimal?
    /** How many concurrent generations this user may request. */
    public var concurrency: Int?
    /** Whether this user has been invited to join a worker to the horde and how many of them. When 0, this user cannot add (new) workers to the horde. */
    public var workerInvited: Int?
    /** This user is a Horde moderator. */
    public var moderator: Bool?
    public var kudosDetails: UserKudosDetails?
    /** How many workers this user has created (active or inactive) */
    public var workerCount: Int?
    public var workerIds: [String]?
    public var sharedkeyIds: [String]?
    public var monthlyKudos: MonthlyKudos?
    /** This user is a trusted member of the Horde. */
    public var trusted: Bool?
    /** This user has been flagged for suspicious activity. */
    public var flagged: Bool?
    /** (Privileged) This user has been given the VPN role. */
    public var vpn: Bool?
    /** (Privileged) How much suspicion this user has accumulated */
    public var suspicious: Int?
    /** If true, this user has not registered using an oauth service. */
    public var pseudonymous: Bool?
    /** (Privileged) Contact details for the horde admins to reach the user in case of emergency. */
    public var contact: String?
    /** How many seconds since this account was created */
    public var accountAge: Int?
    public var usage: UsageDetails?
    public var contributions: ContributionsDetails?
    public var records: UserRecords?

    public init(username: String? = nil, _id: Int? = nil, kudos: Decimal? = nil, evaluatingKudos: Decimal? = nil, concurrency: Int? = nil, workerInvited: Int? = nil, moderator: Bool? = nil, kudosDetails: UserKudosDetails? = nil, workerCount: Int? = nil, workerIds: [String]? = nil, sharedkeyIds: [String]? = nil, monthlyKudos: MonthlyKudos? = nil, trusted: Bool? = nil, flagged: Bool? = nil, vpn: Bool? = nil, suspicious: Int? = nil, pseudonymous: Bool? = nil, contact: String? = nil, accountAge: Int? = nil, usage: UsageDetails? = nil, contributions: ContributionsDetails? = nil, records: UserRecords? = nil) {
        self.username = username
        self._id = _id
        self.kudos = kudos
        self.evaluatingKudos = evaluatingKudos
        self.concurrency = concurrency
        self.workerInvited = workerInvited
        self.moderator = moderator
        self.kudosDetails = kudosDetails
        self.workerCount = workerCount
        self.workerIds = workerIds
        self.sharedkeyIds = sharedkeyIds
        self.monthlyKudos = monthlyKudos
        self.trusted = trusted
        self.flagged = flagged
        self.vpn = vpn
        self.suspicious = suspicious
        self.pseudonymous = pseudonymous
        self.contact = contact
        self.accountAge = accountAge
        self.usage = usage
        self.contributions = contributions
        self.records = records
    }

    public enum CodingKeys: String, CodingKey {
        case username
        case _id = "id"
        case kudos
        case evaluatingKudos = "evaluating_kudos"
        case concurrency
        case workerInvited = "worker_invited"
        case moderator
        case kudosDetails = "kudos_details"
        case workerCount = "worker_count"
        case workerIds = "worker_ids"
        case sharedkeyIds = "sharedkey_ids"
        case monthlyKudos = "monthly_kudos"
        case trusted
        case flagged
        case vpn
        case suspicious
        case pseudonymous
        case contact
        case accountAge = "account_age"
        case usage
        case contributions
        case records
    }
}
