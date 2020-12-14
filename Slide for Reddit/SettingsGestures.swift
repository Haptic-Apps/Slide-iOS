//
//  SettingsGestures.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/22/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import UIKit

class SettingsGestures: BubbleSettingTableViewController {
    var disableBannerCell: UITableViewCell = InsetCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "banner")
    var disableBanner = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var forceTouchSubmissionCell: UITableViewCell = InsetCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "3dsubmission")

    var commentGesturesCell: UITableViewCell = InsetCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "comments")

    var submissionGesturesCell: UITableViewCell = InsetCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "submission")

    var doubleTapActionCell: UITableViewCell = InsetCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "dtap")

    var doubleTapSubActionCell: UITableViewCell = InsetCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "dtaps")
    
    var forceTouchActionCell: UITableViewCell = InsetCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "3dcomment")

    var sideShortcutActionCell: UITableViewCell = InsetCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "side")

    var canForceTouch = false

    var commentCell = InsetCell()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCells()
    }
    
    @objc func switchIsChanged(_ changed: UISwitch) {
        if changed == disableBanner {
            SettingValues.disableBanner = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_disableBanner)
            SubredditReorderViewController.changed = true
        }

        UserDefaults.standard.synchronize()
        updateCells()
    }
    
    func showCommentGesturesMenu() {
        let alertController = DragDownAlertMenu(title: "Comment gesture mode", subtitle: "Full gestures mode will require two fingers to swipe between pages", icon: nil)
        
        let selected = UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)

        for item in SettingValues.CellGestureMode.cases {
            alertController.addAction(title: item.description(), icon: item == SettingValues.commentGesturesMode ? selected : UIImage()) {
                UserDefaults.standard.set(item.rawValue, forKey: SettingValues.pref_commentGesturesMode)
                SettingValues.commentGesturesMode = item
                UserDefaults.standard.synchronize()
                self.commentGesturesCell.detailTextLabel?.text = SettingValues.commentGesturesMode.description()
                self.updateCells()
                SplitMainViewController.needsReTheme = true
                MainViewController.needsReTheme = true
            }
        }
        alertController.show(self)
    }

    func showSubmissionGesturesMenu() {
        let alertController = DragDownAlertMenu(title: "Submission gesture mode", subtitle: "Full gestures mode will require two fingers to swipe between pages", icon: nil)
        
        let selected = UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)

        for item in SettingValues.CellGestureMode.cases {
            alertController.addAction(title: item.description(), icon: item == SettingValues.submissionGestureMode ? selected : UIImage()) {
                UserDefaults.standard.set(item.rawValue, forKey: SettingValues.pref_submissionGesturesMode)
                SettingValues.submissionGestureMode = item
                UserDefaults.standard.synchronize()
                self.submissionGesturesCell.detailTextLabel?.text = SettingValues.submissionGestureMode.description()
                self.updateCells()
                SplitMainViewController.needsReTheme = true
                MainViewController.needsReTheme = true
            }
        }
        alertController.show(self)
    }

    func showShortcutActionsMenu() {
        let alertController = DragDownAlertMenu(title: "Edge swipe gesture mode", subtitle: "This setting changes the edge swipe gesture of the main subreddit screen", icon: nil)
        
        for item in SettingValues.SideGesturesMode.cases {
            alertController.addAction(title: item.description(), icon: UIImage(named: item.getPhoto())!.menuIcon()) {
                UserDefaults.standard.set(item.rawValue, forKey: SettingValues.pref_sideGesture)
                SettingValues.sideGesture = item
                UserDefaults.standard.synchronize()
                self.sideShortcutActionCell.detailTextLabel?.text = SettingValues.sideGesture.description()
                self.updateCells()
            }
        }
        alertController.show(self)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 && indexPath.section == 1 {
            showCommentGesturesMenu()
            return
        }

        if indexPath.row == 0 && indexPath.section == 0 {
            showSubmissionGesturesMenu()
            return
        }

        if indexPath.row == 3 && indexPath.section == 0 {
            showActionSub(cell: doubleTapSubActionCell)
            return
        } else if indexPath.row == 4 && indexPath.section == 0 {
            showActionSub(cell: forceTouchSubmissionCell)
            return
        }
        
        if indexPath.section != 1 {
            return
        }
        
        if indexPath.row == 2 {
            showAction(cell: doubleTapActionCell)
        } else if indexPath.row == 3 {
            showAction(cell: forceTouchActionCell)
        }
    }
    
    func showAction(cell: UITableViewCell) {
        let type = cell.textLabel?.text ?? ""

        let alertController = DragDownAlertMenu(title: "Select a comment gesture", subtitle: type, icon: nil)
        for action in cell == self.forceTouchActionCell ? SettingValues.CommentAction.cases3D : SettingValues.CommentAction.cases {
            alertController.addAction(title: action.getTitle(), icon: UIImage(named: action.getPhoto())!.menuIcon()) {
                if cell == self.forceTouchActionCell {
                    SettingValues.commentActionForceTouch = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_commentActionForceTouch)
                } else {
                    SettingValues.commentActionDoubleTap = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_commentActionDoubleTap)
                }
                
                UserDefaults.standard.synchronize()
                self.updateCells()
            }
        }
        alertController.show(self)
    }
    
    func showActionSub(cell: UITableViewCell) {
        let alertController = DragDownAlertMenu(title: "Select a submission gesture", subtitle: cell.textLabel?.text ?? "", icon: nil)
        
        for action in SettingValues.SubmissionAction.cases {
            alertController.addAction(title: action == .NONE && cell == forceTouchSubmissionCell ? "Peek content" : action.getTitle(), icon: action == .NONE && cell == forceTouchSubmissionCell ? UIImage(named: "fullscreen")!.menuIcon() : UIImage(named: action.getPhoto())!.menuIcon()) {
                if cell == self.doubleTapSubActionCell {
                    SettingValues.submissionActionDoubleTap = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_submissionActionDoubleTap)
                } else if cell == self.forceTouchSubmissionCell {
                    SettingValues.submissionActionForceTouch = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_submissionActionForceTouch)
                }
                
                SubredditReorderViewController.changed = true
                UserDefaults.standard.synchronize()
                self.updateCells()
            }
        }
        VCPresenter.presentAlert(alertController, parentVC: self)
    }

    public func createCell(_ cell: UITableViewCell, _ switchV: UISwitch? = nil, isOn: Bool, text: String) {
        cell.textLabel?.text = text
        cell.textLabel?.textColor = ColorUtil.theme.fontColor
        cell.backgroundColor = ColorUtil.theme.foregroundColor
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        if let s = switchV {
            s.isOn = isOn
            s.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
            cell.accessoryView = s
        }
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
    }
    
    override func loadView() {
        canForceTouch = (UIApplication.shared.keyWindow?.rootViewController?.traitCollection.forceTouchCapability ?? .unknown) == .available
        super.loadView()
        self.view.backgroundColor = ColorUtil.theme.backgroundColor
        // set the title
        self.title = "Gestures"
        self.headers = ["Submissions", "Comments", "Main view edge shortcut"]
        createCell(submissionGesturesCell, nil, isOn: false, text: "Submission gestures mode")
        self.submissionGesturesCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.submissionGesturesCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.submissionGesturesCell.detailTextLabel?.numberOfLines = 0
        self.submissionGesturesCell.detailTextLabel?.text = SettingValues.submissionGestureMode.description()
        self.submissionGesturesCell.contentView.backgroundColor = ColorUtil.theme.foregroundColor
        self.submissionGesturesCell.accessoryType = .disclosureIndicator

        createCell(disableBannerCell, disableBanner, isOn: SettingValues.disableBanner, text: "Open comments from banner image")
        self.disableBannerCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.disableBannerCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.disableBannerCell.detailTextLabel?.numberOfLines = 0
        self.disableBannerCell.detailTextLabel?.text = "Enabling this will open comments when clicking on the submission banner image"
        self.disableBannerCell.contentView.backgroundColor = ColorUtil.theme.foregroundColor

        createCell(commentGesturesCell, nil, isOn: false, text: "Comment gestures mode")
        self.commentGesturesCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.commentGesturesCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.commentGesturesCell.detailTextLabel?.numberOfLines = 0
        self.commentGesturesCell.detailTextLabel?.text = SettingValues.commentGesturesMode.description()
        self.commentGesturesCell.contentView.backgroundColor = ColorUtil.theme.foregroundColor
        self.commentGesturesCell.accessoryType = .disclosureIndicator
        
        self.tableView.register(GesturePreviewCell.classForCoder(), forCellReuseIdentifier: "submissiongesturepreview")
        self.tableView.register(GesturePreviewCell.classForCoder(), forCellReuseIdentifier: "commentgesturepreview")

        updateCells()
        self.tableView.tableFooterView = UIView()
        
        commentCell.contentView.backgroundColor = ColorUtil.theme.foregroundColor
        let label = UILabel()
        for view in commentCell.contentView.subviews {
            view.removeFromSuperview()
        }
        commentCell.contentView.addSubview(label)
        label.edgeAnchors /==/ commentCell.edgeAnchors + 8
        label.attributedText = getText()
        label.numberOfLines = 0
        label.sizeToFit()
        label.setBorder(border: .left, weight: 4, color: GMColor.red500Color())
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func getText() -> NSAttributedString {
        let color = ColorUtil.theme.fontColor
        
        let boldFont = FontGenerator.boldFontOfSize(size: 12, submission: false)
        
        let scoreString = NSMutableAttributedString(string: "[score hidden]", attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 12, submission: false), NSAttributedString.Key.foregroundColor: color])
        
        let endString = NSMutableAttributedString(string: "  •  3d", attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 12, submission: false), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        
        let authorStringNoFlair = NSMutableAttributedString(string: "u/ccrama\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: false), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        
        let infoString = NSMutableAttributedString(string: "")
            infoString.append(authorStringNoFlair)
        
        infoString.append(NSAttributedString(string: "  •  ", attributes: [NSAttributedString.Key.font: boldFont, NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor]))
        infoString.append(scoreString)
        infoString.append(endString)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.5
        infoString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: infoString.length))
        
        let newTitle = NSMutableAttributedString(attributedString: infoString)
            newTitle.append(NSAttributedString.init(string: "\n\n", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 5)]))
        newTitle.append(TextDisplayStackView.createAttributedChunk(baseHTML: "<p>Swipe here to test the gestures out!</p>", fontSize: 16, submission: false, accentColor: ColorUtil.baseAccent, fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil))

        return newTitle
    }
    
    func updateCells() {
        createCell(doubleTapActionCell, nil, isOn: false, text: "Double tap comment action")
        createCell(forceTouchActionCell, nil, isOn: false, text: "3D-Touch comment action")
        createCell(doubleTapSubActionCell, nil, isOn: false, text: "Double tap submission action")
        createCell(forceTouchSubmissionCell, nil, isOn: false, text: "3D-Touch submission action")
        createCell(sideShortcutActionCell, nil, isOn: false, text: "Edge swipe shortcut")

        createLeftView(cell: forceTouchSubmissionCell, image: SettingValues.submissionActionForceTouch == .NONE ? "fullscreen" : SettingValues.submissionActionForceTouch.getPhoto(), color: SettingValues.submissionActionForceTouch == .NONE ? GMColor.lightGreen500Color() :SettingValues.submissionActionForceTouch.getColor())
        self.forceTouchSubmissionCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.forceTouchSubmissionCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.forceTouchSubmissionCell.detailTextLabel?.numberOfLines = 0
        self.forceTouchSubmissionCell.detailTextLabel?.text = SettingValues.submissionActionForceTouch == .NONE ? "Peek content" : SettingValues.submissionActionForceTouch.getTitle()
        self.forceTouchSubmissionCell.imageView?.layer.cornerRadius = 5

        createLeftView(cell: doubleTapActionCell, image: SettingValues.commentActionDoubleTap.getPhoto(), color: SettingValues.commentActionDoubleTap.getColor())
        self.doubleTapActionCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.doubleTapActionCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.doubleTapActionCell.detailTextLabel?.numberOfLines = 0
        self.doubleTapActionCell.detailTextLabel?.text = SettingValues.commentActionDoubleTap.getTitle()
        self.doubleTapActionCell.imageView?.layer.cornerRadius = 5
        
        createLeftView(cell: forceTouchActionCell, image: SettingValues.commentActionForceTouch.getPhoto(), color: SettingValues.commentActionForceTouch.getColor())
        self.forceTouchActionCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.forceTouchActionCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.forceTouchActionCell.detailTextLabel?.numberOfLines = 0
        self.forceTouchActionCell.detailTextLabel?.text = SettingValues.commentActionForceTouch.getTitle()
        self.forceTouchActionCell.imageView?.layer.cornerRadius = 5

        createLeftView(cell: sideShortcutActionCell, image: SettingValues.sideGesture.getPhoto(), color: SettingValues.sideGesture.getColor())
        self.sideShortcutActionCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.sideShortcutActionCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.sideShortcutActionCell.detailTextLabel?.numberOfLines = 0
        self.sideShortcutActionCell.detailTextLabel?.text = SettingValues.sideGesture.description()
        self.sideShortcutActionCell.imageView?.layer.cornerRadius = 5
        
        createLeftView(cell: doubleTapSubActionCell, image: SettingValues.submissionActionDoubleTap.getPhoto(), color: SettingValues.submissionActionDoubleTap.getColor())
        self.doubleTapSubActionCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.doubleTapSubActionCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.doubleTapSubActionCell.detailTextLabel?.numberOfLines = 0
        self.doubleTapSubActionCell.detailTextLabel?.text = SettingValues.submissionActionDoubleTap.getTitle()
        self.doubleTapSubActionCell.imageView?.layer.cornerRadius = 5
        
        UIView.transition(with: tableView, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.tableView.reloadData()
        }, completion: nil)
    }
    
    func createLeftView(cell: UITableViewCell, image: String, color: UIColor) {
        if let icon = UIImage(named: image)?.navIcon().getCopy(withSize: CGSize.square(size: 25), withColor: .white) {
            var coloredIcon = UIImage.convertGradientToImage(colors: [color, color], frame: CGSize.square(size: 45))
            coloredIcon = coloredIcon.overlayWith(image: icon, posX: 10, posY: 10)
            cell.imageView?.image = coloredIcon.sd_roundedCornerImage(withRadius: 10, corners: UIRectCorner.allCorners, borderWidth: 0, borderColor: nil)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ((indexPath.section == 1 && indexPath.row == 1) || (indexPath.section == 0 && indexPath.row == 2)) ? 108 : 70
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 1:
            switch indexPath.row {
            case 0: return self.commentGesturesCell
            //case 1: return self.commentCell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "commentgesturepreview", for: indexPath) as! GesturePreviewCell
                cell.setup(comment: true, parent: self)
                return cell
            case 2: return self.doubleTapActionCell
            case 3: return self.forceTouchActionCell
            default: fatalError("Unknown row in section 0")
            }
        case 0:
            switch indexPath.row {
            case 0: return self.submissionGesturesCell
            case 1: return self.disableBannerCell
            case 3: return self.doubleTapSubActionCell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "submissiongesturepreview", for: indexPath) as! GesturePreviewCell
                cell.setup(comment: false, parent: self)
                return cell
            case 4: return self.forceTouchSubmissionCell
            default: fatalError("Unknown row in section 0")
            }
        case 2:
            return self.sideShortcutActionCell
        default: fatalError("Unknown section")
        }
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1: return 3 + (canForceTouch ? 1 : 0)
        case 0: return 4 + (canForceTouch ? 1 : 0)
        case 2: return 1
        default: fatalError("Unknown number of sections")
        }
    }
    
}

public class GesturePreviewCell: InsetCell {
    
    var didSetup = false
    var comment = false
    
    weak var parentController: SettingsGestures?
    
    func setup(comment: Bool, parent: SettingsGestures) {
        self.parentController = parent
        if !didSetup {
            self.comment = comment
            didSetup = true
            configureViews()
            configureLayout()
        }
        
        for view in left.subviews {
            view.removeFromSuperview()
        }
        for view in right.subviews {
            view.removeFromSuperview()
        }

        if comment {
            right.addArrangedSubview(createGestureView(comment: SettingValues.commentActionLeftRight, enabled: SettingValues.commentGesturesMode != .NONE, action: {
                self.showAction { (action) in
                    SettingValues.commentActionLeftRight = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_commentActionLeftRight)
                    UserDefaults.standard.synchronize()
                    MainViewController.needsReTheme = true
                    self.parentController?.updateCells()
                }
            }))
            
            right.addArrangedSubview(createGestureView(comment: SettingValues.commentActionLeftLeft, enabled: SettingValues.commentGesturesMode != .NONE, action: {
                self.showAction { (action) in
                    SettingValues.commentActionLeftLeft = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_commentActionLeftLeft)
                    UserDefaults.standard.synchronize()
                    MainViewController.needsReTheme = true
                    self.parentController?.updateCells()
                }
            }))
            
            left.addArrangedSubview(createGestureView(comment: SettingValues.commentActionRightLeft, enabled: SettingValues.commentGesturesMode == .FULL, action: {
                self.showAction { (action) in
                    SettingValues.commentActionRightLeft = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_commentActionRightLeft)
                    UserDefaults.standard.synchronize()
                    MainViewController.needsReTheme = true
                    self.parentController?.updateCells()
                }
            }))
            left.addArrangedSubview(createGestureView(comment: SettingValues.commentActionRightRight, enabled: SettingValues.commentGesturesMode == .FULL, action: {
                self.showAction { (action) in
                    SettingValues.commentActionRightRight = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_commentActionRightRight)
                    UserDefaults.standard.synchronize()
                    MainViewController.needsReTheme = true
                    self.parentController?.updateCells()
                }
            }))
        } else {
            right.addArrangedSubview(createGestureView(submission: SettingValues.submissionActionLeft, enabled: SettingValues.submissionGestureMode != .NONE, action: {
                self.showActionSub { (action) in
                    SettingValues.submissionActionLeft = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_submissionActionLeft)
                    SubredditReorderViewController.changed = true
                    UserDefaults.standard.synchronize()
                    MainViewController.needsReTheme = true
                    self.parentController?.updateCells()
                }
            }))
            
            left.addArrangedSubview(createGestureView(submission: SettingValues.submissionActionRight, enabled: SettingValues.submissionGestureMode == .FULL, action: {
                self.showActionSub { (action) in
                    SettingValues.submissionActionRight = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_submissionActionRight)
                    SubredditReorderViewController.changed = true
                    UserDefaults.standard.synchronize()
                    MainViewController.needsReTheme = true
                    self.parentController?.updateCells()
                }
            }))
        }
        
        left.layer.cornerRadius = 10
        left.clipsToBounds = true
        right.layer.cornerRadius = 10
        right.clipsToBounds = true
        
        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
        self.backgroundColor = ColorUtil.theme.foregroundColor
    }
    
    func showAction(_ callback: @escaping (_ action: SettingValues.CommentAction) -> Void) {
        let type = ""

        let alertController = DragDownAlertMenu(title: "Select a comment gesture", subtitle: type, icon: nil)
        for action in SettingValues.CommentAction.cases {
            alertController.addAction(title: action.getTitle(), icon: UIImage(named: action.getPhoto())!.menuIcon()) {
                callback(action)
            }
        }
        alertController.show(parentController)
    }
    
    func showActionSub(_ callback: @escaping (_ action: SettingValues.SubmissionAction) -> Void) {
        let alertController = DragDownAlertMenu(title: "Select a submission gesture", subtitle: "", icon: nil)
        
        for action in SettingValues.SubmissionAction.cases {
            alertController.addAction(title: action.getTitle(), icon: UIImage(named: action.getPhoto())!.menuIcon()) {
                callback(action)
            }
        }
        if let parent = parentController {
            VCPresenter.presentAlert(alertController, parentVC: parent)
        }
    }

    func createGestureView(comment: SettingValues.CommentAction, enabled: Bool, action: @escaping () -> Void) -> UIView {
        let view = UIImageView()
        view.contentMode = .center
        if enabled {
            view.backgroundColor = comment.getColor()
            view.image = UIImage(named: comment.getPhoto())?.getCopy(withSize: CGSize.square(size: 40), withColor: UIColor.white)
            view.addTapGestureRecognizer { (_) in
                action()
            }
        } else {
            view.backgroundColor = ColorUtil.theme.fontColor
            view.image = nil
            view.alpha = 0.5
        }
        view.heightAnchor /==/ 100
        view.widthAnchor /==/ 75
        
        return view
    }
    
    func createGestureView(submission: SettingValues.SubmissionAction, enabled: Bool, action: @escaping () -> Void) -> UIView {
        let view = UIImageView()
        view.contentMode = .center
        if enabled {
            view.backgroundColor = submission.getColor()
            view.image = UIImage(named: submission.getPhoto())?.getCopy(withSize: CGSize.square(size: 40), withColor: UIColor.white)
            view.addTapGestureRecognizer { (_) in
                action()
            }
        } else {
            view.backgroundColor = ColorUtil.theme.fontColor
            view.image = nil
            view.alpha = 0.5
        }
        view.heightAnchor /==/ 100
        view.widthAnchor /==/ 75
        
        return view
    }

    var left = UIStackView()
    var right = UIStackView()
    var body = UIView()
            
    func configureViews() {
        self.clipsToBounds = true
        
        self.body = UIView().then {
            $0.layer.cornerRadius = 6
            $0.clipsToBounds = true
            $0.backgroundColor = ColorUtil.theme.backgroundColor
        }
        
        self.left = UIStackView().then {
            $0.axis = .horizontal
            $0.spacing = 0
        }

        self.right = UIStackView().then {
            $0.axis = .horizontal
            $0.spacing = 0
        }

        self.contentView.addSubviews(left, right, body)
    }
    
    func configureLayout() {
        batch {
            left.leftAnchor /==/ contentView.leftAnchor + 8
            body.leftAnchor /==/ left.rightAnchor + 4
            body.rightAnchor /==/ right.leftAnchor - 4
            right.rightAnchor /==/ contentView.rightAnchor - 8
            
            left.heightAnchor /==/ 100
            right.heightAnchor /==/ 100
            body.heightAnchor /==/ 12
            
            body.centerYAnchor /==/ contentView.centerYAnchor
            left.topAnchor /==/ contentView.topAnchor + 4
            right.topAnchor /==/ contentView.topAnchor + 4
            
            left.bottomAnchor /==/ contentView.bottomAnchor - 4
            right.bottomAnchor /==/ contentView.bottomAnchor - 4
        }
    }
}
