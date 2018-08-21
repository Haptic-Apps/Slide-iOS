//
//  MediaVCDelegate.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/28/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import MaterialComponents.MaterialProgressView
import reddift
import SafariServices
import SDWebImage
import UIKit

protocol MediaVCDelegate: UIViewControllerTransitioningDelegate {

    var subChanged: Bool { get set }
    var link: RSubmission! { get set }
    var commentCallback: (() -> Void)? { get set }

    func setLink(lnk: RSubmission, shownURL: URL?, lq: Bool, saveHistory: Bool, heroView: UIView?, heroVC: UIViewController?)

    func getControllerForUrl(baseUrl: URL, lq: URL?) -> UIViewController?
    var contentUrl: URL? { get set }

    func shouldTruncate(url: URL) -> Bool

    func showSpoiler(_ string: String)

    static func handleCloseNav(controller: UIButtonWithContext)

    func doShow(url: URL, lq: URL?, heroView: UIView?, heroVC: UIViewController?)
    var color: UIColor? { get set }
    func setBarColors(color: UIColor)
    func setNavColors()
}

extension MediaVCDelegate {
    func getControllerForUrl(baseUrl: URL) -> UIViewController? {
        return getControllerForUrl(baseUrl: baseUrl, lq: nil)
    }

    func doShow(url: URL, heroView: UIView?, heroVC: UIViewController?) {
        doShow(url: url, lq: nil, heroView: heroView, heroVC: heroVC)
    }
}

class SmallerPresentationController: UIPresentationController {
    
    override var frameOfPresentedViewInContainerView: CGRect {
        return self.presentingViewController.view.bounds.insetBy(dx: 24, dy: 48)
    }
}

extension URL {

    var queryDictionary: [String: String] {
        var queryDictionary = [String: String]()
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else {
            return queryDictionary
        }
        queryItems.forEach {
            queryDictionary[$0.name] = $0.value
        }
        return queryDictionary
    }

}
