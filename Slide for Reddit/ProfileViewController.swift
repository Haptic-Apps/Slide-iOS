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

class ProfileViewController:  ButtonBarPagerTabStripViewController {
    var content : [UserContent] = []
    var name: String
    var isReload = false
    var session: Session? = nil
    
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
        more.setImage(UIImage.init(named: "ic_more_vert_white"), for: UIControlState.normal)
        more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
        more.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let moreB = UIBarButtonItem.init(customView: more)
        
        if(navigationController != nil){
        navigationItem.rightBarButtonItems = [ moreB, sortB]
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
        
        self.buttonBarView.backgroundColor = ColorUtil.getColorForUser(name: name)
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
            controllers.append(ContentListingViewController.init(dataSource: ProfileContributionLoader.init(name: name, whereContent: place)))
        }
        return Array(controllers)
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: content[pagerTabStripController.currentIndex].title)
    }

}
