//
//  SubredditThemeViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/20/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import MKColorPicker
import reddift
import UIKit

class SubredditThemeViewController: UITableViewController, ColorPickerViewDelegate {

    var subs: [String] = []
    var accentChosen: UIColor?
    var colorChosen: UIColor?
    var chosenButtons = [UIBarButtonItem]()
    var regularButtons = [UIBarButtonItem]()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if UIColor.isLightTheme && SettingValues.reduceColor {
                        if #available(iOS 13, *) {
                return .darkContent
            } else {
                return .default
            }

        } else {
            return .lightContent
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorStyle = .none

        self.tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")
        self.tableView.isEditing = true
        self.tableView.backgroundColor = UIColor.backgroundColor
        self.tableView.allowsSelectionDuringEditing = true
        self.tableView.allowsMultipleSelectionDuringEditing = true
        subs = Subscriptions.subreddits
        
        self.subs = self.subs.sorted {
            if UserDefaults.standard.colorForKey(key: "color+" + $0) != nil && UserDefaults.standard.colorForKey(key: "color+" + $1) == nil {
                return true
            } else {
                return $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
            }
        }

        tableView.reloadData()

        self.title = "Subreddit themes"

        let sync = UIButton.init(type: .custom)
        sync.setImage(UIImage(sfString: SFSymbol.arrow2Circlepath, overrideString: "sync")!.navIcon(), for: UIControl.State.normal)
        sync.addTarget(self, action: #selector(self.sync(_:)), for: UIControl.Event.touchUpInside)
        sync.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)

        let add = UIButton.init(type: .custom)
        add.setImage(UIImage(named: "palette")!.navIcon(), for: UIControl.State.normal)
        add.addTarget(self, action: #selector(self.add(_:)), for: UIControl.Event.touchUpInside)
        add.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let addB = UIBarButtonItem.init(customView: add)

        let delete = UIButton.init(type: .custom)
        delete.setImage(UIImage(named: "nocolors")!.navIcon(), for: UIControl.State.normal)
        delete.addTarget(self, action: #selector(self.remove(_:)), for: UIControl.Event.touchUpInside)
        delete.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let deleteB = UIBarButtonItem.init(customView: delete)

        let all = UIButton.init(type: .custom)
        all.setImage(UIImage(named: "selectall")!.navIcon(), for: UIControl.State.normal)
        all.addTarget(self, action: #selector(self.all(_:)), for: UIControl.Event.touchUpInside)
        all.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let allB = UIBarButtonItem.init(customView: all)

        regularButtons = [allB]
        chosenButtons = [deleteB, addB]
        
        self.navigationItem.rightBarButtonItems = regularButtons
        
        self.tableView.tableFooterView = UIView()
    }

    @objc public func all(_ selector: AnyObject) {
        for row in 0..<subs.count {
            tableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
        }
        self.navigationItem.setRightBarButtonItems(chosenButtons, animated: true)
    }
    
    @objc public func add(_ selector: AnyObject) {
        var selected: [String] = []
        if tableView.indexPathsForSelectedRows != nil {
            for i in tableView.indexPathsForSelectedRows! {
                selected.append(subs[i.row])
            }
            self.edit(selected, sender: selector as! UIButton)
        }
    }

    @objc public func remove(_ selector: AnyObject) {
        if tableView.indexPathsForSelectedRows != nil {
            for i in tableView.indexPathsForSelectedRows! {
                doDelete(subs[i.row])
            }
            self.subs = self.subs.sorted {
                if UserDefaults.standard.colorForKey(key: "color+" + $0) != nil && UserDefaults.standard.colorForKey(key: "color+" + $1) == nil {
                    return true
                } else {
                    return $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
                }
            }
            self.tableView.reloadData()
            self.navigationItem.rightBarButtonItems = regularButtons
        }
    }

    public static var changed = false

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    var alertController: UIAlertController?
    var count = 0

    @objc func sync(_ selector: AnyObject) { // TODO - Is this really needed anymore? We do it by default now
        let defaults = UserDefaults.standard
        alertController = UIAlertController(title: "Syncing colors...\n\n\n", message: nil, preferredStyle: .alert)

        let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.fontColor
        spinnerIndicator.startAnimating()

        alertController?.view.addSubview(spinnerIndicator)
        self.present(alertController!, animated: true, completion: nil)

        var toReturn: [String] = []
        defaults.set(true, forKey: "sc" + AccountController.currentName)
        defaults.synchronize()
        do {
            if !AccountController.isLoggedIn {
                try (UIApplication.shared.delegate as! AppDelegate).session!.getSubreddit(.default, paginator: Paginator(), completion: { (result) -> Void in
                    switch result {
                    case .failure:
                        print(result.error!)
                    case .success(let listing):
                        let subs = listing.children.compactMap({ $0 as? Subreddit })
                        for sub in subs {
                            if sub.keyColor.hexString() != "#FFFFFF" {
                                toReturn.append(sub.displayName)
                                let color = ColorUtil.getClosestColor(hex: sub.keyColor.hexString())
                                if UserDefaults.standard.colorForKey(key: "color+" + sub.displayName) == nil && color != .black {
                                    defaults.setColor(color: color, forKey: "color+" + sub.displayName)
                                    self.count += 1
                                }
                            }
                        }

                    }
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.complete()
                    })
                })

            } else {
                Subscriptions.getSubscriptionsFully(session: (UIApplication.shared.delegate as! AppDelegate).session!, completion: { (subs, multis) in
                    for sub in subs {
                        if sub.keyColor.hexString() != "#FFFFFF" {
                            toReturn.append(sub.displayName)
                            let color = ColorUtil.getClosestColor(hex: sub.keyColor.hexString())
                            if UserDefaults.standard.colorForKey(key: "color+" + sub.displayName) == nil && color.hexString() != "#000000" {
                                defaults.setColor(color: color, forKey: "color+" + sub.displayName)
                                self.count += 1
                            }
                        }
                    }
                    for m in multis {
                        toReturn.append("/m/" + m.displayName)
                        let color = (UIColor.init(hexString: m.keyColor))
                        if UserDefaults.standard.colorForKey(key: "color+" + m.displayName) == nil && color.hexString() != "#000000" {
                            defaults.setColor(color: color, forKey: "color+" + m.displayName)
                            self.count += 1
                        }
                    }

                    toReturn = toReturn.sorted {
                        $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
                    }
                    toReturn.insert("all", at: 0)
                    toReturn.insert("frontpage", at: 0)
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.complete()
                    })
                })
            }
        } catch {
            print(error)
            self.complete()
        }

    }

    func complete() {
        alertController!.dismiss(animated: true, completion: nil)
        BannerUtil.makeBanner(text: "\(count) subs colored", seconds: 5, context: self)
        count = 0
        self.subs = self.subs.sorted {
            if UserDefaults.standard.colorForKey(key: "color+" + $0) != nil && UserDefaults.standard.colorForKey(key: "color+" + $1) == nil {
                return true
            } else {
                return $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
            }
        }
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: – Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thing = subs[indexPath.row]
        var cell: SubredditCellView?
        let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
        c.setSubreddit(subreddit: thing, nav: nil)
        cell = c
        cell?.backgroundColor = UIColor.foregroundColor
        cell?.sideView.isHidden = UserDefaults.standard.colorForKey(key: "color+" + thing) == nil
        return cell!
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    var savedView = UIView()
    var selected = false
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !selected {
            self.navigationItem.setRightBarButtonItems(chosenButtons, animated: true)
            selected = true
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.indexPathsForSelectedRows == nil || tableView.indexPathsForSelectedRows!.isEmpty {
            selected = false
            self.navigationItem.setRightBarButtonItems(regularButtons, animated: true)
        }
    }

    var editSubs: [String] = []

    public func colorPickerView(_ colorPickerView: ColorPickerView, didSelectItemAt indexPath: IndexPath) {
        if isAccent {
            accentChosen = colorPickerView.colors[indexPath.row]
        } else {
            colorChosen = colorPickerView.colors[indexPath.row]
        }
    }

    func edit(_ sub: [String], sender: UIButton) {
        editSubs = sub
        
        if #available(iOS 14, *) {
            let vc = SubredditThemeEditViewController(subreddit: editSubs.count == 1 ? editSubs.first! : "Multiple subreddits", delegate: self)
            VCPresenter.presentModally(viewController: vc, self, CGSize(width: UIScreen.main.bounds.size.width * 0.85, height: 300))
        } else {
            let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

            isAccent = false
            let margin: CGFloat = 10.0
            let rect = CGRect(x: margin, y: margin, width: UIScreen.main.traitCollection.userInterfaceIdiom == .pad ? 314 - margin * 4.0: alertController.view.bounds.size.width - margin * 4.0, height: 150)
            let MKColorPicker = ColorPickerView.init(frame: rect)
            MKColorPicker.delegate = self
            MKColorPicker.colors = GMPalette.allColor()
            MKColorPicker.selectionStyle = .check
            MKColorPicker.scrollDirection = .vertical

            MKColorPicker.style = .circle

            alertController.view.addSubview(MKColorPicker)

            alertController.addAction(image: UIImage(named: "colors"), title: "Accent color", color: ColorUtil.baseAccent, style: .default) { _ in
                if self.colorChosen != nil {
                    for sub in self.editSubs {
                        ColorUtil.setColorForSub(sub: sub, color: self.colorChosen!)
                    }
                }
                self.pickAccent(sub, sender: sender)
            }

            alertController.addAction(image: nil, title: "Save", color: ColorUtil.baseAccent, style: .default) { _ in
                if self.colorChosen != nil {
                    for sub in self.editSubs {
                        ColorUtil.setColorForSub(sub: sub, color: self.colorChosen!)
                    }
                }
                self.tableView.reloadData()
                self.navigationItem.rightBarButtonItems = self.regularButtons
            }

            alertController.addCancelButton()
            alertController.modalPresentationStyle = .popover
            if let presenter = alertController.popoverPresentationController {
                presenter.sourceView = savedView
                presenter.sourceRect = savedView.bounds
            }

            present(alertController, animated: true, completion: nil)
        }
    }

    var isAccent = false
    func pickAccent(_ sub: [String], sender: UIButton) {
        isAccent = true
        let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

        let margin: CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: UIScreen.main.traitCollection.userInterfaceIdiom == .pad ? 314 - margin * 4.0: alertController.view.bounds.size.width - margin * 4.0, height: 150)
        let MKColorPicker = ColorPickerView.init(frame: rect)
        MKColorPicker.delegate = self
        MKColorPicker.colors = GMPalette.allColorAccent()
        MKColorPicker.selectionStyle = .check
        self.isAccent = true
        MKColorPicker.scrollDirection = .vertical

        MKColorPicker.style = .circle

        alertController.view.addSubview(MKColorPicker)

        alertController.addAction(image: UIImage(named: "palette"), title: "Primary color", color: ColorUtil.baseAccent, style: .default) { _ in
            if self.accentChosen != nil {
                for sub in self.editSubs {
                    ColorUtil.setAccentColorForSub(sub: sub, color: self.accentChosen!)
                }
            }
            self.edit(sub, sender: sender)
            self.tableView.reloadData()
        }

        alertController.addAction(image: nil, title: "Save", color: ColorUtil.baseAccent, style: .default) { _ in
            if self.accentChosen != nil {
                for sub in self.editSubs {
                    ColorUtil.setAccentColorForSub(sub: sub, color: self.accentChosen!)
                }
            }
            self.tableView.reloadData()
            self.navigationItem.rightBarButtonItems = self.regularButtons
        }

        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = savedView
            presenter.sourceRect = savedView.bounds
        }

        alertController.addCancelButton()

        present(alertController, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = UIColor.foregroundColor
    }

    func doDelete(_ sub: String) {
        UserDefaults.standard.removeObject(forKey: "color+" + sub)
        UserDefaults.standard.removeObject(forKey: "accent+" + sub)
        UserDefaults.standard.synchronize()
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            doDelete(subs[indexPath.row])
        }
    }

}

extension SubredditThemeViewController: SubredditThemeEditViewControllerDelegate {
    func didClear() -> Bool {
        for sub in self.editSubs {
            UserDefaults.standard.removeObject(forKey: "color+" + sub)
            UserDefaults.standard.removeObject(forKey: "accent+" + sub)
            UserDefaults.standard.synchronize()
        }
        return true
    }
    
    func didChangeColors(_ isAccent: Bool, color: UIColor) {
        if isAccent {
            for sub in self.editSubs {
                ColorUtil.setAccentColorForSub(sub: sub, color: color)
            }
        } else {
            for sub in self.editSubs {
                ColorUtil.setColorForSub(sub: sub, color: color)
            }
        }
        self.tableView.reloadData()
    }
}

public enum ToastPosition {
    case top
    case center
    case bottom
}

//
//  Toast.swift
//  Toast-Swift
//
//  Copyright (c) 2015 Charles Scalesse.
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be included
//  in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

/**
 Toast is a Swift extension that adds toast notifications to the `UIView` object class.
 It is intended to be simple, lightweight, and easy to use. Most toast notifications
 can be triggered with a single line of code.
 
 The `makeToast` methods create a new view and then display it as toast.
 
 The `showToast` methods display any view as toast.
 
 */
public extension UIView {

    /**
     Keys used for associated objects.
     */
    private struct ToastKeys {
        static var Timer = "CSToastTimerKey"
        static var Duration = "CSToastDurationKey"
        static var Position = "CSToastPositionKey"
        static var Completion = "CSToastCompletionKey"
        static var ActiveToast = "CSToastActiveToastKey"
        static var ActivityView = "CSToastActivityViewKey"
        static var Queue = "CSToastQueueKey"
    }

    /**
     Swift closures can't be directly associated with objects via the
     Objective-C runtime, so the (ugly) solution is to wrap them in a
     class that can be used with associated objects.
     */
    private class ToastCompletionWrapper {
        var completion: ((Bool) -> Void)?

        init(_ completion: ((Bool) -> Void)?) {
            self.completion = completion
        }
    }

    private enum ToastError: Error {
        case insufficientData
    }

    private var queue: NSMutableArray {
        if let queue = objc_getAssociatedObject(self, &ToastKeys.Queue) as? NSMutableArray {
            return queue
        } else {
            let queue = NSMutableArray()
            objc_setAssociatedObject(self, &ToastKeys.Queue, queue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return queue
        }
    }

    // MARK: - Make Toast Methods

    /**
     Creates and presents a new toast view with a message and displays it with the
     default duration and position. Styled using the shared style.
     
     @param message The message to be displayed
     */
    func makeToast(_ message: String) {
        self.makeToast(message, duration: ToastManager.shared.duration, position: ToastManager.shared.position)
    }

    /**
     Creates and presents a new toast view with a message. Duration and position
     can be set explicitly. Styled using the shared style.
     
     @param message The message to be displayed
     @param duration The toast duration
     @param position The toast's position
     */
    func makeToast(_ message: String, duration: TimeInterval, position: ToastPosition) {
        self.makeToast(message, duration: duration, position: position, style: nil)
    }

    /**
     Creates and presents a new toast view with a message. Duration and position
     can be set explicitly. Styled using the shared style.
     
     @param message The message to be displayed
     @param duration The toast duration
     @param position The toast's center point
     */
    func makeToast(_ message: String, duration: TimeInterval, position: CGPoint) {
        self.makeToast(message, duration: duration, position: position, style: nil)
    }

    /**
     Creates and presents a new toast view with a message. Duration, position, and
     style can be set explicitly.
     
     @param message The message to be displayed
     @param duration The toast duration
     @param position The toast's position
     @param style The style. The shared style will be used when nil
     */
    func makeToast(_ message: String, duration: TimeInterval, position: ToastPosition, style: ToastStyle?) {
        self.makeToast(message, duration: duration, position: position, title: nil, image: nil, style: style, completion: nil)
    }

    /**
     Creates and presents a new toast view with a message. Duration, position, and
     style can be set explicitly.
     
     @param message The message to be displayed
     @param duration The toast duration
     @param position The toast's center point
     @param style The style. The shared style will be used when nil
     */
    func makeToast(_ message: String, duration: TimeInterval, position: CGPoint, style: ToastStyle?) {
        self.makeToast(message, duration: duration, position: position, title: nil, image: nil, style: style, completion: nil)
    }

    /**
     Creates and presents a new toast view with a message, title, and image. Duration,
     position, and style can be set explicitly. The completion closure executes when the
     toast completes presentation. `didTap` will be `true` if the toast view was dismissed
     from a tap.
     
     @param message The message to be displayed
     @param duration The toast duration
     @param position The toast's position
     @param title The title
     @param image The image
     @param style The style. The shared style will be used when nil
     @param completion The completion closure, executed after the toast view disappears.
     didTap will be `true` if the toast view was dismissed from a tap.
     */
    func makeToast(_ message: String?, duration: TimeInterval, position: ToastPosition, title: String?, image: UIImage?, style: ToastStyle?, completion: ((_ didTap: Bool) -> Void)?) {
        var toastStyle = ToastManager.shared.style
        if let style = style {
            toastStyle = style
        }

        do {
            let toast = try self.toastViewForMessage(message, title: title, image: image, style: toastStyle)
            self.showToast(toast, duration: duration, position: position, completion: completion)
        } catch ToastError.insufficientData {
            print("Error: message, title, and image are all nil")
        } catch {
        }
    }

    /**
     Creates and presents a new toast view with a message, title, and image. Duration,
     position, and style can be set explicitly. The completion closure executes when the
     toast completes presentation. `didTap` will be `true` if the toast view was dismissed
     from a tap.
     
     @param message The message to be displayed
     @param duration The toast duration
     @param position The toast's center point
     @param title The title
     @param image The image
     @param style The style. The shared style will be used when nil
     @param completion The completion closure, executed after the toast view disappears.
     didTap will be `true` if the toast view was dismissed from a tap.
     */
    func makeToast(_ message: String?, duration: TimeInterval, position: CGPoint, title: String?, image: UIImage?, style: ToastStyle?, completion: ((_ didTap: Bool) -> Void)?) {
        var toastStyle = ToastManager.shared.style
        if let style = style {
            toastStyle = style
        }

        do {
            let toast = try self.toastViewForMessage(message, title: title, image: image, style: toastStyle)
            self.showToast(toast, duration: duration, position: position, completion: completion)
        } catch ToastError.insufficientData {
            print("Error: message, title, and image cannot all be nil")
        } catch {
        }
    }

    // MARK: - Show Toast Methods

    /**
     Displays any view as toast using the default duration and position.
     
     @param toast The view to be displayed as toast
     */
    func showToast(_ toast: UIView) {
        self.showToast(toast, duration: ToastManager.shared.duration, position: ToastManager.shared.position, completion: nil)
    }

    /**
     Displays any view as toast at a provided position and duration. The completion closure
     executes when the toast view completes. `didTap` will be `true` if the toast view was
     dismissed from a tap.
     
     @param toast The view to be displayed as toast
     @param duration The notification duration
     @param position The toast's position
     @param completion The completion block, executed after the toast view disappears.
     didTap will be `true` if the toast view was dismissed from a tap.
     */
    func showToast(_ toast: UIView, duration: TimeInterval, position: ToastPosition, completion: ((_ didTap: Bool) -> Void)?) {
        let point = self.centerPointForPosition(position, toast: toast)
        self.showToast(toast, duration: duration, position: point, completion: completion)
    }

    /**
     Displays any view as toast at a provided position and duration. The completion closure
     executes when the toast view completes. `didTap` will be `true` if the toast view was
     dismissed from a tap.
     
     @param toast The view to be displayed as toast
     @param duration The notification duration
     @param position The toast's center point
     @param completion The completion block, executed after the toast view disappears.
     didTap will be `true` if the toast view was dismissed from a tap.
     */
    func showToast(_ toast: UIView, duration: TimeInterval, position: CGPoint, completion: ((_ didTap: Bool) -> Void)?) {
        objc_setAssociatedObject(toast, &ToastKeys.Completion, ToastCompletionWrapper(completion), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        if objc_getAssociatedObject(self, &ToastKeys.ActiveToast) as? UIView != nil, ToastManager.shared.queueEnabled {
            objc_setAssociatedObject(toast, &ToastKeys.Duration, NSNumber(value: duration), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(toast, &ToastKeys.Position, NSValue(cgPoint: position), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

            self.queue.add(toast)
        } else {
            self.showToast(toast, duration: duration, position: position)
        }
    }

    // MARK: - Activity Methods

    /**
     Creates and displays a new toast activity indicator view at a specified position.
     
     @warning Only one toast activity indicator view can be presented per superview. Subsequent
     calls to `makeToastActivity(position:)` will be ignored until `hideToastActivity()` is called.
     
     @warning `makeToastActivity(position:)` works independently of the `showToast` methods. Toast
     activity views can be presented and dismissed while toast views are being displayed.
     `makeToastActivity(position:)` has no effect on the queueing behavior of the `showToast` methods.
     
     @param position The toast's position
     */
    func makeToastActivity(_ position: ToastPosition) {
        // sanity
        if objc_getAssociatedObject(self, &ToastKeys.ActivityView) as? UIView != nil {
            return
        }

        let toast = self.createToastActivityView()
        let point = self.centerPointForPosition(position, toast: toast)
        self.makeToastActivity(toast, position: point)
    }

    /**
     Creates and displays a new toast activity indicator view at a specified position.
     
     @warning Only one toast activity indicator view can be presented per superview. Subsequent
     calls to `makeToastActivity(position:)` will be ignored until `hideToastActivity()` is called.
     
     @warning `makeToastActivity(position:)` works independently of the `showToast` methods. Toast
     activity views can be presented and dismissed while toast views are being displayed.
     `makeToastActivity(position:)` has no effect on the queueing behavior of the `showToast` methods.
     
     @param position The toast's center point
     */
    func makeToastActivity(_ position: CGPoint) {
        // sanity
        if objc_getAssociatedObject(self, &ToastKeys.ActivityView) as? UIView != nil {
            return
        }

        let toast = self.createToastActivityView()
        self.makeToastActivity(toast, position: position)
    }

    /**
     Dismisses the active toast activity indicator view.
     */
    func hideToastActivity() {
        if let toast = objc_getAssociatedObject(self, &ToastKeys.ActivityView) as? UIView {
            UIView.animate(withDuration: ToastManager.shared.style.fadeDuration, delay: 0.0, options: [.curveEaseIn, .beginFromCurrentState], animations: { () -> Void in
                toast.alpha = 0.0
            }, completion: { (_: Bool) -> Void in
                toast.removeFromSuperview()
                objc_setAssociatedObject(self, &ToastKeys.ActivityView, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            })
        }
    }

    // MARK: - Private Activity Methods

    private func makeToastActivity(_ toast: UIView, position: CGPoint) {
        toast.alpha = 0.0
        toast.center = position

        objc_setAssociatedObject(self, &ToastKeys.ActivityView, toast, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        self.addSubview(toast)

        UIView.animate(withDuration: ToastManager.shared.style.fadeDuration, delay: 0.0, options: .curveEaseOut, animations: { () -> Void in
            toast.alpha = 1.0
        }, completion: nil)
    }

    private func createToastActivityView() -> UIView {
        let style = ToastManager.shared.style

        let activityView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: style.activitySize.width, height: style.activitySize.height))
        activityView.backgroundColor = style.backgroundColor
        activityView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        activityView.layer.cornerRadius = style.cornerRadius

        if style.displayShadow {
            activityView.layer.shadowColor = style.shadowColor.cgColor
            activityView.layer.shadowOpacity = style.shadowOpacity
            activityView.layer.shadowRadius = style.shadowRadius
            activityView.layer.shadowOffset = style.shadowOffset
        }

        let activityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicatorView.center = CGPoint(x: activityView.bounds.size.width / 2.0, y: activityView.bounds.size.height / 2.0)
        activityView.addSubview(activityIndicatorView)
        activityIndicatorView.startAnimating()

        return activityView
    }

    // MARK: - Private Show/Hide Methods

    private func showToast(_ toast: UIView, duration: TimeInterval, position: CGPoint) {
        toast.center = position
        toast.alpha = 0.0

        if ToastManager.shared.tapToDismissEnabled {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(UIView.handleToastTapped(_:)))
            toast.addGestureRecognizer(recognizer)
            toast.isUserInteractionEnabled = true
            toast.isExclusiveTouch = true
        }

        objc_setAssociatedObject(self, &ToastKeys.ActiveToast, toast, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        self.addSubview(toast)

        UIView.animate(withDuration: ToastManager.shared.style.fadeDuration, delay: 0.0, options: [.curveEaseOut, .allowUserInteraction], animations: { () -> Void in
            toast.alpha = 1.0
        }, completion: { _ in
            let timer = Timer(timeInterval: duration, target: self, selector: #selector(UIView.toastTimerDidFinish(_:)), userInfo: toast, repeats: false)
            RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
            objc_setAssociatedObject(toast, &ToastKeys.Timer, timer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        })
    }

    private func hideToast(_ toast: UIView) {
        self.hideToast(toast, fromTap: false)
    }

    private func hideToast(_ toast: UIView, fromTap: Bool) {

        UIView.animate(withDuration: ToastManager.shared.style.fadeDuration, delay: 0.0, options: [.curveEaseIn, .beginFromCurrentState], animations: { () -> Void in
            toast.alpha = 0.0
        }, completion: { _ in
            toast.removeFromSuperview()

            objc_setAssociatedObject(self, &ToastKeys.ActiveToast, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

            if let wrapper = objc_getAssociatedObject(toast, &ToastKeys.Completion) as? ToastCompletionWrapper, let completion = wrapper.completion {
                completion(fromTap)
            }

            if let nextToast = self.queue.firstObject as? UIView, let duration = objc_getAssociatedObject(nextToast, &ToastKeys.Duration) as? NSNumber, let position = objc_getAssociatedObject(nextToast, &ToastKeys.Position) as? NSValue {
                self.queue.removeObject(at: 0)
                self.showToast(nextToast, duration: duration.doubleValue, position: position.cgPointValue)
            }
        })
    }

    // MARK: - Events

    @objc func handleToastTapped(_ recognizer: UITapGestureRecognizer) {
        if let toast = recognizer.view, let timer = objc_getAssociatedObject(toast, &ToastKeys.Timer) as? Timer {
            timer.invalidate()
            self.hideToast(toast, fromTap: true)
        }
    }

    @objc func toastTimerDidFinish(_ timer: Timer) {
        if let toast = timer.userInfo as? UIView {
            self.hideToast(toast)
        }
    }

    // MARK: - Toast Construction

    /**
     Creates a new toast view with any combination of message, title, and image.
     The look and feel is configured via the style. Unlike the `makeToast` methods,
     this method does not present the toast view automatically. One of the `showToast`
     methods must be used to present the resulting view.
     
     @warning if message, title, and image are all nil, this method will throw
     `ToastError.InsufficientData`
     
     @param message The message to be displayed
     @param title The title
     @param image The image
     @param style The style. The shared style will be used when nil
     @throws `ToastError.InsufficientData` when message, title, and image are all nil
     @return The newly created toast view
     */
    func toastViewForMessage(_ message: String?, title: String?, image: UIImage?, style: ToastStyle) throws -> UIView {
        // sanity
        if message == nil && title == nil && image == nil {
            throw ToastError.insufficientData
        }

        var messageLabel: UILabel?
        var titleLabel: UILabel?
        var imageView: UIImageView?

        let wrapperView = UIView()
        wrapperView.backgroundColor = style.backgroundColor
        wrapperView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        wrapperView.layer.cornerRadius = style.cornerRadius

        if style.displayShadow {
            wrapperView.layer.shadowColor = UIColor.black.cgColor
            wrapperView.layer.shadowOpacity = style.shadowOpacity
            wrapperView.layer.shadowRadius = style.shadowRadius
            wrapperView.layer.shadowOffset = style.shadowOffset
        }

        if let image = image {
            imageView = UIImageView(image: image)
            imageView?.contentMode = .scaleAspectFit
            imageView?.frame = CGRect(x: style.horizontalPadding, y: style.verticalPadding, width: style.imageSize.width, height: style.imageSize.height)
        }

        var imageRect = CGRect.zero

        if let imageView = imageView {
            imageRect.origin.x = style.horizontalPadding
            imageRect.origin.y = style.verticalPadding
            imageRect.size.width = imageView.bounds.size.width
            imageRect.size.height = imageView.bounds.size.height
        }

        if let title = title {
            titleLabel = UILabel()
            titleLabel?.numberOfLines = style.titleNumberOfLines
            titleLabel?.font = style.titleFont
            titleLabel?.textAlignment = style.titleAlignment
            titleLabel?.lineBreakMode = .byTruncatingTail
            titleLabel?.textColor = style.titleColor
            titleLabel?.backgroundColor = UIColor.clear
            titleLabel?.text = title

            //     let maxTitleSize = CGSize(width: (self.bounds.size.width * style.maxWidthPercentage) - imageRect.size.width, height: self.bounds.size.height * style.maxHeightPercentage)
            //  let titleSize = titleLabel?.sizeThatFits(maxTitleSize)
            //  if let titleSize = titleSize {
            //       titleLabel?.frame = CGRect(x: 0.0, y: 0.0, width: titleSize.width, height: titleSize.height)
            //   }
        }

        if let message = message {
            messageLabel = UILabel()
            messageLabel?.text = message
            messageLabel?.numberOfLines = style.messageNumberOfLines
            messageLabel?.font = style.messageFont
            messageLabel?.textAlignment = style.messageAlignment
            messageLabel?.lineBreakMode = .byTruncatingTail
            messageLabel?.textColor = style.messageColor
            messageLabel?.backgroundColor = UIColor.clear

            //  let maxMessageSize = CGSize(width: (self.bounds.size.width * style.maxWidthPercentage) - imageRect.size.width, height: self.bounds.size.height * style.maxHeightPercentage)
            //  let messageSize = messageLabel?.sizeThatFits(maxMessageSize)
            //  if let messageSize = messageSize {
            ////      let actualWidth = min(messageSize.width, maxMessageSize.width)
            //     let actualHeight = min(messageSize.height, maxMessageSize.height)
            //     messageLabel?.frame = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
            // }
        }

        var titleRect = CGRect.zero

        if let titleLabel = titleLabel {
            titleRect.origin.x = imageRect.origin.x + imageRect.size.width + style.horizontalPadding
            titleRect.origin.y = style.verticalPadding
            titleRect.size.width = titleLabel.bounds.size.width
            titleRect.size.height = titleLabel.bounds.size.height
        }

        var messageRect = CGRect.zero

        if let messageLabel = messageLabel {
            messageRect.origin.x = imageRect.origin.x + imageRect.size.width + style.horizontalPadding
            messageRect.origin.y = titleRect.origin.y + titleRect.size.height + style.verticalPadding
            messageRect.size.width = messageLabel.bounds.size.width
            messageRect.size.height = messageLabel.bounds.size.height
        }

        let longerWidth = max(titleRect.size.width, messageRect.size.width)
        let longerX = max(titleRect.origin.x, messageRect.origin.x)
        let wrapperWidth = max((imageRect.size.width + (style.horizontalPadding * 2.0)), (longerX + longerWidth + style.horizontalPadding))
        let wrapperHeight = max((messageRect.origin.y + messageRect.size.height + style.verticalPadding), (imageRect.size.height + (style.verticalPadding * 2.0)))

        wrapperView.frame = CGRect(x: 0.0, y: 0.0, width: wrapperWidth, height: wrapperHeight)

        if let titleLabel = titleLabel {
            titleLabel.frame = titleRect
            wrapperView.addSubview(titleLabel)
        }

        if let messageLabel = messageLabel {
            messageLabel.frame = messageRect
            wrapperView.addSubview(messageLabel)
        }

        if let imageView = imageView {
            wrapperView.addSubview(imageView)
        }

        return wrapperView
    }

    // MARK: - Helpers
    private func centerPointForPosition(_ position: ToastPosition, toast: UIView) -> CGPoint {
        let padding: CGFloat = ToastManager.shared.style.verticalPadding

        switch position {
        case .top:
            return CGPoint(x: self.bounds.size.width / 2.0, y: (toast.frame.size.height / 2.0) + padding)
        case .center:
            return CGPoint(x: self.bounds.size.width / 2.0, y: self.bounds.size.height / 2.0)
        case .bottom:
            return CGPoint(x: self.bounds.size.width / 2.0, y: (self.bounds.size.height - (toast.frame.size.height / 2.0)) - padding)
        }
    }
}

// MARK: - Toast Style
/**
 `ToastStyle` instances define the look and feel for toast views created via the
 `makeToast` methods as well for toast views created directly with
 `toastViewForMessage(message:title:image:style:)`.
 @warning `ToastStyle` offers relatively simple styling options for the default
 toast view. If you require a toast view with more complex UI, it probably makes more
 sense to create your own custom UIView subclass and present it with the `showToast`
 methods.
 */
public struct ToastStyle {

    public init() {
    }

    /**
     The background color. Default is `UIColor.blackColor()` at 80% opacity.
     */
    public var backgroundColor = UIColor.black.withAlphaComponent(0.8)

    /**
     The title color. Default is `UIColor.whiteColor()`.
     */
    public var titleColor = UIColor.white

    /**
     The message color. Default is `UIColor.whiteColor()`.
     */
    public var messageColor = UIColor.white

    /**
     A percentage value from 0.0 to 1.0, representing the maximum width of the toast
     view relative to it's superview. Default is 0.8 (80% of the superview's width).
     */
    public var maxWidthPercentage: CGFloat = 0.8 {
        didSet {
            maxWidthPercentage = max(min(maxWidthPercentage, 1.0), 0.0)
        }
    }

    /**
     A percentage value from 0.0 to 1.0, representing the maximum height of the toast
     view relative to it's superview. Default is 0.8 (80% of the superview's height).
     */
    public var maxHeightPercentage: CGFloat = 0.8 {
        didSet {
            maxHeightPercentage = max(min(maxHeightPercentage, 1.0), 0.0)
        }
    }

    /**
     The spacing from the horizontal edge of the toast view to the content. When an image
     is present, this is also used as the padding between the image and the text.
     Default is 10.0.
     */
    public var horizontalPadding: CGFloat = 10.0

    /**
     The spacing from the vertical edge of the toast view to the content. When a title
     is present, this is also used as the padding between the title and the message.
     Default is 10.0.
     */
    public var verticalPadding: CGFloat = 10.0

    /**
     The corner radius. Default is 10.0.
     */
    public var cornerRadius: CGFloat = 10.0

    /**
     The title font. Default is `UIFont.boldSystemFontOfSize(16.0)`.
     */
    public var titleFont = UIFont.boldSystemFont(ofSize: 16.0)

    /**
     The message font. Default is `UIFont.systemFontOfSize(16.0)`.
     */
    public var messageFont = UIFont.systemFont(ofSize: 16.0)

    /**
     The title text alignment. Default is `NSTextAlignment.Left`.
     */
    public var titleAlignment = NSTextAlignment.left

    /**
     The message text alignment. Default is `NSTextAlignment.Left`.
     */
    public var messageAlignment = NSTextAlignment.left

    /**
     The maximum number of lines for the title. The default is 0 (no limit).
     */
    public var titleNumberOfLines = 0

    /**
     The maximum number of lines for the message. The default is 0 (no limit).
     */
    public var messageNumberOfLines = 0

    /**
     Enable or disable a shadow on the toast view. Default is `false`.
     */
    public var displayShadow = false

    /**
     The shadow color. Default is `UIColor.blackColor()`.
     */
    public var shadowColor = UIColor.black

    /**
     A value from 0.0 to 1.0, representing the opacity of the shadow.
     Default is 0.8 (80% opacity).
     */
    public var shadowOpacity: Float = 0.8 {
        didSet {
            shadowOpacity = max(min(shadowOpacity, 1.0), 0.0)
        }
    }

    /**
     The shadow radius. Default is 6.0.
     */
    public var shadowRadius: CGFloat = 6.0

    /**
     The shadow offset. The default is 4 x 4.
     */
    public var shadowOffset = CGSize(width: 4.0, height: 4.0)

    /**
     The image size. The default is 80 x 80.
     */
    public var imageSize = CGSize(width: 80.0, height: 80.0)

    /**
     The size of the toast activity view when `makeToastActivity(position:)` is called.
     Default is 100 x 100.
     */
    public var activitySize = CGSize(width: 100.0, height: 100.0)

    /**
     The fade in/out animation duration. Default is 0.2.
     */
    public var fadeDuration: TimeInterval = 0.2

}

// MARK: - Toast Manager
/**
 `ToastManager` provides general configuration options for all toast
 notifications. Backed by a singleton instance.
 */
public class ToastManager {

    /**
     The `ToastManager` singleton instance.
     */
    public static let shared = ToastManager()

    /**
     The shared style. Used whenever toastViewForMessage(message:title:image:style:) is called
     with with a nil style.
     */
    public var style = ToastStyle()

    /**
     Enables or disables tap to dismiss on toast views. Default is `true`.
     */
    public var tapToDismissEnabled = true

    /**
     Enables or disables queueing behavior for toast views. When `true`,
     toast views will appear one after the other. When `false`, multiple toast
     views will appear at the same time (potentially overlapping depending
     on their positions). This has no effect on the toast activity view,
     which operates independently of normal toast views. Default is `true`.
     */
    public var queueEnabled = true

    /**
     The default duration. Used for the `makeToast` and
     `showToast` methods that don't require an explicit duration.
     Default is 3.0.
     */
    public var duration: TimeInterval = 3.0

    /**
     Sets the default position. Used for the `makeToast` and
     `showToast` methods that don't require an explicit position.
     Default is `ToastPosition.Bottom`.
     */
    public var position = ToastPosition.bottom

}
