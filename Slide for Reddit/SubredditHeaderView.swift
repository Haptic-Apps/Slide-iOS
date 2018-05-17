//
//  SubredditHeaderView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import UZTextView
import MaterialComponents.MaterialSnackbar

class SubredditHeaderView: UIView, UZTextViewDelegate, UIViewControllerPreviewingDelegate {

    var back: UIView = UIView()
    var subscribers: UILabel = UILabel()
    var here: UILabel = UILabel()
    var desc: UZTextView = UZTextView()
    var info: UZTextView = UZTextView()

    var subscribe: UITableViewCell = UITableViewCell()
    var theme = UITableViewCell()
    var submit = UITableViewCell()
    var wiki = UITableViewCell()
    var sorting = UITableViewCell()
    var mods = UITableViewCell()


    func mods(_ sender: UITableViewCell) {
        var list: [User] = []
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.about(subreddit!, aboutWhere: SubredditAbout.moderators, completion: { (result) in
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "No subreddit moderators found"
                        MDCSnackbarManager.show(message)
                    }
                    break
                case .success(let users):
                    list.append(contentsOf: users)
                    DispatchQueue.main.async {
                        let sheet = UIAlertController(title: "/r/\(self.subreddit!.displayName) mods", message: nil, preferredStyle: .actionSheet)
                        sheet.addAction(
                                UIAlertAction(title: "Close", style: .cancel) { (action) in
                                    sheet.dismiss(animated: true, completion: nil)
                                }
                        )
                        sheet.addAction(
                                UIAlertAction(title: "Message /r/\(self.subreddit!.displayName) moderators", style: .default) { (action) in
                                    sheet.dismiss(animated: true, completion: nil)
                                    //todo this
                                }
                        )

                        for user in users {
                            let somethingAction = UIAlertAction(title: "/u/\(user.name)", style: .default) { (action) in
                                sheet.dismiss(animated: true, completion: nil)
                                VCPresenter.showVC(viewController: ProfileViewController.init(name: user.name), popupIfPossible: false, parentNavigationController: self.parentController?.navigationController, parentViewController: self.parentController)
                            }

                            let color = ColorUtil.getColorForUser(name: user.name)
                            if (color != ColorUtil.baseColor) {
                                somethingAction.setValue(color, forKey: "titleTextColor")

                            }
                            sheet.addAction(somethingAction)
                        }
                        if let presenter = sheet.popoverPresentationController {
                            presenter.sourceView = sender
                            presenter.sourceRect = sender.bounds
                        }

                        self.parentController?.present(sheet, animated: true)
                    }
                    break
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

        self.subscribe.textLabel?.text = "Subscribed"
        self.subscribe.accessoryType = .none
        self.subscribe.backgroundColor = ColorUtil.foregroundColor
        self.subscribe.textLabel?.textColor = ColorUtil.fontColor
        self.subscribe.imageView?.image = UIImage.init(named: "subbed")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.subscribe.imageView?.tintColor = ColorUtil.fontColor

        self.theme.textLabel?.text = "Subreddit theme"
        self.theme.accessoryType = .none
        self.theme.backgroundColor = ColorUtil.foregroundColor
        self.theme.textLabel?.textColor = ColorUtil.fontColor
        self.theme.imageView?.image = UIImage.init(named: "palette")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.theme.imageView?.tintColor = ColorUtil.fontColor

        self.submit.textLabel?.text = "New post"
        self.submit.accessoryType = .none
        self.submit.backgroundColor = ColorUtil.foregroundColor
        self.submit.textLabel?.textColor = ColorUtil.fontColor
        self.submit.imageView?.image = UIImage.init(named: "edit")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.submit.imageView?.tintColor = ColorUtil.fontColor

        self.wiki.textLabel?.text = "Subreddit wiki"
        self.wiki.accessoryType = .none
        self.wiki.backgroundColor = ColorUtil.foregroundColor
        self.wiki.textLabel?.textColor = ColorUtil.fontColor
        self.wiki.imageView?.image = UIImage.init(named: "wiki")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.wiki.imageView?.tintColor = ColorUtil.fontColor

        self.sorting.textLabel?.text = "Default subreddit sorting"
        self.sorting.accessoryType = .none
        self.sorting.backgroundColor = ColorUtil.foregroundColor
        self.sorting.textLabel?.textColor = ColorUtil.fontColor
        self.sorting.imageView?.image = UIImage.init(named: "ic_sort_white")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.sorting.imageView?.tintColor = ColorUtil.fontColor

        self.mods.textLabel?.text = "Subreddit moderators"
        self.mods.accessoryType = .none
        self.mods.backgroundColor = ColorUtil.foregroundColor
        self.mods.textLabel?.textColor = ColorUtil.fontColor
        self.mods.imageView?.image = UIImage.init(named: "mod")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.mods.imageView?.tintColor = ColorUtil.fontColor

        self.desc = UZTextView(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        self.desc.delegate = self
        self.desc.isUserInteractionEnabled = true
        self.desc.backgroundColor = .clear

        self.info = UZTextView(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        self.info.delegate = self
        self.info.isUserInteractionEnabled = true
        self.info.backgroundColor = .clear

        self.subscribers = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));
        subscribers.numberOfLines = 1
        subscribers.font = UIFont.systemFont(ofSize: 16)
        subscribers.textColor = UIColor.white

        self.here = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));
        here.numberOfLines = 1
        here.font = UIFont.systemFont(ofSize: 16)
        here.textColor = UIColor.white

        self.back = UIImageView(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))

        theme.translatesAutoresizingMaskIntoConstraints = false
        submit.translatesAutoresizingMaskIntoConstraints = false
        subscribe.translatesAutoresizingMaskIntoConstraints = false
        back.translatesAutoresizingMaskIntoConstraints = false
        desc.translatesAutoresizingMaskIntoConstraints = false
        info.translatesAutoresizingMaskIntoConstraints = false
        subscribers.translatesAutoresizingMaskIntoConstraints = false
        here.translatesAutoresizingMaskIntoConstraints = false
        sorting.translatesAutoresizingMaskIntoConstraints = false
        wiki.translatesAutoresizingMaskIntoConstraints = false
        mods.translatesAutoresizingMaskIntoConstraints = false

        addSubview(theme)
        addSubview(submit)
        addSubview(subscribe)
        addSubview(back)
        addSubview(info)
        back.addSubview(subscribers)
        back.addSubview(here)
        back.addSubview(desc)
        back.addSubview(sorting)
        back.addSubview(wiki)
        back.addSubview(mods)

        self.clipsToBounds = true
        updateConstraints()


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

    func new(_ selector: UITableViewCell) {
        let actionSheetController2: UIAlertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)

        var cancelActionButton2: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
        }
        actionSheetController2.addAction(cancelActionButton2)


        cancelActionButton2 = UIAlertAction(title: "Image", style: .default) { action -> Void in
            VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(subreddit: self.subreddit!.displayName, type: ReplyViewController.ReplyType.SUBMIT_IMAGE, completion: { (submission) in
                VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: submission!.permalink)!), popupIfPossible: true, parentNavigationController: self.parentController?.navigationController, parentViewController: self.parentController)
            })), parentVC: self.parentController!)
        }
        actionSheetController2.addAction(cancelActionButton2)


        cancelActionButton2 = UIAlertAction(title: "Link", style: .default) { action -> Void in
            VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(subreddit: self.subreddit!.displayName, type: ReplyViewController.ReplyType.SUBMIT_LINK, completion: { (submission) in
                VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: submission!.permalink)!), popupIfPossible: true, parentNavigationController: self.parentController?.navigationController, parentViewController: self.parentController)
            })), parentVC: self.parentController!)
        }
        actionSheetController2.addAction(cancelActionButton2)


        cancelActionButton2 = UIAlertAction(title: "Text", style: .default) { action -> Void in
            VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(subreddit: self.subreddit!.displayName, type: ReplyViewController.ReplyType.SUBMIT_TEXT, completion: { (submission) in
                VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: submission!.permalink)!), popupIfPossible: true, parentNavigationController: self.parentController?.navigationController, parentViewController: self.parentController)
            })), parentVC: self.parentController!)
        }
        actionSheetController2.addAction(cancelActionButton2)

        if let presenter = actionSheetController2.popoverPresentationController {
            presenter.sourceView = selector
            presenter.sourceRect = selector.bounds
        }
        parentController?.present(actionSheetController2, animated: true)
    }

    func sort(_ selector: UITableViewCell) {
        let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)

        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)

        for link in LinkSortType.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: link.description, style: .default) { action -> Void in
                self.showTimeMenu(s: link, selector: selector)
            }
            actionSheetController.addAction(saveActionButton)
        }

        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = selector
            presenter.sourceRect = selector.bounds
        }

        self.parentController?.present(actionSheetController, animated: true, completion: nil)

    }

    func showTimeMenu(s: LinkSortType, selector: UITableViewCell) {
        if (s == .hot || s == .new) {
            UserDefaults.standard.set(s.path, forKey: self.subreddit!.displayName + "Sorting")
            UserDefaults.standard.set(TimeFilterWithin.day, forKey: self.subreddit!.displayName + "Time")
            UserDefaults.standard.synchronize()
            return
        } else {
            let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)

            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                print("Cancel")
            }
            actionSheetController.addAction(cancelActionButton)

            for t in TimeFilterWithin.cases {
                let saveActionButton: UIAlertAction = UIAlertAction(title: t.param, style: .default) { action -> Void in
                    print("Sort is \(s) and time is \(t)")
                    UserDefaults.standard.set(s.path, forKey: self.subreddit!.displayName + "Sorting")
                    UserDefaults.standard.set(t.param, forKey: self.subreddit!.displayName + "Time")
                    UserDefaults.standard.synchronize()
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


    var content: CellContent?
    var textHeight: CGFloat = 0
    var descHeight: CGFloat = 0
    var contentInfo: CellContent?
    var parentController: MediaViewController?

    func setSubreddit(subreddit: Subreddit, parent: MediaViewController, _ width: CGFloat) {
        self.subreddit = subreddit
        self.width = width
        self.parentController = parent
        back.backgroundColor = ColorUtil.getColorForSub(sub: subreddit.displayName)
        subscribers.text = "\(subreddit.subscribers) subscribers"
        here.text = "\(subreddit.accountsActive) here"

        if (!subreddit.publicDescription.isEmpty()) {
            let html = subreddit.publicDescriptionHtml.preprocessedHTMLStringBeforeNSAttributedStringParsing
            do {
                let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
                let font = UIFont(name: ".SFUIText-Light", size: 16) ?? UIFont.systemFont(ofSize: 16)
                let attr2 = attr.reconstruct(with: font, color: .white, linkColor: ColorUtil.accentColorForSub(sub: subreddit.displayName))
                content = CellContent.init(string: LinkParser.parse(attr2, ColorUtil.accentColorForSub(sub: subreddit.displayName)), width: width - 24)
                desc.attributedString = content?.attributedString
                textHeight = (content?.textHeight)!
            } catch {
            }
        }

        if (!subreddit.descriptionHtml.isEmpty()) {
            let html = subreddit.descriptionHtml.preprocessedHTMLStringBeforeNSAttributedStringParsing
            do {
                let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
                let font = UIFont(name: ".SFUIText-Light", size: 16) ?? UIFont.systemFont(ofSize: 16)
                let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: ColorUtil.accentColorForSub(sub: subreddit.displayName))
                contentInfo = CellContent.init(string: LinkParser.parse(attr2, ColorUtil.accentColorForSub(sub: subreddit.displayName)), width: width - 24)
                info.attributedString = contentInfo?.attributedString
                descHeight = (contentInfo?.textHeight)!
            } catch {

            }
            parentController?.registerForPreviewing(with: self, sourceView: info)
        }

        updateConstraints()
    }

    var subreddit: Subreddit?
    var constraintBack: [NSLayoutConstraint] = []
    var constraintMain: [NSLayoutConstraint] = []
    var width: CGFloat = 0

    override func updateConstraints() {
        super.updateConstraints()

        let metrics = ["topMargin": 0, "bh": CGFloat(130 + textHeight), "dh": descHeight, "b": textHeight + 30, "w": width]
        let views = ["theme": theme, "submit": submit, "subscribe": subscribe, "mods": mods, "back": back, "sort": sorting, "wiki": wiki, "desc": desc, "info": info, "subscribers": subscribers, "here": here] as [String: Any]


        back.removeConstraints(constraintBack)
        constraintBack = []


        constraintBack.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(16)-[desc]-(16)-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        constraintBack.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(16)-[subscribers]-(16)-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        constraintBack.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(16)-[here]-(16)-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        constraintBack.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-16-[subscribers]-2-[here]-2-[desc]-4-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        back.addConstraints(constraintBack)

        removeConstraints(constraintMain)
        constraintMain = []

        constraintMain.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[back(w)]-(0)-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        constraintMain.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[submit]-(12)-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        constraintMain.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[subscribe]-(12)-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        constraintMain.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[sort]-(12)-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        constraintMain.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[wiki]-(12)-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        constraintMain.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[theme]-(12)-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))


        constraintMain.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[info]-(12)-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        constraintMain.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[mods]-(12)-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))


        constraintMain.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[back]-(8)-[subscribe(50)]-(2)-[theme(50)]-(2)-[wiki(50)]-(2)-[submit(50)]-(2)-[mods(50)]-(2)-[sort(50)]-(8)-[info(dh)]-(4)-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        addConstraints(constraintMain)

    }

    func getEstHeight() -> CGFloat {
        return CGFloat(60 + textHeight) + ((contentInfo == nil) ? 0 : descHeight) + (50 * 7)
    }


    func textView(_ textView: UZTextView, didLongTapLinkAttribute value: Any?) {
        if let attr = value as? [String: Any] {
            if let url = attr[NSLinkAttributeName] as? URL {
                if parentController != nil {
                    let sheet = UIAlertController(title: url.absoluteString, message: nil, preferredStyle: .actionSheet)
                    sheet.addAction(
                            UIAlertAction(title: "Close", style: .cancel) { (action) in
                                sheet.dismiss(animated: true, completion: nil)
                            }
                    )
                    let open = OpenInChromeController.init()
                    if (open.isChromeInstalled()) {
                        sheet.addAction(
                                UIAlertAction(title: "Open in Chrome", style: .default) { (action) in
                                    open.openInChrome(url, callbackURL: nil, createNewTab: true)
                                }
                        )
                    }
                    sheet.addAction(
                            UIAlertAction(title: "Open in Safari", style: .default) { (action) in
                                if #available(iOS 10.0, *) {
                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                } else {
                                    UIApplication.shared.openURL(url)
                                }
                                sheet.dismiss(animated: true, completion: nil)
                            }
                    )
                    sheet.addAction(
                            UIAlertAction(title: "Open", style: .default) { (action) in
                                /* let controller = WebViewController(nibName: nil, bundle: nil)
                                 controller.url = url
                                 let nav = UINavigationController(rootViewController: controller)
                                 self.present(nav, animated: true, completion: nil)*/
                            }
                    )
                    sheet.addAction(
                            UIAlertAction(title: "Copy URL", style: .default) { (action) in
                                UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
                                sheet.dismiss(animated: true, completion: nil)
                            }
                    )
                    //todo make this work on ipad
                    parentController?.present(sheet, animated: true, completion: nil)
                }
            }
        }
    }

    func textView(_ textView: UZTextView, didClickLinkAttribute value: Any?) {
        if ((parentController) != nil) {
            if let attr = value as? [String: Any] {
                if let url = attr[NSLinkAttributeName] as? URL {
                    parentController?.doShow(url: url)
                }
            }
        }
    }

    func selectionDidEnd(_ textView: UZTextView) {
    }

    func selectionDidBegin(_ textView: UZTextView) {
    }

    func didTapTextDoesNotIncludeLinkTextView(_ textView: UZTextView) {
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        let locationInTextView = info.convert(location, to: info)

        if let (url, rect) = getInfo(locationInTextView: locationInTextView) {
            previewingContext.sourceRect = info.convert(rect, from: info)
            if let controller = parentController?.getControllerForUrl(baseUrl: url) {
                return controller
            }
        }
        return nil
    }

    func getInfo(locationInTextView: CGPoint) -> (URL, CGRect)? {
        if let attr = info.attributes(at: locationInTextView) {
            if let url = attr[NSLinkAttributeName] as? URL,
               let value = attr[UZTextViewClickedRect] as? CGRect {
                return (url, value)
            }
        }
        return nil
    }


    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        parentController?.show(viewControllerToCommit, sender: parentController)
    }

}

extension UIImage {

    func addImagePadding(x: CGFloat, y: CGFloat) -> UIImage {
        let width: CGFloat = self.size.width + x;
        let height: CGFloat = self.size.width + y;
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0);
        let context: CGContext = UIGraphicsGetCurrentContext()!;
        UIGraphicsPushContext(context);
        let origin: CGPoint = CGPoint(x: (width - self.size.width) / 2, y: (height - self.size.height) / 2);
        self.draw(at: origin)
        UIGraphicsPopContext();
        let imageWithPadding = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

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