//
//  SearchViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import reddift
import RLBAlertsPickers
import UIKit
import SDCAlertView

class SearchViewController: ContentListingViewController {

    var search = ""
    var sub = ""
    init(subreddit: String, searchFor: String) {
        super.init(dataSource: SearchContributionLoader.init(query: searchFor, sub: subreddit))
        baseData.delegate = self
        self.navigationItem.titleView = setTitle(title: searchFor, subtitle: "r/\(subreddit)")
        setBarColors(color: ColorUtil.getColorForSub(sub: subreddit))
        search = searchFor
        sub = subreddit
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let edit = UIButton.init(type: .custom)
        edit.setImage(UIImage.init(named: "edit")?.navIcon(), for: UIControl.State.normal)
        edit.addTarget(self, action: #selector(self.edit(_:)), for: UIControl.Event.touchUpInside)
        edit.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let editB = UIBarButtonItem.init(customView: edit)

        let time = UIButton.init(type: .custom)
        time.setImage(UIImage.init(named: "restore")?.navIcon(), for: UIControl.State.normal)
        time.addTarget(self, action: #selector(self.time(_:)), for: UIControl.Event.touchUpInside)
        time.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        timeB = UIBarButtonItem.init(customView: time)

        let filter = UIButton.init(type: .custom)
        filter.setImage(UIImage.init(named: "filter")?.navIcon(), for: UIControl.State.normal)
        filter.addTarget(self, action: #selector(self.filter(_:)), for: UIControl.Event.touchUpInside)
        filter.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        filterB = UIBarButtonItem.init(customView: filter)

        navigationItem.rightBarButtonItems = [editB, filterB, timeB]
    }
    
    var filterB = UIBarButtonItem.init()
    var timeB = UIBarButtonItem.init()
    
    @objc func time(_ sender: UIView) {
        let actionSheetController = DragDownAlertMenu(title: "Select a time period", subtitle: "", icon: nil, themeColor: ColorUtil.baseAccent, full: true)
        
        let selected = UIImage(named: "selected")!.menuIcon()

        for t in SearchTimePeriod.cases {
            actionSheetController.addAction(title: t.path.firstUppercased, icon: (baseData as! SearchContributionLoader).time == t ? selected : nil) {
                (self.baseData as! SearchContributionLoader).time = t
                self.refresh()
            }
        }
        
        actionSheetController.show(self)
    }
    
    @objc func filter(_ sender: UIView) {
        let actionSheetController = DragDownAlertMenu(title: "Select a sorting type", subtitle: "", icon: nil, themeColor: ColorUtil.baseAccent, full: true)
        
        let selected = UIImage(named: "selected")!.menuIcon()
        
        for t in SearchSortBy.cases {
            actionSheetController.addAction(title: t.path.firstUppercased, icon: (baseData as! SearchContributionLoader).sorting == t ? selected : nil) {
                (self.baseData as! SearchContributionLoader).sorting = t
                self.refresh()
            }
        }

        actionSheetController.show(self)
    }

    var searchText: String?

    @objc func edit(_ sender: AnyObject) {
        let alert = DragDownAlertMenu(title: "Edit search", subtitle: self.search, icon: nil)
        
        alert.addTextInput(title: "Search again", icon: UIImage(named: "edit")?.menuIcon(), action: {
            let text = alert.getText() ?? ""
            let search = SearchViewController.init(subreddit: self.sub, searchFor: text)
            self.navigationController?.popViewController(animated: true)
            VCPresenter.showVC(viewController: search, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
        }, inputPlaceholder: "Edit your search...", inputValue: self.search, inputIcon: UIImage(named: "search")!.menuIcon(), textRequired: true, exitOnAction: true)
        
        alert.show(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

//https://stackoverflow.com/a/28288340/3697225
extension StringProtocol {
    var firstUppercased: String {
        guard let first = first else { return "" }
        return String(first).uppercased() + dropFirst()
    }
}
