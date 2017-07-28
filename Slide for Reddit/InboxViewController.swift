//
//  InboxViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/23/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import PagingMenuController
import MaterialComponents.MaterialSnackbar

class InboxViewController:  PagingMenuController {
    var content : [MessageWhere] = []
    var isReload = false
    var session: Session? = nil
    
    static var viewControllers : [UIViewController] = []

    struct PagingMenuOptionsBar: PagingMenuControllerCustomizable {
        var componentType: ComponentType {
            return .all(menuOptions: MenuOptions(), pagingControllers:viewControllers)
        }
    }
    struct MenuItem: MenuItemViewCustomizable {
        var horizontalMargin = 10
        var displayMode: MenuItemDisplayMode
    }

    struct MenuOptions: MenuViewCustomizable {
        var marginTop: CGFloat {
            return 0
        }

        static var color = UIColor.blue
        
        var itemsOptions: [MenuItemViewCustomizable] {
            var menuitems: [MenuItemViewCustomizable] = []
            for controller in viewControllers {
                menuitems.append(MenuItem(horizontalMargin: 10, displayMode:( (controller as! ContentListingViewController).baseData.displayMode)))
            }
            return menuitems
        }
        
        static func setColor(c: UIColor){
            color = c
        }
        
        
        var displayMode: MenuDisplayMode {
            return MenuDisplayMode.segmentedControl
        }
        
        var backgroundColor: UIColor {
            return ColorUtil.getColorForUser(name: AccountController.currentName)
        }
        var selectedBackgroundColor: UIColor {
            return ColorUtil.getColorForUser(name: AccountController.currentName)
        }
        
        var height: CGFloat {
            return 40
        }
        var animationDuration: TimeInterval {
            return 0.3
        }
        var deceleratingRate: CGFloat {
            return UIScrollViewDecelerationRateFast
        }
        var selectedItemCenter: Bool {
            return true
        }
        var focusMode: MenuFocusMode {
            return .roundRect(radius: 5, horizontalPadding: 5, verticalPadding: 5, selectedColor: .white)
        }
        var dummyItemViewsSet: Int {
            return 3
        }
        var menuPosition: MenuPosition {
            return .top
        }
        var dividerImage: UIImage? {
            return nil
        }
        
    }
    
    init(){
        self.session = (UIApplication.shared.delegate as! AppDelegate).session
        self.content = InboxViewController.doDefault()
        InboxViewController.viewControllers.removeAll()

        for place in content {
            InboxViewController.viewControllers.append(ContentListingViewController.init(dataSource: InboxContributionLoader(whereContent: place)))
        }

        super.init(options: PagingMenuOptionsBar())
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.splitViewController?.maximumPrimaryColumnWidth = 375
        self.splitViewController?.preferredPrimaryColumnWidthFraction = 0.5
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        self.title = "Inbox"
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: "")
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
                let message = MDCSnackbarMessage()
                message.text = "Message sent!"
                MDCSnackbarManager.show(message)
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
                        let message = MDCSnackbarMessage()
                        message.text = "All messages marked as read"
                        MDCSnackbarManager.show(message)
                    }
                    break
                default: break
                    
                }
            })
        } catch {
            
        }
    }
    
    var time: Double = 0
    
    override func viewDidLoad() {
        
        time = History.getInboxSeen()
        History.inboxSeen()
                view.backgroundColor = ColorUtil.backgroundColor
        // set up style before super view did load is executed
        // -
        
        super.viewDidLoad()
        self.edgesForExtendedLayout = []
        
        
        self.menuView?.backgroundColor = ColorUtil.getColorForSub(sub: "")
    }
}
