//
// AestheticRating.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation



public struct AestheticRating: Codable {

    /** The UUID of image being rated */
    public var _id: String
    /** The aesthetic rating 1-10 for this image */
    public var rating: Int
    /** The artifacts rating for this image. 0 for flawless generation that perfectly fits to the prompt. 1 for small, hardly recognizable flaws. 2 small flaws that can easily be spotted, but don not harm the aesthetic experience. 3 for flaws that look obviously wrong, but only mildly harm the aesthetic experience. 4 for flaws that look obviously wrong &amp; significantly harm the aesthetic experience. 5 for flaws that make the image look like total garbage */
    public var artifacts: Int?

    public init(_id: String, rating: Int, artifacts: Int? = nil) {
        self._id = _id
        self.rating = rating
        self.artifacts = artifacts
    }

    public enum CodingKeys: String, CodingKey { 
        case _id = "id"
        case rating
        case artifacts
    }

}
