//
//  SubredditLinkViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/22/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import SDWebImage
import SideMenu
import KCFloatingActionButton
import UZTextView
import RealmSwift
import MaterialComponents.MaterialSnackbar
import MaterialComponents.MDCActivityIndicator
import TTTAttributedLabel
import SloppySwiper

class SubredditLinkViewController: MediaViewController, UICollectionViewDelegate,  UICollectionViewDataSource, LinkCellViewDelegate, ColorPickerDelegate, KCFloatingActionButtonDelegate,  WrappingFlowLayoutDelegate {
    
    let maxHeaderHeight: CGFloat = 120;
    let minHeaderHeight: CGFloat = 56;

    
    func openComments(id: String) {
        var index = 0
        for s in links {
            if(s.getId() == id){
                break
            }
            index += 1
        }
        var newLinks : [RSubmission] = []
        for i in index...links.count - 1{
            newLinks.append(links[i])
        }
        
        
        if(UIScreen.main.traitCollection.userInterfaceIdiom == .pad && Int(round(self.view.bounds.width / CGFloat(320))) > 1 && SettingValues.multiColumn && navigationController!.modalPresentationStyle != .pageSheet){
            let comment = PagingCommentViewController.init(submissions: newLinks)
            let navigationController = TapBehindModalViewController(rootViewController: comment)
            navigationController.modalPresentationStyle = .pageSheet
            navigationController.modalTransitionStyle = .crossDissolve
            self.present(navigationController, animated: true, completion: nil)
        } else if(UIScreen.main.traitCollection.userInterfaceIdiom != .pad || navigationController!.modalPresentationStyle == .pageSheet){
            let comment = PagingCommentViewController.init(submissions: newLinks)
            self.navigationController?.pushViewController(comment, animated: true)
        } else {
            let comment = CommentViewController.init(submission: newLinks[0])
            let nav = UINavigationController.init(rootViewController: comment)
            self.splitViewController?.showDetailViewController(nav, sender: self)
            
        }
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return [ UIKeyCommand(input: " ", modifierFlags: [], action: #selector(spacePressed)) ]
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
        if(SettingValues.postViewMode == .CARD ){
            itemWidth -= 10
        }
        
        let submission = links[indexPath.row]
        
        var thumb = submission.thumbnail
        var big = submission.banner
        
        var type = ContentType.getContentType(baseUrl: submission.url!)
        if(submission.isSelf){
            type = .SELF
        }
        
        if(SettingValues.bannerHidden){
            big = false
            thumb = true
        }
        
        let fullImage = ContentType.fullImage(t: type)
        var submissionHeight = submission.height

        if(!fullImage && submissionHeight < 50){
            big = false
            thumb = true
        } else if(big && (SettingValues.bigPicCropped )){
            submissionHeight = 200
        } else if(big){
            let ratio = Double(submissionHeight)/Double(submission.width)
            let width = Double(itemWidth);

            let h = width*ratio
            if(h == 0){
                submissionHeight = 200
            } else {
                submissionHeight  = Int(h)
            }
        }
        
        
        if(type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big){
            big = false
            thumb = false
        }
        
        if(submissionHeight < 50){
            thumb = true
            big = false
        }

        
        if(big || !submission.thumbnail){
            thumb = false
        }
        
        
        if(!big && !thumb && submission.type != .SELF && submission.type != .NONE){ //If a submission has a link but no images, still show the web thumbnail
            thumb = true
        }
        
        if(submission.nsfw && !SettingValues.nsfwPreviews){
            big = false
            thumb = true
        }
        
        if(submission.nsfw && SettingValues.hideNSFWCollection && (sub == "all" || sub == "frontpage" || sub == "popular")){
            big = false
            thumb = true
        }
        
        
        if(SettingValues.noImages){
            big = false
            thumb = false
        }
        if(thumb && type == .SELF){
            thumb = false
        }
        
        
        let he = CachedTitle.getTitle(submission: submission, full: false, false).boundingRect(with: CGSize.init(width: itemWidth - 24 - (SettingValues.postViewMode == .CARD ? 10:0) - (thumb ? (SettingValues.largerThumbnail ? 75 : 50) + 28 : 0), height:10000), options: [.usesLineFragmentOrigin , .usesFontLeading], context: nil).height
        let thumbheight = CGFloat(SettingValues.largerThumbnail ? 83 : 58)
        let estimatedHeight = CGFloat((he < thumbheight && thumb || he < thumbheight && !big) ? thumbheight : he) + CGFloat(48) + (SettingValues.postViewMode == .CARD ? 10:0) + (SettingValues.hideButtonActionbar ? -28 : 0) +  CGFloat(big && !thumb ? (submissionHeight + 20) : 0)
        return CGSize(width: itemWidth, height: estimatedHeight)
    }

    
    var parentController: SubredditsViewController?
    var accentChosen: UIColor?
    func valueChanged(_ value: CGFloat, accent: Bool) {
        if(accent){
            let c = UIColor.init(cgColor: GMPalette.allAccentCGColor()[Int(value * CGFloat(GMPalette.allAccentCGColor().count))])
            accentChosen = c
            hide.backgroundColor = c
        } else {
            let c = UIColor.init(cgColor: GMPalette.allCGColor()[Int(value * CGFloat(GMPalette.allCGColor().count))])
            self.navigationController?.navigationBar.barTintColor = c
                sideView.backgroundColor = c
            add.backgroundColor = c
            sideView.backgroundColor = c
            if(parentController != nil){
                parentController?.colorChanged()
            }
        }
    }
    
    func reply(_ cell: LinkCellView){
        
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
        if(SettingValues.markReadOnScroll){
            History.addSeen(s: links[indexPath.row])
        }
    }
    
    func upvote(_ cell: LinkCellView) {
        do{
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
            try session?.setHide(true, name: cell.link!.getId(), completion: {(result) in })
            let id = cell.link!.getId()
            var location = 0
            var item = links[0]
            for submission in links {
                if(submission.getId() == id){
                    item = links[location]
                    links.remove(at: location)
                    break
                }
                location += 1
            }
            
            tableView.performBatchUpdates({
                self.tableView.deleteItems(at: [IndexPath.init(item: location, section: 0)])
                self.flowLayout.reset()
                let message = MDCSnackbarMessage.init(text: "Submission hidden forever")
                let action = MDCSnackbarMessageAction()
                let actionHandler = {() in
                    self.links.insert(item, at: location)
                    self.tableView.insertItems(at: [IndexPath.init(item: location, section: 0)])
                    do {
                        try self.session?.setHide(false, name: cell.link!.getId(), completion: {(result) in })
                    }catch {
                        
                    }
                    
                }
                action.handler = actionHandler
                action.title = "UNDO"
                
                message.action = action
                MDCSnackbarManager.show(message)

            }, completion: nil)

            } catch {
            
        }
    }
    
    var isCollapsed = false
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let currentY = scrollView.contentOffset.y;
        var didHide = false
        
        if(currentY > lastYUsed && currentY > 60) {
            if(navigationController != nil && !(navigationController!.isNavigationBarHidden)){
            hideUI(inHeader: true)
            didHide = true
            }
        } else if((currentY < lastYUsed + 20 ) && navigationController != nil && (navigationController!.isNavigationBarHidden)){
            showUI()
        }
        lastYUsed = currentY
        lastY = currentY
    }

    func hideUI(inHeader: Bool){
        (navigationController)?.setNavigationBarHidden(true, animated: true)
        if(inHeader){
        hide.isHidden = true
        add.isHidden = true
        }
    }
    
    func showUI(){
        (navigationController)?.setNavigationBarHidden(false, animated: true)
        hide.isHidden = false
        add.isHidden = false
    }

    
    func more(_ cell: LinkCellView){
        let link = cell.link!
        let actionSheetController: UIAlertController = UIAlertController(title: link.title, message: "", preferredStyle: .actionSheet)
        
        var cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "/u/\(link.author)", style: .default) { action -> Void in
            self.show(ProfileViewController.init(name: link.author), sender: self)
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "/r/\(link.subreddit)", style: .default) { action -> Void in
            self.show(SubredditLinkViewController.init(subName: link.subreddit, single: true), sender: self)
        }
        actionSheetController.addAction(cancelActionButton)
        
        if(AccountController.isLoggedIn){
            
            cancelActionButton = UIAlertAction(title: "Save", style: .default) { action -> Void in
                self.save(cell)
            }
            actionSheetController.addAction(cancelActionButton)
        }
        
        cancelActionButton = UIAlertAction(title: "Report", style: .default) { action -> Void in
            self.report(cell.link!)
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Hide", style: .default) { action -> Void in
            //todo hide
        }
        actionSheetController.addAction(cancelActionButton)
        
        let open = OpenInChromeController.init()
        if(open.isChromeInstalled()){
            cancelActionButton = UIAlertAction(title: "Open in Chrome", style: .default) { action -> Void in
                open.openInChrome(link.url!, callbackURL: nil, createNewTab: true)
            }
            actionSheetController.addAction(cancelActionButton)
        }
        
        cancelActionButton = UIAlertAction(title: "Open in Safari", style: .default) { action -> Void in
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(link.url!, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(link.url!)
            }
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Share content", style: .default) { action -> Void in
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [link.url!], applicationActivities: nil);
            let currentViewController:UIViewController = UIApplication.shared.keyWindow!.rootViewController!
            currentViewController.present(activityViewController, animated: true, completion: nil);
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Share comments", style: .default) { action -> Void in
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [URL.init(string: "https://reddit.com" + link.permalink)!], applicationActivities: nil);
            let currentViewController:UIViewController = UIApplication.shared.keyWindow!.rootViewController!
            currentViewController.present(activityViewController, animated: true, completion: nil);
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Fiter this content", style: .default) { action -> Void in
            self.showFilterMenu(link)
        }
        actionSheetController.addAction(cancelActionButton)
        
        actionSheetController.modalPresentationStyle = .popover
        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = cell.contentView
            presenter.sourceRect = cell.contentView.bounds
        }

        self.present(actionSheetController, animated: true, completion: nil)
        
    }
    
    func report(_ thing: Object){
        let alert = UIAlertController(title: "Report this content", message: "Enter a reason (not required)", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.text = ""
        }
        
        alert.addAction(UIAlertAction(title: "Report", style: .destructive, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            do {
                let name = (thing is RComment) ? (thing as! RComment).name : (thing as! RSubmission).name
                try self.session?.report(name, reason: (textField?.text!)!, otherReason: "", completion: { (result) in
                    DispatchQueue.main.async{
                        let message = MDCSnackbarMessage()
                        message.text = "Report sent"
                        MDCSnackbarManager.show(message)
                    }
                })
            } catch {
                DispatchQueue.main.async{
                    let message = MDCSnackbarMessage()
                    message.text = "Error sending report"
                    MDCSnackbarManager.show(message)
                }
            }
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }

    
    func showFilterMenu(_ link: RSubmission){
        let actionSheetController: UIAlertController = UIAlertController(title: "What would you like to filter?", message: "", preferredStyle: .actionSheet)
        
        var cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Posts by /u/\(link.author)", style: .default) { action -> Void in
            PostFilter.profiles.append(link.author as NSString)
            PostFilter.saveAndUpdate()
            self.links = PostFilter.filter(self.links, previous: nil)
            self.reloadDataReset()
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Posts from /r/\(link.subreddit)", style: .default) { action -> Void in
            PostFilter.subreddits.append(link.subreddit as NSString)
            PostFilter.saveAndUpdate()
            self.links = PostFilter.filter(self.links, previous: nil)
            self.reloadDataReset()
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Posts linking to \(link.domain)", style: .default) { action -> Void in
            PostFilter.domains.append(link.domain as NSString)
            PostFilter.saveAndUpdate()
            self.links = PostFilter.filter(self.links, previous: nil)
            self.reloadDataReset()
        }
        actionSheetController.addAction(cancelActionButton)
        
        self.present(actionSheetController, animated: true, completion: nil)
        
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tableView.collectionViewLayout.invalidateLayout()
        super.viewWillTransition(to: size, with: coordinator)
    }

    
    var links: [RSubmission] = []
    var paginator = Paginator()
    var sub : String
    var session: Session? = nil
    var tableView : UICollectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: UICollectionViewLayout.init())
    var single: Bool = false
    
    init(subName: String, parent: SubredditsViewController){
        sub = subName;
        self.parentController = parent

        super.init(nibName:nil, bundle:nil)
      //  setBarColors(color: ColorUtil.getColorForSub(sub: subName))
    }
    
    init(subName: String, single: Bool){
        sub = subName
        self.single = true
        super.init(nibName:nil, bundle:nil)
       // setBarColors(color: ColorUtil.getColorForSub(sub: subName))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(_ animated: Bool = true) {
        if(fab != nil){
            if animated == true {
                fab!.isHidden = false
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    self.fab!.alpha = 1
                })
            } else {
                fab!.isHidden = false
            }
        }
    }
    
    func hideFab(_ animated: Bool = true) {
        if(fab != nil){
            if animated == true {
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    self.fab!.alpha = 0
                }, completion: { finished in
                    self.fab!.isHidden = true
                })
            } else {
                fab!.isHidden = true
            }
        }
    }
    
    
    var loaded = false
    var sideView: UIView = UIView()
    var subb: UIButton = UIButton()
    
    func drefresh(_ sender:AnyObject) {
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
        if(SettingValues.viewType){
            frame = CGRect.init(x: 0, y: 0, width: frame.size.width, height: frame.size.height - 40)
        }
        
        self.tableView = UICollectionView(frame: frame, collectionViewLayout: flowLayout)
        self.view = UIView.init(frame: CGRect.zero)

        self.view.addSubview(tableView)

        self.tableView.delegate = self
        self.tableView.dataSource = self
        refreshControl = UIRefreshControl()
        indicator = MDCActivityIndicator.init(frame: CGRect.init(x: CGFloat(0), y: CGFloat(0), width: CGFloat(80), height: CGFloat(80)))
        indicator.strokeWidth = 5
        indicator.radius = 20
        indicator.indicatorMode = .indeterminate
        indicator.cycleColors = [ColorUtil.getColorForSub(sub: sub), ColorUtil.accentColorForSub(sub: sub)]

        reloadNeedingColor()

    }
   
    static var firstPresented = true
    
    var headerView = UIView()
    

    func reloadNeedingColor(){
        tableView.backgroundColor = ColorUtil.backgroundColor
        
        hide = MDCFloatingButton.init(shape: .default)
        hide.backgroundColor = ColorUtil.accentColorForSub(sub: sub)
        hide.setImage(UIImage.init(named: "hide")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), for: .normal)
        hide.sizeToFit()
        hide.addTarget(self, action:#selector(self.hideAll(_:)), for: .touchUpInside)
        hide.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(hide)

        refreshControl.tintColor = ColorUtil.fontColor
        refreshControl.attributedTitle = NSAttributedString(string: "")
        refreshControl.addTarget(self, action: #selector(self.drefresh(_:)), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController
        
        self.automaticallyAdjustsScrollViewInsets = false
        let metrics=["bottommargin" : SettingValues.viewType ? 50 : 10]
        let views=["more": more,  "hide": hide, "superview": view] as [String : Any]
        var constraint:[NSLayoutConstraint] = []

        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[hide]-bottommargin-|",
                                                                     options: NSLayoutFormatOptions(rawValue: 0),
                                                                     metrics: metrics,
                                                                     views: views))
        
        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[hide]-20-|",
                                                                     options: NSLayoutFormatOptions(rawValue: 0),
                                                                     metrics: metrics,
                                                                     views: views))
        self.view.addConstraints(constraint)

        
        self.tableView.register(BannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "banner")
        self.tableView.register(ThumbnailLinkCellView.classForCoder(), forCellWithReuseIdentifier: "thumb")
        self.tableView.register(TextLinkCellView.classForCoder(), forCellWithReuseIdentifier: "text")
        
        self.tableView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 40, right: 0)

        session = (UIApplication.shared.delegate as! AppDelegate).session
        
        if (SubredditLinkViewController.firstPresented && !single) || (self.links.count == 0 && !single && !SettingValues.viewType) {
            load(reset: true)
            SubredditLinkViewController.firstPresented = false
        }
        
        if(single){

            let sort = UIButton.init(type: .custom)
            sort.setImage(UIImage.init(named: "ic_sort_white")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), for: UIControlState.normal)
            sort.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
            sort.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
            let sortB = UIBarButtonItem.init(customView: sort)
            
            let shadowbox = UIButton.init(type: .custom)
            shadowbox.setImage(UIImage.init(named: "shadowbox")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), for: UIControlState.normal)
            shadowbox.addTarget(self, action: #selector(self.shadowboxMode), for: UIControlEvents.touchUpInside)
            shadowbox.frame = CGRect.init(x: 0, y: 00, width: 30, height: 30)
            let sB = UIBarButtonItem.init(customView: shadowbox)

            let more = UIButton.init(type: .custom)
            var img = UIImage.init(named: "ic_more_vert_white")
                img = img?.cropToBounds(image: img!, width: 10, height: 30)
            more.setImage(img, for: UIControlState.normal)
            more.addTarget(self, action: #selector(self.showMoreNone(_:)), for: UIControlEvents.touchUpInside)
            more.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
            let moreB = UIBarButtonItem.init(customView: more)

            navigationItem.rightBarButtonItems = [ moreB, sortB, sB]

            do {
                try (UIApplication.shared.delegate as! AppDelegate).session?.about(sub, completion: { (result) in
                    switch result {
                    case .failure:
                        print(result.error!.description)
                        DispatchQueue.main.async {
                            if(self.sub == ("all") || self.sub == ("frontpage") || self.sub.hasPrefix("/m/") || self.sub.contains("+")){
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
                            if(self.subInfo!.over18 && !SettingValues.nsfwEnabled){
                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                                let alert = UIAlertController.init(title: "/r/\(self.sub) is NSFW", message: "If you are 18 and willing to see adult content, enable NSFW content in Settings > Content", preferredStyle: .alert)
                                alert.addAction(UIAlertAction.init(title: "Close", style: .default, handler: { (_) in
                                    self.navigationController?.popViewController(animated: true)
                                    self.dismiss(animated: true, completion: nil)
                                }))
                                self.present(alert, animated: true, completion: nil)
                                }
                            } else {
                            if(self.sub != ("all") && self.sub != ("frontpage") && !self.sub.hasPrefix("/m/")){
                                if(SettingValues.saveHistory){
                                    if(SettingValues.saveNSFWHistory && self.subInfo!.over18){
                                        Subscriptions.addHistorySub(name: AccountController.currentName, sub: self.subInfo!.displayName)
                                    } else if(!self.subInfo!.over18){
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
        
        if(false && SettingValues.hiddenFAB){
            fab = KCFloatingActionButton()
            fab!.buttonColor = ColorUtil.accentColorForSub(sub: sub)
            fab!.buttonImage = UIImage.init(named: "hide")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30))
            fab!.fabDelegate = self
            fab!.sticky = true
            self.view.addSubview(fab!)
        }
    }
    
    func exit(){
        self.navigationController?.popViewController(animated: true)
        if(self.navigationController!.modalPresentationStyle  == .pageSheet){
            self.navigationController!.dismiss(animated: true, completion: nil)
        }
    }
    
    var lastY: CGFloat = CGFloat(0)
    var add : MDCFloatingButton = MDCFloatingButton()
    var hide : MDCFloatingButton = MDCFloatingButton()
    var lastYUsed = CGFloat(0)
    
    func hideAll(_ sender: AnyObject){
        for submission in links {
            if(History.getSeen(s: submission)){
                let index = links.index(of: submission)!
                links.remove(at: index)
            }
        }
        tableView.reloadData()
        self.flowLayout.reset()
    }
    
    
    
    func doDisplayMultiSidebar(_ sub: Multireddit){
        let alrController = UIAlertController(title: sub.displayName, message: sub.descriptionMd, preferredStyle: UIAlertControllerStyle.actionSheet)
        for s in sub.subreddits {
            let somethingAction = UIAlertAction(title: "/r/" + s, style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
                self.show(SubredditLinkViewController.init(subName: s, single: true), sender: self)
            })
            let color = ColorUtil.getColorForSub(sub: s)
            if(color != ColorUtil.baseColor){
                somethingAction.setValue(color, forKey: "titleTextColor")

            }
            alrController.addAction(somethingAction)

        }
        var somethingAction = UIAlertAction(title: "Edit multireddit", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in print("something")})
        alrController.addAction(somethingAction)
        
        somethingAction = UIAlertAction(title: "Delete multireddit", style: UIAlertActionStyle.destructive, handler: {(alert: UIAlertAction!) in print("something")})
        alrController.addAction(somethingAction)
        

        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {(alert: UIAlertAction!) in print("cancel")})
        
        alrController.addAction(cancelAction)
        
        self.present(alrController, animated: true, completion:{})
    }

    func subscribeSingle(_ selector: AnyObject){
        if(subChanged && !Subscriptions.isSubscriber(sub) || Subscriptions.isSubscriber(sub)){
            //was not subscriber, changed, and unsubscribing again
            Subscriptions.unsubscribe(sub, session: session!)
            subChanged = false
            let message = MDCSnackbarMessage()
            message.text = "Unsubscribed"
            MDCSnackbarManager.show(message)
            subb.setImage(UIImage.init(named: "addcircle")?.withColor(tintColor: ColorUtil.fontColor), for: UIControlState.normal)
        } else {
            let alrController = UIAlertController.init(title: "Subscribe to \(sub)", message: nil, preferredStyle: .actionSheet)
            if(AccountController.isLoggedIn){
                let somethingAction = UIAlertAction(title: "Add to sub list and subscribe", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
                    Subscriptions.subscribe(self.sub, true, session: self.session!)
                    self.subChanged = true
                    let message = MDCSnackbarMessage()
                    message.text = "Subscribed"
                    MDCSnackbarManager.show(message)
                    self.subb.setImage(UIImage.init(named: "subbed")?.withColor(tintColor: ColorUtil.fontColor), for: UIControlState.normal)
                })
                alrController.addAction(somethingAction)
            }
            
            let somethingAction = UIAlertAction(title: "Add to sub list", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
                Subscriptions.subscribe(self.sub, false, session: self.session!)
                self.subChanged = true
                let message = MDCSnackbarMessage()
                message.text = "Added"
                MDCSnackbarManager.show(message)
                self.subb.setImage(UIImage.init(named: "subbed")?.withColor(tintColor: ColorUtil.fontColor), for: UIControlState.normal)
            })
            alrController.addAction(somethingAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {(alert: UIAlertAction!) in print("cancel")})
            
            alrController.addAction(cancelAction)
            
            alrController.modalPresentationStyle = .fullScreen
            if let presenter = alrController.popoverPresentationController {
                presenter.sourceView = subb
                presenter.sourceRect = subb.bounds
            }

            self.present(alrController, animated: true, completion:{})
            
        }
        
    }
    
    func displayMultiredditSidebar(){
            do {
                print("Getting \(sub.substring(3, length: sub.length - 3))")
                try (UIApplication.shared.delegate as! AppDelegate).session?.getMultireddit(Multireddit.init(name: sub.substring(3, length: sub.length - 3), user: AccountController.currentName), completion: { (result) in
                    switch result {
                    case .success(let r):
                        DispatchQueue.main.async {
                            self.doDisplayMultiSidebar(r)
                        }
                    default:
                        DispatchQueue.main.async{
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
    
    func emptyKCFABSelected(_ fab: KCFloatingActionButton) {
        var indexPaths : [IndexPath] = []
        var newLinks : [RSubmission] = []
        
        var count = 0
        for submission in links {
            if(History.getSeen(s: submission)){
                indexPaths.append(IndexPath(row: count, section: 0))
            } else {
                newLinks.append(submission)
            }
            count += 1
        }
        
        links = newLinks
        
        //todo save realm
        
        tableView.deleteItems(at: indexPaths)
        
        print("Empty")
    }
    
    var fab : KCFloatingActionButton?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let height = NSNumber(value: Float(cell.frame.size.height))
        heightAtIndexPath.setObject(height, forKey: indexPath as NSCopying)
    }

    func pickTheme(parent: SubredditsViewController?){
        parentController = parent
        let alertController = UIAlertController(title: "\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let margin:CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: alertController.view.bounds.size.width - margin * 4.0, height: 120)
        let customView = ColorPicker(frame: rect)
        customView.delegate = self
        
        customView.backgroundColor = ColorUtil.backgroundColor
        alertController.view.addSubview(customView)
        
        let somethingAction = UIAlertAction(title: "Save", style: .default, handler: {(alert: UIAlertAction!) in
            ColorUtil.setColorForSub(sub: self.sub, color: (self.navigationController?.navigationBar.barTintColor)!)
            self.reloadDataReset()
        })
        
        let accentAction = UIAlertAction(title: "Accent color", style: .default, handler: {(alert: UIAlertAction!) in
            ColorUtil.setColorForSub(sub: self.sub, color: (self.navigationController?.navigationBar.barTintColor)!)
            self.pickAccent(parent: parent)
            self.reloadDataReset()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(alert: UIAlertAction!) in
            if(parent != nil){
                parent?.resetColors()
            }
        })
        
        alertController.addAction(accentAction)
        alertController.addAction(somethingAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func pickAccent(parent: SubredditsViewController?){
        parentController = parent
        let alertController = UIAlertController(title: "\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let margin:CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: alertController.view.bounds.size.width - margin * 4.0, height: 120)
        let customView = ColorPicker(frame: rect)
        customView.setAccent(accent: true)
        customView.delegate = self
        
        customView.backgroundColor = ColorUtil.backgroundColor
        alertController.view.addSubview(customView)
        
        let somethingAction = UIAlertAction(title: "Save", style: .default, handler: {(alert: UIAlertAction!) in
            if self.accentChosen != nil {
                ColorUtil.setAccentColorForSub(sub: self.sub, color: self.accentChosen!)
            }
            self.reloadDataReset()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(alert: UIAlertAction!) in
            if(parent != nil){
                parent?.resetColors()
                self.sideView.backgroundColor = ColorUtil.getColorForSub(sub: self.sub)
                self.add.backgroundColor = ColorUtil.getColorForSub(sub: self.sub)
                self.hide.backgroundColor = ColorUtil.accentColorForSub(sub: self.sub)
            }
        })
        
        alertController.addAction(somethingAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    var first = true
    var indicator: MDCActivityIndicator = MDCActivityIndicator()
    

    override func viewWillAppear(_ animated: Bool) {

        if(SubredditReorderViewController.changed){
            self.reloadNeedingColor()
            self.tableView.reloadData()
        }
                
        self.automaticallyAdjustsScrollViewInsets = false
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true

        first = false
        tableView.delegate = self

         if(savedIndex != nil){
         tableView.reloadItems(at: [savedIndex!])
         } else {
         tableView.reloadData()
         }
        self.navigationController?.setNavigationBarHidden(false, animated: true)
     //   ColorUtil.setBackgroundToolbar(toolbar: self.navigationController?.navigationBar)
        
        if(parentController == nil){
        createDotHeader()
        }
        if(single && navigationController!.modalPresentationStyle != .pageSheet){
            let swiper = SloppySwiper.init(navigationController: self.navigationController!)
            self.navigationController!.delegate = swiper!
        }
        
        if(!loaded){
            indicator.center = CGPoint.init(x: self.view.frame.size.width / 2, y: self.view.frame.size.height / 2)
            self.tableView.addSubview(indicator)
            indicator.startAnimating()
        }
    }
    
    func createDotHeader(){
        let label = UILabel()
        if(!SettingValues.viewType || single){
            label.text =  "        \(sub)"
        }
        label.textColor = .white
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.boldSystemFont(ofSize: 20)
        
        /*sideView = UIView()
        sideView = UIView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        sideView.backgroundColor = ColorUtil.getColorForSub(sub: sub)
        sideView.translatesAutoresizingMaskIntoConstraints = false
        
        label.addSubview(sideView)
        
        sideView.layer.cornerRadius = 12.5
        sideView.clipsToBounds = true*/
        let close = UIButton.init(type: .custom)
        close.setImage(UIImage.init(named: "close")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), for: UIControlState.normal)
        close.addTarget(self, action: #selector(self.exit), for: UIControlEvents.touchUpInside)
        close.frame = CGRect.init(x: -30, y: 0, width: 30, height: 30)
        let closeB = UIBarButtonItem.init(customView: close)

        label.sizeToFit()
        let leftItem = UIBarButtonItem(customView: label)
        self.navigationItem.leftBarButtonItems = [closeB, leftItem]
        self.navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: sub)
    }
    
    func reloadDataReset(){
        heightAtIndexPath.removeAllObjects()
        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableView.contentOffset = CGPoint.init(x: 0, y: 56)
    }
    
    func showMoreNone(_ sender: AnyObject){
        showMore(sender, parentVC: nil)
    }
    
    func search(){
        let alert = UIAlertController(title: "Search", message: "", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.text = ""
        }
        
        alert.addAction(UIAlertAction(title: "Search All", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            let search = SearchViewController.init(subreddit: "all", searchFor: (textField?.text!)!)
            self.navigationController?.show(search, sender: self)
        }))
        
        if(sub != "all" && sub != "frontpage" && sub != "friends" && !sub.startsWith("/m/")){
            alert.addAction(UIAlertAction(title: "Search \(sub)", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                let search = SearchViewController.init(subreddit: self.sub, searchFor: (textField?.text!)!)
                self.navigationController?.show(search, sender: self)
            }))
        }
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
        
    }
    
    func showMore(_ sender: AnyObject, parentVC: SubredditsViewController? = nil){
        let actionSheetController: UIAlertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        
        var cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Search", style: .default) { action -> Void in
            self.search()
        }
        actionSheetController.addAction(cancelActionButton)
        
        if(sub.contains("/m/")){
            cancelActionButton = UIAlertAction(title: "Manage multireddit", style: .default) { action -> Void in
                self.displayMultiredditSidebar()
            }
        } else {
            cancelActionButton = UIAlertAction(title: "Sidebar", style: .default) { action -> Void in
                Sidebar.init(parent: self, subname: self.sub).displaySidebar()
            }
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Refresh", style: .default) { action -> Void in
            self.refresh()
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Gallery mode", style: .default) { action -> Void in
            self.galleryMode()
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Shadowbox mode", style: .default) { action -> Void in
            self.shadowboxMode()
        }
        actionSheetController.addAction(cancelActionButton)
        

        cancelActionButton = UIAlertAction(title: "Subreddit Theme", style: .default) { action -> Void in
            if(parentVC != nil){
                let p = (parentVC!)
                self.pickTheme(parent: p)
            } else {
                self.pickTheme(parent: nil)
            }
            
        }
        actionSheetController.addAction(cancelActionButton)
        
        if(!single){
            cancelActionButton = UIAlertAction(title: "Base Theme", style: .default) { action -> Void in
                if(parentVC != nil){
                    (parentVC)!.showThemeMenu()
                }
            }
            actionSheetController.addAction(cancelActionButton)
        }
        
        cancelActionButton = UIAlertAction(title: "Filter", style: .default) { action -> Void in
            print("Filter")
        }
        actionSheetController.addAction(cancelActionButton)
        
        actionSheetController.modalPresentationStyle = .fullScreen
        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = self.view
            presenter.sourceRect = self.view.bounds
        }

        actionSheetController.modalPresentationStyle = .popover
        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = subb
            presenter.sourceRect = subb.bounds
        }

        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    func galleryMode(){
        let controller = GalleryTableViewController()
        var gLinks:[RSubmission] = []
        for l in links{
            if l.banner {
                gLinks.append(l)
            }
        }
        controller.setLinks(links: gLinks)
        show(controller, sender: self)
    }
    
    func shadowboxMode(){
        var gLinks:[RSubmission] = []
        for l in links{
            if l.banner {
                gLinks.append(l)
            }
        }
        let controller = ShadowboxViewController.init(submissions: gLinks)
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
        if(submission.isSelf){
            type = .SELF
        }
        
        if(SettingValues.bannerHidden){
            big = false
            thumb = true
        }
        
        let fullImage = ContentType.fullImage(t: type)
        
        if(!fullImage && height < 50){
            big = false
            thumb = true
        }
        
        if(type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big){
            big = false
            thumb = false
        }
        
        if(height < 50){
            thumb = true
            big = false
        }
        
        if (type == ContentType.CType.SELF && SettingValues.hideImageSelftext
            || SettingValues.noImages && submission.isSelf) {
            big = false
            thumb = false
        }
        
        if(big || !submission.thumbnail){
            thumb = false
        }
        
        
        if(!big && !thumb && submission.type != .SELF && submission.type != .NONE){ //If a submission has a link but no images, still show the web thumbnail
            thumb = true
        }
        
        if(submission.nsfw && (!SettingValues.nsfwPreviews || SettingValues.hideNSFWCollection && (sub == "all" || sub == "frontpage" || sub.contains("/m/") || sub.contains("+") || sub == "popular"))){
            big = false
            thumb = true
        }
        
        if(SettingValues.noImages){
            big = false
            thumb = false
        }
        if(thumb && type == .SELF){
            thumb = false
        }
        
        if(thumb && !big){
            target = .thumb
        } else if(big){
            target = .banner
        } else {
            target = .text
        }
        
        var cell: LinkCellView?
        if(target == .thumb){
            cell = tableView.dequeueReusableCell(withReuseIdentifier: "thumb", for: indexPath) as! ThumbnailLinkCellView
        } else if(target == .banner){
            cell = tableView.dequeueReusableCell(withReuseIdentifier: "banner", for: indexPath) as! BannerLinkCellView
        } else {
            cell = tableView.dequeueReusableCell(withReuseIdentifier: "text", for: indexPath) as! TextLinkCellView
        }
        
        cell?.preservesSuperviewLayoutMargins = false
        cell?.del = self
        if indexPath.row == self.links.count - 1 && !loading && !nomore {
            self.loadMore()
        }
        
        (cell)!.setLink(submission: submission, parent: self, nav: self.navigationController, baseSub: sub)
        
        cell?.layer.shouldRasterize = true
        cell?.layer.rasterizationScale = UIScreen.main.scale

        return cell!

    }
    
    var loading = false
    var nomore = false
    
    func loadMore(){
        if(!showing){
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
        func showMenu(_ selector: AnyObject){
        let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        for link in LinkSortType.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: link.description, style: .default)
            { action -> Void in
                self.showTimeMenu(s: link)
            }
            actionSheetController.addAction(saveActionButton)
        }
        
        self.present(actionSheetController, animated: true, completion: nil)
        
    }
    
    func showTimeMenu(s: LinkSortType){
        if(s == .hot || s == .new){
            sort = s
            refresh()
            return
        } else {
            let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                print("Cancel")
            }
            actionSheetController.addAction(cancelActionButton)
            
            for t in TimeFilterWithin.cases {
                let saveActionButton: UIAlertAction = UIAlertAction(title: t.param, style: .default)
                { action -> Void in
                    print("Sort is \(s) and time is \(t)")
                    self.sort = s
                    self.time = t
                    self.refresh()
                }
                actionSheetController.addAction(saveActionButton)
            }
            self.present(actionSheetController, animated: true, completion: nil)
        }
    }
    
    var refreshControl: UIRefreshControl!
    
    func refresh(){
        self.links = []
        load(reset: true)
    }
    
    var savedIndex: IndexPath?
    var realmListing: RListing?
    
    func load(reset: Bool){
        if(!loading){
            loaded = true

            do {
                loading = true
                if(reset){
                    paginator = Paginator()
                }
                var subreddit: SubredditURLPath = Subreddit.init(subreddit: sub)
                
                if(sub.hasPrefix("/m/")){
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
                                    if let listing =  realm.objects(RListing.self).filter({ (item) -> Bool in
                                        return item.subreddit == self.sub
                                    }).first {
                                        self.links = []
                                        for i in listing.links {
                                            self.links.append(i)
                                        }
                                        updated = listing.updated
                                        self.flowLayout.reset()
                                        self.reloadDataReset()
                                    }
                                    self.refreshControl.endRefreshing()
                                    self.indicator.stopAnimating()
                                    self.loading = false
                                    self.nomore = true
                                    
                                    if(self.links.isEmpty){
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
                            
                            if(reset){
                                self.links = []
                            }
                            let before = self.links.count
                            if(self.realmListing == nil){
                                self.realmListing = RListing()
                                self.realmListing!.subreddit = self.sub
                                self.realmListing!.updated = NSDate()
                            }
                            if(reset && self.realmListing!.links.count > 0){
                                self.realmListing!.links.removeAll()
                            }
                            
                            let newLinks = listing.children.flatMap({$0 as? Link})
                            var converted : [RSubmission] = []
                            for link in newLinks {
                                let newRS = RealmDataWrapper.linkToRSubmission(submission: link)
                                converted.append(newRS)
                                CachedTitle.addTitle(s: newRS)
                            }
                            let values = PostFilter.filter(converted, previous: self.links)
                            print("Link size is \(self.links.count) and values is \(values.count)")
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
                            DispatchQueue.main.async{
                                var paths = [IndexPath]()
                                for i in before...(self.links.count - 1) {
                                    print("Inserting to \(i)")
                                    paths.append(IndexPath.init(item: i, section: 0))
                                }
                                print("Size is \(self.links.count)")
                                if(before == 0){
                                    self.tableView.reloadData()
                                    self.loadViewIfNeeded()
                                    self.tableView.contentOffset = CGPoint.init(x: 0, y: -60)
                                } else {
                                    self.tableView.insertItems(at: paths)
                                }
                                
                                self.flowLayout.reset()

                                self.refreshControl.endRefreshing()
                                self.indicator.stopAnimating()
                                self.loading = false
                            }
                        }
                    })
            } catch {
                print(error)
            }
            
        }
    }

    func preloadImages(_ values: [RSubmission]){
        var urls : [URL] = []
        for submission in values {
            var thumb = submission.thumbnail
            var big = submission.banner
            var height = submission.height
            var type = ContentType.getContentType(baseUrl: submission.url!)
            if(submission.isSelf){
                type = .SELF
            }
            
            if(thumb && type == .SELF){
                thumb = false
            }
            
            let fullImage = ContentType.fullImage(t: type)
            
            if(!fullImage && height < 50){
                big = false
                thumb = true
            } else if(big && (SettingValues.bigPicCropped)){
                height = 200
            }
            
            if(type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big || type == .SELF ){
                big = false
                thumb = false
            }
            
            if(height < 50){
                thumb = true
                big = false
            }
            
            let shouldShowLq = SettingValues.dataSavingEnabled && submission.lQ && !(SettingValues.dataSavingDisableWiFi && LinkCellView.checkWiFi())
            if (type == ContentType.CType.SELF && SettingValues.hideImageSelftext
                || SettingValues.noImages && submission.isSelf) {
                big = false
                thumb = false
            }
            
            if(big || !submission.thumbnail){
                thumb = false
            }
            
            if(!big && !thumb && submission.type != .SELF && submission.type != .NONE){
                thumb = true
            }
            
            if(thumb && !big){
                if(submission.thumbnailUrl == "nsfw"){
                } else if(submission.thumbnailUrl == "web" || submission.thumbnailUrl.isEmpty){
                } else {
                    if let url = URL.init(string: submission.thumbnailUrl) {
                        urls.append(url)
                    }
                }
            }
            
            if(big){
                if(shouldShowLq){
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
        if(self.view.bounds.width != oldsize){
            oldsize = self.view.bounds.width
            flowLayout.reset()
            tableView.reloadData()
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
            for view in self.view.subviews
            {
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
    
    func fitFontForSize( minFontSize : CGFloat = 5.0, maxFontSize : CGFloat = 300.0, accuracy : CGFloat = 1.0) {
        var minFontSize = minFontSize
        var maxFontSize = maxFontSize
        assert(maxFontSize > minFontSize)
        layoutIfNeeded()
        let constrainedSize = bounds.size
        while maxFontSize - minFontSize > accuracy {
            let midFontSize : CGFloat = ((minFontSize + maxFontSize) / 2)
            font = font.withSize(midFontSize)
            sizeToFit()
            let checkSize : CGSize = bounds.size
            if  checkSize.height < constrainedSize.height && checkSize.width < constrainedSize.width {
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
