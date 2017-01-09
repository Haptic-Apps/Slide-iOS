//
//  Response.swift
//  reddift
//
//  Created by sonson on 2015/06/26.
//  Copyright © 2015年 sonson. All rights reserved.
//

import Foundation

/**
Object to eliminate codes to parse http response object.
*/
struct Response {
    let data: Data
    let statusCode: Int
    
    init(data: Data?, urlResponse: URLResponse?) {
        if let data = data {
            self.data = data
        } else {
            self.data = Data()
        }
        if let httpResponse = urlResponse as? HTTPURLResponse {
            statusCode = httpResponse.statusCode
        } else {
            statusCode = 500
        }
    }
}
