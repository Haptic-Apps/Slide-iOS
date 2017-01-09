//
//  HttpStatus.swift
//  reddift
//
//  Created by HttpStatusGenerator.rb
//  Generated from wikipedia http://en.wikipedia.org/wiki/List_of_HTTP_status_codes
//
//  https://gist.github.com/sonsongithub/2fc372c869abfdb2719b
//

import Foundation

public enum HttpStatus: Int, Error {
    case `continue`                         = 100
    case switchingProtocols                 = 101
    case processing                         = 102
    case ok                                 = 200
    case created                            = 201
    case accepted                           = 202
    case nonAuthoritativeInformation        = 203
    case noContent                          = 204
    case resetContent                       = 205
    case partialContent                     = 206
    case multiStatus                        = 207
    case alreadyReported                    = 208
    case imUsed                             = 226
    case multipleChoices                    = 300
    case notModified                        = 304
    case useProxy                           = 305
    case switchProxy                        = 306
    case temporaryRedirect                  = 307
    case permanentRedirect                  = 308
    case badRequest                         = 400
    case unauthorized                       = 401
    case paymentRequired                    = 402
    case forbidden                          = 403
    case notFound                           = 404
    case methodNotAllowed                   = 405
    case notAcceptable                      = 406
    case proxyAuthenticationRequired        = 407
    case requestTimeout                     = 408
    case conflict                           = 409
    case gone                               = 410
    case lengthRequired                     = 411
    case preconditionFailed                 = 412
    case requestEntityTooLarge              = 413
    case requestURITooLong                  = 414
    case unsupportedMediaType               = 415
    case requestedRangeNotSatisfiable       = 416
    case expectationFailed                  = 417
    case imaTeapot                          = 418
    case authenticationTimeout              = 419
    case methodFailure                      = 420
    case misdirectedRequest                 = 421
    case unprocessableEntity                = 422
    case locked                             = 423
    case failedDependency                   = 424
    case upgradeRequired                    = 426
    case preconditionRequired               = 428
    case tooManyRequests                    = 429
    case requestHeaderFieldsTooLarge        = 431
    case loginTimeout                       = 440
    case noResponse                         = 444
    case retryWith                          = 449
    case blockedByWindowsParentalControls   = 450
    case requestHeaderTooLarge              = 494
    case certError                          = 495
    case noCert                             = 496
    case httpToHTTPS                        = 497
    case tokenExpiredinvalid                = 498
    case clientClosedRequest                = 499
    case internalServerError                = 500
    case notImplemented                     = 501
    case badGateway                         = 502
    case serviceUnavailable                 = 503
    case gatewayTimeout                     = 504
    case httpVersionNotSupported            = 505
    case variantAlsoNegotiates              = 506
    case insufficientStorage                = 507
    case loopDetected                       = 508
    case bandwidthLimitExceeded             = 509
    case notExtended                        = 510
    case networkAuthenticationRequired      = 511
    case networkReadTimeoutError            = 598
    case networkConnectTimeoutError         = 599
    case unknown                            = -1
    
    init(_ statusCode: Int) {
        self = HttpStatus(rawValue:statusCode) ?? .unknown
    }
    
    public var _code: Int {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .continue:
            return "Continue"
        case .switchingProtocols:
            return "Switching Protocols"
        case .processing:
            return "Processing"
        case .ok:
            return "OK"
        case .created:
            return "Created"
        case .accepted:
            return "Accepted"
        case .nonAuthoritativeInformation:
            return "Non-Authoritative Information"
        case .noContent:
            return "No Content"
        case .resetContent:
            return "Reset Content"
        case .partialContent:
            return "Partial Content"
        case .multiStatus:
            return "Multi-Status"
        case .alreadyReported:
            return "Already Reported"
        case .imUsed:
            return "IM Used"
        case .multipleChoices:
            return "Multiple Choices"
        case .notModified:
            return "Not Modified"
        case .useProxy:
            return "Use Proxy"
        case .switchProxy:
            return "Switch Proxy"
        case .temporaryRedirect:
            return "Temporary Redirect"
        case .permanentRedirect:
            return "Permanent Redirect"
        case .badRequest:
            return "Bad Request"
        case .unauthorized:
            return "Unauthorized"
        case .paymentRequired:
            return "Payment Required"
        case .forbidden:
            return "Forbidden"
        case .notFound:
            return "NotFound"
        case .methodNotAllowed:
            return "Method Not Allowed"
        case .notAcceptable:
            return "Not Acceptable"
        case .proxyAuthenticationRequired:
            return "Proxy Authentication Required"
        case .requestTimeout:
            return "Request Timeout"
        case .conflict:
            return "Conflict"
        case .gone:
            return "Gone"
        case .lengthRequired:
            return "Length Required"
        case .preconditionFailed:
            return "Precondition Failed"
        case .requestEntityTooLarge:
            return "Request Entity Too Large"
        case .requestURITooLong:
            return "Request-URI Too Long"
        case .unsupportedMediaType:
            return "Unsupported Media Type"
        case .requestedRangeNotSatisfiable:
            return "Requested Range Not Satisfiable"
        case .expectationFailed:
            return "Expectation Failed"
        case .imaTeapot:
            return "I'm a teapot"
        case .authenticationTimeout:
            return "Authentication Timeout"
        case .methodFailure:
            return "Method Failure"
        case .misdirectedRequest:
            return "Misdirected Request"
        case .unprocessableEntity:
            return "Unprocessable Entity"
        case .locked:
            return "Locked"
        case .failedDependency:
            return "Failed Dependency"
        case .upgradeRequired:
            return "Upgrade Required"
        case .preconditionRequired:
            return "Precondition Required"
        case .tooManyRequests:
            return "Too Many Requests"
        case .requestHeaderFieldsTooLarge:
            return "Request Header Fields Too Large"
        case .loginTimeout:
            return "Login Timeout"
        case .noResponse:
            return "No Response"
        case .retryWith:
            return "Retry With"
        case .blockedByWindowsParentalControls:
            return "Blocked by Windows Parental Controls"
        case .requestHeaderTooLarge:
            return "Request Header Too Large"
        case .certError:
            return "Cert Error"
        case .noCert:
            return "No Cert"
        case .httpToHTTPS:
            return "HTTP to HTTPS"
        case .tokenExpiredinvalid:
            return "Token expired/invalid"
        case .clientClosedRequest:
            return "Client Closed Request"
        case .internalServerError:
            return "Internal Server Error"
        case .notImplemented:
            return "Not Implemented"
        case .badGateway:
            return "Bad Gateway"
        case .serviceUnavailable:
            return "Service Unavailable"
        case .gatewayTimeout:
            return "Gateway Timeout"
        case .httpVersionNotSupported:
            return "HTTP Version Not Supported"
        case .variantAlsoNegotiates:
            return "Variant Also Negotiates"
        case .insufficientStorage:
            return "Insufficient Storage"
        case .loopDetected:
            return "Loop Detected"
        case .bandwidthLimitExceeded:
            return "Bandwidth Limit Exceeded"
        case .notExtended:
            return "Not Extended"
        case .networkAuthenticationRequired:
            return "Network Authentication Required"
        case .networkReadTimeoutError:
            return "Network read timeout error"
        case .networkConnectTimeoutError:
            return "Network connect timeout error"
        default:
            return "HTTP Error - Unknown"
        }
    }
}
