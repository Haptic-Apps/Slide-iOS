//
//  NSURLComponents+reddift.swift
//  reddift
//
//  Created by sonson on 2015/05/06.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

extension URLComponents {
    var dictionary: [String:String] {
        var parameters: [String:String] = [:]
        if #available(macOS 10.10, *) {
            if let queryItems = self.queryItems {
                for queryItem in queryItems {
                    #if os(iOS)
                        parameters[queryItem.name] = queryItem.value
                    #elseif os(macOS)
                        if let value = queryItem.value {
                            parameters[queryItem.name] = value
                        }
                    #endif
                }
            }
        } else {
            // Fallback on earlier versions
        }
        return parameters
    }
}
