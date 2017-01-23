//
//  InboxViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/23/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import reddift
import AMScrollingNavbar

class InboxViewController:  ButtonBarPagerTabStripViewController {
    var content : [MessageWhere] = []
    var isReload = false
    var session: Session? = nil
    
    init(){
        self.session = (UIApplication.shared.delegate as! AppDelegate).session
        self.content = InboxViewController.doDefault()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func doDefault() -> [MessageWhere]{
        return [MessageWhere.inbox, MessageWhere.unread, MessageWhere.messages, MessageWhere.sent, MessageWhere.mentions]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Inbox"
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: "")
        (navigationController as? ScrollingNavigationController)?.showNavbar(animated: true)
        let edit = UIButton.init(type: .custom)
        edit.setImage(UIImage.init(named: "edit")?.imageResize(sizeChange: CGSize.init(width: 23, height: 23)), for: UIControlState.normal)
        edit.addTarget(self, action: #selector(self.new(_:)), for: UIControlEvents.touchUpInside)
        edit.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let editB = UIBarButtonItem.init(customView: edit)
        
        let read = UIButton.init(type: .custom)
        read.setImage(UIImage.init(named: "seen"), for: UIControlState.normal)
        read.addTarget(self, action: #selector(self.read(_:)), for: UIControlEvents.touchUpInside)
        read.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let readB = UIBarButtonItem.init(customView: read)
        
        if(navigationController != nil){
            navigationItem.rightBarButtonItems = [ readB, editB]
        }
        
    }
    
    func new(_ sender: AnyObject){
        let reply  = ReplyViewController.init(message: nil) { (message) in
            DispatchQueue.main.async(execute: { () -> Void in
                self.view.makeToast("Message sent", duration: 4, position: .top)
            })
        }
        
        let navEditorViewController: UINavigationController = UINavigationController(rootViewController: reply)
        prepareOverlayVC(overlayVC: navEditorViewController)
        present(navEditorViewController, animated: true, completion: nil)
        
        
    }
    private func prepareOverlayVC(overlayVC: UIViewController) {
        overlayVC.transitioningDelegate = overlayTransitioningDelegate
        overlayVC.modalPresentationStyle = .custom
    }
    
    let overlayTransitioningDelegate = OverlayTransitioningDelegate()
    
    func read(_ sender: AnyObject){
        do {
            try session?.markAllMessagesAsRead(completion: { (result) in
                switch(result){
                case .success(_):
                    DispatchQueue.main.async {
                        self.view.makeToast("All messages marked as read", duration: 3, position: .top)
                    }
                    break
                default: break
                    
                }
            })
        } catch {
            
        }
    }
    
    
    override func viewDidLoad() {
        settings.style.buttonBarItemFont = UIFont.systemFont(ofSize: 14)
        settings.style.selectedBarHeight = 3.0
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarItemTitleColor = .black
        settings.style.buttonBarItemsShouldFillAvailiableWidth = true
        
        
        settings.style.buttonBarLeftContentInset = 20
        settings.style.buttonBarRightContentInset = 20
        settings.style.buttonBarItemBackgroundColor = .clear
        
        changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            oldCell?.label.alpha = 0.5
            newCell?.label.alpha = 1
            newCell?.label.textColor = .white
            oldCell?.label.textColor = .white
        }
        view.backgroundColor = ColorUtil.backgroundColor
        // set up style before super view did load is executed
        // -
        
        super.viewDidLoad()
        self.edgesForExtendedLayout = []
        
        self.buttonBarView.backgroundColor = ColorUtil.getColorForSub(sub: "")
        self.buttonBarView.selectedBar.backgroundColor = ColorUtil.accentColorForSub(sub: "")
    }
    
    func showSortMenu(_ sender: AnyObject){
        (viewControllers[currentIndex] as? SubredditLinkViewController)?.showMenu(sender)
    }
    
    func showMenu(_ sender: AnyObject){
        let actionSheetController: UIAlertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        
        var cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Search", style: .default) { action -> Void in
            print("Search")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Refresh", style: .default) { action -> Void in
            (self.viewControllers[self.currentIndex] as? SubredditLinkViewController)?.refresh()
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Subreddit Theme", style: .default) { action -> Void in
            print("Subreddit Theme")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Base Theme", style: .default) { action -> Void in
            self.showThemeMenu()
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Filter", style: .default) { action -> Void in
            print("Filter")
        }
        actionSheetController.addAction(cancelActionButton)
        
        
        self.present(actionSheetController, animated: true, completion: nil)
        
    }
    
    func showThemeMenu(){
        let actionSheetController: UIAlertController = UIAlertController(title: "Select a base theme", message: "", preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        for theme in ColorUtil.Theme.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: theme.rawValue , style: .default)
            { action -> Void in
                UserDefaults.standard.set(theme.rawValue, forKey: "theme")
                UserDefaults.standard.synchronize()
                ColorUtil.doInit()
            }
            actionSheetController.addAction(saveActionButton)
        }
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        var controllers : [UIViewController] = []
        for place in content {
            controllers.append(ContentListingViewController.init(dataSource: InboxContributionLoader(whereContent: place)))
        }
        return Array(controllers)
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: content[pagerTabStripController.currentIndex].description)
    }
    
}
