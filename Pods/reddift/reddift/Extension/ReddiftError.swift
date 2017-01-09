//
//  ReddiftError.swift
//  reddift
//
//  Created by sonson on 2016/07/25.
//  Copyright © 2016年 sonson. All rights reserved.
//

import Foundation

public enum ReddiftError: Int, Error {
    case unknown
    case tokenIsNotAvailable
    case canNotCreateURLRequest
    
    case specifiedNameTokenNotFoundInKeychain
    case tokenNameIsInvalid
    
    case needsCAPTCHAResponseIsInvalid
    case imageOfCAPTCHAIsInvalid
    case identifierOfCAPTCHAIsMalformed
    
    case sr_nameOfRecommendedSubredditKeyNotFound
    case nameAsResultOfSearchSubredditKeyNotFound
    case submit_textxSubredditKeyNotFound
    case jsonObjectIsNotListingThing
    
    case accountJsonObjectIsMalformed
    case accountJsonObjectIsNotDictionary
    
    case tokenJsonObjectIsNotDictionary
    case canNotCreateURLRequestForOAuth2Page
    case canNotAllocateDataToCreateURLForOAuth2
    
    case moreCommentJsonObjectIsNotDictionary
    case canNotGetMoreCommentForAnyReason
    
    case multiredditJsonObjectIsNotDictionary
    case multiredditJsonObjectIsMalformed
    
    case canNotCreateDataObjectForClientIDForBasicAuthentication
    case canNotCreateDataObjectForUserInfoForBasicAuthentication
    
    case dataIsNotUTF8String
    
    case preferenceJsonObjectIsNotDictionary
    
    case failedToParseThingFromJsonObject
    case commentJsonObjectIsMalformed
    
    case failedToParseThingFromRedditAny
    case failedToParseMultiredditArrayFromRedditAny
    case failedToParseListingPairFromRedditAny
    
    case failedToCreateJSONForMultireadditPosting
    
    public var _code: Int {
        return self.rawValue
    }
    
    public var _description: String {
        return "not yet"
    }
    
    public var _domain: String {
        return "com.reddift"
    }
    
    public var errorDomain: String {
        return self._domain
    }
    
    public var errorCode: Int {
        return self._code
    }
    
    public var errorUserInfo: [String : AnyObject] {
        return [:]
    }
}
