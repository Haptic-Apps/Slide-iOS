//
//  SubredditHeaderView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import reddift
import TTTAttributedLabel
import UIKit

class SubredditHeaderView: UIView, TTTAttributedLabelDelegate {

    var back: UILabel = UILabel()
    var subscribers: UILabel = UILabel()
    var here: UILabel = UILabel()
    var info = TextDisplayStackView()
    
    var submit = UITableViewCell()
    var sorting = UITableViewCell()
    var mods = UITableViewCell()

    var subbed = UISwitch()

    func mods(_ sender: UITableViewCell) {
        var list: [User] = []
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.about(subreddit!, aboutWhere: SubredditAbout.moderators, completion: { (result) in
                switch result {
                case .failure:
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "No subreddit moderators found!", color: GMColor.red500Color(), seconds: 3, context: self.parentController)
                    }
                case .success(let users):
                    list.append(contentsOf: users)
                    DispatchQueue.main.async {
                        let sheet = UIAlertController(title: "r/\(self.subreddit!.displayName) mods", message: nil, preferredStyle: .actionSheet)
                        sheet.addAction(
                                UIAlertAction(title: "Close", style: .cancel) { (_) in
                                    sheet.dismiss(animated: true, completion: nil)
                                }
                        )
                        sheet.addAction(
                                UIAlertAction(title: "Message r/\(self.subreddit!.displayName) moderators", style: .default) { (_) in
                                    sheet.dismiss(animated: true, completion: nil)
                                    //todo this
                                }
                        )

                        for user in users {
                            let somethingAction = UIAlertAction(title: "u/\(user.name)", style: .default) { (_) in
                                sheet.dismiss(animated: true, completion: nil)
                                VCPresenter.showVC(viewController: ProfileViewController.init(name: user.name), popupIfPossible: false, parentNavigationController: self.parentController?.navigationController, parentViewController: self.parentController)
                            }

                            let color = ColorUtil.getColorForUser(name: user.name)
                            if color != ColorUtil.baseColor {
                                somethingAction.setValue(color, forKey: "titleTextColor")

                            }
                            sheet.addAction(somethingAction)
                        }
                        if let presenter = sheet.popoverPresentationController {
                            presenter.sourceView = self.mods
                            presenter.sourceRect = self.mods.bounds
                        }

                        self.parentController?.present(sheet, animated: true)
                    }
                }
            })
        } catch {
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

        let pointForTargetViewmore: CGPoint = mods.convert(point, from: self)
        if mods.bounds.contains(pointForTargetViewmore) {
            return mods
        }

        let pointForTargetViewsort: CGPoint = sorting.convert(point, from: self)
        if sorting.bounds.contains(pointForTargetViewsort) {
            return sorting
        }

        let pointForTargetViewsubmit: CGPoint = submit.convert(point, from: self)
        if submit.bounds.contains(pointForTargetViewsubmit) {
            return submit
        }

        return super.hitTest(point, with: event)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.submit.textLabel?.text = "New post"
        self.submit.accessoryType = .none
        self.submit.backgroundColor = ColorUtil.foregroundColor
        self.submit.textLabel?.textColor = ColorUtil.fontColor
        self.submit.imageView?.image = UIImage.init(named: "edit")?.menuIcon()
        self.submit.imageView?.tintColor = ColorUtil.fontColor
        self.submit.layer.cornerRadius = 5
        self.submit.clipsToBounds = true

        self.sorting.textLabel?.text = "Default subreddit sorting"
        self.sorting.accessoryType = .none
        self.sorting.backgroundColor = ColorUtil.foregroundColor
        self.sorting.textLabel?.textColor = ColorUtil.fontColor
        self.sorting.imageView?.image = UIImage.init(named: "ic_sort_white")?.menuIcon()
        self.sorting.imageView?.tintColor = ColorUtil.fontColor
        self.sorting.layer.cornerRadius = 5
        self.sorting.clipsToBounds = true

        self.mods.textLabel?.text = "Subreddit moderators"
        self.mods.accessoryType = .none
        self.mods.backgroundColor = ColorUtil.foregroundColor
        self.mods.textLabel?.textColor = ColorUtil.fontColor
        self.mods.imageView?.image = UIImage.init(named: "mod")?.menuIcon()
        self.mods.imageView?.tintColor = ColorUtil.fontColor
        self.mods.layer.cornerRadius = 5
        self.mods.clipsToBounds = true

        self.info = TextDisplayStackView.init(fontSize: 16, submission: false, color: .blue, delegate: self, width: width - 24)
        
        self.subscribers = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        subscribers.numberOfLines = 1
        subscribers.font = UIFont.systemFont(ofSize: 16)
        subscribers.textColor = UIColor.white

        self.here = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        here.numberOfLines = 1
        here.font = UIFont.systemFont(ofSize: 16)
        here.textColor = UIColor.white

        self.back = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 56))

        addSubviews(submit, back, info, subscribers, here, sorting, mods)

        self.clipsToBounds = true

        back.addSubview(subbed)
        subbed.leftAnchor == back.leftAnchor + CGFloat(24)
        subbed.centerYAnchor == back.centerYAnchor
        
        setupAnchors()

        let pTap = UITapGestureRecognizer(target: self, action: #selector(self.mods(_:)))
        mods.addGestureRecognizer(pTap)
        mods.isUserInteractionEnabled = true

        let sTap = UITapGestureRecognizer(target: self, action: #selector(self.sort(_:)))
        sorting.addGestureRecognizer(sTap)
        sorting.isUserInteractionEnabled = true

        let nTap = UITapGestureRecognizer(target: self, action: #selector(self.new(_:)))
        submit.addGestureRecognizer(nTap)
        submit.isUserInteractionEnabled = true

    }
    
    func doSub(_ changed: UISwitch) {
        if !changed.isOn {
            Subscriptions.unsubscribe(subreddit!.displayName, session: (UIApplication.shared.delegate as! AppDelegate).session!)
            BannerUtil.makeBanner(text: "Unsubscribed from r/\(subreddit!.displayName)", color: ColorUtil.accentColorForSub(sub: subreddit!.displayName), seconds: 3, context: parentController, top: true)

        } else {
            let alrController = UIAlertController.init(title: "Subscribe to \(subreddit!.displayName)", message: nil, preferredStyle: .actionSheet)
            if AccountController.isLoggedIn {
                let somethingAction = UIAlertAction(title: "Add to sub list and subscribe", style: UIAlertActionStyle.default, handler: { (_: UIAlertAction!) in
                    Subscriptions.subscribe(self.subreddit!.displayName, true, session: (UIApplication.shared.delegate as! AppDelegate).session!)
                    BannerUtil.makeBanner(text: "Subscribed", color: ColorUtil.accentColorForSub(sub: self.subreddit!.displayName), seconds: 3, context: self.parentController, top: true)
                })
                alrController.addAction(somethingAction)
            }
            
            let somethingAction = UIAlertAction(title: "Just add to sub list", style: UIAlertActionStyle.default, handler: { (_: UIAlertAction!) in
                Subscriptions.subscribe(self.subreddit!.displayName, false, session: (UIApplication.shared.delegate as! AppDelegate).session!)
                BannerUtil.makeBanner(text: "Added to subreddit list", color: ColorUtil.accentColorForSub(sub: self.subreddit!.displayName), seconds: 3, context: self.parentController, top: true)
            })
            alrController.addAction(somethingAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (_: UIAlertAction!) in print("cancel") })
            
            alrController.addAction(cancelAction)
            
            alrController.modalPresentationStyle = .fullScreen
            if let presenter = alrController.popoverPresentationController {
                presenter.sourceView = changed
                presenter.sourceRect = changed.bounds
            }
            
            parentController?.present(alrController, animated: true, completion: {})
            
        }
    }

    func new(_ selector: UITableViewCell) {
        PostActions.showPostMenu(parentController!, sub: self.subreddit!.displayName)
    }
    
    func sort(_ selector: UITableViewCell) {
        let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)

        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        let selected = UIImage.init(named: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)

        for link in LinkSortType.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: link.description, style: .default) { _ -> Void in
                self.showTimeMenu(s: link, selector: selector)
            }
            
            if SettingValues.getLinkSorting(forSubreddit: self.subreddit!.displayName) == link {
                saveActionButton.setValue(selected, forKey: "image")
            }

            actionSheetController.addAction(saveActionButton)
        }

        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = self.sorting
            presenter.sourceRect = self.sorting.bounds
        }

        self.parentController?.present(actionSheetController, animated: true, completion: nil)

    }

    func showTimeMenu(s: LinkSortType, selector: UITableViewCell) {
        if s == .hot || s == .new || s == .rising {
            UserDefaults.standard.set(s.path, forKey: self.subreddit!.displayName.lowercased() + "Sorting")
            UserDefaults.standard.set(TimeFilterWithin.day.param, forKey: self.subreddit!.displayName.lowercased() + "Time")
            UserDefaults.standard.synchronize()
            return
        } else {
            let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)

            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
                print("Cancel")
            }
            actionSheetController.addAction(cancelActionButton)
            let selected = UIImage.init(named: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)

            for t in TimeFilterWithin.cases {
                let saveActionButton: UIAlertAction = UIAlertAction(title: t.param, style: .default) { _ -> Void in
                    UserDefaults.standard.set(s.path, forKey: self.subreddit!.displayName.lowercased() + "Sorting")
                    UserDefaults.standard.set(t.param, forKey: self.subreddit!.displayName.lowercased() + "Time")
                    UserDefaults.standard.synchronize()
                }
                
                if SettingValues.getTimePeriod(forSubreddit: self.subreddit!.displayName) == t {
                    saveActionButton.setValue(selected, forKey: "image")
                }

                actionSheetController.addAction(saveActionButton)
            }

            if let presenter = actionSheetController.popoverPresentationController {
                presenter.sourceView = selector
                presenter.sourceRect = selector.bounds
            }

            self.parentController?.present(actionSheetController, animated: true, completion: nil)
        }
    }

    func exit() {
        parentController?.dismiss(animated: true, completion: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func subscribe(_ sender: AnyObject) {
    }

    func theme(_ sender: AnyObject) {

    }

    func submit(_ sender: AnyObject) {

    }

    var content: NSAttributedString?
    var textHeight: CGFloat = 0
    var descHeight: CGFloat = 0
    var parentController: (UIViewController & MediaVCDelegate)?

    func setSubreddit(subreddit: Subreddit, parent: MediaViewController, _ width: CGFloat) {
        self.subreddit = subreddit
        self.setWidth = width
        self.parentController = parent
        back.backgroundColor = ColorUtil.getColorForSub(sub: subreddit.displayName)
        back.text = subreddit.displayName
        back.textColor = .white
        back.font = FontGenerator.boldFontOfSize(size: 24, submission: true)
        back.textAlignment = .center
        
        subbed.isOn = Subscriptions.isSubscriber(subreddit.displayName)
        subbed.onTintColor = ColorUtil.accentColorForSub(sub: subreddit.displayName)
        subbed.addTarget(self, action: #selector(doSub(_:)), for: .valueChanged)
        subbed.isUserInteractionEnabled = true
        
        back.isUserInteractionEnabled = true
        
        here.numberOfLines = 0
        subscribers.numberOfLines = 0
        subscribers.font = FontGenerator.boldFontOfSize(size: 14, submission: true)
        here.font = subscribers.font
        here.textAlignment = .center
        subscribers.textAlignment = .center
        here.textColor = ColorUtil.fontColor
        subscribers.textColor = ColorUtil.fontColor

        let attrs = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 20, submission: true)]
        var attributedString = NSMutableAttributedString(string: "\(subreddit.subscribers.delimiter)", attributes: attrs)
        var subt = NSMutableAttributedString(string: "\nSUBSCRIBERS")
        attributedString.append(subt)
        subscribers.attributedText = attributedString
        
        attributedString = NSMutableAttributedString(string: "\(subreddit.accountsActive.delimiter)", attributes: attrs)
        subt = NSMutableAttributedString(string: "\nHERE")
        attributedString.append(subt)
        here.attributedText = attributedString

        info.estimatedWidth = width - 24
        if !subreddit.descriptionHtml.isEmpty() {
            info.tColor = ColorUtil.accentColorForSub(sub: subreddit.displayName)
            info.setTextWithTitleHTML(NSMutableAttributedString(), htmlString: subreddit.descriptionHtml)
            descHeight = info.estimatedHeight
        }
    }

    var subreddit: Subreddit?
    var setWidth: CGFloat = 0

    func setupAnchors() {

        back.horizontalAnchors == horizontalAnchors
        submit.horizontalAnchors == horizontalAnchors + CGFloat(12)
        sorting.horizontalAnchors == horizontalAnchors + CGFloat(12)
        mods.horizontalAnchors == horizontalAnchors + CGFloat(12)
        info.horizontalAnchors == horizontalAnchors + CGFloat(12)
        subscribers.leftAnchor == leftAnchor + CGFloat(12)
        subscribers.rightAnchor == here.leftAnchor - CGFloat(4)
        here.leftAnchor == subscribers.rightAnchor + CGFloat(4)
        here.widthAnchor == subscribers.widthAnchor
        here.rightAnchor == rightAnchor - CGFloat(12)
        here.centerYAnchor == subscribers.centerYAnchor
        
        back.heightAnchor == CGFloat(86)
        back.topAnchor == topAnchor
        subscribers.topAnchor == back.bottomAnchor + CGFloat(6)
        submit.topAnchor == subscribers.bottomAnchor + CGFloat(8)
        mods.topAnchor == submit.bottomAnchor + CGFloat(2)
        sorting.topAnchor == mods.bottomAnchor + CGFloat(2)
        info.topAnchor == sorting.bottomAnchor + CGFloat(16)
        info.bottomAnchor == bottomAnchor - CGFloat(16)
        subscribers.heightAnchor == CGFloat(50)
        submit.heightAnchor == CGFloat(50)
        mods.heightAnchor == CGFloat(50)
        sorting.heightAnchor == CGFloat(50)
    }

    func getEstHeight() -> CGFloat {
        return CGFloat(320) + (descHeight)
    }
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        parentController?.doShow(url: url)
    }
}

extension UIImage {

    func addImagePadding(x: CGFloat, y: CGFloat) -> UIImage {
        let width: CGFloat = self.size.width + x
        let height: CGFloat = self.size.width + y
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        UIGraphicsPushContext(context)
        let origin: CGPoint = CGPoint(x: (width - self.size.width) / 2, y: (height - self.size.height) / 2)
        self.draw(at: origin)
        UIGraphicsPopContext()
        let imageWithPadding = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return imageWithPadding!
    }
}

//https://medium.com/@sdrzn/adding-gesture-recognizers-with-closures-instead-of-selectors-9fb3e09a8f0b
extension UIView {

    // In order to create computed properties for extensions, we need a key to
    // store and access the stored property
    fileprivate struct AssociatedObjectKeys {
        static var tapGestureRecognizer = "tapGR"
        static var longTapGestureRecognizer = "longTapGR"

    }

    fileprivate typealias Action = (() -> Void)?

    // Set our computed property type to a closure
    fileprivate var tapGestureRecognizerAction: Action? {
        set {
            if let newValue = newValue {
                // Computed properties get stored as associated objects
                objc_setAssociatedObject(self, &AssociatedObjectKeys.tapGestureRecognizer, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            }
        }
        get {
            let tapGestureRecognizerActionInstance = objc_getAssociatedObject(self, &AssociatedObjectKeys.tapGestureRecognizer) as? Action
            return tapGestureRecognizerActionInstance
        }
    }

    fileprivate var longTapGestureRecognizerAction: Action? {
        set {
            if let newValue = newValue {
                // Computed properties get stored as associated objects
                objc_setAssociatedObject(self, &AssociatedObjectKeys.longTapGestureRecognizer, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            }
        }
        get {
            let tapGestureRecognizerActionInstance = objc_getAssociatedObject(self, &AssociatedObjectKeys.longTapGestureRecognizer) as? Action
            return tapGestureRecognizerActionInstance
        }
    }

    // This is the meat of the sauce, here we create the tap gesture recognizer and
    // store the closure the user passed to us in the associated object we declared above
    public func addTapGestureRecognizer(action: (() -> Void)?) {
        self.isUserInteractionEnabled = true
        self.tapGestureRecognizerAction = action
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        self.addGestureRecognizer(tapGestureRecognizer)
    }

    public func addLongTapGestureRecognizer(action: (() -> Void)?) {
        self.isUserInteractionEnabled = true
        self.longTapGestureRecognizerAction = action
        let tapGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongTapGesture))
        self.addGestureRecognizer(tapGestureRecognizer)
    }

    // Every time the user taps on the UIImageView, this function gets called,
    // which triggers the closure we stored
    @objc fileprivate func handleTapGesture(sender: UITapGestureRecognizer) {
        if let action = self.tapGestureRecognizerAction {
            action?()
        }
    }

    @objc fileprivate func handleLongTapGesture(sender: UITapGestureRecognizer) {
        if let action = self.longTapGestureRecognizerAction {
            action?()
        }
    }
}
extension Int {
    private static var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        
        return numberFormatter
    }()
    
    var delimiter: String {
        return Int.numberFormatter.string(from: NSNumber(value: self)) ?? ""
    }
}
