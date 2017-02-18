//
//  SubredditsViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/4/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import reddift
import AMScrollingNavbar

class ProfileViewController:  ButtonBarPagerTabStripViewController, ColorPickerDelegate {
    var content : [UserContent] = []
    var name: String
    var isReload = false
    var session: Session? = nil
    
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
            ColorUtil.setColorForUser(name: self.name, color: (self.navigationController?.navigationBar.barTintColor)!)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(alert: UIAlertAction!) in
            self.navigationController?.navigationBar.barTintColor = ColorUtil.getColorForUser(name: self.name)
        })
        
        alertController.addAction(somethingAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func tagUser(){
        let alertController = UIAlertController(title: "Tag /u/\(self.name)", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        let confirmAction = UIAlertAction(title: "Set", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                print("Setting tag \(field.text!)")
                ColorUtil.setTagForUser(name: self.name, tag: field.text!)
            } else {
                // user did not fill field
            }
        }
        
        if(!ColorUtil.getTagForUser(name: self.name).isEmpty){
        let removeAction = UIAlertAction(title: "Remove tag", style: .default) { (_) in
            ColorUtil.removeTagForUser(name: self.name)
        }
            alertController.addAction(removeAction)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Tag"
            textField.text = ColorUtil.getTagForUser(name: self.name)
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)

    }

    init(name: String){
        self.name = name
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
        super.init(nibName: nil, bundle: nil)
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
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (navigationController as? ScrollingNavigationController)?.showNavbar(animated: true)
        self.title = name
        if(navigationController != nil){
            navigationController?.navigationBar.barTintColor = ColorUtil.getColorForUser(name: name)
        }
        let sort = UIButton.init(type: .custom)
        sort.setImage(UIImage.init(named: "ic_sort_white"), for: UIControlState.normal)
        sort.addTarget(self, action: #selector(self.showSortMenu(_:)), for: UIControlEvents.touchUpInside)
        sort.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let sortB = UIBarButtonItem.init(customView: sort)
        
        let more = UIButton.init(type: .custom)
        more.setImage(UIImage.init(named: "info"), for: UIControlState.normal)
        more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
        more.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let moreB = UIBarButtonItem.init(customView: more)
        
        if(navigationController != nil){
            navigationItem.rightBarButtonItems = [ moreB, sortB]
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
                            var b = self.generateButtons(trophy: trophy)
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
                                self.view.makeToast("Unfriended /u/\(user.name)", duration: 4, position: .bottom)
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
                                print(result.error)
                            }
                            DispatchQueue.main.async {
                                self.view.makeToast("Friended /u/\(user.name)", duration: 4, position: .bottom)
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
        let tag = ColorUtil.getTagForUser(name: self.name)
        alrController.addAction(UIAlertAction.init(title: "Tag user\((!(tag.isEmpty)) ? " (currently \(tag))" : "")", style: .default, handler: { (action) in
            self.tagUser()
        }))
        
        alrController.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: { (action) in
        }))

        
        self.present(alrController, animated: true, completion:{})
        
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
        
        self.buttonBarView.backgroundColor = ColorUtil.getColorForUser(name: name)
        self.buttonBarView.selectedBar.backgroundColor = ColorUtil.accentColorForSub(sub: "")
    }
    
    func showSortMenu(_ sender: AnyObject){
        (viewControllers[currentIndex] as? SubredditLinkViewController)?.showMenu(sender)
    }
    
    func showMenu(_ sender: AnyObject){
        do {
            try session?.getUserProfile(name, completion: { (result) in
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
            controllers.append(ContentListingViewController.init(dataSource: ProfileContributionLoader.init(name: name, whereContent: place)))
        }
        return Array(controllers)
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: content[pagerTabStripController.currentIndex].title)
    }
    
}
