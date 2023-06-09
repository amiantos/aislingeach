//
// DatasetImagePopResponse.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

public struct DatasetImagePopResponse: Codable {
    /** The UUID of the image to rate */
    public var _id: String?
    /** The URL from which to download the image */
    public var url: String?
    /** The UUID of the dataset in which this image belongs */
    public var datasetId: String?

    public init(_id: String? = nil, url: String? = nil, datasetId: String? = nil) {
        self._id = _id
        self.url = url
        self.datasetId = datasetId
    }

    public enum CodingKeys: String, CodingKey {
        case _id = "id"
        case url
        case datasetId = "dataset_id"
    }
}
