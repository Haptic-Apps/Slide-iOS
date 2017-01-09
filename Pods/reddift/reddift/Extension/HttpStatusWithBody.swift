//
//  HttpStatusWithBody.swift
//  reddift
//
//  Created by sonson on 2016/07/25.
//  Copyright © 2016年 sonson. All rights reserved.
//

import Foundation

public enum HttpStatusWithBody<T>: Error {
    case `continue`(T)
    case switchingProtocols(T)
    case processing(T)
    case ok(T)
    case created(T)
    case accepted(T)
    case nonAuthoritativeInformation(T)
    case noContent(T)
    case resetContent(T)
    case partialContent(T)
    case multiStatus(T)
    case alreadyReported(T)
    case imUsed(T)
    case multipleChoices(T)
    case notModified(T)
    case useProxy(T)
    case switchProxy(T)
    case temporaryRedirect(T)
    case permanentRedirect(T)
    case badRequest(T)
    case unauthorized(T)
    case paymentRequired(T)
    case forbidden(T)
    case notFound(T)
    case methodNotAllowed(T)
    case notAcceptable(T)
    case proxyAuthenticationRequired(T)
    case requestTimeout(T)
    case conflict(T)
    case gone(T)
    case lengthRequired(T)
    case preconditionFailed(T)
    case requestEntityTooLarge(T)
    case requestURITooLong(T)
    case unsupportedMediaType(T)
    case requestedRangeNotSatisfiable(T)
    case expectationFailed(T)
    case imaTeapot(T)
    case authenticationTimeout(T)
    case methodFailure(T)
    case misdirectedRequest(T)
    case unprocessableEntity(T)
    case locked(T)
    case failedDependency(T)
    case upgradeRequired(T)
    case preconditionRequired(T)
    case tooManyRequests(T)
    case requestHeaderFieldsTooLarge(T)
    case loginTimeout(T)
    case noResponse(T)
    case retryWith(T)
    case blockedByWindowsParentalControls(T)
    case requestHeaderTooLarge(T)
    case certError(T)
    case noCert(T)
    case httpToHTTPS(T)
    case tokenExpiredinvalid(T)
    case clientClosedRequest(T)
    case internalServerError(T)
    case notImplemented(T)
    case badGateway(T)
    case serviceUnavailable(T)
    case gatewayTimeout(T)
    case httpVersionNotSupported(T)
    case variantAlsoNegotiates(T)
    case insufficientStorage(T)
    case loopDetected(T)
    case bandwidthLimitExceeded(T)
    case notExtended(T)
    case networkAuthenticationRequired(T)
    case networkReadTimeoutError(T)
    case networkConnectTimeoutError(T)
    case unknown(T)
    
    init(_ statusCode: Int, object: T) {
        switch statusCode {
        case 100:
            self = .continue(object)
        case 101:
            self = .switchingProtocols(object)
        case 102:
            self = .processing(object)
        case 200:
            self = .ok(object)
        case 201:
            self = .created(object)
        case 202:
            self = .accepted(object)
        case 203:
            self = .nonAuthoritativeInformation(object)
        case 204:
            self = .noContent(object)
        case 205:
            self = .resetContent(object)
        case 206:
            self = .partialContent(object)
        case 207:
            self = .multiStatus(object)
        case 208:
            self = .alreadyReported(object)
        case 226:
            self = .imUsed(object)
        case 300:
            self = .multipleChoices(object)
        case 304:
            self = .notModified(object)
        case 305:
            self = .useProxy(object)
        case 306:
            self = .switchProxy(object)
        case 307:
            self = .temporaryRedirect(object)
        case 308:
            self = .permanentRedirect(object)
        case 400:
            self = .badRequest(object)
        case 401:
            self = .unauthorized(object)
        case 402:
            self = .paymentRequired(object)
        case 403:
            self = .forbidden(object)
        case 404:
            self = .notFound(object)
        case 405:
            self = .methodNotAllowed(object)
        case 406:
            self = .notAcceptable(object)
        case 407:
            self = .proxyAuthenticationRequired(object)
        case 408:
            self = .requestTimeout(object)
        case 409:
            self = .conflict(object)
        case 410:
            self = .gone(object)
        case 411:
            self = .lengthRequired(object)
        case 412:
            self = .preconditionFailed(object)
        case 413:
            self = .requestEntityTooLarge(object)
        case 414:
            self = .requestURITooLong(object)
        case 415:
            self = .unsupportedMediaType(object)
        case 416:
            self = .requestedRangeNotSatisfiable(object)
        case 417:
            self = .expectationFailed(object)
        case 418:
            self = .imaTeapot(object)
        case 419:
            self = .authenticationTimeout(object)
        case 420:
            self = .methodFailure(object)
        case 421:
            self = .misdirectedRequest(object)
        case 422:
            self = .unprocessableEntity(object)
        case 423:
            self = .locked(object)
        case 424:
            self = .failedDependency(object)
        case 426:
            self = .upgradeRequired(object)
        case 428:
            self = .preconditionRequired(object)
        case 429:
            self = .tooManyRequests(object)
        case 431:
            self = .requestHeaderFieldsTooLarge(object)
        case 440:
            self = .loginTimeout(object)
        case 444:
            self = .noResponse(object)
        case 449:
            self = .retryWith(object)
        case 450:
            self = .blockedByWindowsParentalControls(object)
        case 494:
            self = .requestHeaderTooLarge(object)
        case 495:
            self = .certError(object)
        case 496:
            self = .noCert(object)
        case 497:
            self = .httpToHTTPS(object)
        case 498:
            self = .tokenExpiredinvalid(object)
        case 499:
            self = .clientClosedRequest(object)
        case 500:
            self = .internalServerError(object)
        case 501:
            self = .notImplemented(object)
        case 502:
            self = .badGateway(object)
        case 503:
            self = .serviceUnavailable(object)
        case 504:
            self = .gatewayTimeout(object)
        case 505:
            self = .httpVersionNotSupported(object)
        case 506:
            self = .variantAlsoNegotiates(object)
        case 507:
            self = .insufficientStorage(object)
        case 508:
            self = .loopDetected(object)
        case 509:
            self = .bandwidthLimitExceeded(object)
        case 510:
            self = .notExtended(object)
        case 511:
            self = .networkAuthenticationRequired(object)
        case 598:
            self = .networkReadTimeoutError(object)
        case 599:
            self = .networkConnectTimeoutError(object)
        default:
            self = .unknown(object)
        }
    }
    
    public var _code: Int {
        return self.errorCode
    }
    
    public var errorCode: Int {
        switch self {
        case .continue:
            return 100
        case .switchingProtocols:
            return 101
        case .processing:
            return 102
        case .ok:
            return 200
        case .created:
            return 201
        case .accepted:
            return 202
        case .nonAuthoritativeInformation:
            return 203
        case .noContent:
            return 204
        case .resetContent:
            return 205
        case .partialContent:
            return 206
        case .multiStatus:
            return 207
        case .alreadyReported:
            return 208
        case .imUsed:
            return 226
        case .multipleChoices:
            return 300
        case .notModified:
            return 304
        case .useProxy:
            return 305
        case .switchProxy:
            return 306
        case .temporaryRedirect:
            return 307
        case .permanentRedirect:
            return 308
        case .badRequest:
            return 400
        case .unauthorized:
            return 401
        case .paymentRequired:
            return 402
        case .forbidden:
            return 403
        case .notFound:
            return 404
        case .methodNotAllowed:
            return 405
        case .notAcceptable:
            return 406
        case .proxyAuthenticationRequired:
            return 407
        case .requestTimeout:
            return 408
        case .conflict:
            return 409
        case .gone:
            return 410
        case .lengthRequired:
            return 411
        case .preconditionFailed:
            return 412
        case .requestEntityTooLarge:
            return 413
        case .requestURITooLong:
            return 414
        case .unsupportedMediaType:
            return 415
        case .requestedRangeNotSatisfiable:
            return 416
        case .expectationFailed:
            return 417
        case .imaTeapot:
            return 418
        case .authenticationTimeout:
            return 419
        case .methodFailure:
            return 420
        case .misdirectedRequest:
            return 421
        case .unprocessableEntity:
            return 422
        case .locked:
            return 423
        case .failedDependency:
            return 424
        case .upgradeRequired:
            return 426
        case .preconditionRequired:
            return 428
        case .tooManyRequests:
            return 429
        case .requestHeaderFieldsTooLarge:
            return 431
        case .loginTimeout:
            return 440
        case .noResponse:
            return 444
        case .retryWith:
            return 449
        case .blockedByWindowsParentalControls:
            return 450
        case .requestHeaderTooLarge:
            return 494
        case .certError:
            return 495
        case .noCert:
            return 496
        case .httpToHTTPS:
            return 497
        case .tokenExpiredinvalid:
            return 498
        case .clientClosedRequest:
            return 499
        case .internalServerError:
            return 500
        case .notImplemented:
            return 501
        case .badGateway:
            return 502
        case .serviceUnavailable:
            return 503
        case .gatewayTimeout:
            return 504
        case .httpVersionNotSupported:
            return 505
        case .variantAlsoNegotiates:
            return 506
        case .insufficientStorage:
            return 507
        case .loopDetected:
            return 508
        case .bandwidthLimitExceeded:
            return 509
        case .notExtended:
            return 510
        case .networkAuthenticationRequired:
            return 511
        case .networkReadTimeoutError:
            return 598
        case .networkConnectTimeoutError:
            return 599
        case .unknown:
            return -1
        }
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
