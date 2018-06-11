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

    var back: UILabel = UILabel()
    var subscribers: UILabel = UILabel()
    var here: UILabel = UILabel()
    var info: UZTextView = UZTextView()

    var submit = UITableViewCell()
    var sorting = UITableViewCell()
    var mods = UITableViewCell()

    var subbed = UISwitch()

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
                        let sheet = UIAlertController(title: "r/\(self.subreddit!.displayName) mods", message: nil, preferredStyle: .actionSheet)
                        sheet.addAction(
                                UIAlertAction(title: "Close", style: .cancel) { (action) in
                                    sheet.dismiss(animated: true, completion: nil)
                                }
                        )
                        sheet.addAction(
                                UIAlertAction(title: "Message r/\(self.subreddit!.displayName) moderators", style: .default) { (action) in
                                    sheet.dismiss(animated: true, completion: nil)
                                    //todo this
                                }
                        )

                        for user in users {
                            let somethingAction = UIAlertAction(title: "u/\(user.name)", style: .default) { (action) in
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

        self.back = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 56))

        submit.translatesAutoresizingMaskIntoConstraints = false
        back.translatesAutoresizingMaskIntoConstraints = false
        info.translatesAutoresizingMaskIntoConstraints = false
        subscribers.translatesAutoresizingMaskIntoConstraints = false
        here.translatesAutoresizingMaskIntoConstraints = false
        sorting.translatesAutoresizingMaskIntoConstraints = false
        mods.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(submit)
        addSubview(back)
        addSubview(info)
        addSubview(subscribers)
        addSubview(here)
        addSubview(sorting)
        addSubview(mods)

        self.clipsToBounds = true
        updateConstraints()
        
        
        back.addSubview(subbed)
        subbed.frame.origin = CGPoint.init(x: 24, y: back.frame.size.height / 2)

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
        if (!changed.isOn) {
            Subscriptions.unsubscribe(subreddit!.displayName, session: (UIApplication.shared.delegate as! AppDelegate).session!)
            let message = MDCSnackbarMessage()
            message.text = "Unsubscribed from r/\(subreddit!.displayName)"
            MDCSnackbarManager.show(message)
        } else {
            let alrController = UIAlertController.init(title: "Subscribe to \(subreddit!.displayName)", message: nil, preferredStyle: .actionSheet)
            if (AccountController.isLoggedIn) {
                let somethingAction = UIAlertAction(title: "Add to sub list and subscribe", style: UIAlertActionStyle.default, handler: { (alert: UIAlertAction!) in
                    Subscriptions.subscribe(self.subreddit!.displayName, true, session: (UIApplication.shared.delegate as! AppDelegate).session!)
                    let message = MDCSnackbarMessage()
                    message.text = "Subscribed"
                    MDCSnackbarManager.show(message)
                })
                alrController.addAction(somethingAction)
            }
            
            let somethingAction = UIAlertAction(title: "Just add to sub list", style: UIAlertActionStyle.default, handler: { (alert: UIAlertAction!) in
                Subscriptions.subscribe(self.subreddit!.displayName, false, session: (UIApplication.shared.delegate as! AppDelegate).session!)
                let message = MDCSnackbarMessage()
                message.text = "Added r/\(self.subreddit!.displayName) to your sub list!"
                MDCSnackbarManager.show(message)
            })
            alrController.addAction(somethingAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (alert: UIAlertAction!) in print("cancel") })
            
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
        

        let attrs = [NSFontAttributeName : FontGenerator.boldFontOfSize(size: 20, submission: true)]
        var attributedString = NSMutableAttributedString(string: "\(subreddit.subscribers.delimiter)", attributes:attrs)
        var subt = NSMutableAttributedString(string: "\nSUBSCRIBERS")
        attributedString.append(subt)
        subscribers.attributedText = attributedString
        
        attributedString = NSMutableAttributedString(string: "\(subreddit.accountsActive.delimiter)", attributes:attrs)
        subt = NSMutableAttributedString(string: "\nHERE")
        attributedString.append(subt)
        here.attributedText = attributedString

        if (!subreddit.descriptionHtml.isEmpty()) {
            let html = subreddit.descriptionHtml.preprocessedHTMLStringBeforeNSAttributedStringParsing
            do {
                let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
                let font = FontGenerator.fontOfSize(size: 16, submission: false)
                let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: ColorUtil.accentColorForSub(sub: subreddit.displayName))
                contentInfo = CellContent.init(string: LinkParser.parse(attr2, ColorUtil.accentColorForSub(sub: subreddit.displayName)), width: setWidth - 24)
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
    var setWidth: CGFloat = 0

    override func updateConstraints() {
        super.updateConstraints()

        let metrics = ["topMargin": 0, "swidth": ((setWidth - 32) / 2), "bh": CGFloat(130 + textHeight), "dh": descHeight, "b": textHeight + 30, "w": setWidth]
        let views = ["submit": submit, "mods": mods, "back": back, "sort": sorting,"info": info, "subscribers": subscribers, "here": here] as [String: Any]


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

        constraintMain.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[sort]-(12)-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        constraintMain.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[theme]-(12)-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        constraintMain.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[mods]-(12)-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        
        constraintMain.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[subscribers(swidth)]-(8)-[here(swidth)]-(12)-|",options: NSLayoutFormatOptions(rawValue: 0),metrics: metrics,views: views))


        constraintMain.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[back(86)]-6-[subscribers(50)]-(8)-[submit(50)]-(2)-[mods(50)]-(2)-[sort(50)]-(8)-[info(dh)]-(4)-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        constraintMain.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[back(86)]-6-[here(50)]-(8)-[submit(50)]-(2)-[mods(50)]-(2)-[sort(50)]-(8)-[info(dh)]-(4)-|",
                                                                         options: NSLayoutFormatOptions(rawValue: 0),
                                                                         metrics: metrics,
                                                                         views: views))

        addConstraints(constraintMain)

    }

    func getEstHeight() -> CGFloat {
        return CGFloat(62) + ((contentInfo == nil) ? 0 : descHeight) + (50 * 6)
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

