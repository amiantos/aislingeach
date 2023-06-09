// APIs.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

open class RatingsSwaggerClientAPI {
    public static var basePath = "https://ratings.aihorde.net/api"
    public static var credential: URLCredential?
    public static var customHeaders: [String: String] = [:]
    public static var requestBuilderFactory: RequestBuilderFactory = RatingsRatingsAlamofireRequestBuilderFactory()
}

open class RatingsRequestBuilder<T> {
    var credential: URLCredential?
    var headers: [String: String]
    public let parameters: [String: Any]?
    public let isBody: Bool
    public let method: String
    public let URLString: String

    /// Optional block to obtain a reference to the request's progress instance when available.
    public var onProgressReady: ((Progress) -> Void)?

    public required init(method: String, URLString: String, parameters: [String: Any]?, isBody: Bool, headers: [String: String] = [:]) {
        self.method = method
        self.URLString = URLString
        self.parameters = parameters
        self.isBody = isBody
        self.headers = headers

        addHeaders(RatingsSwaggerClientAPI.customHeaders)
    }

    open func addHeaders(_ aHeaders: [String: String]) {
        for (header, value) in aHeaders {
            headers[header] = value
        }
    }

    open func execute(_: @escaping (_ response: Response<T>?, _ error: Error?) -> Void) {}

    public func addHeader(name: String, value: String) -> Self {
        if !value.isEmpty {
            headers[name] = value
        }
        return self
    }

    open func addCredential() -> Self {
        credential = RatingsSwaggerClientAPI.credential
        return self
    }
}

public protocol RequestBuilderFactory {
    func getNonDecodableBuilder<T>() -> RatingsRequestBuilder<T>.Type
    func getBuilder<T: Decodable>() -> RatingsRequestBuilder<T>.Type
}
