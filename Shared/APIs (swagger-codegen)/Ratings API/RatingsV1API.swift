//
// RatingsV1API.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation
import Alamofire


open class RatingsV1API {
    /**

     - parameter userId: (path)  
     - parameter apikey: (header) A Moderator API key (optional)
     - parameter minutes: (query) Check how many divergent ratings they had in the last minutes (optional)
     - parameter divergence: (query) How much +- divergence to check for (optional, default to 3)
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func getCheckUser(userId: String, apikey: String? = nil, minutes: Decimal? = nil, divergence: Int? = nil, completion: @escaping ((_ data: Void?,_ error: Error?) -> Void)) {
        getCheckUserWithRequestBuilder(userId: userId, apikey: apikey, minutes: minutes, divergence: divergence).execute { (response, error) -> Void in
            if error == nil {
                completion((), error)
            } else {
                completion(nil, error)
            }
        }
    }


    /**
     - GET /v1/user/check/{user_id}
     - 

     - parameter userId: (path)  
     - parameter apikey: (header) A Moderator API key (optional)
     - parameter minutes: (query) Check how many divergent ratings they had in the last minutes (optional)
     - parameter divergence: (query) How much +- divergence to check for (optional, default to 3)

     - returns: RequestBuilder<Void> 
     */
    open class func getCheckUserWithRequestBuilder(userId: String, apikey: String? = nil, minutes: Decimal? = nil, divergence: Int? = nil) -> RatingsRequestBuilder<Void> {
        var path = "/v1/user/check/{user_id}"
        let userIdPreEscape = "\(userId)"
        let userIdPostEscape = userIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: "{user_id}", with: userIdPostEscape, options: .literal, range: nil)
        let URLString = RatingsSwaggerClientAPI.basePath + path
        let parameters: [String:Any]? = nil
        var url = URLComponents(string: URLString)
        url?.queryItems = APIHelper.mapValuesToQueryItems([
                        "minutes": minutes, 
                        "divergence": divergence?.encodeToJSON()
        ])
        let nillableHeaders: [String: Any?] = [
                        "apikey": apikey
        ]
        let headerParameters = APIHelper.rejectNilHeaders(nillableHeaders)

        let requestBuilder: RatingsRequestBuilder<Void>.Type = RatingsSwaggerClientAPI.requestBuilderFactory.getNonDecodableBuilder()

        return requestBuilder.init(method: "GET", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false, headers: headerParameters)
    }
    /**
     Retrieve an image to rate from a specific dataset

     - parameter datasetId: (path)  
     - parameter apikey: (header) The user API key. This is used to prevent retrieving the same image. When not provided, will retrieve as anonymous (optional)
     - parameter xFields: (header) An optional fields mask (optional)
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func getDatasetImagePop(datasetId: String, apikey: String? = nil, xFields: String? = nil, completion: @escaping ((_ data: DatasetImagePopResponse?,_ error: Error?) -> Void)) {
        getDatasetImagePopWithRequestBuilder(datasetId: datasetId, apikey: apikey, xFields: xFields).execute { (response, error) -> Void in
            completion(response?.body, error)
        }
    }


    /**
     Retrieve an image to rate from a specific dataset
     - GET /v1/rating/new/{dataset_id}
     - 

     - examples: [{contentType=application/json, example={
  "dataset_id" : "00000000-0000-0000-0000-000000000000",
  "id" : "00000000-0000-0000-0000-000000000000",
  "url" : "https://cdn.droom.cloud/00000000-0000-0000-0000-000000000000.webp"
}}]
     - parameter datasetId: (path)  
     - parameter apikey: (header) The user API key. This is used to prevent retrieving the same image. When not provided, will retrieve as anonymous (optional)
     - parameter xFields: (header) An optional fields mask (optional)

     - returns: RequestBuilder<DatasetImagePopResponse> 
     */
    open class func getDatasetImagePopWithRequestBuilder(datasetId: String, apikey: String? = nil, xFields: String? = nil) -> RatingsRequestBuilder<DatasetImagePopResponse> {
        var path = "/v1/rating/new/{dataset_id}"
        let datasetIdPreEscape = "\(datasetId)"
        let datasetIdPostEscape = datasetIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: "{dataset_id}", with: datasetIdPostEscape, options: .literal, range: nil)
        let URLString = RatingsSwaggerClientAPI.basePath + path
        let parameters: [String:Any]? = nil
        let url = URLComponents(string: URLString)
        let nillableHeaders: [String: Any?] = [
                        "apikey": apikey,
                        "X-Fields": xFields
        ]
        let headerParameters = APIHelper.rejectNilHeaders(nillableHeaders)

        let requestBuilder: RatingsRequestBuilder<DatasetImagePopResponse>.Type = RatingsSwaggerClientAPI.requestBuilderFactory.getBuilder()

        return requestBuilder.init(method: "GET", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false, headers: headerParameters)
    }
    /**
     Display all datasets

     - parameter apikey: (header) A privileged user API key. (optional)
     - parameter xFields: (header) An optional fields mask (optional)
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func getDatasets(apikey: String? = nil, xFields: String? = nil, completion: @escaping ((_ data: [DatasetsGetResponse]?,_ error: Error?) -> Void)) {
        getDatasetsWithRequestBuilder(apikey: apikey, xFields: xFields).execute { (response, error) -> Void in
            completion(response?.body, error)
        }
    }


    /**
     Display all datasets
     - GET /v1/datasets

     - examples: [{contentType=application/json, example=[ {
  "name" : "My Dataset",
  "description" : "This is a dataset of images of cats.",
  "image_count" : 100,
  "id" : "00000000-0000-0000-0000-000000000000"
}, {
  "name" : "My Dataset",
  "description" : "This is a dataset of images of cats.",
  "image_count" : 100,
  "id" : "00000000-0000-0000-0000-000000000000"
} ]}]
     - parameter apikey: (header) A privileged user API key. (optional)
     - parameter xFields: (header) An optional fields mask (optional)

     - returns: RequestBuilder<[DatasetsGetResponse]> 
     */
    open class func getDatasetsWithRequestBuilder(apikey: String? = nil, xFields: String? = nil) -> RatingsRequestBuilder<[DatasetsGetResponse]> {
        let path = "/v1/datasets"
        let URLString = RatingsSwaggerClientAPI.basePath + path
        let parameters: [String:Any]? = nil
        let url = URLComponents(string: URLString)
        let nillableHeaders: [String: Any?] = [
                        "apikey": apikey,
                        "X-Fields": xFields
        ]
        let headerParameters = APIHelper.rejectNilHeaders(nillableHeaders)

        let requestBuilder: RatingsRequestBuilder<[DatasetsGetResponse]>.Type = RatingsSwaggerClientAPI.requestBuilderFactory.getBuilder()

        return requestBuilder.init(method: "GET", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false, headers: headerParameters)
    }
    /**
     Retrieve an image to rate from the default dataset

     - parameter apikey: (header) The user API key. This is used to prevent retrieving the same image. When not provided, will retrieve as anonymous (optional)
     - parameter xFields: (header) An optional fields mask (optional)
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func getDefaultDatasetImagePop(apikey: String? = nil, xFields: String? = nil, completion: @escaping ((_ data: DatasetImagePopResponse?,_ error: Error?) -> Void)) {
        getDefaultDatasetImagePopWithRequestBuilder(apikey: apikey, xFields: xFields).execute { (response, error) -> Void in
            completion(response?.body, error)
        }
    }


    /**
     Retrieve an image to rate from the default dataset
     - GET /v1/rating/new
     - 

     - examples: [{contentType=application/json, example={
  "dataset_id" : "00000000-0000-0000-0000-000000000000",
  "id" : "00000000-0000-0000-0000-000000000000",
  "url" : "https://cdn.droom.cloud/00000000-0000-0000-0000-000000000000.webp"
}}]
     - parameter apikey: (header) The user API key. This is used to prevent retrieving the same image. When not provided, will retrieve as anonymous (optional)
     - parameter xFields: (header) An optional fields mask (optional)

     - returns: RequestBuilder<DatasetImagePopResponse> 
     */
    open class func getDefaultDatasetImagePopWithRequestBuilder(apikey: String? = nil, xFields: String? = nil) -> RatingsRequestBuilder<DatasetImagePopResponse> {
        let path = "/v1/rating/new"
        let URLString = RatingsSwaggerClientAPI.basePath + path
        let parameters: [String:Any]? = nil
        let url = URLComponents(string: URLString)
        let nillableHeaders: [String: Any?] = [
                        "apikey": apikey,
                        "X-Fields": xFields
        ]
        let headerParameters = APIHelper.rejectNilHeaders(nillableHeaders)

        let requestBuilder: RatingsRequestBuilder<DatasetImagePopResponse>.Type = RatingsSwaggerClientAPI.requestBuilderFactory.getBuilder()

        return requestBuilder.init(method: "GET", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false, headers: headerParameters)
    }
    /**
     Download the specified file

     - parameter filename: (path)  
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func getDownloadFile(filename: String, completion: @escaping ((_ data: Void?,_ error: Error?) -> Void)) {
        getDownloadFileWithRequestBuilder(filename: filename).execute { (response, error) -> Void in
            if error == nil {
                completion((), error)
            } else {
                completion(nil, error)
            }
        }
    }


    /**
     Download the specified file
     - GET /v1/download/{filename}
     - 

     - parameter filename: (path)  

     - returns: RequestBuilder<Void> 
     */
    open class func getDownloadFileWithRequestBuilder(filename: String) -> RatingsRequestBuilder<Void> {
        var path = "/v1/download/{filename}"
        let filenamePreEscape = "\(filename)"
        let filenamePostEscape = filenamePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: "{filename}", with: filenamePostEscape, options: .literal, range: nil)
        let URLString = RatingsSwaggerClientAPI.basePath + path
        let parameters: [String:Any]? = nil
        let url = URLComponents(string: URLString)


        let requestBuilder: RatingsRequestBuilder<Void>.Type = RatingsSwaggerClientAPI.requestBuilderFactory.getNonDecodableBuilder()

        return requestBuilder.init(method: "GET", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false)
    }
    /**
     Retrieve an image to rate from one model in the Stable Horde dataset

     - parameter datasetId: (path)  
     - parameter modelName: (path)  
     - parameter apikey: (header) The user API key. This is used to prevent retrieving the same image. When not provided, will retrieve as anonymous (optional)
     - parameter xFields: (header) An optional fields mask (optional)
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func getModelImagePop(datasetId: String, modelName: String, apikey: String? = nil, xFields: String? = nil, completion: @escaping ((_ data: DatasetImagePopResponse?,_ error: Error?) -> Void)) {
        getModelImagePopWithRequestBuilder(datasetId: datasetId, modelName: modelName, apikey: apikey, xFields: xFields).execute { (response, error) -> Void in
            completion(response?.body, error)
        }
    }


    /**
     Retrieve an image to rate from one model in the Stable Horde dataset
     - GET /v1/rating/new/{dataset_id}/{model_name}
     - 

     - examples: [{contentType=application/json, example={
  "dataset_id" : "00000000-0000-0000-0000-000000000000",
  "id" : "00000000-0000-0000-0000-000000000000",
  "url" : "https://cdn.droom.cloud/00000000-0000-0000-0000-000000000000.webp"
}}]
     - parameter datasetId: (path)  
     - parameter modelName: (path)  
     - parameter apikey: (header) The user API key. This is used to prevent retrieving the same image. When not provided, will retrieve as anonymous (optional)
     - parameter xFields: (header) An optional fields mask (optional)

     - returns: RequestBuilder<DatasetImagePopResponse> 
     */
    open class func getModelImagePopWithRequestBuilder(datasetId: String, modelName: String, apikey: String? = nil, xFields: String? = nil) -> RatingsRequestBuilder<DatasetImagePopResponse> {
        var path = "/v1/rating/new/{dataset_id}/{model_name}"
        let datasetIdPreEscape = "\(datasetId)"
        let datasetIdPostEscape = datasetIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: "{dataset_id}", with: datasetIdPostEscape, options: .literal, range: nil)
        let modelNamePreEscape = "\(modelName)"
        let modelNamePostEscape = modelNamePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: "{model_name}", with: modelNamePostEscape, options: .literal, range: nil)
        let URLString = RatingsSwaggerClientAPI.basePath + path
        let parameters: [String:Any]? = nil
        let url = URLComponents(string: URLString)
        let nillableHeaders: [String: Any?] = [
                        "apikey": apikey,
                        "X-Fields": xFields
        ]
        let headerParameters = APIHelper.rejectNilHeaders(nillableHeaders)

        let requestBuilder: RatingsRequestBuilder<DatasetImagePopResponse>.Type = RatingsSwaggerClientAPI.requestBuilderFactory.getBuilder()

        return requestBuilder.init(method: "GET", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false, headers: headerParameters)
    }
    /**

     - parameter apikey: (header) A Moderator API key (optional)
     - parameter rating: (query) Filter by rating (optional)
     - parameter ratingComparison: (query) Type of comparison (optional, default to eq)
     - parameter artifacts: (query) Filter by artifact (optional)
     - parameter artifactsComparison: (query) Type of comparison (optional, default to eq)
     - parameter limit: (query) How many images to retrieve (optional, default to 100)
     - parameter offset: (query) How much to offset (optional, default to 0)
     - parameter diverge: (query) Selecting only ratings which diverge from the average by this much (optional)
     - parameter minRatings: (query) Selecting only images which have at least this amount of ratings (optional, default to 3)
     - parameter clientAgent: (query) Selecting only ratings from this agent (optional)
     - parameter format: (query) Type of return result (optional, default to html)
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func getShowAllRatings(apikey: String? = nil, rating: Int? = nil, ratingComparison: String? = nil, artifacts: Int? = nil, artifactsComparison: String? = nil, limit: Int? = nil, offset: Int? = nil, diverge: Int? = nil, minRatings: Int? = nil, clientAgent: String? = nil, format: String? = nil, completion: @escaping ((_ data: Void?,_ error: Error?) -> Void)) {
        getShowAllRatingsWithRequestBuilder(apikey: apikey, rating: rating, ratingComparison: ratingComparison, artifacts: artifacts, artifactsComparison: artifactsComparison, limit: limit, offset: offset, diverge: diverge, minRatings: minRatings, clientAgent: clientAgent, format: format).execute { (response, error) -> Void in
            if error == nil {
                completion((), error)
            } else {
                completion(nil, error)
            }
        }
    }


    /**
     - GET /v1/user/ratings
     - 

     - parameter apikey: (header) A Moderator API key (optional)
     - parameter rating: (query) Filter by rating (optional)
     - parameter ratingComparison: (query) Type of comparison (optional, default to eq)
     - parameter artifacts: (query) Filter by artifact (optional)
     - parameter artifactsComparison: (query) Type of comparison (optional, default to eq)
     - parameter limit: (query) How many images to retrieve (optional, default to 100)
     - parameter offset: (query) How much to offset (optional, default to 0)
     - parameter diverge: (query) Selecting only ratings which diverge from the average by this much (optional)
     - parameter minRatings: (query) Selecting only images which have at least this amount of ratings (optional, default to 3)
     - parameter clientAgent: (query) Selecting only ratings from this agent (optional)
     - parameter format: (query) Type of return result (optional, default to html)

     - returns: RequestBuilder<Void> 
     */
    open class func getShowAllRatingsWithRequestBuilder(apikey: String? = nil, rating: Int? = nil, ratingComparison: String? = nil, artifacts: Int? = nil, artifactsComparison: String? = nil, limit: Int? = nil, offset: Int? = nil, diverge: Int? = nil, minRatings: Int? = nil, clientAgent: String? = nil, format: String? = nil) -> RatingsRequestBuilder<Void> {
        let path = "/v1/user/ratings"
        let URLString = RatingsSwaggerClientAPI.basePath + path
        let parameters: [String:Any]? = nil
        var url = URLComponents(string: URLString)
        url?.queryItems = APIHelper.mapValuesToQueryItems([
                        "rating": rating?.encodeToJSON(), 
                        "rating_comparison": ratingComparison, 
                        "artifacts": artifacts?.encodeToJSON(), 
                        "artifacts_comparison": artifactsComparison, 
                        "limit": limit?.encodeToJSON(), 
                        "offset": offset?.encodeToJSON(), 
                        "diverge": diverge?.encodeToJSON(), 
                        "min_ratings": minRatings?.encodeToJSON(), 
                        "client_agent": clientAgent, 
                        "format": format
        ])
        let nillableHeaders: [String: Any?] = [
                        "apikey": apikey
        ]
        let headerParameters = APIHelper.rejectNilHeaders(nillableHeaders)

        let requestBuilder: RatingsRequestBuilder<Void>.Type = RatingsSwaggerClientAPI.requestBuilderFactory.getNonDecodableBuilder()

        return requestBuilder.init(method: "GET", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false, headers: headerParameters)
    }
    /**

     - parameter imageId: (path)  
     - parameter apikey: (header) A Moderator API key (optional)
     - parameter format: (query) Type of return result (optional, default to html)
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func getShowImageRatings(imageId: String, apikey: String? = nil, format: String? = nil, completion: @escaping ((_ data: Void?,_ error: Error?) -> Void)) {
        getShowImageRatingsWithRequestBuilder(imageId: imageId, apikey: apikey, format: format).execute { (response, error) -> Void in
            if error == nil {
                completion((), error)
            } else {
                completion(nil, error)
            }
        }
    }


    /**
     - GET /v1/image/ratings/{image_id}
     - 

     - parameter imageId: (path)  
     - parameter apikey: (header) A Moderator API key (optional)
     - parameter format: (query) Type of return result (optional, default to html)

     - returns: RequestBuilder<Void> 
     */
    open class func getShowImageRatingsWithRequestBuilder(imageId: String, apikey: String? = nil, format: String? = nil) -> RatingsRequestBuilder<Void> {
        var path = "/v1/image/ratings/{image_id}"
        let imageIdPreEscape = "\(imageId)"
        let imageIdPostEscape = imageIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: "{image_id}", with: imageIdPostEscape, options: .literal, range: nil)
        let URLString = RatingsSwaggerClientAPI.basePath + path
        let parameters: [String:Any]? = nil
        var url = URLComponents(string: URLString)
        url?.queryItems = APIHelper.mapValuesToQueryItems([
                        "format": format
        ])
        let nillableHeaders: [String: Any?] = [
                        "apikey": apikey
        ]
        let headerParameters = APIHelper.rejectNilHeaders(nillableHeaders)

        let requestBuilder: RatingsRequestBuilder<Void>.Type = RatingsSwaggerClientAPI.requestBuilderFactory.getNonDecodableBuilder()

        return requestBuilder.init(method: "GET", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false, headers: headerParameters)
    }
    /**

     - parameter userId: (path)  
     - parameter apikey: (header) A Moderator API key (optional)
     - parameter rating: (query) Filter by rating (optional)
     - parameter ratingComparison: (query) Type of comparison (optional, default to eq)
     - parameter artifacts: (query) Filter by artifact (optional)
     - parameter artifactsComparison: (query) Type of comparison (optional, default to eq)
     - parameter minRatings: (query) Selecting only images which have at least this amount of ratings (optional, default to 3)
     - parameter format: (query) Type of return result (optional, default to html)
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func getShowUserRatings(userId: String, apikey: String? = nil, rating: Int? = nil, ratingComparison: String? = nil, artifacts: Int? = nil, artifactsComparison: String? = nil, minRatings: Int? = nil, format: String? = nil, completion: @escaping ((_ data: Void?,_ error: Error?) -> Void)) {
        getShowUserRatingsWithRequestBuilder(userId: userId, apikey: apikey, rating: rating, ratingComparison: ratingComparison, artifacts: artifacts, artifactsComparison: artifactsComparison, minRatings: minRatings, format: format).execute { (response, error) -> Void in
            if error == nil {
                completion((), error)
            } else {
                completion(nil, error)
            }
        }
    }


    /**
     - GET /v1/user/validate/{user_id}
     - 

     - parameter userId: (path)  
     - parameter apikey: (header) A Moderator API key (optional)
     - parameter rating: (query) Filter by rating (optional)
     - parameter ratingComparison: (query) Type of comparison (optional, default to eq)
     - parameter artifacts: (query) Filter by artifact (optional)
     - parameter artifactsComparison: (query) Type of comparison (optional, default to eq)
     - parameter minRatings: (query) Selecting only images which have at least this amount of ratings (optional, default to 3)
     - parameter format: (query) Type of return result (optional, default to html)

     - returns: RequestBuilder<Void> 
     */
    open class func getShowUserRatingsWithRequestBuilder(userId: String, apikey: String? = nil, rating: Int? = nil, ratingComparison: String? = nil, artifacts: Int? = nil, artifactsComparison: String? = nil, minRatings: Int? = nil, format: String? = nil) -> RatingsRequestBuilder<Void> {
        var path = "/v1/user/validate/{user_id}"
        let userIdPreEscape = "\(userId)"
        let userIdPostEscape = userIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: "{user_id}", with: userIdPostEscape, options: .literal, range: nil)
        let URLString = RatingsSwaggerClientAPI.basePath + path
        let parameters: [String:Any]? = nil
        var url = URLComponents(string: URLString)
        url?.queryItems = APIHelper.mapValuesToQueryItems([
                        "rating": rating?.encodeToJSON(), 
                        "rating_comparison": ratingComparison, 
                        "artifacts": artifacts?.encodeToJSON(), 
                        "artifacts_comparison": artifactsComparison, 
                        "min_ratings": minRatings?.encodeToJSON(), 
                        "format": format
        ])
        let nillableHeaders: [String: Any?] = [
                        "apikey": apikey
        ]
        let headerParameters = APIHelper.rejectNilHeaders(nillableHeaders)

        let requestBuilder: RatingsRequestBuilder<Void>.Type = RatingsSwaggerClientAPI.requestBuilderFactory.getNonDecodableBuilder()

        return requestBuilder.init(method: "GET", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false, headers: headerParameters)
    }
    /**
     Display all public Teams

     - parameter xFields: (header) An optional fields mask (optional)
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func getTeams(xFields: String? = nil, completion: @escaping ((_ data: [TeamsGetResponse]?,_ error: Error?) -> Void)) {
        getTeamsWithRequestBuilder(xFields: xFields).execute { (response, error) -> Void in
            completion(response?.body, error)
        }
    }


    /**
     Display all public Teams
     - GET /v1/teams
     - 

     - examples: [{contentType=application/json, example=[ {
  "is_private" : false,
  "id" : "00000000-0000-0000-0000-000000000000",
  "team_name" : "My Team"
}, {
  "is_private" : false,
  "id" : "00000000-0000-0000-0000-000000000000",
  "team_name" : "My Team"
} ]}]
     - parameter xFields: (header) An optional fields mask (optional)

     - returns: RequestBuilder<[TeamsGetResponse]> 
     */
    open class func getTeamsWithRequestBuilder(xFields: String? = nil) -> RatingsRequestBuilder<[TeamsGetResponse]> {
        let path = "/v1/teams"
        let URLString = RatingsSwaggerClientAPI.basePath + path
        let parameters: [String:Any]? = nil
        let url = URLComponents(string: URLString)
        let nillableHeaders: [String: Any?] = [
                        "X-Fields": xFields
        ]
        let headerParameters = APIHelper.rejectNilHeaders(nillableHeaders)

        let requestBuilder: RatingsRequestBuilder<[TeamsGetResponse]>.Type = RatingsSwaggerClientAPI.requestBuilderFactory.getBuilder()

        return requestBuilder.init(method: "GET", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false, headers: headerParameters)
    }
    /**

     - parameter userId: (path)  
     - parameter apikey: (header) A Moderator API key (optional)
     - parameter xFields: (header) An optional fields mask (optional)
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func postFlagUser(userId: String, apikey: String? = nil, xFields: String? = nil, completion: @escaping ((_ data: RequestAccepted?,_ error: Error?) -> Void)) {
        postFlagUserWithRequestBuilder(userId: userId, apikey: apikey, xFields: xFields).execute { (response, error) -> Void in
            completion(response?.body, error)
        }
    }


    /**
     - POST /v1/user/flag/{user_id}
     - 

     - examples: [{contentType=application/json, example={
  "message" : "message"
}}]
     - parameter userId: (path)  
     - parameter apikey: (header) A Moderator API key (optional)
     - parameter xFields: (header) An optional fields mask (optional)

     - returns: RequestBuilder<RequestAccepted> 
     */
    open class func postFlagUserWithRequestBuilder(userId: String, apikey: String? = nil, xFields: String? = nil) -> RatingsRequestBuilder<RequestAccepted> {
        var path = "/v1/user/flag/{user_id}"
        let userIdPreEscape = "\(userId)"
        let userIdPostEscape = userIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: "{user_id}", with: userIdPostEscape, options: .literal, range: nil)
        let URLString = RatingsSwaggerClientAPI.basePath + path
        let parameters: [String:Any]? = nil
        let url = URLComponents(string: URLString)
        let nillableHeaders: [String: Any?] = [
                        "apikey": apikey,
                        "X-Fields": xFields
        ]
        let headerParameters = APIHelper.rejectNilHeaders(nillableHeaders)

        let requestBuilder: RatingsRequestBuilder<RequestAccepted>.Type = RatingsSwaggerClientAPI.requestBuilderFactory.getBuilder()

        return requestBuilder.init(method: "POST", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false, headers: headerParameters)
    }
    /**

     - parameter body: (body)  
     - parameter userId: (path)  
     - parameter apikey: (header) A Moderator API key (optional)
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func postModifyUser(body: ModifyUserIdBody, userId: String, apikey: String? = nil, completion: @escaping ((_ data: Void?,_ error: Error?) -> Void)) {
        postModifyUserWithRequestBuilder(body: body, userId: userId, apikey: apikey).execute { (response, error) -> Void in
            if error == nil {
                completion((), error)
            } else {
                completion(nil, error)
            }
        }
    }


    /**
     - POST /v1/user/modify/{user_id}
     - 

     - parameter body: (body)  
     - parameter userId: (path)  
     - parameter apikey: (header) A Moderator API key (optional)

     - returns: RequestBuilder<Void> 
     */
    open class func postModifyUserWithRequestBuilder(body: ModifyUserIdBody, userId: String, apikey: String? = nil) -> RatingsRequestBuilder<Void> {
        var path = "/v1/user/modify/{user_id}"
        let userIdPreEscape = "\(userId)"
        let userIdPostEscape = userIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: "{user_id}", with: userIdPostEscape, options: .literal, range: nil)
        let URLString = RatingsSwaggerClientAPI.basePath + path
        let parameters = JSONEncodingHelper.encodingParameters(forEncodableObject: body)
        let url = URLComponents(string: URLString)
        let nillableHeaders: [String: Any?] = [
                        "apikey": apikey
        ]
        let headerParameters = APIHelper.rejectNilHeaders(nillableHeaders)

        let requestBuilder: RatingsRequestBuilder<Void>.Type = RatingsSwaggerClientAPI.requestBuilderFactory.getNonDecodableBuilder()

        return requestBuilder.init(method: "POST", URLString: (url?.string ?? URLString), parameters: parameters, isBody: true, headers: headerParameters)
    }
    /**
     Aesthetically rate an image

     - parameter body: (body)  
     - parameter apikey: (header) The user API key 
     - parameter imageId: (path)  
     - parameter clientAgent: (header) The client name and version (optional, default to unknown:0:unknown)
     - parameter xFields: (header) An optional fields mask (optional)
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func postRate(body: RatePostInput, apikey: String, imageId: String, clientAgent: String? = nil, xFields: String? = nil, completion: @escaping ((_ data: RatePostResponse?,_ error: Error?) -> Void)) {
        postRateWithRequestBuilder(body: body, apikey: apikey, imageId: imageId, clientAgent: clientAgent, xFields: xFields).execute { (response, error) -> Void in
            completion(response?.body, error)
        }
    }


    /**
     Aesthetically rate an image
     - POST /v1/rating/{image_id}

     - examples: [{contentType=application/json, example={
  "reward" : 5,
  "message" : "Rating submittted"
}}]
     - parameter body: (body)  
     - parameter apikey: (header) The user API key 
     - parameter imageId: (path)  
     - parameter clientAgent: (header) The client name and version (optional, default to unknown:0:unknown)
     - parameter xFields: (header) An optional fields mask (optional)

     - returns: RequestBuilder<RatePostResponse> 
     */
    open class func postRateWithRequestBuilder(body: RatePostInput, apikey: String, imageId: String, clientAgent: String? = nil, xFields: String? = nil) -> RatingsRequestBuilder<RatePostResponse> {
        var path = "/v1/rating/{image_id}"
        let imageIdPreEscape = "\(imageId)"
        let imageIdPostEscape = imageIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: "{image_id}", with: imageIdPostEscape, options: .literal, range: nil)
        let URLString = RatingsSwaggerClientAPI.basePath + path
        let parameters = JSONEncodingHelper.encodingParameters(forEncodableObject: body)
        let url = URLComponents(string: URLString)
        let nillableHeaders: [String: Any?] = [
                        "apikey": apikey,
                        "Client-Agent": clientAgent,
                        "X-Fields": xFields
        ]
        let headerParameters = APIHelper.rejectNilHeaders(nillableHeaders)

        let requestBuilder: RatingsRequestBuilder<RatePostResponse>.Type = RatingsSwaggerClientAPI.requestBuilderFactory.getBuilder()

        return requestBuilder.init(method: "POST", URLString: (url?.string ?? URLString), parameters: parameters, isBody: true, headers: headerParameters)
    }
    /**
     Rate a set of Stable Horde generated images

     - parameter body: (body)  
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func postRateSet(body: RatingSetBody, completion: @escaping ((_ data: Void?,_ error: Error?) -> Void)) {
        postRateSetWithRequestBuilder(body: body).execute { (response, error) -> Void in
            if error == nil {
                completion((), error)
            } else {
                completion(nil, error)
            }
        }
    }


    /**
     Rate a set of Stable Horde generated images
     - POST /v1/rating/set

     - parameter body: (body)  

     - returns: RequestBuilder<Void> 
     */
    open class func postRateSetWithRequestBuilder(body: RatingSetBody) -> RatingsRequestBuilder<Void> {
        let path = "/v1/rating/set"
        let URLString = RatingsSwaggerClientAPI.basePath + path
        let parameters = JSONEncodingHelper.encodingParameters(forEncodableObject: body)
        let url = URLComponents(string: URLString)


        let requestBuilder: RatingsRequestBuilder<Void>.Type = RatingsSwaggerClientAPI.requestBuilderFactory.getNonDecodableBuilder()

        return requestBuilder.init(method: "POST", URLString: (url?.string ?? URLString), parameters: parameters, isBody: true)
    }
    /**
     Upload the specified std csv

     - parameter file: (form)  
     - parameter apikey: (header) The user API key 
     - parameter xFields: (header) An optional fields mask (optional)
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func postUploadStd(file: Data, apikey: String, xFields: String? = nil, completion: @escaping ((_ data: RequestAccepted?,_ error: Error?) -> Void)) {
        postUploadStdWithRequestBuilder(file: file, apikey: apikey, xFields: xFields).execute { (response, error) -> Void in
            completion(response?.body, error)
        }
    }


    /**
     Upload the specified std csv
     - POST /v1/upload/std
     - 

     - examples: [{contentType=application/json, example={
  "message" : "message"
}}]
     - parameter file: (form)  
     - parameter apikey: (header) The user API key 
     - parameter xFields: (header) An optional fields mask (optional)

     - returns: RequestBuilder<RequestAccepted> 
     */
    open class func postUploadStdWithRequestBuilder(file: Data, apikey: String, xFields: String? = nil) -> RatingsRequestBuilder<RequestAccepted> {
        let path = "/v1/upload/std"
        let URLString = RatingsSwaggerClientAPI.basePath + path
        let formParams: [String:Any?] = [
                "file": file
        ]

        let nonNullParameters = APIHelper.rejectNil(formParams)
        let parameters = APIHelper.convertBoolToString(nonNullParameters)
        let url = URLComponents(string: URLString)
        let nillableHeaders: [String: Any?] = [
                        "apikey": apikey,
                        "X-Fields": xFields
        ]
        let headerParameters = APIHelper.rejectNilHeaders(nillableHeaders)

        let requestBuilder: RatingsRequestBuilder<RequestAccepted>.Type = RatingsSwaggerClientAPI.requestBuilderFactory.getBuilder()

        return requestBuilder.init(method: "POST", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false, headers: headerParameters)
    }
}