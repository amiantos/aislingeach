//
// UserKudosDetails.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

public struct UserKudosDetails: Codable {
    /** The ammount of Kudos accumulated or used for generating images. */
    public var accumulated: Decimal?
    /** The amount of Kudos this user has given to other users. */
    public var gifted: Decimal?
    /** The amount of Kudos this user has been given by the Horde admins. */
    public var admin: Decimal?
    /** The amount of Kudos this user has been given by other users. */
    public var received: Decimal?
    /** The amount of Kudos this user has received from recurring rewards. */
    public var recurring: Decimal?
    /** The amount of Kudos this user has been awarded from things like rating images. */
    public var awarded: Decimal?

    public init(accumulated: Decimal? = nil, gifted: Decimal? = nil, admin: Decimal? = nil, received: Decimal? = nil, recurring: Decimal? = nil, awarded: Decimal? = nil) {
        self.accumulated = accumulated
        self.gifted = gifted
        self.admin = admin
        self.received = received
        self.recurring = recurring
        self.awarded = awarded
    }
}
