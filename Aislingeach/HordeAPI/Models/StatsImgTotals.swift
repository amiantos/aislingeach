//
// StatsImgTotals.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation



public struct StatsImgTotals: Codable {

    public var minute: SinglePeriodImgStat?
    public var hour: SinglePeriodImgStat?
    public var day: SinglePeriodImgStat?
    public var month: SinglePeriodImgStat?
    public var total: SinglePeriodImgStat?

    public init(minute: SinglePeriodImgStat? = nil, hour: SinglePeriodImgStat? = nil, day: SinglePeriodImgStat? = nil, month: SinglePeriodImgStat? = nil, total: SinglePeriodImgStat? = nil) {
        self.minute = minute
        self.hour = hour
        self.day = day
        self.month = month
        self.total = total
    }


}
