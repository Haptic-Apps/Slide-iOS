//
//  SubSidebarViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import SDWebImage
import SideMenu
import MaterialComponents.MaterialSnackbar

class SubSidebarViewController: MediaViewController, UIGestureRecognizerDelegate {
    weak var scrollView: UIScrollView!
    var subreddit: Subreddit?
    var filteredContent: [String] = []
    var parentController: MediaViewController?

    init(sub: Subreddit, parent: MediaViewController) {
        super.init(nibName: nil, bundle: nil)
        self.subreddit = sub
        self.parentController = parent
    }

    func doSubreddit(sub: Subreddit, _ width: CGFloat) {
        header.setSubreddit(subreddit: sub, parent: self, width)

        header.frame.size.height = header.getEstHeight()
        header.frame.size.width = width
        scrollView.contentSize = header.frame.size
        scrollView.addSubview(header)

        header.isUserInteractionEnabled  = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        navigationController?.navigationBar.isTranslucent = false
        title = subreddit!.displayName
        color = ColorUtil.getColorForSub(sub: subreddit!.displayName)

        setNavColors()

        self.view = UIScrollView(frame: CGRect.zero)
        self.scrollView = self.view as! UIScrollView

        scrollView.backgroundColor = ColorUtil.backgroundColor
    }

    func close(_ sender: AnyObject){
        self.dismiss(animated: true)
    }

    var header: SubredditHeaderView = SubredditHeaderView()

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    var loaded = false

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if(!loaded) {
            loaded = true
            self.doSubreddit(sub: subreddit!, scrollView.frame.size.width)
        }
    }

}
