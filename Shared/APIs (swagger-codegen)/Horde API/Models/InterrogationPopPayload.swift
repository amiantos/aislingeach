//
// InterrogationPopPayload.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

public struct InterrogationPopPayload: Codable {
    public var forms: [InterrogationPopFormPayload]?
    public var skipped: NoValidInterrogationsFound?

    public init(forms: [InterrogationPopFormPayload]? = nil, skipped: NoValidInterrogationsFound? = nil) {
        self.forms = forms
        self.skipped = skipped
    }
}
