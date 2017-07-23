//
//  SubredditsViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/4/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import PagingMenuController
import MaterialComponents.MaterialSnackbar

class ProfileViewController:  PagingMenuController, ColorPickerDelegate {
    var content : [UserContent] = []
    static var name: String = ""
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
        static var color = UIColor.blue
        var marginTop: CGFloat {
            return 0
        }

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
            return ColorUtil.getColorForUser(name: name)
        }
        var selectedBackgroundColor: UIColor {
            return ColorUtil.getColorForUser(name: name)
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


    func valueChanged(_ value: CGFloat, accent: Bool) {
            self.navigationController?.navigationBar.barTintColor = UIColor.init(cgColor: GMPalette.allCGColor()[Int(value * CGFloat(GMPalette.allCGColor().count))])
        
    }

    func pickColor(){
        let alertController = UIAlertController(title: "\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let margin:CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: alertController.view.bounds.size.width - margin * 4.0, height: 120)
        let customView = ColorPicker(frame: rect)
        customView.delegate = self
        
        customView.backgroundColor = ColorUtil.backgroundColor
        alertController.view.addSubview(customView)
        
        let somethingAction = UIAlertAction(title: "Save", style: .default, handler: {(alert: UIAlertAction!) in
            ColorUtil.setColorForUser(name: ProfileViewController.name, color: (self.navigationController?.navigationBar.barTintColor)!)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(alert: UIAlertAction!) in
            self.navigationController?.navigationBar.barTintColor = ColorUtil.getColorForUser(name: ProfileViewController.name)
        })
        
        alertController.addAction(somethingAction)
        alertController.addAction(cancelAction)
        
        alertController.modalPresentationStyle = .popover
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = (moreB!.value(forKey: "view") as! UIView)
            presenter.sourceRect = (moreB!.value(forKey: "view") as! UIView).bounds
        }

        present(alertController, animated: true, completion: nil)
    }
    
    func tagUser(){
        let alertController = UIAlertController(title: "Tag /u/\(ProfileViewController.name)", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        let confirmAction = UIAlertAction(title: "Set", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                print("Setting tag \(field.text!)")
                ColorUtil.setTagForUser(name: ProfileViewController.name, tag: field.text!)
            } else {
                // user did not fill field
            }
        }
        
        if(!ColorUtil.getTagForUser(name: ProfileViewController.name).isEmpty){
        let removeAction = UIAlertAction(title: "Remove tag", style: .default) { (_) in
            ColorUtil.removeTagForUser(name: ProfileViewController.name)
        }
            alertController.addAction(removeAction)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Tag"
            textField.text = ColorUtil.getTagForUser(name: ProfileViewController.name)
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        alertController.modalPresentationStyle = .popover
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = (moreB!.value(forKey: "view") as! UIView)
            presenter.sourceRect = (moreB!.value(forKey: "view") as! UIView).bounds
        }

        self.present(alertController, animated: true, completion: nil)

    }

    init(name: String){
        ProfileViewController.viewControllers = []
        ProfileViewController.name = name
        self.session = (UIApplication.shared.delegate as! AppDelegate).session
        if let n = (session?.token.flatMap { (token) -> String? in
            return token.name
            }) as String? {
            if(name == n){
                self.content = UserContent.cases
            } else {
                self.content = ProfileViewController.doDefault()
            }
        } else {
            self.content = ProfileViewController.doDefault()
        }
        
        
        for place in content {
            ProfileViewController.viewControllers.append(ContentListingViewController.init(dataSource: ProfileContributionLoader.init(name: name, whereContent: place)))
        }
        ProfileViewController.viewControllers.remove(at: 0)

        super.init(options: PagingMenuOptionsBar())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func doDefault() -> [UserContent]{
        return [UserContent.overview, UserContent.comments, UserContent.submitted, UserContent.gilded]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    var moreB: UIBarButtonItem?
    var sortB: UIBarButtonItem?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        self.title = ProfileViewController.name
        navigationController?.navigationBar.tintColor = .white
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        if(navigationController != nil){
            navigationController?.navigationBar.barTintColor = ColorUtil.getColorForUser(name: ProfileViewController.name)
        }
        let sort = UIButton.init(type: .custom)
        sort.setImage(UIImage.init(named: "ic_sort_white"), for: UIControlState.normal)
        sort.addTarget(self, action: #selector(self.showSortMenu(_:)), for: UIControlEvents.touchUpInside)
        sort.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
         sortB = UIBarButtonItem.init(customView: sort)
        
        let more = UIButton.init(type: .custom)
        more.setImage(UIImage.init(named: "info"), for: UIControlState.normal)
        more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
        more.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
         moreB = UIBarButtonItem.init(customView: more)
        
        if(navigationController != nil){
            navigationItem.rightBarButtonItems = [ moreB!, sortB!]
        }
        
    }
    
    func showMenu(user: Account){
        let alrController = UIAlertController(title: user.name + "\n\n\n\n", message: "\(user.linkKarma) post karma\n\(user.commentKarma) comment karma\nRedditor for \("todo")", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let margin:CGFloat = 8.0
        let rect = CGRect.init(x: margin, y: margin + 23, width: alrController.view.bounds.size.width - margin * 4.0, height:75)
        let scrollView = UIScrollView(frame: rect)
        scrollView.backgroundColor = UIColor.clear
        
        //todo add trophies
        do {
            try session?.getTrophies(user.name, completion: { (result) in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let trophies):
                    var i = 0
                    DispatchQueue.main.async {
                        for trophy in trophies {
                            let b = self.generateButtons(trophy: trophy)
                            b.frame = CGRect.init(x: i * 75, y: 0, width: 70, height: 70)
                            scrollView.addSubview(b)
                            i += 1
                        }
                        scrollView.contentSize = CGSize.init(width: i * 75, height: 70)
                    }
                }
            })
        } catch {
            
        }
        scrollView.delaysContentTouches = false
        
    
        alrController.view.addSubview(scrollView)
        if(AccountController.isLoggedIn){
            alrController.addAction(UIAlertAction.init(title: "Private message", style: .default, handler: { (action) in
                //todo send
            }))
            if(user.isFriend){
                alrController.addAction(UIAlertAction.init(title: "Unfriend", style: .default, handler: { (action) in
                    do {
                        try self.session?.unfriend(user.name, completion: { (result) in
                            DispatchQueue.main.async {
                                let message = MDCSnackbarMessage()
                                message.text = "Unfriended /u/\(user.name)"
                                MDCSnackbarManager.show(message)
                            }
                        })
                    } catch {
                        
                    }
                }))
            } else {
                alrController.addAction(UIAlertAction.init(title: "Friend", style: .default, handler: { (action) in
                    do {
                        try self.session?.friend(user.name, completion: { (result) in
                            if(result.error != nil){
                                print(result.error!)
                            }
                            DispatchQueue.main.async {
                                let message = MDCSnackbarMessage()
                                message.text = "Friended /u/\(user.name)"
                                MDCSnackbarManager.show(message)
                            }
                        })
                    } catch {
                        
                    }
                }))
            }
        }
        alrController.addAction(UIAlertAction.init(title: "Change color", style: .default, handler: { (action) in
            self.pickColor()
        }))
        let tag = ColorUtil.getTagForUser(name: ProfileViewController.name)
        alrController.addAction(UIAlertAction.init(title: "Tag user\((!(tag.isEmpty)) ? " (currently \(tag))" : "")", style: .default, handler: { (action) in
            self.tagUser()
        }))
        
        alrController.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: { (action) in
        }))

        alrController.modalPresentationStyle = .popover
        if let presenter = alrController.popoverPresentationController {
            presenter.sourceView = (moreB!.value(forKey: "view") as! UIView)
            presenter.sourceRect = (moreB!.value(forKey: "view") as! UIView).bounds
        }

        
        self.present(alrController, animated: true, completion:{})
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.splitViewController?.maximumPrimaryColumnWidth = 375
        self.splitViewController?.preferredPrimaryColumnWidthFraction = 0.5
    }

    
    func generateButtons(trophy: Trophy) -> UIImageView {
        let more = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 70, height: 70))
        more.sd_setImage(with: trophy.icon70!)
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.trophyTapped(_:)))
        singleTap.numberOfTapsRequired = 1
        
        more.isUserInteractionEnabled = true
        more.addGestureRecognizer(singleTap)
        
        return more
    }
    
    func trophyTapped(_ sender: AnyObject){
    }
    
    override func viewDidLoad() {
       
        view.backgroundColor = ColorUtil.backgroundColor
        // set up style before super view did load is executed
        // -
        
        super.viewDidLoad()
        self.edgesForExtendedLayout = []
        
        self.menuView?.backgroundColor = ColorUtil.getColorForUser(name: ProfileViewController.name)
    }
    
    func showSortMenu(_ sender: AnyObject){
        (ProfileViewController.viewControllers[currentPage] as? SubredditLinkViewController)?.showMenu(sender)
    }
    
    func showMenu(_ sender: AnyObject){
        do {
            try session?.getUserProfile(ProfileViewController.name, completion: { (result) in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let account):
                    self.showMenu(user: account)
                }
            })
        } catch {
            
        }
    }
    
}
