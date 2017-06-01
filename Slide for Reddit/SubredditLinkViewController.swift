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
import ChameleonFramework
import AMScrollingNavbar
import SideMenu
import KCFloatingActionButton
import UZTextView
import RealmSwift
import PagingMenuController

class SubredditLinkViewController: MediaViewController, UITableViewDelegate, UITableViewDataSource, ScrollingNavigationControllerDelegate, LinkCellViewDelegate, ColorPickerDelegate, KCFloatingActionButtonDelegate {
    
    var parentController: SubredditsViewController?
    var accentChosen: UIColor?
    func valueChanged(_ value: CGFloat, accent: Bool) {
        if(accent){
            accentChosen = UIColor.init(cgColor: GMPalette.allAccentCGColor()[Int(value * CGFloat(GMPalette.allAccentCGColor().count))])
        } else {
            self.navigationController?.navigationBar.barTintColor = UIColor.init(cgColor: GMPalette.allCGColor()[Int(value * CGFloat(GMPalette.allCGColor().count))])
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
            UIApplication.shared.open(link.url!, options: [:], completionHandler: nil)
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
                        self.view.makeToast("Report sent", duration: 3, position: .top)
                    }
                })
            } catch {
                DispatchQueue.main.async{
                    self.view.makeToast("Error sending report", duration: 3, position: .top)
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
    
    
    var links: [RSubmission] = []
    var paginator = Paginator()
    var sub : String
    var session: Session? = nil
    weak var tableView : UITableView!
    var displayMode: MenuItemDisplayMode
    var single: Bool = false
    
    /* override func previewActionItems() -> [UIPreviewActionItem] {
     let regularAction = UIPreviewAction(title: "Regular", style: .Default) { (action: UIPreviewAction, vc: UIViewController) -> Void in
     
     }
     
     let destructiveAction = UIPreviewAction(title: "Destructive", style: .Destructive) { (action: UIPreviewAction, vc: UIViewController) -> Void in
     
     }
     
     let actionGroup = UIPreviewActionGroup(title: "Group...", style: .Default, actions: [regularAction, destructiveAction])
     
     return [regularAction, destructiveAction, actionGroup]
     }*/
    init(subName: String, parent: SubredditsViewController){
        sub = subName;
        self.parentController = parent
        displayMode = MenuItemDisplayMode.text(title: MenuItemText.init(text: sub, color: UIColor.white, selectedColor: UIColor.white, font: UIFont.systemFont(ofSize: 12), selectedFont: UIFont.systemFont(ofSize: 12)))
        super.init(nibName:nil, bundle:nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: subName))
    }
    
    init(subName: String, single: Bool){
        sub = subName
        self.single = true
        displayMode = MenuItemDisplayMode.text(title: MenuItemText.init(text: sub, color: UIColor.white, selectedColor: UIColor.white, font: UIFont.systemFont(ofSize: 12), selectedFont: UIFont.systemFont(ofSize: 12)))
        super.init(nibName:nil, bundle:nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: subName))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scrollingNavigationController(_ controller: ScrollingNavigationController, didChangeState state: NavigationBarState) {
        switch state {
        case .collapsed:
           // hide(true)
            break
        case .expanded:
          //  show(true)
            break
        case .scrolling:
            break
        }
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
    
    func hide(_ animated: Bool = true) {
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
    
    override func loadView(){
        
        self.view = UITableView(frame: CGRect.zero, style: .plain)
        self.tableView = self.view as! UITableView
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.separatorColor = ColorUtil.backgroundColor
        tableView.separatorInset = .zero
        
        refreshControl = UIRefreshControl()
        self.tableView.contentOffset = CGPoint.init(x: 0, y: -self.refreshControl.frame.size.height)
        refreshControl.tintColor = ColorUtil.fontColor
        refreshControl.attributedTitle = NSAttributedString(string: "")
        refreshControl.addTarget(self, action: #selector(self.drefresh(_:)), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController
        
    }
    
    func drefresh(_ sender:AnyObject) {
        load(reset: true)
    }
    
    var heightAtIndexPath = NSMutableDictionary()

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = heightAtIndexPath.object(forKey: indexPath) as? NSNumber {
            return CGFloat(height.floatValue)
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    var sideMenu: UISideMenuNavigationController?
    // var menuNav: SubSidebarViewController?
    var subInfo: Subreddit?
    override func viewDidLoad() {
        self.tableView.register(LinkCellView.classForCoder(), forCellReuseIdentifier: "cell")
        session = (UIApplication.shared.delegate as! AppDelegate).session
        if self.links.count == 0 && !single {
            load(reset: true)
        }
        
        tableView.estimatedRowHeight = 400.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        if(single){
            sideMenu = UISideMenuNavigationController()
            
            do {
                try (UIApplication.shared.delegate as! AppDelegate).session?.about(sub, completion: { (result) in
                    switch result {
                    case .failure:
                        DispatchQueue.main.async {
                            if(self.sub == ("all") || self.sub == ("frontpage") || self.sub.hasPrefix("/m/")){
                                self.load(reset: true)
                            } else {
                                let alert = UIAlertController.init(title: "Subreddit not found", message: "/r/\(self.sub) could not be found, is it spelled correctly?", preferredStyle: .alert)
                                alert.addAction(UIAlertAction.init(title: "Ok", style: .default, handler: { (_) in
                                    let presentingViewController: UIViewController! = self.presentingViewController
                                    
                                    self.dismiss(animated: false) {
                                        // go back to MainMenuView as the eyes of the user
                                        presentingViewController.dismiss(animated: false, completion: nil)
                                    }
                                    
                                }))
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    case .success(let r):
                        self.subInfo = r
                        DispatchQueue.main.async {
                            if(self.sub != ("all") && self.sub != ("frontpage") && !self.sub.hasPrefix("/m/")){
                                if(SettingValues.saveHistory){
                                    if(SettingValues.saveNSFWHistory && self.subInfo!.over18){
                                        Subscriptions.addHistorySub(name: AccountController.currentName, sub: self.subInfo!.displayName)
                                    } else if(!self.subInfo!.over18){
                                        Subscriptions.addHistorySub(name: AccountController.currentName, sub: self.subInfo!.displayName)
                                    }
                                }
                            }
                            
                            self.load(reset: true)
                            
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
        super.viewDidLoad()
        
    }
    
    func doDisplaySidebar(_ sub: Subreddit){
        let alrController = UIAlertController(title: sub.displayName + "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", message: "\(sub.accountsActive) here now\n\(sub.subscribers) subscribers", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let margin:CGFloat = 8.0
        let rect = CGRect.init(x: margin, y: margin + 23, width: alrController.view.bounds.size.width - margin * 4.0, height: 300)
        let scrollView = UIScrollView(frame: rect)
        scrollView.backgroundColor = UIColor.clear
        var info: UZTextView = UZTextView()
        info = UZTextView(frame: CGRect(x: 0, y: 0, width: rect.size.width, height: CGFloat.greatestFiniteMagnitude))
        //todo info.delegate = self
        info.isUserInteractionEnabled = true
        info.backgroundColor = .clear
        
        if(!sub.description.isEmpty()){
            let html = sub.descriptionHtml.preprocessedHTMLStringBeforeNSAttributedStringParsing
            do {
                let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
                let font = FontGenerator.fontOfSize(size: 16, submission: false)
                let attr2 = attr.reconstruct(with: font, color: UIColor.darkGray, linkColor: ColorUtil.accentColorForSub(sub: sub.displayName))
                let contentInfo = CellContent.init(string:LinkParser.parse(attr2), width: rect.size.width)
                info.attributedString = contentInfo.attributedString
                info.frame.size.height = (contentInfo.textHeight)
                scrollView.contentSize = CGSize.init(width: rect.size.width, height: info.frame.size.height)
                scrollView.addSubview(info)
            } catch {
            }
            //todo parentController?.registerForPreviewing(with: self, sourceView: info)
        }
        
        alrController.view.addSubview(scrollView)
        
        let subscribed = sub.userIsSubscriber || subChanged && !sub.userIsSubscriber ? "Unsubscribe" : "Subscribe"
        var somethingAction = UIAlertAction(title: subscribed, style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in self.subscribe(sub)})
        alrController.addAction(somethingAction)
        
        somethingAction = UIAlertAction(title: "Submit a post", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in print("something")})
        alrController.addAction(somethingAction)
        
        somethingAction = UIAlertAction(title: "Subreddit moderators", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in print("something")})
        alrController.addAction(somethingAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {(alert: UIAlertAction!) in print("cancel")})
        
        alrController.addAction(cancelAction)
        
        self.present(alrController, animated: true, completion:{})
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

    
    var subChanged = false
    func subscribe(_ sub: Subreddit){
        if(subChanged && !sub.userIsSubscriber || sub.userIsSubscriber){
            //was not subscriber, changed, and unsubscribing again
            Subscriptions.unsubscribe(sub.displayName, session: session!)
            subChanged = false
            self.view.makeToast("Unsubscribed", duration: 4, position: .bottom)
        } else {
            let alrController = UIAlertController.init(title: "Subscribe to \(sub.displayName)", message: nil, preferredStyle: .actionSheet)
            if(AccountController.isLoggedIn){
                let somethingAction = UIAlertAction(title: "Add to sub list and subscribe", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
                    Subscriptions.subscribe(sub.displayName, true, session: self.session!)
                    self.subChanged = true
                    self.view.makeToast("Subscribed", duration: 4, position: .bottom)
                })
                alrController.addAction(somethingAction)
            }
            
            let somethingAction = UIAlertAction(title: "Add to sub list", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
                Subscriptions.subscribe(sub.displayName, false, session: self.session!)
                self.subChanged = true
                self.view.makeToast("Added", duration: 4, position: .bottom)
            })
            alrController.addAction(somethingAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {(alert: UIAlertAction!) in print("cancel")})
            
            alrController.addAction(cancelAction)
            
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
                        print(result.error)
                        DispatchQueue.main.async{
                            self.view.makeToast("Multireddit info not found", duration: 5, position: .bottom)
                        }
                        break
                    }

                })
            } catch {
            }
    }

    
    func displaySidebar(){
        if(subInfo != nil){
            doDisplaySidebar(subInfo!)
        } else {
            do {
                try (UIApplication.shared.delegate as! AppDelegate).session?.about(sub, completion: { (result) in
                    switch result {
                    case .success(let r):
                        self.subInfo = r
                        DispatchQueue.main.async {
                            self.doDisplaySidebar(r)
                        }
                    default:
                        DispatchQueue.main.async{
                            self.view.makeToast("Subreddit sidebar not found", duration: 5, position: .bottom)
                        }
                        break
                    }
                })
            } catch {
            }
            
        }
    }
    
    var listingId: String = "" //a random id for use in Realm
    
    func emptyKCFABSelected(_ fab: KCFloatingActionButton) {
        tableView.beginUpdates()
        
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
        
        tableView.deleteRows(at: indexPaths, with: .middle)
        tableView.endUpdates()
        
        print("Empty")
    }
    
    var fab : KCFloatingActionButton?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let navigationController = navigationController as? ScrollingNavigationController {
            navigationController.stopFollowingScrollView()
        }

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
            }
        })
        
        alertController.addAction(somethingAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isTranslucent = false
        (navigationController as? ScrollingNavigationController)?.showNavbar(animated: true)
        if let navigationController = self.navigationController as? ScrollingNavigationController {
         //   navigationController.followScrollView(self.tableView, delay: 50.0)
         //   navigationController.scrollingNavbarDelegate = self
        }
        if(single){
            self.navigationController?.navigationBar.barTintColor = UIColor.white
            if(navigationController != nil){
                self.title = sub
                let sort = UIButton.init(type: .custom)
                sort.setImage(UIImage.init(named: "ic_sort_white"), for: UIControlState.normal)
                sort.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
                sort.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
                let sortB = UIBarButtonItem.init(customView: sort)
                
                let more = UIButton.init(type: .custom)
                more.setImage(UIImage.init(named: "ic_more_vert_white"), for: UIControlState.normal)
                more.addTarget(self, action: #selector(self.showMoreNone(_:)), for: UIControlEvents.touchUpInside)
                more.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
                let moreB = UIBarButtonItem.init(customView: more)
                
                navigationItem.rightBarButtonItems = [ moreB, sortB]
            } else if parentController != nil && parentController?.navigationController != nil{
                parentController?.navigationController?.title = sub
                let sort = UIButton.init(type: .custom)
                sort.setImage(UIImage.init(named: "ic_sort_white"), for: UIControlState.normal)
                sort.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
                sort.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
                let sortB = UIBarButtonItem.init(customView: sort)
                
                let more = UIButton.init(type: .custom)
                more.setImage(UIImage.init(named: "ic_more_vert_white"), for: UIControlState.normal)
                more.addTarget(self, action: #selector(self.showMoreNone(_:)), for: UIControlEvents.touchUpInside)
                more.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
                let moreB = UIBarButtonItem.init(customView: more)
                
                parentController?.navigationItem.rightBarButtonItems = [ moreB, sortB]
            }
        } else {
            paging = true
        }
        super.viewWillAppear(animated)
         if(savedIndex != nil){
         tableView.reloadRows(at: [savedIndex!], with: .none)
         } else {
         tableView.reloadData()
         }
    }
    
    func reloadDataReset(){
        heightAtIndexPath.removeAllObjects()
        tableView.reloadData()
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
            self.parentController?.show(search, sender: self.parentController)
        }))
        
        if(sub != "all" && sub != "frontpage" && sub != "friends"){
            alert.addAction(UIAlertAction(title: "Search \(sub)", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                let search = SearchViewController.init(subreddit: self.sub, searchFor: (textField?.text!)!)
                self.parentController?.show(search, sender: self.parentController)
            }))
        }
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        parentController?.present(alert, animated: true, completion: nil)
        
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
                self.displaySidebar()
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return links.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! LinkCellView
        
        let link = self.links[(indexPath as NSIndexPath).row]
        cell.setLink(submission: link, parent: self, nav: self.navigationController)
        cell.delegate = self
        if indexPath.row == self.links.count - 1 && !loading {
            self.loadMore()
        }
        
        return cell
    }
    
    var loading = false
    
    func loadMore(){
        if(!showing){
            showLoader()
        }
        load(reset: false)
    }
    
    var showing = false
    func showLoader() {
        showing = true
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        spinner.frame = CGRect(x: 0, y: 0.0, width: 80.0, height: 80.0)
        spinner.center = CGPoint(x: tableView.frame.size.width  / 2,
                                 y: tableView.frame.size.height / 2);
        
        tableView.tableFooterView = spinner
        spinner.startAnimating()
        
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
        reloadDataReset()
        refreshControl.beginRefreshing()
        load(reset: true)
    }
    
    var savedIndex: IndexPath?
    var realmListing: RListing?
    
    func load(reset: Bool){
        if(!loading){
            do {
                loading = true
                refreshControl.beginRefreshing()
                if(reset){
                    paginator = Paginator()
                }
                if(sub.hasPrefix("/m/")){
                    try session?.getList(paginator, subreddit: Multireddit.init(name: sub.substring(3, length: sub.length - 3), user: AccountController.currentName) , sort: sort, timeFilterWithin: time, completion: { (result) in
                        switch result {
                        case .failure:
                            //test if realm exists and show that
                            DispatchQueue.main.async {
                                print("Getting realm data")
                                do {
                                    let realm = try Realm()
                                    if let listing =  realm.objects(RListing.self).filter({ (item) -> Bool in
                                        return item.subreddit == self.sub
                                    }).sorted(by: { (listing1, listing2) -> Bool in
                                        return listing1.created.timeIntervalSince1970 < listing2.created.timeIntervalSince1970
                                    }).first {
                                        self.links = []
                                        for i in listing.links {
                                            self.links.append(i)
                                        }
                                        
                                        self.reloadDataReset()
                                    }
                                    self.refreshControl.endRefreshing()
                                    self.loading = false
                                    
                                    if(self.links.isEmpty){
                                        self.view.makeToast("No offline data found", duration: 10, position: .top)
                                    } else {
                                        self.view.makeToast("Showing offline data", duration: 10, position: .top)
                                    }
                                } catch {
                                    
                                }
                            }
                            print(result.error!)
                        case .success(let listing):
                            if(reset){
                                self.links = []
                            }
                            if(self.listingId.isEmpty || self.realmListing == nil){
                                self.listingId = UUID.init().uuidString
                                self.realmListing = RListing()
                                self.realmListing!.id = self.listingId
                                self.realmListing!.subreddit = self.sub
                            }
                            let links = listing.children.flatMap({$0 as? Link})
                            var converted : [RSubmission] = []
                            for link in links {
                                converted.append(RealmDataWrapper.linkToRSubmission(submission: link))
                            }
                            self.links.append(contentsOf: converted)
                            let values = PostFilter.filter(converted, previous: self.links)
                            self.preloadImages(values)
                            self.links += values
                            self.paginator = listing.paginator
                            DispatchQueue.main.async{
                                do {
                                    if(reset){
                                        self.realmListing!.links.removeAll()
                                    }
                                    let realm = try! Realm()
                                    //todo insert
                                    realm.beginWrite()
                                    for submission in self.links {
                                        realm.create(type(of: submission), value: submission, update: true)
                                        self.realmListing!.links.append(objectsIn: values)
                                    }
                                    realm.create(type(of: self.realmListing!), value: self.realmListing!, update: true)
                                    try realm.commitWrite()
                                } catch {
                                    
                                }
                                
                                self.reloadDataReset()
                                self.refreshControl.endRefreshing()
                                self.loading = false
                            }
                        }
                    })
                } else {
                    print("Sort is \(self.sort) and time is \(self.time)")
                    
                    try session?.getList(paginator, subreddit: Subreddit.init(subreddit: sub) , sort: sort, timeFilterWithin: time, completion: { (result) in
                        switch result {
                        case .failure:
                            //test if realm exists and show that
                            DispatchQueue.main.async {
                                print("Getting realm data")
                                do {
                                    let realm = try Realm()
                                    if let listing =  realm.objects(RListing.self).filter({ (item) -> Bool in
                                        return item.subreddit == self.sub
                                    }).sorted(by: { (listing1, listing2) -> Bool in
                                        return listing1.created.timeIntervalSince1970 > listing2.created.timeIntervalSince1970
                                    }).first {
                                        self.links = []
                                        for i in listing.links {
                                            self.links.append(i)
                                        }
                                        self.reloadDataReset()
                                    }
                                    self.refreshControl.endRefreshing()
                                    self.loading = false
                                    
                                    if(self.links.isEmpty){
                                        self.view.makeToast("No offline data found", duration: 10, position: .top)
                                    } else {
                                        self.view.makeToast("Showing offline data", duration: 10, position: .top)
                                    }
                                } catch {
                                    
                                }
                            }
                            print(result.error!)
                        case .success(let listing):
                            
                            
                            if(reset){
                                self.links = []
                            }
                            if(self.listingId.isEmpty || self.realmListing == nil){
                                self.listingId = UUID.init().uuidString
                                self.realmListing = RListing()
                                self.realmListing!.id = self.listingId
                                self.realmListing!.subreddit = self.sub
                            }
                            
                            let links = listing.children.flatMap({$0 as? Link})
                            var converted : [RSubmission] = []
                            for link in links {
                                converted.append(RealmDataWrapper.linkToRSubmission(submission: link))
                            }
                            
                            let values = PostFilter.filter(converted, previous: self.links)
                            self.links += values
                            self.paginator = listing.paginator
                            DispatchQueue.main.async{
                                do {
                                    if(reset){
                                        self.realmListing!.links.removeAll()
                                    }

                                    let realm = try! Realm()
                                    //todo insert
                                    realm.beginWrite()
                                    for submission in self.links {
                                        realm.create(type(of: submission), value: submission, update: true)
                                        self.realmListing!.links.append(objectsIn: values)
                                    }
                                    realm.create(type(of: self.realmListing!), value: self.realmListing!, update: true)
                                    try realm.commitWrite()
                                } catch {
                                    
                                }
                                
                                self.reloadDataReset()
                                self.refreshControl.endRefreshing()
                                self.loading = false
                            }
                        }
                    })
                }
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
            
            let shouldShowLq = SettingValues.lqEnabled && false && submission.lQ
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
    
}
extension UIViewController {
    func topMostViewController() -> UIViewController {
        // Handling Modal views
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
