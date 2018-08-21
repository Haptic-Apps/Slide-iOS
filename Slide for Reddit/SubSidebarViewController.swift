//
//  SubSidebarViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import Anchorage
import reddift
import SDWebImage
import SideMenu
import UIKit

class SubSidebarViewController: MediaViewController, UIGestureRecognizerDelegate {
    var scrollView = UIScrollView()
    var subreddit: Subreddit?
    var filteredContent: [String] = []
    var parentController: (UIViewController & MediaVCDelegate)?

    init(sub: Subreddit, parent: UIViewController & MediaVCDelegate) {
        super.init(nibName: nil, bundle: nil)
        self.subreddit = sub
        self.parentController = parent

    }

    func doSubreddit(sub: Subreddit, _ width: CGFloat) {
        header.setSubreddit(subreddit: sub, parent: self, width)
        var widthF = UIScreen.main.bounds.width * (UIDevice.current.userInterfaceIdiom == .pad ? 0.75 : 0.95)
        if widthF < 250 {
            widthF = UIScreen.main.bounds.width * 0.95
        }

        header.frame.size.height = header.getEstHeight()
        header.frame.size.width = widthF
        scrollView.contentSize = header.frame.size
        scrollView.addSubview(header)
        header.leftAnchor == scrollView.leftAnchor
        header.topAnchor == scrollView.topAnchor
        scrollView.layer.cornerRadius = 15
        scrollView.clipsToBounds = true
        scrollView.bounces = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)

        header.isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func close(_ sender: AnyObject) {
        self.dismiss(animated: true)
    }

    var header: SubredditHeaderView = SubredditHeaderView()

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.frame = CGRect.zero
        
        self.view.addSubview(scrollView)
        scrollView.edgeAnchors == self.view.edgeAnchors
        title = subreddit!.displayName
        color = ColorUtil.getColorForSub(sub: subreddit!.displayName)
        
        setNavColors()
        
        scrollView.backgroundColor = ColorUtil.backgroundColor
        
        self.doSubreddit(sub: subreddit!, UIScreen.main.bounds.width)
    }

    var loaded = false

}
