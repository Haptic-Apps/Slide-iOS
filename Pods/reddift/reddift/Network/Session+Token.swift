//
//  Session+Token.swift
//  reddift
//
//  Created by sonson on 2015/09/21.
//  Copyright © 2015年 sonson. All rights reserved.
//

import Foundation

func refreshTokenWithJSON(_ result: Result<JSONDictionary>, token: OAuth2Token) -> Result<OAuth2Token> {
    switch result {
    case .success(let json):
        var newJSON = json
        newJSON["name"] = token.name as AnyObject
        newJSON["refresh_token"] = token.refreshToken as AnyObject
        return OAuth2Token.tokenWithJSON(newJSON)
    case .failure(let error):
        return Result(error: error)
    }
}

extension Session {
    /**
    Refresh own token.
    
    - parameter completion: The completion handler to call when the load request is complete.
    */
    public func refreshToken(_ completion: @escaping (Result<Token>) -> Void) throws -> Void {
        guard let currentToken = token as? OAuth2Token
            else { throw ReddiftError.tokenIsNotAvailable as NSError }
        do {
            try currentToken.refresh({ (result) -> Void in
                switch result {
                case .failure(let error):
                    completion(Result(error:error as NSError))
                case .success(let newToken):
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.token = newToken
                        do {
                            try OAuth2TokenRepository.save(token: newToken)
                            completion(Result(value: newToken))
                        } catch { completion(Result(error:error as NSError)) }
                    })
                }
            })
        } catch { throw error }
    }
    
    /**
    Revoke own token. After calling this function, this object must be released becuase it has lost any conection.
    
    - parameter completion: The completion handler to call when the load request is complete.
    */
    public func revokeToken(_ completion: @escaping (Result<Token>) -> Void) throws -> Void {
        guard let currentToken = token as? OAuth2Token
            else { throw ReddiftError.tokenIsNotAvailable as NSError }
        do {
            try currentToken.revoke({ (result) -> Void in
                switch result {
                case .failure(let error):
                    completion(Result(error:error as NSError))
                case .success:
                    DispatchQueue.main.async(execute: { () -> Void in
                        do {
                            try OAuth2TokenRepository.removeToken(of: currentToken.name)
                            completion(Result(value: currentToken))
                        } catch { completion(Result(error:error as NSError)) }
                    })
                }
            })
        } catch { throw error }
    }
    
    /**
     Set an expired token to self.
     This method is implemented in order to test codes to automatiaclly refresh an expired token.
    */
    public func setDummyExpiredToken() {
        if let path = Bundle.main.path(forResource: "expired_token.json", ofType: nil), let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] {
                    let token = OAuth2Token(json)
                    self.token = token
                }
            } catch { print(error) }
        }
    }
}
