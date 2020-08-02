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
    var scroll: UIScrollView?
    var failedLabel: UILabel?
    var loader: UIActivityIndicatorView?

    var sideView: UIView = UIView()
    var pin = UIImageView()
    var icon = UIImageView()
    var title: UILabel = UILabel()
    var navController: UIViewController?
    static var defaultIcon = UIImage(sfString: SFSymbol.rCircle, overrideString: "subs")?.getCopy(withSize: CGSize.square(size: 20), withColor: UIColor.white)
    static var defaultIconMulti = UIImage(sfString: SFSymbol.mCircle, overrideString: "subs")?.getCopy(withSize: CGSize.square(size: 20), withColor: UIColor.white)
    static var allIcon = UIImage(sfString: SFSymbol.globe, overrideString: "subs")?.getCopy(withSize: CGSize.square(size: 20), withColor: UIColor.white)
    static var frontpageIcon = UIImage(sfString: SFSymbol.houseFill, overrideString: "subs")?.getCopy(withSize: CGSize.square(size: 20), withColor: UIColor.white)
    static var popularIcon = UIImage(sfString: SFSymbol.flameFill, overrideString: "subs")?.getCopy(withSize: CGSize.square(size: 20), withColor: UIColor.white)

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
            $0.layer.cornerRadius = 15
            $0.clipsToBounds = true
        }

        self.pin = UIImageView().then {
            $0.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
            $0.image = UIImage(sfString: SFSymbol.pinFill, overrideString: "lock")!.menuIcon() // TODO: - Should cache this image
            $0.isHidden = true
        }
        
        self.icon = UIImageView().then {
            $0.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
            $0.layer.cornerRadius = 15
            $0.clipsToBounds = true
            $0.isHidden = true
        }

        self.contentView.addSubviews(sideView, title, pin, icon)
        self.backgroundColor = ColorUtil.theme.backgroundColor
    }

    func configureLayout() {
        batch {
            sideView.leftAnchor == contentView.leftAnchor + 16
            sideView.sizeAnchors == CGSize.square(size: 30)
            sideView.centerYAnchor == contentView.centerYAnchor

            pin.leftAnchor == sideView.rightAnchor + 6
            pin.sizeAnchors == CGSize.square(size: 10)
            pin.centerYAnchor == contentView.centerYAnchor

            icon.edgeAnchors == sideView.edgeAnchors

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
        self.icon.isHidden = false
        if !exists {
            title.text = "Go to r/\(subreddit)"
        } else {
            title.text = subreddit
        }
        
        failedLabel?.removeFromSuperview()
        scroll?.removeFromSuperview()
        loader?.removeFromSuperview()
        
        self.profile = ""
        sideView.backgroundColor = ColorUtil.getColorForSub(sub: subreddit)
        let selectedView = UIView()
        selectedView.backgroundColor = ColorUtil.theme.backgroundColor
        selectedBackgroundView = selectedView
        
        if let icon = Subscriptions.icon(for: subreddit) {
            self.icon.contentMode = .scaleAspectFill
            self.icon.image = UIImage()
            self.icon.sd_setImage(with: URL(string: icon.unescapeHTML), completed: nil)
        } else {
            self.icon.contentMode = .center
            if subreddit.contains("m/") {
                self.icon.image = SubredditCellView.defaultIconMulti
            } else if subreddit.lowercased() == "all" {
                self.icon.image = SubredditCellView.allIcon
                self.sideView.backgroundColor = GMColor.blue500Color()
            } else if subreddit.lowercased() == "frontpage" {
                self.icon.image = SubredditCellView.frontpageIcon
                self.sideView.backgroundColor = GMColor.green500Color()
            } else if subreddit.lowercased() == "popular" {
                self.icon.image = SubredditCellView.popularIcon
                self.sideView.backgroundColor = GMColor.purple500Color()
            } else {
                self.icon.image = SubredditCellView.defaultIcon
            }
        }
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
        
        failedLabel?.removeFromSuperview()
        scroll?.removeFromSuperview()
        loader?.removeFromSuperview()

        self.search = string
        self.subreddit = sub ?? "all"
        self.profile = ""
        self.icon.isHidden = false
        self.sideView.isHidden = true
        self.navController = nav
        title.text = "Search " + (sub == nil ? "Reddit" : "r/\(self.subreddit)")
        self.icon.contentMode = .center
        self.icon.image = UIImage.init(sfString: SFSymbol.magnifyingglass, overrideString: "search")!.menuIcon()
        sideView.backgroundColor = ColorUtil.getColorForSub(sub: subreddit)
        let selectedView = UIView()
        selectedView.backgroundColor = ColorUtil.theme.backgroundColor
        selectedBackgroundView = selectedView
    }

    func setResults(subreddit: String, nav: UIViewController?, results: [RSubmission]?, complete: Bool) {
        title.textColor = ColorUtil.theme.fontColor
        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
        self.navController = nav
        self.subreddit = subreddit
        self.sideView.isHidden = false
        self.icon.isHidden = false
        self.profile = ""
        self.title.isHidden = true
        self.icon.isHidden = true
        self.sideView.isHidden = true

        if scroll != nil {
            scroll?.removeFromSuperview()
        }
                
        scroll = UIScrollView()
        let contentView = UIStackView().then {
            $0.accessibilityIdentifier = "Search results"
            $0.axis = .horizontal
            $0.alignment = .leading
            $0.spacing = 8
        }
        
        if !complete && (results == nil || results!.count == 0) {
            failedLabel?.removeFromSuperview()
            if loader == nil {
                loader = UIActivityIndicatorView()
                self.contentView.addSubview(loader!)
                loader!.tintColor = ColorUtil.theme.fontColor
                loader!.sizeAnchors == CGSize.square(size: 30)
                loader!.centerAnchors == self.contentView.centerAnchors
                loader!.startAnimating()
            }
        } else if complete && (results == nil || results!.count == 0) {
            loader?.removeFromSuperview()
            loader = nil
            failedLabel?.removeFromSuperview()
            failedLabel = UILabel()
            failedLabel?.font = UIFont.boldSystemFont(ofSize: 10)
            failedLabel?.text = "No search results found..."
            failedLabel?.textColor = ColorUtil.theme.fontColor
            
            self.contentView.addSubview(failedLabel!)
            failedLabel?.sizeToFit()
            failedLabel!.centerAnchors == self.contentView.centerAnchors
        } else {
            failedLabel?.removeFromSuperview()
            failedLabel = nil
            for submission in results ?? [] {
                let submissionView = UIView()
                let textView = UILabel()
                let thumbView = UIImageView()
                let subName = UILabel()
                let subDot = UIImageView()
                let shadowView = UIView()
                shadowView.backgroundColor = .black
                shadowView.alpha = 0.4
                
                subName.font = UIFont.boldSystemFont(ofSize: 14)
                subName.textColor = ColorUtil.theme.fontColor
                
                subDot.sizeAnchors == CGSize.square(size: 25)
                subDot.layer.cornerRadius = (25 / 2)
                subDot.clipsToBounds = true
                textView.textColor = ColorUtil.theme.fontColor

                subDot.backgroundColor = ColorUtil.getColorForSub(sub: submission.subreddit)
                
                if let icon = Subscriptions.icon(for: submission.subreddit) {
                    subDot.sd_setImage(with: URL(string: icon.unescapeHTML), completed: nil)
                }
                subName.text = "r/\(submission.subreddit)"
                thumbView.contentMode = .scaleAspectFill
                let type = ContentType.getContentType(submission: submission)
                
                if submission.banner {

                    if submission.nsfw && !SettingValues.nsfwPreviews {
                    } else if submission.thumbnailUrl == "web" || submission.thumbnailUrl.isEmpty || submission.spoiler {
                    } else {
                        submissionView.addSubviews(thumbView, shadowView)
                        
                        thumbView.edgeAnchors == submissionView.edgeAnchors

                        shadowView.edgeAnchors == thumbView.edgeAnchors
                        thumbView.loadImageWithPulsingAnimation(atUrl: URL(string: submission.smallPreview == "" ? submission.thumbnailUrl : submission.bannerUrl), withPlaceHolderImage: LinkCellImageCache.web)
                        thumbView.alpha = 0.7
                        textView.textColor = .white
                        subName.textColor = .white
                    }
                }
                
                submissionView.addSubviews(textView, subDot, subName)

                subDot.leftAnchor == submissionView.leftAnchor + 8
                subName.leftAnchor == subDot.rightAnchor + 4
                subName.centerYAnchor == subDot.centerYAnchor
                subDot.topAnchor == submissionView.topAnchor + 8
                
                textView.horizontalAnchors == submissionView.horizontalAnchors + 8
                textView.topAnchor == subDot.bottomAnchor + 8
                textView.bottomAnchor <= submissionView.bottomAnchor - 8
                
                textView.numberOfLines = 0
                textView.lineBreakMode = .byTruncatingTail

                textView.font = UIFont.systemFont(ofSize: 18)
                textView.text = submission.title
                textView.sizeToFit()
                
                submissionView.backgroundColor = ColorUtil.theme.backgroundColor
                submissionView.clipsToBounds = true
                submissionView.layer.cornerRadius = 5
                submissionView.heightAnchor == 150
                submissionView.widthAnchor == 200
                
                submissionView.addTapGestureRecognizer {
                    VCPresenter.openRedditLink(submission.permalink, nav?.navigationController, nav)
                }
                contentView.addArrangedSubview(submissionView)
            }
            
            contentView.heightAnchor == 150
            contentView.widthAnchor == CGFloat((results?.count ?? 0) * 208)
            
            scroll!.addSubview(contentView)
            scroll!.contentSize = CGSize(width: (results?.count ?? 0) * 208, height: 150)
            
            self.contentView.addSubview(scroll!)
            scroll!.edgeAnchors == self.contentView.edgeAnchors + 4
            scroll!.heightAnchor == 150
            
            if nav is SubredditToolbarSearchViewController {
                (nav as! SubredditToolbarSearchViewController).gestureRecognizer.require(toFail: scroll!.panGestureRecognizer)
            }
        }
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
