//
//  SubredditCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/6/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import Anchorage
import AudioToolbox
import Then
import UIKit

class SubredditCellView: UITableViewCell {

    var subreddit = ""
    var profile = ""
    var search = ""
    var timer: Timer?
    var cancelled = false

    var sideView: UIView = UIView()
    var pin = UIImageView()
    var icon = UIImageView()
    var title: UILabel = UILabel()
    var navController: UIViewController?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureViews()
        configureLayout()
        configureActions()
    }

    func configureViews() {
        self.clipsToBounds = true

        self.title = UILabel().then {
            $0.numberOfLines = 0
            $0.font = UIFont.boldSystemFont(ofSize: 16)
        }

        self.sideView = UIView().then {
            $0.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
            $0.layer.cornerRadius = 12
            $0.clipsToBounds = true
        }

        self.pin = UIImageView().then {
            $0.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
            $0.image = UIImage(sfString: SFSymbol.pinFill, overrideString: "lock")!.menuIcon() // TODO: - Should cache this image
            $0.isHidden = true
        }
        
        self.icon = UIImageView().then {
            $0.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
            $0.layer.cornerRadius = 12
            $0.clipsToBounds = true
            $0.isHidden = true
        }

        self.contentView.addSubviews(sideView, title, pin, icon)
        self.backgroundColor = ColorUtil.theme.backgroundColor
    }

    func configureLayout() {
        batch {
            sideView.leftAnchor == contentView.leftAnchor + 16
            sideView.sizeAnchors == CGSize.square(size: 24)
            sideView.centerYAnchor == contentView.centerYAnchor

            pin.leftAnchor == sideView.rightAnchor + 6
            pin.sizeAnchors == CGSize.square(size: 10)
            pin.centerYAnchor == contentView.centerYAnchor

            icon.leftAnchor == contentView.leftAnchor + 16
            icon.sizeAnchors == CGSize.square(size: 24)
            icon.centerYAnchor == contentView.centerYAnchor

            title.leftAnchor == pin.rightAnchor + 2
            title.centerYAnchor == contentView.centerYAnchor
        }
    }

    func configureActions() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.25
        longPress.delegate = self
        self.contentView.addGestureRecognizer(longPress)
    }

    func showPin(_ shouldShow: Bool) {
        pin.isHidden = !shouldShow
    }

    @objc func openFull(_ sender: AnyObject) {
        timer!.invalidate()
        if navController != nil {
            if #available(iOS 10.0, *) {
                HapticUtility.hapticActionStrong()
            } else if SettingValues.hapticFeedback {
                AudioServicesPlaySystemSound(1519)
            }
            if !self.cancelled {
                if profile.isEmpty() {
                    let vc = SingleSubredditViewController.init(subName: self.subreddit, single: true)
                    print("Dismissing")
                    navController!.dismiss(animated: true) {
                        VCPresenter.showVC(viewController: vc, popupIfPossible: true, parentNavigationController: self.navController!.parent?.navigationController, parentViewController: self.navController!)
                    }
                } else {
                    let vc = ProfileViewController.init(name: self.profile)
                    navController!.dismiss(animated: true) {
                        VCPresenter.showVC(viewController: vc, popupIfPossible: true, parentNavigationController: self.navController!.parent?.navigationController, parentViewController: self.navController!)
                    }
                }
            }
        }
    }

    func setSubreddit(subreddit: String, nav: UIViewController?, exists: Bool = true) {
        title.textColor = ColorUtil.theme.fontColor
        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
        self.navController = nav
        self.subreddit = subreddit
        self.sideView.isHidden = false
        self.icon.isHidden = true
        if !exists {
            title.text = "Go to r/\(subreddit)"
        } else {
            title.text = subreddit
        }
        self.profile = ""
        sideView.backgroundColor = ColorUtil.getColorForSub(sub: subreddit)
        let selectedView = UIView()
        selectedView.backgroundColor = ColorUtil.theme.backgroundColor
        selectedBackgroundView = selectedView
    }
    
    func setProfile(profile: String, nav: UIViewController?) {
        title.textColor = ColorUtil.theme.fontColor
        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
        self.profile = profile
        self.subreddit = ""
        self.search = ""
        self.icon.isHidden = false
        self.sideView.isHidden = true
        self.navController = nav
        title.text = "Go to u/\(profile)'s profile"
        self.icon.image = UIImage(sfString: SFSymbol.personFill, overrideString: "profile")!.menuIcon()
        sideView.backgroundColor = ColorUtil.getColorForSub(sub: subreddit)
        let selectedView = UIView()
        selectedView.backgroundColor = ColorUtil.theme.backgroundColor
        selectedBackgroundView = selectedView
    }

    func setSearch(string: String, sub: String?, nav: UIViewController?) {
        title.textColor = ColorUtil.theme.fontColor
        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
        self.search = string
        self.subreddit = sub ?? "all"
        self.profile = ""
        self.icon.isHidden = false
        self.sideView.isHidden = true
        self.navController = nav
        title.text = "Search " + (sub == nil ? "Reddit" : "r/\(self.subreddit)")
        self.icon.image = UIImage.init(sfString: SFSymbol.magnifyingglass, overrideString: "search")!.menuIcon()
        sideView.backgroundColor = ColorUtil.getColorForSub(sub: subreddit)
        let selectedView = UIView()
        selectedView.backgroundColor = ColorUtil.theme.backgroundColor
        selectedBackgroundView = selectedView
    }

}

// MARK: Actions
extension SubredditCellView {

    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.began {
            cancelled = false
            timer = Timer.scheduledTimer(timeInterval: 0.25,
                                         target: self,
                                         selector: #selector(self.openFull(_:)),
                                         userInfo: nil,
                                         repeats: false)

        }
        if sender.state == UIGestureRecognizer.State.ended {
            timer!.invalidate()
            cancelled = true
        }
    }

}
