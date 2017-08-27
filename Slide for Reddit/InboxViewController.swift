//
//  InboxViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/23/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import MaterialComponents.MaterialSnackbar

class InboxViewController:  UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIToolbarDelegate {
    var content : [MessageWhere] = []
    var isReload = false
    var session: Session? = nil
    
    var vCs : [UIViewController] = [ClearVC()]

    public init(){
        self.session = (UIApplication.shared.delegate as! AppDelegate).session
        self.content = InboxViewController.doDefault()
        
        for place in content {
            vCs.append(ContentListingViewController.init(dataSource: InboxContributionLoader(whereContent: place)))
        }
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func doDefault() -> [MessageWhere]{
        return [MessageWhere.inbox, MessageWhere.messages, MessageWhere.unread]
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
        read.setImage(UIImage.init(named: "seen")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)), for: UIControlState.normal)
        read.addTarget(self, action: #selector(self.read(_:)), for: UIControlEvents.touchUpInside)
        read.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let readB = UIBarButtonItem.init(customView: read)
        
        if(navigationController != nil){
            navigationItem.rightBarButtonItems = [ readB]
        }
    }
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
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
    
    func close(){
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        var items: [String] = []
        for i in content {
            items.append(i.description)
        }
        let segment: UISegmentedControl = UISegmentedControl(items: items)
        segment.sizeToFit()
        segment.tintColor = .white
        let close = UIButton.init(type: .custom)
        close.setImage(UIImage.init(named: "close")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)), for: UIControlState.normal)
        close.addTarget(self, action: #selector(self.close), for: UIControlEvents.touchUpInside)
        close.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let closeB = UIBarButtonItem.init(customView: close)
        navigationItem.leftBarButtonItem = closeB
        segment.selectedSegmentIndex = 0;
        var toolbar = UIToolbar.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: 40))
        toolbar.addSubview(segment)
        toolbar.isTranslucent = false
        segment.frame = CGRect.init(x: 15, y: 5, width: toolbar.frame.size.width - 30, height: 30)
        toolbar.barTintColor = ColorUtil.getColorForSub(sub: "NONE")
        toolbar.delegate = self
        self.view.addSubview(toolbar)
        time = History.getInboxSeen()
        History.inboxSeen()
                view.backgroundColor = ColorUtil.backgroundColor
        // set up style before super view did load is executed
        // -
        
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self

        self.navigationController?.view.backgroundColor = UIColor.clear
        let firstViewController = vCs[1]
        
        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: true,
                           completion: nil)
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = vCs.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard vCs.count > previousIndex else {
            return nil
        }
        
        return vCs[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = vCs.index(of: viewController) else {
            return nil
        }
        
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = vCs.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return vCs[nextIndex]
    }

}
