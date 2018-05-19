//
//  Session+helper.swift
//  reddift
//
//  Created by sonson on 2015/04/26.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

// MARK: Response -> Data

/**
 Function to eliminate codes to parse http response object.
 This function filters response object to handle errors.
 Returns Result<Error> object when any error happned.
 */
func response2Data(from response: Response) -> Result<Data> {
    #if _TEST
    if let str = String(data: response.data, encoding: .utf8) { print("response body:\n\(str)") }
    #endif
    if !(200..<300 ~= response.statusCode) {
        do {
            let json = try JSONSerialization.jsonObject(with: response.data as Data, options: [])
            if let json = json as? JSONDictionary {
                return .failure(HttpStatusWithBody(response.statusCode, object: json) as NSError)
            }
        } catch { print(error) }
        if let bodyAsString = String(data: response.data as Data, encoding: .utf8) {
            return .failure(HttpStatusWithBody(response.statusCode, object: bodyAsString) as NSError)
        }
        return .failure(HttpStatus(response.statusCode) as NSError)
    }
    return .success(response.data)
}

// MARK: Data -> JSON, String

/**
 Parse binary data to JSON object.
 Returns Result<Error> object when any error happned.
 - parameter data: Binary data is returned from reddit.
 - returns: Result object. Result object has JSON as JSONDictionary or [AnyObject], otherwise error object.
 */
func data2Json(from data: Data) -> Result<JSONAny> {
    do {
        if data.count == 0 { return Result(value:[:]) } else {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return Result(value:json)
        }
    } catch {
        return Result(error: error as NSError)
    }
}

func flair2Choices(from json: JSONAny) -> Result<JSONAny> {
    return Result(value: (json as! JSONDictionary)["choices"])
}

/**
 Parse simple string response.
 Returns Result<Error> object when any error happned.
 Returns vacant JSON object when binary data size is 0.
 - parameter data: Binary data is returned from reddit.
 - returns: Result object. Result object has String, otherwise error object.
 */
func data2String(from data: Data) -> Result<String> {
    if data.count == 0 {
        return Result(value: "")
    }
    if let decoded = String(data:data, encoding:.utf8) {
        return Result(value: decoded)
    }
    return Result(error:ReddiftError.dataIsNotUTF8String as NSError)
}

// MARK: JSON -> RedditAny

/**
 Parse "more" response.
 Returns Result<Error> object when any error happned.
 - parameter json: JSON object is returned from reddit.
 - returns: Result object. Result object has a list of Thing object, otherwise error object.
 */
func json2CommentAndMore(from json: JSONAny) -> Result<[Thing]> {
    let (list, error) = Parser.commentAndMore(from: json)
    if let error = error {
        return Result(error: error)
    }
    return Result(value: list)
}

/**
 Function to extract Account object from JSON object.
 Returns Result<Error> object when any error happned.
 - parameter json: JSON object is returned from reddit.
 - returns: Result object. Result object has Account object, otherwise error object.
 */
func json2Account(from json: JSONAny) -> Result<Account> {
    if let object = json as? JSONDictionary {
        return Result(fromOptional: Account(json:object), error: ReddiftError.accountJsonObjectIsMalformed as NSError)
    }
    return Result(fromOptional: nil, error: ReddiftError.accountJsonObjectIsNotDictionary as NSError)
}

/**
 Function to extract Preference object from JSON object.
 Returns Result<Error> object when any error happned.
 - parameter data: JSON object is returned from reddit.
 - returns: Result object. Result object has Preference object, otherwise error object.
 */
func json2Preference(from json: JSONAny) -> Result<Preference> {
    if let object = json as? JSONDictionary {
        return Result(value: Preference(json: object))
    }
    return Result(fromOptional: nil, error: ReddiftError.preferenceJsonObjectIsNotDictionary as NSError)
}

/**
 Parse Thing, Listing JSON object.
 Returns Result<Error> object when any error happned.
 - parameter data: Binary data is returned from reddit.
 - returns: Result object. Result object has any Thing or Listing object, otherwise error object.
 */
func json2RedditAny(from json: JSONAny) -> Result<RedditAny> {
    let object: Any? = Parser.redditAny(from: json)
    return Result(fromOptional: object, error: ReddiftError.failedToParseThingFromJsonObject as NSError)
}

func json2Flair(from json: JSONAny) -> Result<RedditAny> {
    let object: Any? = Parser.flairAny(from: json)
    return Result(fromOptional: object, error: ReddiftError.failedToParseThingFromJsonObject as NSError)
}


/**
 Parse JSON for response to /api/comment.
 Returns Result<Error> object when any error happned.
 {"json": {"errors": [], "data": { "things": [] }}}
 - parameter json: JSON object, like above sample.
 - returns: Result object. When parsing is succeeded, object contains list which consists of Thing.
 */
func json2Comment(from json: JSONAny) -> Result<Comment> {
    if let json = json as? JSONDictionary, let j = json["json"] as? JSONDictionary, let data = j["data"] as? JSONDictionary, let things = data["things"] as? JSONArray {
        // No error?
        if things.count == 1 {
            for thing in things {
                if let thing = thing as? JSONDictionary {
                    let obj: Any? = Parser.redditAny(from: thing)
                    if let comment = obj as? Comment {
                        return Result(value: comment)
                    }
                }
            }
        }
    } else if let json = json as? JSONDictionary, let j = json["json"] as? JSONDictionary, let errors = j["errors"] as? JSONArray {
        // Error happened.
        for obj in errors {
            if let errorStrings = obj as? [String] {
                print(errorStrings)
                return Result(error: ReddiftError.commentJsonObjectIsMalformed as NSError)
            }
        }
    }
    return Result(error: ReddiftError.commentJsonObjectIsMalformed as NSError)
}

// MARK: RedditAny -> Objects

func redditAny2Object<T>(from redditAny: RedditAny) -> Result<T> {
    if let obj = redditAny as? T {
        return Result(value: obj)
    }
    return Result(error: ReddiftError.failedToParseThingFromRedditAny as NSError)
}

func redditAny2MultiredditArray(from redditAny: RedditAny) -> Result<[Multireddit]> {
    if let array = redditAny as? [Any] {
        return Result(value:array.flatMap({$0 as? Multireddit}))
    }
    return Result(error: ReddiftError.failedToParseMultiredditArrayFromRedditAny as NSError)
}

func redditAny2ListingTuple(from redditAny: RedditAny) -> Result<(Listing, Listing)> {
    if let array = redditAny as? [RedditAny] {
        if array.count == 2 {
            if let listing0 = array[0] as? Listing, let listing1 = array[1] as? Listing {
                return Result(value: (listing0, listing1))
            }
        }
    }
    return Result(error: ReddiftError.failedToParseListingPairFromRedditAny as NSError)
}

// MARK: Convert from data and response
public func accountInResult(from data: Data?, response: URLResponse?, error: NSError? = nil) -> Result<Account> {
    return Result(from: Response(data: data, urlResponse: response), optional:nil)
        .flatMap(response2Data)
        .flatMap(data2Json)
        .flatMap(json2Account)
}
