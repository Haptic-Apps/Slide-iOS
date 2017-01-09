//
//  Result.swift
//  reddift
//
//  Created by sonson on 2015/05/06.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

public enum Result<A> {
    case success(A)
    case failure(NSError)
    
    public init(value: A) {
        self = .success(value)
    }
    
    public init(fromOptional: A?, error: NSError) {
        if let value = fromOptional {
            self = .success(value)
        } else {
            self = .failure(error)
        }
    }
    
    public init(from: A, optional error: NSError?) {
        if let error = error {
            self = .failure(error)
        } else {
            self = .success(from )
        }
    }
    
    public init(error: NSError?) {
        if let error = error {
            self = .failure(error)
        } else {
            self = .failure(ReddiftError.unknown as NSError)
        }
    }
    
    func package<B>(ifSuccess: (A) -> B, ifFailure: (NSError) -> B) -> B {
        switch self {
        case .success(let value):
            return ifSuccess(value)
        case .failure(let value):
            return ifFailure(value)
        }
    }
    
    func map<B>(_ transform: (A) -> B) -> Result<B> {
        return flatMap { .success(transform($0)) }
    }
    
    public func flatMap<B>(_ transform: (A) -> Result<B>) -> Result<B> {
        return package(
            ifSuccess: transform,
            ifFailure: Result<B>.failure)
    }
    
    public var error: NSError? {
        switch self {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }
    
    public var value: A? {
        switch self {
        case .success(let success):
            return success
        default:
            return nil
        }
    }
}
