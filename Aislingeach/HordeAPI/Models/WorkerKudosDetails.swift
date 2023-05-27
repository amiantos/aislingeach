//
// WorkerKudosDetails.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation



public struct WorkerKudosDetails: Codable {

    /** How much Kudos this worker has received for generating images */
    public var generated: Decimal?
    /** How much Kudos this worker has received for staying online longer */
    public var uptime: Int?

    public init(generated: Decimal? = nil, uptime: Int? = nil) {
        self.generated = generated
        self.uptime = uptime
    }


}
