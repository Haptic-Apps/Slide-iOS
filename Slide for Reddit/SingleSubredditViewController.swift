//
//  SingleSubredditViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/22/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import SDWebImage
import SideMenu
import UZTextView
import RealmSwift
import MaterialComponents.MaterialSnackbar
import MaterialComponents.MDCActivityIndicator
import MaterialComponents.MaterialBottomSheet
import TTTAttributedLabel
import SloppySwiper
import XLActionController
import MKColorPicker
import RLBAlertsPickers

class SingleSubredditViewController: MediaViewController, UICollectionViewDelegate, UICollectionViewDataSource, LinkCellViewDelegate, ColorPickerViewDelegate, WrappingFlowLayoutDelegate {

    let maxHeaderHeight: CGFloat = 120;
    let minHeaderHeight: CGFloat = 56;

    func openComments(id: String) {
        var index = 0
        for s in links {
            if (s.getId() == id) {
                break
            }
            index += 1
        }
        var newLinks: [RSubmission] = []
        for i in index...links.count - 1 {
            newLinks.append(links[i])
        }

        var comment: UIViewController = UIViewController()

        if (self.splitViewController != nil && !SettingValues.multiColumn) {
            let comment = CommentViewController.init(submission: newLinks[0])
            let nav = UINavigationController.init(rootViewController: comment)
            self.splitViewController?.showDetailViewController(nav, sender: self)
        } else {
            let comment = PagingCommentViewController.init(submissions: newLinks)
            VCPresenter.showVC(viewController: comment, popupIfPossible: true, parentNavigationController: navigationController, parentViewController: self)
        }
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }

    override var keyCommands: [UIKeyCommand]? {
        return [UIKeyCommand(input: " ", modifierFlags: [], action: #selector(spacePressed))]
    }

    @objc func spacePressed() {
        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.tableView.contentOffset.y = self.tableView.contentOffset.y + 350
        }, completion: nil)
    }


    let margin: CGFloat = 10
    let cellsPerRow = 3

    func collectionView(_ collectionView: UICollectionView, width: CGFloat, indexPath: IndexPath) -> CGSize {
        var itemWidth = width
        if (indexPath.row < links.count) {
            let submission = links[indexPath.row]

            var thumb = submission.thumbnail
            var big = submission.banner

            var type = ContentType.getContentType(baseUrl: submission.url!)
            if (submission.isSelf) {
                type = .SELF
            }

            if (SettingValues.bannerHidden) {
                big = false
                thumb = true
            }

            let fullImage = ContentType.fullImage(t: type)
            var submissionHeight = submission.height

            if (!fullImage && submissionHeight < 50) {
                big = false
                thumb = true
            } else if (big && (SettingValues.bigPicCropped)) {
                submissionHeight = 200
            } else if (big) {
                let ratio = Double(submissionHeight) / Double(submission.width)
                let width = Double(itemWidth);

                let h = width * ratio
                if (h == 0) {
                    submissionHeight = 200
                } else {
                    submissionHeight = Int(h)
                }
            }


            if (type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big) {
                big = false
                thumb = false
            }

            if (submissionHeight < 50) {
                thumb = true
                big = false
            }


            if (big || !submission.thumbnail) {
                thumb = false
            }


            if (!big && !thumb && submission.type != .SELF && submission.type != .NONE) { //If a submission has a link but no images, still show the web thumbnail
                thumb = true
            }

            if (submission.nsfw && !SettingValues.nsfwPreviews) {
                big = false
                thumb = true
            }

            if (submission.nsfw && SettingValues.hideNSFWCollection && (sub == "all" || sub == "frontpage" || sub == "popular")) {
                big = false
                thumb = true
            }


            if (SettingValues.noImages) {
                big = false
                thumb = false
            }
            if (thumb && type == .SELF) {
                thumb = false
            }

            var paddingTop = CGFloat(0)
            var paddingBottom = CGFloat(2)
            var paddingLeft = CGFloat(0)
            var paddingRight = CGFloat(0)
            var innerPadding = CGFloat(0)
            if (SettingValues.postViewMode == .CARD) {
                paddingTop = 5
                paddingBottom = 5
                paddingLeft = 5
                paddingRight = 5
            }

            let actionbar = CGFloat(SettingValues.hideButtonActionbar ? 0 : 24)

            var imageHeight = big && !thumb ? CGFloat(submissionHeight) : CGFloat(0)
            let thumbheight = SettingValues.largerThumbnail ? CGFloat(75) : CGFloat(50)
            let textHeight = CGFloat(0)

            if (thumb) {
                imageHeight = thumbheight
                innerPadding += 8 //between top and thumbnail
                innerPadding += 18 //between label and bottom box
                innerPadding += 8 //between box and end
            } else if (big) {
                if (SettingValues.centerLeadImage) {
                    innerPadding += 16 //between label
                    innerPadding += 12 //between banner and box
                } else {
                    innerPadding += 8 //between banner and label
                    innerPadding += 12 //between label and box
                }

                innerPadding += 8 //between box and end
            } else {
                innerPadding += 8
                innerPadding += 5 //between label and body
                innerPadding += 12 //between body and box
                innerPadding += 8 //between box and end
            }

            var estimatedUsableWidth = itemWidth - paddingLeft - paddingRight
            if (thumb) {
                estimatedUsableWidth -= thumbheight //is the same as the width
                estimatedUsableWidth -= 12 //between edge and thumb
                estimatedUsableWidth -= 8 //between thumb and label
            } else {
                estimatedUsableWidth -= 24 //12 padding on either side
            }

            let framesetter = CTFramesetterCreateWithAttributedString(CachedTitle.getTitle(submission: submission, full: false, false))
            let textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(), nil, CGSize.init(width: estimatedUsableWidth, height: CGFloat.greatestFiniteMagnitude), nil)

            let totalHeight = paddingTop + paddingBottom + (thumb ? max(ceil(textSize.height), imageHeight) : ceil(textSize.height) + imageHeight) + innerPadding + actionbar + textHeight
            var estimatedHeight = totalHeight

            return CGSize(width: itemWidth, height: estimatedHeight)
        }
        return CGSize(width: itemWidth, height: 0)
    }


    var parentController: MainViewController?
    var accentChosen: UIColor?

    var isAccent = false

    public func colorPickerView(_ colorPickerView: ColorPickerView, didSelectItemAt indexPath: IndexPath) {

        if (isAccent) {
            accentChosen = colorPickerView.colors[indexPath.row]
            hide.backgroundColor = accentChosen
        } else {
            let c = colorPickerView.colors[indexPath.row]
            self.navigationController?.navigationBar.barTintColor = c
            sideView.backgroundColor = c
            add.backgroundColor = c
            sideView.backgroundColor = c
            if (parentController != nil) {
                parentController?.colorChanged()
            }

        }
    }

    func valueChanged(_ value: CGFloat, accent: Bool) {

    }

    func reply(_ cell: LinkCellView) {

    }

    func save(_ cell: LinkCellView) {
        do {
            try session?.setSave(!ActionStates.isSaved(s: cell.link!), name: (cell.link?.getId())!, completion: { (result) in

            })
            ActionStates.setSaved(s: cell.link!, saved: !ActionStates.isSaved(s: cell.link!))
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {

        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if (SettingValues.markReadOnScroll) {
            History.addSeen(s: links[indexPath.row])
        }
    }

    func upvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up, name: (cell.link?.getId())!, completion: { (result) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up)
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {

        }
    }

    func downvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down, name: (cell.link?.getId())!, completion: { (result) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down)
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {

        }
    }

    func hide(_ cell: LinkCellView) {
        do {
            try session?.setHide(true, name: cell.link!.getId(), completion: { (result) in })
            let id = cell.link!.getId()
            var location = 0
            var item = links[0]
            for submission in links {
                if (submission.getId() == id) {
                    item = links[location]
                    print("Removing link")
                    links.remove(at: location)
                    break
                }
                location += 1
            }

            tableView.performBatchUpdates({
                self.tableView.deleteItems(at: [IndexPath.init(item: location, section: 0)])
                let message = MDCSnackbarMessage.init(text: "Submission hidden forever")
                let action = MDCSnackbarMessageAction()
                let actionHandler = { () in
                    self.links.insert(item, at: location)
                    self.tableView.insertItems(at: [IndexPath.init(item: location, section: 0)])
                    do {
                        try self.session?.setHide(false, name: cell.link!.getId(), completion: { (result) in })
                    } catch {

                    }
                }
                action.handler = actionHandler
                action.title = "UNDO"

                message.action = action
                MDCSnackbarManager.show(message)

                self.flowLayout.reset()
            }, completion: nil)

        } catch {

        }
    }

    var isCollapsed = false
    var isHiding = false

    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let currentY = scrollView.contentOffset.y;
        if (currentY > lastYUsed && currentY > 60) {
            if (navigationController != nil && !isHiding && !(navigationController!.isToolbarHidden)) {
                hideUI(inHeader: true)
            }
        } else if ((currentY < lastYUsed + 20) && !isHiding && navigationController != nil && (navigationController!.isToolbarHidden)) {
            showUI()
        }
        lastYUsed = currentY
        lastY = currentY
    }

    func hideUI(inHeader: Bool) {
        isHiding = true
        if (single || !SettingValues.viewType) {
            (navigationController)?.setNavigationBarHidden(true, animated: true)
        }
        UIApplication.shared.statusBarView?.backgroundColor = ColorUtil.getColorForSub(sub: self.sub)

        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            SingleSubredditViewController.fab?.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
        }, completion: { finished in
            SingleSubredditViewController.fab?.isHidden = true
            self.isHiding = false

        })
        (navigationController)?.setToolbarHidden(true, animated: true)
    }

    func showUI() {
        if (single || !SettingValues.viewType) {
            (navigationController)?.setNavigationBarHidden(false, animated: true)
        }
        SingleSubredditViewController.fab?.isHidden = false

        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            SingleSubredditViewController.fab?.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
        }, completion: { finished in

        })

        (navigationController)?.setToolbarHidden(false, animated: true)
    }


    func more(_ cell: LinkCellView) {
        let link = cell.link!

        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Post by /u/\(link.author)"


        alertController.addAction(Action(ActionData(title: "/u/\(link.author)'s profile", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { action in

            let prof = ProfileViewController.init(name: link.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
        }))
        alertController.addAction(Action(ActionData(title: "/r/\(link.subreddit)", image: UIImage(named: "subs")!.menuIcon()), style: .default, handler: { action in

            let sub = SingleSubredditViewController.init(subName: link.subreddit, single: true)
            VCPresenter.showVC(viewController: sub, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)

        }))

        alertController.addAction(Action(ActionData(title: "Share comment permalink", image: UIImage(named: "link")!.menuIcon()), style: .default, handler: { action in
            let activityViewController = UIActivityViewController(activityItems: [link.permalink], applicationActivities: nil)
            self.present(activityViewController, animated: true, completion: {})
        }))
        if (AccountController.isLoggedIn) {
            alertController.addAction(Action(ActionData(title: "Save", image: UIImage(named: "save")!.menuIcon()), style: .default, handler: { action in
                self.save(cell)
            }))

            alertController.addAction(Action(ActionData(title: "Crosspost", image: UIImage(named: "crosspost")!.menuIcon()), style: .default, handler: { action in
                self.crosspost(cell.link!)
            }))

            alertController.addAction(Action(ActionData(title: "Report", image: UIImage(named: "hide")!.menuIcon()), style: .default, handler: { action in
                self.report(cell.link!)
            }))
        }


        alertController.addAction(Action(ActionData(title: "Hide", image: UIImage(named: "hide")!.menuIcon()), style: .default, handler: { action in
            self.hide(cell)
        }))
        let open = OpenInChromeController.init()
        if (open.isChromeInstalled()) {

            alertController.addAction(Action(ActionData(title: "Open in Chrome", image: UIImage(named: "link")!.menuIcon()), style: .default, handler: { action in
                open.openInChrome(link.url!, callbackURL: nil, createNewTab: true)
            }))
        }
        alertController.addAction(Action(ActionData(title: "Open in Safari", image: UIImage(named: "world")!.menuIcon()), style: .default, handler: { action in
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(link.url!, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(link.url!)
            }
        }))

        alertController.addAction(Action(ActionData(title: "Share content", image: UIImage(named: "link")!.menuIcon()), style: .default, handler: { action in
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [link.url!], applicationActivities: nil);
            let currentViewController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
            currentViewController.present(activityViewController, animated: true, completion: nil);
        }))
        alertController.addAction(Action(ActionData(title: "Share comments", image: UIImage(named: "comments")!.menuIcon()), style: .default, handler: { action in
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [URL.init(string: "https://reddit.com" + link.permalink)!], applicationActivities: nil);
            let currentViewController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
            currentViewController.present(activityViewController, animated: true, completion: nil);
        }))

        alertController.addAction(Action(ActionData(title: "Filter this content", image: UIImage(named: "filter")!.menuIcon()), style: .default, handler: { action in
            self.showFilterMenu(link)
        }))


        alertController.addAction(Action(ActionData(title: "Cancel", image: UIImage(named: "close")!.menuIcon()), style: .default, handler: nil))

        //todo make this work on ipad
        self.present(alertController, animated: true, completion: nil)
    }


    var reportText: String?

    func report(_ thing: Object) {

        let alert = UIAlertController(title: "Report this content", message: "", preferredStyle: .alert)

        let config: TextField.Config = { textField in
            textField.becomeFirstResponder()
            textField.textColor = .black
            textField.placeholder = "Reason (optional)"
            textField.left(image: UIImage.init(named: "flag"), color: .black)
            textField.leftViewPadding = 12
            textField.borderWidth = 1
            textField.cornerRadius = 8
            textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
            textField.backgroundColor = .white
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.returnKeyType = .done
            textField.action { textField in
                self.reportText = textField.text
            }
        }

        alert.addOneTextField(configuration: config)

        alert.addAction(UIAlertAction(title: "Report", style: .destructive, handler: { [weak alert] (_) in
            let text = self.reportText ?? ""
            do {
                let name = (thing is RComment) ? (thing as! RComment).name : (thing as! RSubmission).name
                try self.session?.report(name, reason: text, otherReason: "", completion: { (result) in
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Report sent"
                        MDCSnackbarManager.show(message)
                    }
                })
            } catch {
                DispatchQueue.main.async {
                    let message = MDCSnackbarMessage()
                    message.text = "Error sending report"
                    MDCSnackbarManager.show(message)
                }
            }
        }))

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

        //todo make this work on ipad
        self.present(alert, animated: true, completion: nil)
    }

    var subText : String?
    var titleText : String?

    func crosspost(_ thing: RSubmission, _ title: String? = nil, _ subreddit: String? = nil, _ error: String? = "") {

        let alert = UIAlertController.init(style: .actionSheet)

        let configS: TextField.Config = { textField in
            textField.becomeFirstResponder()
            textField.textColor = .black
            textField.placeholder = "Subreddit"
            textField.left(image: UIImage.init(named: "subs"), color: .black)
            textField.leftViewPadding = 12
            textField.borderWidth = 1
            textField.cornerRadius = 8
            textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
            textField.backgroundColor = .white
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.leftViewPadding = 16
            textField.returnKeyType = .done
            if(subreddit != nil){
                textField.text = subreddit
            }
            textField.action { textField in
                self.subText = textField.text
            }
        }

        let configT: TextField.Config = { textField in
            textField.textColor = .black
            textField.placeholder = "Enter a new title"
            textField.left(image: UIImage.init(named: "size"), color: .black)
            textField.leftViewPadding = 16
            textField.borderWidth = 0
            textField.cornerRadius = 0
            textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
            textField.backgroundColor = .white
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.returnKeyType = .done
            textField.text = thing.title
            textField.clearButtonMode = .whileEditing
            if(title != nil){
                textField.text = title
            }
            textField.action { textField in
                self.titleText = textField.text
            }
        }

        alert.addTwoTextFields(textFieldOne: configS, textFieldTwo: configT)

        alert.addAction(UIAlertAction(title: "Crosspost", style: .default, handler: { [weak alert] (_) in
            let subField = self.subText ?? ""
            let titleField = self.titleText ?? ""

            if (subField.isEmpty || titleField.isEmpty) {
                if (subField.isEmpty) {
                    self.crosspost(thing, titleField, subField, "Subreddit must not be empty!")
                } else {
                    self.crosspost(thing, titleField, subField, "Title must not be empty!")
                }
            } else {
                do {
                    try self.session?.crosspost(Link.init(id: thing.id), subreddit: subField, newTitle: titleField) { result in
                        switch result {
                        case .failure(let error):
                            print(error)
                            DispatchQueue.main.async {
                                self.crosspost(thing, titleField, subField, error.localizedDescription)
                            }
                            break
                        case .success(let submission):
                            if let error = self.getError(submission) {
                                DispatchQueue.main.async {
                                    self.crosspost(thing, titleField, subField, error)
                                }
                            } else {
                                let string = self.getIDString(submission).value!
                                print("Got \(string)")
                                DispatchQueue.main.async {
                                    alert?.dismiss(animated: true)
                                    VCPresenter.openRedditLink("https://redd.it/\(string)", self.navigationController, self)
                                }
                            }

                        }
                    }

                } catch {

                }
            }
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        //todo make this work on ipad
        self.present(alert, animated: true, completion: nil)
    }

    func getIDString(_ json: JSONAny) -> reddift.Result<String> {
        if let json = json as? JSONDictionary {
            if let j = json["json"] as? JSONDictionary {
                if let data = j["data"] as? JSONDictionary {
                    if let iden = data["id"] as? String {
                        return Result(value: iden)
                    }
                }
            }
        }
        return Result(error: ReddiftError.identifierOfCAPTCHAIsMalformed as NSError)
    }

    func getError(_ json: JSONAny) -> String? {
        if let json = json as? JSONDictionary, let j = json["json"] as? JSONDictionary, let errors = j["errors"] as? JSONArray {
            // Error happened.
            for obj in errors {
                if let errorStrings = obj as? [String] {
                    print(errorStrings)
                    return errorStrings[1]
                }
            }
        }
        return nil
    }
    func showFilterMenu(_ link: RSubmission) {
        let actionSheetController: UIAlertController = UIAlertController(title: "What would you like to filter?", message: "", preferredStyle: .alert)

        var cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)

        cancelActionButton = UIAlertAction(title: "Posts by /u/\(link.author)", style: .default) { action -> Void in
            PostFilter.profiles.append(link.author as NSString)
            PostFilter.saveAndUpdate()
            self.links = PostFilter.filter(self.links, previous: nil, baseSubreddit: self.sub)
            self.reloadDataReset()
        }
        actionSheetController.addAction(cancelActionButton)

        cancelActionButton = UIAlertAction(title: "Posts from /r/\(link.subreddit)", style: .default) { action -> Void in
            PostFilter.subreddits.append(link.subreddit as NSString)
            PostFilter.saveAndUpdate()
            self.links = PostFilter.filter(self.links, previous: nil, baseSubreddit: self.sub)
            self.reloadDataReset()
        }
        actionSheetController.addAction(cancelActionButton)

        cancelActionButton = UIAlertAction(title: "Posts linking to \(link.domain)", style: .default) { action -> Void in
            PostFilter.domains.append(link.domain as NSString)
            PostFilter.saveAndUpdate()
            self.links = PostFilter.filter(self.links, previous: nil, baseSubreddit: self.sub)
            self.reloadDataReset()
        }
        actionSheetController.addAction(cancelActionButton)

        //todo make this work on ipad
        self.present(actionSheetController, animated: true, completion: nil)

    }


    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tableView.collectionViewLayout.invalidateLayout()
        super.viewWillTransition(to: size, with: coordinator)
    }


    var links: [RSubmission] = []
    var paginator = Paginator()
    var sub: String
    var session: Session? = nil
    var tableView: UICollectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: UICollectionViewLayout.init())
    var single: Bool = false

    init(subName: String, parent: MainViewController) {
        sub = subName;
        self.parentController = parent

        super.init(nibName: nil, bundle: nil)
        //  setBarColors(color: ColorUtil.getColorForSub(sub: subName))
    }

    init(subName: String, single: Bool) {
        sub = subName
        self.single = true
        super.init(nibName: nil, bundle: nil)
        // setBarColors(color: ColorUtil.getColorForSub(sub: subName))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(_ animated: Bool = true) {
        if (SingleSubredditViewController.fab != nil) {
            if animated == true {
                SingleSubredditViewController.fab!.isHidden = false
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    SingleSubredditViewController.fab!.alpha = 1
                })
            } else {
                SingleSubredditViewController.fab!.isHidden = false
            }
        }
    }

    func hideFab(_ animated: Bool = true) {
        if (SingleSubredditViewController.fab != nil) {
            if animated == true {
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    SingleSubredditViewController.fab!.alpha = 0
                }, completion: { finished in
                    SingleSubredditViewController.fab!.isHidden = true
                })
            } else {
                SingleSubredditViewController.fab!.isHidden = true
            }
        }
    }


    var loaded = false
    var sideView: UIView = UIView()
    var subb: UIButton = UIButton()

    func drefresh(_ sender: AnyObject) {
        load(reset: true)
    }


    var heightAtIndexPath = NSMutableDictionary()

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension

        /*
        if let height = heightAtIndexPath.object(forKey: indexPath) as? NSNumber {
            return CGFloat(height.floatValue)
        } else {
            return UITableViewAutomaticDimension
        }*/
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    var subInfo: Subreddit?
    var flowLayout: WrappingFlowLayout = WrappingFlowLayout.init()

    override func viewDidLoad() {
        super.viewDidLoad()
        flowLayout.delegate = self
        var frame = self.view.bounds
        self.tableView = UICollectionView(frame: frame, collectionViewLayout: flowLayout)
        self.view = UIView.init(frame: CGRect.zero)

        self.view.addSubview(tableView)

        self.tableView.delegate = self
        self.tableView.dataSource = self
        refreshControl = UIRefreshControl()

        reloadNeedingColor()
    }

    func setupFab() {
        if (SingleSubredditViewController.fab != nil) {
            SingleSubredditViewController.fab!.removeFromSuperview()
            SingleSubredditViewController.fab = nil
        }
        if(!MainViewController.isOffline){
            SingleSubredditViewController.fab = UIButton(frame: CGRect.init(x: (tableView.frame.size.width / 2) - 70, y: -20, width: 140, height: 45))
            SingleSubredditViewController.fab!.backgroundColor = ColorUtil.accentColorForSub(sub: sub)
            SingleSubredditViewController.fab!.layer.cornerRadius = 22.5
            SingleSubredditViewController.fab!.clipsToBounds = true
            var title = "  " + SettingValues.fabType.getTitle();
            SingleSubredditViewController.fab!.setTitle(title, for: .normal)
            SingleSubredditViewController.fab!.leftImage(image: (UIImage.init(named: SettingValues.fabType.getPhoto())?.navIcon())!, renderMode: UIImageRenderingMode.alwaysOriginal)
            SingleSubredditViewController.fab!.elevate(elevation: 2)
            SingleSubredditViewController.fab!.titleLabel?.textAlignment = .center
            SingleSubredditViewController.fab!.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            
            var width = title.size(with: SingleSubredditViewController.fab!.titleLabel!.font).width + CGFloat(65)
            SingleSubredditViewController.fab!.frame = CGRect.init(x: (tableView.frame.size.width / 2) - (width / 2), y: -20, width: width, height: CGFloat(45))
            
            SingleSubredditViewController.fab!.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: 20, bottom: 0, right: 20)
            navigationController?.toolbar.addSubview(SingleSubredditViewController.fab!)
            
            SingleSubredditViewController.fab!.addTapGestureRecognizer {
                switch (SettingValues.fabType) {
                case .SIDEBAR:
                    self.doDisplaySidebar()
                    break
                case .NEW_POST:
                    self.newPost(SingleSubredditViewController.fab!)
                    break
                case .SHADOWBOX:
                    self.shadowboxMode()
                    break
                case .HIDE_READ:
                    self.hideReadPosts()
                    break
                case .GALLERY:
                    self.galleryMode()
                    break
                }
            }
            
            SingleSubredditViewController.fab!.addLongTapGestureRecognizer {
                self.changeFab()
            }
            
            SingleSubredditViewController.fab!.transform = CGAffineTransform.init(scaleX: 0.001, y: 0.001)
            UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                SingleSubredditViewController.fab!.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
            }, completion: nil)
        }
    }

    func changeFab() {
        let actionSheetController: UIAlertController = UIAlertController(title: "Change button type", message: "", preferredStyle: .alert)

        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)

        for t in SettingValues.FabType.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: t.getTitle(), style: .default) { action -> Void in
                UserDefaults.standard.set(t.rawValue, forKey: SettingValues.pref_fabType)
                SettingValues.fabType = t
                self.setupFab()
            }
            actionSheetController.addAction(saveActionButton)
        }

        self.present(actionSheetController, animated: true, completion: nil)
    }


    static var firstPresented = true

    var headerView = UIView()


    func reloadNeedingColor() {
        tableView.backgroundColor = ColorUtil.backgroundColor

        refreshControl.tintColor = ColorUtil.fontColor
        refreshControl.attributedTitle = NSAttributedString(string: "")
        refreshControl.addTarget(self, action: #selector(self.drefresh(_:)), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController

        self.automaticallyAdjustsScrollViewInsets = false


        self.tableView.register(BannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "banner")
        self.tableView.register(ThumbnailLinkCellView.classForCoder(), forCellWithReuseIdentifier: "thumb")
        self.tableView.register(TextLinkCellView.classForCoder(), forCellWithReuseIdentifier: "text")

        var top = 56
        if #available(iOS 11.0, *) {
            top = 0
        }

        top = top + ((SettingValues.viewType && !single) ? 52 : 0)

        self.tableView.contentInset = UIEdgeInsets.init(top: CGFloat(top) , left: 0, bottom: 0, right: 0)

        session = (UIApplication.shared.delegate as! AppDelegate).session

        if (SingleSubredditViewController.firstPresented && !single) || (self.links.count == 0 && !single && !SettingValues.viewType) {
            load(reset: true)
            SingleSubredditViewController.firstPresented = false
        }

        if (single) {

            let sort = UIButton.init(type: .custom)
            sort.setImage(UIImage.init(named: "ic_sort_white")?.navIcon(), for: UIControlState.normal)
            sort.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
            sort.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            let sortB = UIBarButtonItem.init(customView: sort)

            let more = UIButton.init(type: .custom)
            more.setImage(UIImage.init(named: "moreh")?.menuIcon(), for: UIControlState.normal)
            more.addTarget(self, action: #selector(self.showMoreNone(_:)), for: UIControlEvents.touchUpInside)
            more.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            let moreB = UIBarButtonItem.init(customView: more)

            navigationItem.rightBarButtonItems = [sortB]
            let flexButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)

            toolbarItems = [flexButton, moreB]
            title = sub

            self.sort = SettingValues.getLinkSorting(forSubreddit: self.sub)
            self.time = SettingValues.getTimePeriod(forSubreddit: self.sub)

            do {
                try (UIApplication.shared.delegate as! AppDelegate).session?.about(sub, completion: { (result) in
                    switch result {
                    case .failure:
                        print(result.error!.description)
                        DispatchQueue.main.async {
                            if (self.sub == ("all") || self.sub == ("frontpage") || self.sub.hasPrefix("/m/") || self.sub.contains("+")) {
                                self.load(reset: true)
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                                    let alert = UIAlertController.init(title: "Subreddit not found", message: "/r/\(self.sub) could not be found, is it spelled correctly?", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction.init(title: "Close", style: .default, handler: { (_) in
                                        self.navigationController?.popViewController(animated: true)
                                        self.dismiss(animated: true, completion: nil)

                                    }))
                                    self.present(alert, animated: true, completion: nil)
                                }

                            }
                        }
                    case .success(let r):
                        self.subInfo = r
                        DispatchQueue.main.async {
                            if (self.subInfo!.over18 && !SettingValues.nsfwEnabled) {
                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                                    let alert = UIAlertController.init(title: "/r/\(self.sub) is NSFW", message: "If you are 18 and willing to see adult content, enable NSFW content in Settings > Content", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction.init(title: "Close", style: .default, handler: { (_) in
                                        self.navigationController?.popViewController(animated: true)
                                        self.dismiss(animated: true, completion: nil)
                                    }))
                                    self.present(alert, animated: true, completion: nil)
                                }
                            } else {
                                if (self.sub != ("all") && self.sub != ("frontpage") && !self.sub.hasPrefix("/m/")) {
                                    if (SettingValues.saveHistory) {
                                        if (SettingValues.saveNSFWHistory && self.subInfo!.over18) {
                                            Subscriptions.addHistorySub(name: AccountController.currentName, sub: self.subInfo!.displayName)
                                        } else if (!self.subInfo!.over18) {
                                            Subscriptions.addHistorySub(name: AccountController.currentName, sub: self.subInfo!.displayName)
                                        }
                                    }
                                }
                                print("Loading")
                                self.load(reset: true)
                            }

                        }
                    }
                })
            } catch {
            }
        }

    }

    func exit() {
        self.navigationController?.popViewController(animated: true)
        if (self.navigationController!.modalPresentationStyle == .pageSheet) {
            self.navigationController!.dismiss(animated: true, completion: nil)
        }
    }

    var lastY: CGFloat = CGFloat(0)
    var add: MDCFloatingButton = MDCFloatingButton()
    var hide: MDCFloatingButton = MDCFloatingButton()
    var lastYUsed = CGFloat(0)

    func hideAll(_ sender: AnyObject) {
        for submission in links {
            if (History.getSeen(s: submission)) {
                let index = links.index(of: submission)!
                links.remove(at: index)
            }
        }
        tableView.reloadData()
        self.flowLayout.reset()
    }


    func doDisplayMultiSidebar(_ sub: Multireddit) {
        let alrController = UIAlertController(title: sub.displayName, message: sub.descriptionMd, preferredStyle: UIAlertControllerStyle.actionSheet)
        for s in sub.subreddits {
            let somethingAction = UIAlertAction(title: "/r/" + s, style: UIAlertActionStyle.default, handler: { (alert: UIAlertAction!) in
                self.show(SingleSubredditViewController.init(subName: s, single: true), sender: self)
            })
            let color = ColorUtil.getColorForSub(sub: s)
            if (color != ColorUtil.baseColor) {
                somethingAction.setValue(color, forKey: "titleTextColor")

            }
            alrController.addAction(somethingAction)

        }
        var somethingAction = UIAlertAction(title: "Edit multireddit", style: UIAlertActionStyle.default, handler: { (alert: UIAlertAction!) in print("something") })
        alrController.addAction(somethingAction)

        somethingAction = UIAlertAction(title: "Delete multireddit", style: UIAlertActionStyle.destructive, handler: { (alert: UIAlertAction!) in print("something") })
        alrController.addAction(somethingAction)


        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (alert: UIAlertAction!) in print("cancel") })

        alrController.addAction(cancelAction)


        //todo make this work on ipad
        self.present(alrController, animated: true, completion: {})
    }

    func subscribeSingle(_ selector: AnyObject) {
        if (subChanged && !Subscriptions.isSubscriber(sub) || Subscriptions.isSubscriber(sub)) {
            //was not subscriber, changed, and unsubscribing again
            Subscriptions.unsubscribe(sub, session: session!)
            subChanged = false
            let message = MDCSnackbarMessage()
            message.text = "Unsubscribed"
            MDCSnackbarManager.show(message)
            subb.setImage(UIImage.init(named: "addcircle")?.withColor(tintColor: ColorUtil.fontColor), for: UIControlState.normal)
        } else {
            let alrController = UIAlertController.init(title: "Subscribe to \(sub)", message: nil, preferredStyle: .actionSheet)
            if (AccountController.isLoggedIn) {
                let somethingAction = UIAlertAction(title: "Add to sub list and subscribe", style: UIAlertActionStyle.default, handler: { (alert: UIAlertAction!) in
                    Subscriptions.subscribe(self.sub, true, session: self.session!)
                    self.subChanged = true
                    let message = MDCSnackbarMessage()
                    message.text = "Subscribed"
                    MDCSnackbarManager.show(message)
                    self.subb.setImage(UIImage.init(named: "subbed")?.withColor(tintColor: ColorUtil.fontColor), for: UIControlState.normal)
                })
                alrController.addAction(somethingAction)
            }

            let somethingAction = UIAlertAction(title: "Add to sub list", style: UIAlertActionStyle.default, handler: { (alert: UIAlertAction!) in
                Subscriptions.subscribe(self.sub, false, session: self.session!)
                self.subChanged = true
                let message = MDCSnackbarMessage()
                message.text = "Added"
                MDCSnackbarManager.show(message)
                self.subb.setImage(UIImage.init(named: "subbed")?.withColor(tintColor: ColorUtil.fontColor), for: UIControlState.normal)
            })
            alrController.addAction(somethingAction)

            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (alert: UIAlertAction!) in print("cancel") })

            alrController.addAction(cancelAction)

            alrController.modalPresentationStyle = .fullScreen
            if let presenter = alrController.popoverPresentationController {
                presenter.sourceView = subb
                presenter.sourceRect = subb.bounds
            }

            self.present(alrController, animated: true, completion: {})

        }

    }

    func displayMultiredditSidebar() {
        do {
            print("Getting \(sub.substring(3, length: sub.length - 3))")
            try (UIApplication.shared.delegate as! AppDelegate).session?.getMultireddit(Multireddit.init(name: sub.substring(3, length: sub.length - 3), user: AccountController.currentName), completion: { (result) in
                switch result {
                case .success(let r):
                    DispatchQueue.main.async {
                        self.doDisplayMultiSidebar(r)
                    }
                default:
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Multireddit info not found"
                        MDCSnackbarManager.show(message)
                    }
                    break
                }

            })
        } catch {
        }
    }

    var listingId: String = "" //a random id for use in Realm

    func hideReadPosts() {
        var indexPaths: [IndexPath] = []
        var newLinks: [RSubmission] = []

        var count = 0
        for submission in links {
            if (History.getSeen(s: submission)) {
                indexPaths.append(IndexPath(row: count, section: 0))
                links.remove(at: count)
            } else {
                count += 1
            }
        }

        //todo save realm
        tableView.performBatchUpdates({
            self.tableView.deleteItems(at: indexPaths)
            self.flowLayout.reset()
        }, completion: nil)
    }

    static var fab: UIButton?

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (single || !SettingValues.viewType) {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
        UIApplication.shared.statusBarStyle = .lightContent

        if (single) {
            UIApplication.shared.statusBarView?.backgroundColor = .clear
        }


        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            SingleSubredditViewController.fab?.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
        }, completion: { finished in
            SingleSubredditViewController.fab?.isHidden = true
        })

    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let height = NSNumber(value: Float(cell.frame.size.height))
        heightAtIndexPath.setObject(height, forKey: indexPath as NSCopying)
    }

    func pickTheme(sender: AnyObject?, parent: MainViewController?) {
        parentController = parent
        let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)

        isAccent = false
        let margin: CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: alertController.view.bounds.size.width - margin * 4.0, height: 150)
        let MKColorPicker = ColorPickerView.init(frame: rect)
        MKColorPicker.delegate = self
        MKColorPicker.colors = GMPalette.allColor()
        MKColorPicker.selectionStyle = .check
        MKColorPicker.scrollDirection = .vertical

        MKColorPicker.style = .circle

        alertController.view.addSubview(MKColorPicker)

        let somethingAction = UIAlertAction(title: "Save", style: .default, handler: { (alert: UIAlertAction!) in
            ColorUtil.setColorForSub(sub: self.sub, color: (self.navigationController?.navigationBar.barTintColor)!)
            self.reloadDataReset()
        })

        let accentAction = UIAlertAction(title: "Accent color", style: .default, handler: { (alert: UIAlertAction!) in
            ColorUtil.setColorForSub(sub: self.sub, color: (self.navigationController?.navigationBar.barTintColor)!)
            self.pickAccent(sender: sender, parent: parent)
            self.reloadDataReset()
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (alert: UIAlertAction!) in
            if (parent != nil) {
                parent?.resetColors()
            }
        })

        alertController.addAction(accentAction)
        alertController.addAction(somethingAction)
        alertController.addAction(cancelAction)

        alertController.modalPresentationStyle = .popover
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = sender as! UIButton
            presenter.sourceRect = (sender as! UIButton).bounds
        }

        //todo make this work on ipad
        present(alertController, animated: true, completion: nil)
    }

    func pickAccent(sender: AnyObject?, parent: MainViewController?) {
        parentController = parent
        let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)

        isAccent = true
        let margin: CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: alertController.view.bounds.size.width - margin * 4.0, height: 150)
        let MKColorPicker = ColorPickerView.init(frame: rect)
        MKColorPicker.delegate = self
        MKColorPicker.colors = GMPalette.allColorAccent()
        MKColorPicker.selectionStyle = .check
        MKColorPicker.scrollDirection = .vertical

        MKColorPicker.style = .circle

        alertController.view.addSubview(MKColorPicker)

        let somethingAction = UIAlertAction(title: "Save", style: .default, handler: { (alert: UIAlertAction!) in
            if self.accentChosen != nil {
                ColorUtil.setAccentColorForSub(sub: self.sub, color: self.accentChosen!)
            }
            self.reloadDataReset()
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (alert: UIAlertAction!) in
            if (parent != nil) {
                parent?.resetColors()
                self.sideView.backgroundColor = ColorUtil.getColorForSub(sub: self.sub)
                self.add.backgroundColor = ColorUtil.getColorForSub(sub: self.sub)
                self.hide.backgroundColor = ColorUtil.accentColorForSub(sub: self.sub)
            }
        })

        alertController.addAction(somethingAction)
        alertController.addAction(cancelAction)

        alertController.modalPresentationStyle = .popover
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = sender as! UIButton
            presenter.sourceRect = (sender as! UIButton).bounds
        }

        //todo make this work on ipad
        present(alertController, animated: true, completion: nil)
    }


    var first = true
    var indicator: MDCActivityIndicator?


    override func viewWillAppear(_ animated: Bool) {

        if (SubredditReorderViewController.changed) {
            self.reloadNeedingColor()
            self.tableView.reloadData()
        }


        if (single || !SettingValues.viewType) {
            navigationController?.setNavigationBarHidden(false, animated: true)
            navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: sub)
        }


        self.automaticallyAdjustsScrollViewInsets = false
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true

        first = false
        tableView.delegate = self

        if (savedIndex != nil) {
            tableView.reloadItems(at: [savedIndex!])
        } else {
            tableView.reloadData()
        }

        if (single && navigationController!.modalPresentationStyle != .pageSheet) {
            // let swiper = SloppySwiper.init(navigationController: self.navigationController!)
            // self.navigationController!.delegate = swiper!
        }

        self.view.backgroundColor = ColorUtil.backgroundColor


    }

    func reloadDataReset() {
        heightAtIndexPath.removeAllObjects()
        self.flowLayout.reset()
        tableView.reloadData()
        tableView.layoutIfNeeded()
    }

    func showMoreNone(_ sender: AnyObject) {
        showMore(sender, parentVC: nil)
    }

    var searchText: String?

    func search() {
        let alert = UIAlertController(title: "Search", message: "", preferredStyle: .alert)

        let config: TextField.Config = { textField in
            textField.becomeFirstResponder()
            textField.textColor = .black
            textField.placeholder = "Search for a post..."
            textField.left(image: UIImage.init(named: "search"), color: .black)
            textField.leftViewPadding = 12
            textField.borderWidth = 1
            textField.cornerRadius = 8
            textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
            textField.backgroundColor = .white
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.returnKeyType = .done
            textField.action { textField in
                self.searchText = textField.text
            }
        }

        alert.addOneTextField(configuration: config)

        alert.addAction(UIAlertAction(title: "Search All", style: .default, handler: { [weak alert] (_) in
            let text = self.searchText ?? ""
            let search = SearchViewController.init(subreddit: "all", searchFor: text)
            VCPresenter.showVC(viewController: search, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
        }))

        if (sub != "all" && sub != "frontpage" && sub != "friends" && !sub.startsWith("/m/")) {
            alert.addAction(UIAlertAction(title: "Search \(sub)", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                let search = SearchViewController.init(subreddit: self.sub, searchFor: (textField?.text!)!)
                VCPresenter.showVC(viewController: search, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
            }))
        }

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)

    }

    func doDisplaySidebar() {
        Sidebar.init(parent: self, subname: self.sub).displaySidebar()
    }

    func showMore(_ sender: AnyObject, parentVC: MainViewController? = nil) {

        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "/r/\(sub)"


        alertController.addAction(Action(ActionData(title: "Search", image: UIImage(named: "search")!.menuIcon()), style: .default, handler: { action in
            self.search()
        }))

        if (sub.contains("/m/")) {
            alertController.addAction(Action(ActionData(title: "Manage multireddit", image: UIImage(named: "info")!.menuIcon()), style: .default, handler: { action in
                self.displayMultiredditSidebar()
            }))
        } else {
            alertController.addAction(Action(ActionData(title: "Sidebar", image: UIImage(named: "info")!.menuIcon()), style: .default, handler: { action in
                self.doDisplaySidebar()
            }))
        }

        alertController.addAction(Action(ActionData(title: "Refresh", image: UIImage(named: "sync")!.menuIcon()), style: .default, handler: { action in
            self.refresh()
        }))

        alertController.addAction(Action(ActionData(title: "Gallery", image: UIImage(named: "image")!.menuIcon()), style: .default, handler: { action in
            self.galleryMode()
        }))

        alertController.addAction(Action(ActionData(title: "Shadowbox", image: UIImage(named: "shadowbox")!.menuIcon()), style: .default, handler: { action in
            self.shadowboxMode()
        }))

        alertController.addAction(Action(ActionData(title: "Subreddit theme", image: UIImage(named: "colors")!.menuIcon()), style: .default, handler: { action in
            if (parentVC != nil) {
                let p = (parentVC!)
                self.pickTheme(sender: sender, parent: p)
            } else {
                self.pickTheme(sender: sender, parent: nil)
            }
        }))

        if (!single && (sub != "all" && sub != "frontpage" && !sub.contains("+") && !sub.contains("/m/"))) {
            alertController.addAction(Action(ActionData(title: "Submit", image: UIImage(named: "edit")!.menuIcon()), style: .default, handler: { action in
                self.newPost(sender)
            }))
        }

        alertController.addAction(Action(ActionData(title: "Filter content", image: UIImage(named: "filter")!.menuIcon()), style: .default, handler: { action in
            self.filterContent()
        }))

        alertController.addAction(Action(ActionData(title: "Cancel", image: UIImage(named: "close")!.menuIcon()), style: .default, handler: { action in
        }))

        VCPresenter.presentAlert(alertController, parentVC: self)

    }
    
    func filterContent(){
        let alert = UIAlertController(title: "Content to hide on", message: "/r/\(sub)", preferredStyle: .alert)
        
        let settings = Filter(subreddit: sub, parent: self)
        
        alert.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: nil))
        alert.setValue(settings, forKey: "contentViewController")
        present(alert, animated: true, completion: nil)
    }

    func newPost(_ sender: AnyObject) {
        let actionSheetController2: UIAlertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)

        var cancelActionButton2: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController2.addAction(cancelActionButton2)


        cancelActionButton2 = UIAlertAction(title: "Image", style: .default) { action -> Void in
            VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(subreddit: self.sub, type: ReplyViewController.ReplyType.SUBMIT_IMAGE, completion: { (submission) in
                VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: submission!.permalink)!), popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
            })), parentVC: self)
        }
        actionSheetController2.addAction(cancelActionButton2)


        cancelActionButton2 = UIAlertAction(title: "Link", style: .default) { action -> Void in
            VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(subreddit: self.sub, type: ReplyViewController.ReplyType.SUBMIT_LINK, completion: { (submission) in
                VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: submission!.permalink)!), popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
            })), parentVC: self)
        }
        actionSheetController2.addAction(cancelActionButton2)


        cancelActionButton2 = UIAlertAction(title: "Text", style: .default) { action -> Void in
            VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(subreddit: self.sub, type: ReplyViewController.ReplyType.SUBMIT_TEXT, completion: { (submission) in
                VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: submission!.permalink)!), popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
            })), parentVC: self)
        }
        actionSheetController2.addAction(cancelActionButton2)

        if let presenter = actionSheetController2.popoverPresentationController {
            presenter.sourceView = (sender as! UIView)
            presenter.sourceRect = (sender as! UIView).bounds
        }

        self.present(actionSheetController2, animated: true)

    }

    func galleryMode() {
        let controller = GalleryTableViewController()
        var gLinks: [RSubmission] = []
        for l in links {
            if l.banner {
                gLinks.append(l)
            }
        }
        controller.setLinks(links: gLinks)
        controller.modalPresentationStyle = .overFullScreen
        present(controller, animated: true, completion: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.statusBarView?.backgroundColor = ColorUtil.getColorForSub(sub: self.sub)
        (navigationController)?.setToolbarHidden(false, animated: true)

        setupFab()
    }

    func shadowboxMode() {
        let controller = ShadowboxViewController.init(submissions: links)
        controller.modalPresentationStyle = .overFullScreen
        present(controller, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return links.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var target = CurrentType.none
        let submission = self.links[(indexPath as NSIndexPath).row]

        var thumb = submission.thumbnail
        var big = submission.banner
        let height = submission.height

        var type = ContentType.getContentType(baseUrl: submission.url!)
        if (submission.isSelf) {
            type = .SELF
        }

        if (SettingValues.bannerHidden) {
            big = false
            thumb = true
        }

        let fullImage = ContentType.fullImage(t: type)

        if (!fullImage && height < 50) {
            big = false
            thumb = true
        }

        if (type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big) {
            big = false
            thumb = false
        }

        if (height < 50) {
            thumb = true
            big = false
        }

        if (type == ContentType.CType.SELF && SettingValues.hideImageSelftext
                || SettingValues.noImages && submission.isSelf) {
            big = false
            thumb = false
        }

        if (big || !submission.thumbnail) {
            thumb = false
        }


        if (!big && !thumb && submission.type != .SELF && submission.type != .NONE) { //If a submission has a link but no images, still show the web thumbnail
            thumb = true
        }

        if (submission.nsfw && (!SettingValues.nsfwPreviews || SettingValues.hideNSFWCollection && (sub == "all" || sub == "frontpage" || sub.contains("/m/") || sub.contains("+") || sub == "popular"))) {
            big = false
            thumb = true
        }

        if (SettingValues.noImages) {
            big = false
            thumb = false
        }
        if (thumb && type == .SELF) {
            thumb = false
        }

        if (thumb && !big) {
            target = .thumb
        } else if (big) {
            target = .banner
        } else {
            target = .text
        }

        var cell: LinkCellView?
        if (target == .thumb) {
            cell = tableView.dequeueReusableCell(withReuseIdentifier: "thumb", for: indexPath) as! ThumbnailLinkCellView
        } else if (target == .banner) {
            cell = tableView.dequeueReusableCell(withReuseIdentifier: "banner", for: indexPath) as! BannerLinkCellView
        } else {
            cell = tableView.dequeueReusableCell(withReuseIdentifier: "text", for: indexPath) as! TextLinkCellView
        }

        cell?.preservesSuperviewLayoutMargins = false
        cell?.del = self
        if indexPath.row == self.links.count - 3 && !loading && !nomore {
            self.loadMore()
        }

        (cell)!.setLink(submission: submission, parent: self, nav: self.navigationController, baseSub: sub)

        cell?.layer.shouldRasterize = true
        cell?.layer.rasterizationScale = UIScreen.main.scale

        return cell!

    }

    var loading = false
    var nomore = false

    func loadMore() {
        if (!showing) {
            showLoader()
        }
        load(reset: false)
    }

    var showing = false

    func showLoader() {
        showing = true
        //todo maybe?
    }

    var sort = SettingValues.defaultSorting
    var time = SettingValues.defaultTimePeriod

    func showMenu(_ selector: UIButton?) {
        let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)

        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)

        let selected = UIImage.init(named: "selected")!.imageResize(sizeChange: CGSize.init(width: 20, height: 20)).withColor(tintColor: .blue)

        for link in LinkSortType.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: link.description, style: .default) { action -> Void in
                self.showTimeMenu(s: link, selector: selector)
            }
            if(sort == link){
                saveActionButton.setValue(selected, forKey: "image")
            }
            actionSheetController.addAction(saveActionButton)
        }

        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = selector!
            presenter.sourceRect = selector!.bounds
        }

        self.present(actionSheetController, animated: true, completion: nil)

    }

    func showTimeMenu(s: LinkSortType, selector: UIButton?) {
        if (s == .hot || s == .new) {
            sort = s
            refresh()
            return
        } else {
            let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)

            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Close", style: .cancel) { action -> Void in
            }
            actionSheetController.addAction(cancelActionButton)

            let selected = UIImage.init(named: "selected")!.imageResize(sizeChange: CGSize.init(width: 20, height: 20)).withColor(tintColor: .blue)

            for t in TimeFilterWithin.cases {
                let saveActionButton: UIAlertAction = UIAlertAction(title: t.param, style: .default) { action -> Void in
                    print("Sort is \(s) and time is \(t)")
                    self.sort = s
                    self.time = t
                    self.refresh()
                }
                if(time == t){
                    saveActionButton.setValue(selected, forKey: "image")
                }

                actionSheetController.addAction(saveActionButton)
            }

            if let presenter = actionSheetController.popoverPresentationController {
                presenter.sourceView = selector!
                presenter.sourceRect = selector!.bounds
            }

            self.present(actionSheetController, animated: true, completion: nil)
        }
    }

    var refreshControl: UIRefreshControl!

    func refresh() {
        links = []
        tableView.reloadData()
        flowLayout.reset()
        flowLayout.invalidateLayout()
        load(reset: true)
    }

    func deleteSelf(_ cell: LinkCellView) {
        do {
            try session?.deleteCommentOrLink(cell.link!.getId(), completion: { (stream) in
                DispatchQueue.main.async {
                    if (self.navigationController!.modalPresentationStyle == .formSheet) {
                        self.navigationController!.dismiss(animated: true)
                    } else {
                        self.navigationController!.popViewController(animated: true)
                    }
                }
            })
        } catch {

        }
    }

    var savedIndex: IndexPath?
    var realmListing: RListing?

    func load(reset: Bool) {
        if (!loading) {
            if (!loaded) {
                if (indicator == nil) {
                    indicator = MDCActivityIndicator.init(frame: CGRect.init(x: CGFloat(0), y: CGFloat(0), width: CGFloat(80), height: CGFloat(80)))
                    indicator?.strokeWidth = 5
                    indicator?.radius = 20
                    indicator?.indicatorMode = .indeterminate
                    indicator?.cycleColors = [ColorUtil.getColorForSub(sub: sub), ColorUtil.accentColorForSub(sub: sub)]
                    let center = CGPoint.init(x: self.tableView.center.x, y: CGFloat(tableView.bounds.height / 2))
                    indicator?.center = center
                    self.tableView.addSubview(indicator!)
                    indicator?.startAnimating()
                }
            }
            loaded = true

            do {
                loading = true
                if (reset) {
                    paginator = Paginator()
                }
                var subreddit: SubredditURLPath = Subreddit.init(subreddit: sub)

                if (sub.hasPrefix("/m/")) {
                    subreddit = Multireddit.init(name: sub.substring(3, length: sub.length - 3), user: AccountController.currentName)
                }

                try session?.getList(paginator, subreddit: subreddit, sort: sort, timeFilterWithin: time, completion: { (result) in
                    switch result {
                    case .failure:
                        //test if realm exists and show that
                        DispatchQueue.main.async {
                            print("Getting realm data")
                            do {
                                let realm = try Realm()
                                var updated = NSDate()
                                if let listing = realm.objects(RListing.self).filter({ (item) -> Bool in
                                    return item.subreddit == self.sub
                                }).first {
                                    self.links = []
                                    for i in listing.links {
                                        self.links.append(i)
                                    }
                                    updated = listing.updated
                                }
                                var paths = [IndexPath]()
                                for i in 0...(self.links.count - 1) {
                                    paths.append(IndexPath.init(item: i, section: 0))
                                }

                                    self.flowLayout.reset()
                                    self.tableView.reloadData()
                                    self.tableView.contentOffset = CGPoint.init(x: 0, y: -64 + ((SettingValues.viewType && !self.single) ? -20 : 0))

                                self.refreshControl.endRefreshing()
                                self.indicator?.stopAnimating()
                                self.loading = false
                                self.loading = false
                                self.nomore = true

                                if (self.links.isEmpty) {
                                    let message = MDCSnackbarMessage()
                                    message.text = "No offline content found"
                                    MDCSnackbarManager.show(message)
                                } else {
                                    let message = MDCSnackbarMessage()
                                    message.text = "Showing offline content (\(DateFormatter().timeSince(from: updated, numericDates: true)))"
                                    MDCSnackbarManager.show(message)
                                }
                            } catch {

                            }
                        }
                        print(result.error!)
                    case .success(let listing):

                        if (reset) {
                            self.links = []
                        }
                        let before = self.links.count
                        if (self.realmListing == nil) {
                            self.realmListing = RListing()
                            self.realmListing!.subreddit = self.sub
                            self.realmListing!.updated = NSDate()
                        }
                        if (reset && self.realmListing!.links.count > 0) {
                            self.realmListing!.links.removeAll()
                        }

                        let newLinks = listing.children.flatMap({ $0 as? Link })
                        var converted: [RSubmission] = []
                        for link in newLinks {
                            let newRS = RealmDataWrapper.linkToRSubmission(submission: link)
                            converted.append(newRS)
                            CachedTitle.addTitle(s: newRS)
                        }
                        let values = PostFilter.filter(converted, previous: self.links, baseSubreddit: self.sub)
                        self.links += values
                        self.paginator = listing.paginator
                        self.nomore = !listing.paginator.hasMore() || values.isEmpty
                        do {
                            let realm = try! Realm()
                            //todo insert
                            realm.beginWrite()
                            for submission in self.links {
                                realm.create(type(of: submission), value: submission, update: true)
                                self.realmListing!.links.append(submission)
                            }
                            realm.create(type(of: self.realmListing!), value: self.realmListing!, update: true)
                            try realm.commitWrite()
                        } catch {

                        }
                        self.preloadImages(values)
                        DispatchQueue.main.async {
                            var paths = [IndexPath]()
                            for i in before...(self.links.count - 1) {
                                paths.append(IndexPath.init(item: i, section: 0))
                            }

                            if (before == 0) {
                                self.flowLayout.reset()
                                self.tableView.reloadData()
                                self.tableView.contentOffset = CGPoint.init(x: 0, y: -64 + ((SettingValues.viewType && !self.single) ? -20 : 0))
                            } else {
                                self.tableView.insertItems(at: paths)
                                self.flowLayout.reset()
                            }

                            self.refreshControl.endRefreshing()
                            self.indicator?.stopAnimating()
                            self.loading = false
                        }
                    }
                })
            } catch {
                print(error)
            }

        }
    }


    func preloadImages(_ values: [RSubmission]) {
        var urls: [URL] = []
        for submission in values {
            var thumb = submission.thumbnail
            var big = submission.banner
            var height = submission.height
            var type = ContentType.getContentType(baseUrl: submission.url!)
            if (submission.isSelf) {
                type = .SELF
            }

            if (thumb && type == .SELF) {
                thumb = false
            }

            let fullImage = ContentType.fullImage(t: type)

            if (!fullImage && height < 50) {
                big = false
                thumb = true
            } else if (big && (SettingValues.bigPicCropped)) {
                height = 200
            }

            if (type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big || type == .SELF) {
                big = false
                thumb = false
            }

            if (height < 50) {
                thumb = true
                big = false
            }

            let shouldShowLq = SettingValues.dataSavingEnabled && submission.lQ && !(SettingValues.dataSavingDisableWiFi && LinkCellView.checkWiFi())
            if (type == ContentType.CType.SELF && SettingValues.hideImageSelftext
                    || SettingValues.noImages && submission.isSelf) {
                big = false
                thumb = false
            }

            if (big || !submission.thumbnail) {
                thumb = false
            }

            if (!big && !thumb && submission.type != .SELF && submission.type != .NONE) {
                thumb = true
            }

            if (thumb && !big) {
                if (submission.thumbnailUrl == "nsfw") {
                } else if (submission.thumbnailUrl == "web" || submission.thumbnailUrl.isEmpty) {
                } else {
                    if let url = URL.init(string: submission.thumbnailUrl) {
                        urls.append(url)
                    }
                }
            }

            if (big) {
                if (shouldShowLq) {
                    if let url = URL.init(string: submission.lqUrl) {
                        urls.append(url)
                    }

                } else {
                    if let url = URL.init(string: submission.bannerUrl) {
                        urls.append(url)
                    }
                }
            }

        }
        SDWebImagePrefetcher.init().prefetchURLs(urls)
    }

    var oldsize = CGFloat(0)

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.frame = self.view.bounds
        if (self.view.bounds.width != oldsize) {
            oldsize = self.view.bounds.width
            flowLayout.reset()
            tableView.reloadData()
        }

    }

    func mod(_ cell: LinkCellView) {

        //go here
        //todo remove with reason, new icons
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Submission by /u/\(cell.link!.author)"

        alertController.addAction(Action(ActionData(title: "\(cell.link!.reports.count) reports", image: UIImage(named: "reports")!.menuIcon()), style: .default, handler: { action in
            var reports = ""
            for report in cell.link!.reports {
                reports = reports + report + "\n"
            }
            let alert = UIAlertController(title: "Reports",
                    message: reports,
                    preferredStyle: UIAlertControllerStyle.alert)

            let cancelAction = UIAlertAction(title: "OK",
                    style: .cancel, handler: nil)

            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)

        }))
        alertController.addAction(Action(ActionData(title: "Approve", image: UIImage(named: "approve")!.menuIcon()), style: .default, handler: { action in
            self.modApprove(cell)
        }))

        alertController.addAction(Action(ActionData(title: "Ban user", image: UIImage(named: "ban")!.menuIcon()), style: .default, handler: { action in
            //todo show dialog for this
        }))

        alertController.addAction(Action(ActionData(title: "Set flair", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { action in
            cell.flairSelf()
        }))

        if(!cell.link!.nsfw){
            alertController.addAction(Action(ActionData(title: "Mark as NSFW", image: UIImage(named: "hide")!.menuIcon()), style: .default, handler: { action in
                self.modNSFW(cell, true)
            }))
        } else {
            alertController.addAction(Action(ActionData(title: "Unmark as NSFW", image: UIImage(named: "hide")!.menuIcon()), style: .default, handler: { action in
                self.modNSFW(cell, false)
            }))
        }

        if(!cell.link!.spoiler){
            alertController.addAction(Action(ActionData(title: "Mark as spoiler", image: UIImage(named: "reports")!.menuIcon()), style: .default, handler: { action in
                self.modSpoiler(cell, true)
            }))
        } else {
            alertController.addAction(Action(ActionData(title: "Unmark as spoiler", image: UIImage(named: "reports")!.menuIcon()), style: .default, handler: { action in
                self.modSpoiler(cell, false)
            }))
        }

        if(cell.link!.locked){
            alertController.addAction(Action(ActionData(title: "Unlock thread", image: UIImage(named: "lock")!.menuIcon()), style: .default, handler: { action in
                self.modLock(cell, false)
            }))
        } else {
            alertController.addAction(Action(ActionData(title: "Lock thread", image: UIImage(named: "lock")!.menuIcon()), style: .default, handler: { action in
                self.modLock(cell, true)
            }))
        }

        if (cell.link!.author == AccountController.currentName) {
            alertController.addAction(Action(ActionData(title: "Distinguish", image: UIImage(named: "save")!.menuIcon()), style: .default, handler: { action in
                self.modDistinguish(cell)
            }))
        }

        if (cell.link!.author == AccountController.currentName) {
            if (cell.link!.stickied) {
                alertController.addAction(Action(ActionData(title: "Un-sticky", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { action in
                    self.modSticky(cell, sticky: false)
                }))
            } else {
                alertController.addAction(Action(ActionData(title: "Sticky and distinguish", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { action in
                    self.modSticky(cell, sticky: true)
                }))
            }
        }

        alertController.addAction(Action(ActionData(title: "Remove", image: UIImage(named: "close")!.menuIcon()), style: .default, handler: { action in
            self.modRemove(cell)
        }))

        alertController.addAction(Action(ActionData(title: "Remove with reason", image: UIImage(named: "close")!.menuIcon()), style: .default, handler: { action in
            self.modRemove(cell)
            //todo this
        }))

        alertController.addAction(Action(ActionData(title: "Mark as spam", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { action in
            self.modRemove(cell, spam: true)
        }))

        alertController.addAction(Action(ActionData(title: "User profile", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { action in
            let prof = ProfileViewController.init(name: cell.link!.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self);
        }))

        alertController.addAction(Action(ActionData(title: "Cancel", image: UIImage(named: "close")!.menuIcon()), style: .default, handler: nil))

        VCPresenter.presentAlert(alertController, parentVC: self)
    }

    func modLock(_ cell: LinkCellView, _ set: Bool) {
        let id = cell.link!.id
        do {
            try self.session?.setLocked(id, locked: set, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Locking submission failed!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                case .success(_):
                    CachedTitle.approved.append(id)
                    if (CachedTitle.removed.contains(id)) {
                        CachedTitle.removed.remove(at: CachedTitle.removed.index(of: id)!)
                    }
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Submission locked!"
                        MDCSnackbarManager.show(message)
                        cell.link!.locked = set
                        cell.refreshLink(cell.link!)
                    }
                    break
                }
            })
        } catch {
            print(error)
        }
    }

    func modSpoiler(_ cell: LinkCellView, _ set: Bool) {
        let id = cell.link!.id
        do {
            try self.session?.setSpoiler(id, spoiler: set, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Request failed!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                case .success(_):
                    CachedTitle.approved.append(id)
                    if (CachedTitle.removed.contains(id)) {
                        CachedTitle.removed.remove(at: CachedTitle.removed.index(of: id)!)
                    }
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Spoiler tag set!"
                        cell.link!.spoiler = set
                        cell.refreshLink(cell.link!)
                        MDCSnackbarManager.show(message)
                    }
                    break
                }
            })
        } catch {
            print(error)
        }
    }

    func modNSFW(_ cell: LinkCellView, _ set: Bool) {
        let id = cell.link!.id
        do {
            try self.session?.setNSFW(id, nsfw: set, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Request failed!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                case .success(_):
                    CachedTitle.approved.append(id)
                    if (CachedTitle.removed.contains(id)) {
                        CachedTitle.removed.remove(at: CachedTitle.removed.index(of: id)!)
                    }
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "NSFW tag set!"
                        cell.link!.nsfw = set
                        cell.refreshLink(cell.link!)
                        MDCSnackbarManager.show(message)
                    }
                    break
                }
            })
        } catch {
            print(error)
        }
    }

    func modApprove(_ cell: LinkCellView) {
        let id = cell.link!.id
        do {
            try self.session?.approve(id, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Approving submission failed!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                case .success(_):
                    CachedTitle.approved.append(id)
                    if (CachedTitle.removed.contains(id)) {
                        CachedTitle.removed.remove(at: CachedTitle.removed.index(of: id)!)
                    }
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Submission approved!"
                        cell.refreshLink(cell.link!)
                        MDCSnackbarManager.show(message)
                    }
                    break
                }
            })
        } catch {
            print(error)
        }
    }

    func modDistinguish(_ cell: LinkCellView) {
        let id = cell.link!.id
        do {
            try self.session?.distinguish(id, how: "yes", completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Distinguishing submission failed!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                case .success(_):
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Submission distinguished!"
                        cell.link!.distinguished = "mod"
                        cell.refreshLink(cell.link!)
                        MDCSnackbarManager.show(message)
                    }
                    break
                }
            })
        } catch {
            print(error)
        }
    }

    func modSticky(_ cell: LinkCellView, sticky: Bool) {
        let id = cell.link!.id
        do {
            try self.session?.sticky(id, sticky: sticky, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Couldn't \(sticky ? "" : "un-")sticky submission!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                case .success(_):
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Submission \(sticky ? "" : "un-")stickied!"
                        cell.link!.stickied = sticky
                        cell.refreshLink(cell.link!)
                        MDCSnackbarManager.show(message)
                    }
                    break
                }
            })
        } catch {
            print(error)
        }
    }

    func modRemove(_ cell: LinkCellView, spam: Bool = false) {
        let id = cell.link!.id
        do {
            try self.session?.remove(id, spam: spam, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Removing submission failed!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                case .success(_):
                    CachedTitle.removed.append(id)
                    if (CachedTitle.approved.contains(id)) {
                        CachedTitle.approved.remove(at: CachedTitle.approved.index(of: id)!)
                    }
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Submission removed!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                }
            })

        } catch {
            print(error)
        }
    }

    func modBan(_ cell: LinkCellView, why: String, duration: Int?) {
        let id = cell.link!.id
        do {
            try self.session?.ban(cell.link!.author, banReason: why, duration: duration == nil ? 999 /*forever*/ : duration!, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Banning user failed!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                case .success(_):
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "/u/\(cell.link!.author) banned!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                }

            })
        } catch {
            print(error)
        }
    }

}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        // Handling Modal views/Users/carloscrane/Desktop/Slide for Reddit/Slide for Reddit/SettingValues.swift
        if let presentedViewController = self.presentedViewController {
            return presentedViewController.topMostViewController()
        }
        // Handling UIViewController's added as subviews to some other views.
        else {
            for view in self.view.subviews {
                // Key property which most of us are unaware of / rarely use.
                if let subViewController = view.next {
                    if subViewController is UIViewController {
                        let viewController = subViewController as! UIViewController
                        return viewController.topMostViewController()
                    }
                }
            }
            return self
        }
    }
}

extension UITabBarController {
    override func topMostViewController() -> UIViewController {
        return self.selectedViewController!.topMostViewController()
    }
}

extension UINavigationController {
    override func topMostViewController() -> UIViewController {
        return self.visibleViewController!.topMostViewController()
    }
}

extension UILabel {

    func fitFontForSize(minFontSize: CGFloat = 5.0, maxFontSize: CGFloat = 300.0, accuracy: CGFloat = 1.0) {
        var minFontSize = minFontSize
        var maxFontSize = maxFontSize
        assert(maxFontSize > minFontSize)
        layoutIfNeeded()
        let constrainedSize = bounds.size
        while maxFontSize - minFontSize > accuracy {
            let midFontSize: CGFloat = ((minFontSize + maxFontSize) / 2)
            font = font.withSize(midFontSize)
            sizeToFit()
            let checkSize: CGSize = bounds.size
            if checkSize.height < constrainedSize.height && checkSize.width < constrainedSize.width {
                minFontSize = midFontSize
            } else {
                maxFontSize = midFontSize
            }
        }
        font = font.withSize(minFontSize)
        sizeToFit()
        layoutIfNeeded()
    }

}

extension UIImage {
    func cropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {

        let contextImage: UIImage = UIImage(cgImage: image.cgImage!)

        let contextSize: CGSize = contextImage.size

        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)

        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }

        let rect: CGRect = CGRect.init(x: posX, y: posY, width: cgwidth, height: cgheight)

        // Create bitmap image from context using the rect
        let imageRef: CGImage = (contextImage.cgImage?.cropping(to: rect)!)!

        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage.init(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)

        return image
    }
}

//https://stackoverflow.com/a/50127204/3697225
extension UIButton {
    func leftImage(image: UIImage, renderMode: UIImageRenderingMode) {
        self.setImage(image.withRenderingMode(renderMode), for: .normal)
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: image.size.width / 2, bottom: 0, right: image.size.width / 2)
        self.contentHorizontalAlignment = .left
        self.imageView?.contentMode = .scaleAspectFit
    }

    func rightImage(image: UIImage, renderMode: UIImageRenderingMode) {
        self.setImage(image.withRenderingMode(renderMode), for: .normal)
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: image.size.width / 2, bottom: 0, right: 0)
        self.contentHorizontalAlignment = .right
        self.imageView?.contentMode = .scaleAspectFit
    }
}


extension String {
    func size(with: UIFont) -> CGSize {
        let fontAttribute = [NSFontAttributeName: with]
        let size = self.size(attributes: fontAttribute)  // for Single Line
        return size;
    }
}

extension UIApplication {

    var statusBarView: UIView? {
        return value(forKey: "statusBar") as? UIView
    }

}

