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
import UIKit

class SubSidebarViewController: MediaViewController, UIGestureRecognizerDelegate {
    var scrollView = UIScrollView()
    var subreddit: Subreddit?
    var filteredContent: [String] = []
    var subname: String

    init(sub: Subreddit) {
        self.subname = sub.displayName
        super.init(nibName: nil, bundle: nil)
        self.subreddit = sub
    }
    
    init(subname: String) {
        self.subname = subname
        super.init(nibName: nil, bundle: nil)
    }
    
    var doneOnce = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subbed.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: subbed)
        setupBaseBarColors(ColorUtil.getColorForSub(sub: (subreddit?.displayName)!))
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.setToolbarHidden(true, animated: true)
        if self.subreddit == nil {
             do {
                 try (UIApplication.shared.delegate as! AppDelegate).session?.about(subname, completion: { (result) in
                    switch result {
                    case .success(let r):
                        self.subreddit = r
                        DispatchQueue.main.async {
                            self.doSubStuff()
                        }
                    default:
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Subreddit sidebar not found", seconds: 3, context: self.parent)
                        }
                    }
                })
            } catch {
            }
        }
    }

    func doSubreddit(sub: Subreddit, _ width: CGFloat) {
        header.setSubreddit(subreddit: sub, parent: self, width)
        header.frame.size.height = header.getEstHeight()
        header.frame.size.width = self.view.frame.size.width
        scrollView.contentSize = header.frame.size
        scrollView.addSubview(header)
        header.leftAnchor == scrollView.leftAnchor
        header.topAnchor == scrollView.topAnchor
        scrollView.clipsToBounds = true
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)

        header.isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func close(_ sender: AnyObject) {
        self.dismiss(animated: true)
    }
    
    var subbed = UISwitch()
    var header: SubredditHeaderView = SubredditHeaderView()

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.frame = CGRect.zero
        self.setBarColors(color: ColorUtil.getColorForSub(sub: subreddit!.displayName))
        doSubStuff()
    }
    
    func doSubStuff() {
        if self.subreddit != nil {
            doneOnce = true
            subbed.isOn = Subscriptions.isSubscriber(subreddit!.displayName)
            subbed.onTintColor = ColorUtil.accentColorForSub(sub: subreddit!.displayName)
            subbed.addTarget(self, action: #selector(doSub(_:)), for: .valueChanged)

            self.view.addSubview(scrollView)
            scrollView.edgeAnchors == self.view.edgeAnchors
            title = subreddit!.displayName
            self.setupBaseBarColors()
            color = ColorUtil.getColorForSub(sub: subreddit!.displayName)
            
            setNavColors()
            
            scrollView.backgroundColor = ColorUtil.theme.backgroundColor
            scrollView.isUserInteractionEnabled = true
            
            self.doSubreddit(sub: subreddit!, UIScreen.main.bounds.width)
        }
    }

    @objc func doSub(_ changed: UISwitch) {
        if !changed.isOn {
            Subscriptions.unsubscribe(subreddit!.displayName, session: (UIApplication.shared.delegate as! AppDelegate).session!)
            BannerUtil.makeBanner(text: "Unsubscribed from r/\(subreddit!.displayName)", color: ColorUtil.accentColorForSub(sub: subreddit!.displayName), seconds: 3, context: self, top: true)
            
        } else {
            let alrController = DragDownAlertMenu(title: "Follow \(subreddit!.displayName)", subtitle: "", icon: nil, themeColor: ColorUtil.accentColorForSub(sub: subreddit!.displayName), full: true)
            
            if AccountController.isLoggedIn {
                alrController.addAction(title: "Subscribe", icon: nil) {
                    Subscriptions.subscribe(self.subreddit!.displayName, true, session: (UIApplication.shared.delegate as! AppDelegate).session!)
                    BannerUtil.makeBanner(text: "Subscribed to r/\(self.subreddit!.displayName)", color: ColorUtil.accentColorForSub(sub: self.subreddit!.displayName), seconds: 3, context: self, top: true)
                }
            }
            
            alrController.addAction(title: "Casually subscribe", icon: nil) {
                Subscriptions.subscribe(self.subreddit!.displayName, false, session: (UIApplication.shared.delegate as! AppDelegate).session!)
                BannerUtil.makeBanner(text: "r/\(self.subreddit!.displayName) added to your subreddit list", color: ColorUtil.accentColorForSub(sub: self.subreddit!.displayName), seconds: 3, context: self, top: true)
            }
            
            alrController.show(self)
        }
    }

}
