//
//  BackgroundFetch.swift
//  reddift
//
//  Created by sonson on 2016/06/03.
//  Copyright © 2016年 sonson. All rights reserved.
//

#if os(iOS)

import UIKit
import Foundation

/// Session class to communicate with reddit.com using OAuth.
public class BackgroundFetch: NSObject, URLSessionDownloadDelegate {
    let session: Session
    var taskURLSession: URLSession? = nil
    var tokenURLSession: URLSession? = nil
    var firstTry = true
    let taskHandler: ((_ response: HTTPURLResponse?, _ dataURL: URL?, _ error: NSError?) -> Void)
    var request: URLRequest
    
    public init(current currentSession: Session, request aRequest: URLRequest, taskHandler aTaskHandler: @escaping (_ response: HTTPURLResponse?, _ dataURL: URL?, _ error: NSError?) -> Void) {
        session = currentSession
        taskHandler = aTaskHandler
        request = aRequest
        super.init()
        taskURLSession = URLSession(configuration: URLSessionConfiguration.background(withIdentifier: "profileMSG"), delegate: self, delegateQueue: nil)
        tokenURLSession = URLSession(configuration: URLSessionConfiguration.background(withIdentifier: "tokenMSG"), delegate: self, delegateQueue: nil)
    }
    
    deinit {
        taskURLSession?.finishTasksAndInvalidate()
        tokenURLSession?.finishTasksAndInvalidate()
    }
    
    public func resume() {
        guard let taskURLSession = self.taskURLSession else { return }
        taskURLSession.downloadTask(with: request).resume()
    }
    
    func handleTask(with response: HTTPURLResponse, didFinishDownloadingToURL: URL, requestForRefreshToken: URLRequest) {
        if response.statusCode == HttpStatus.unauthorized.rawValue {
            if firstTry {
                if let tokenURLSession = self.tokenURLSession {
                    firstTry = false
                    tokenURLSession.downloadTask(with: requestForRefreshToken).resume()
                }
            } else {
                taskHandler(nil, nil, HttpStatus(response.statusCode) as NSError)
            }
        } else {
            taskHandler(response, didFinishDownloadingToURL, nil)
        }
    }
    
    func handleTokenRefresh(with response: HTTPURLResponse, didFinishDownloadingToURL: URL, token: OAuth2Token) {
        if response.statusCode == HttpStatus.ok.rawValue {
            let data = try? Data(contentsOf: didFinishDownloadingToURL)
            let result: Result<JSONDictionary> = Result(from: Response(data: data, urlResponse: response), optional:nil)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(redditAny2Object)
            let result2 = refreshTokenWithJSON(result, token: token)
            switch result2 {
            case .success(let token):
                session.token = token
                request.setOAuth2Token(token)
                resume()
            case .failure(let error):
                taskHandler(nil, nil, error)
            }
        } else {
            taskHandler(nil, nil, HttpStatus(response.statusCode) as NSError)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let response = downloadTask.response as? HTTPURLResponse
            else { return }
        guard let token = self.session.token as? OAuth2Token
            else { return }
        guard let requestForRefreshToken = token.requestForRefreshing()
            else { return }
        
        if session == tokenURLSession {
            handleTokenRefresh(with: response, didFinishDownloadingToURL: location, token: token)
        } else if session == taskURLSession {
            handleTask(with: response, didFinishDownloadingToURL: location, requestForRefreshToken: requestForRefreshToken)
        } else {
            taskHandler(nil, nil, ReddiftError.unknown as NSError)
        }
    }
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        taskHandler(nil, nil, error as NSError?)
    }
}

#endif
