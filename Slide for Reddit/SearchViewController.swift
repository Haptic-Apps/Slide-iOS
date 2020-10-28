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
import SDCAlertView
import UIKit

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
        let edit = UIButton(buttonImage: UIImage(sfString: SFSymbol.pencil, overrideString: "edit"))
        edit.addTarget(self, action: #selector(self.edit(_:)), for: UIControl.Event.touchUpInside)
        let editB = UIBarButtonItem.init(customView: edit)

        let time = UIButton(buttonImage: UIImage(sfString: SFSymbol.clockFill, overrideString: "restore"))
        time.addTarget(self, action: #selector(self.time(_:)), for: UIControl.Event.touchUpInside)
        timeB = UIBarButtonItem.init(customView: time)

        let filter = UIButton(buttonImage: UIImage(named: "filter"))
        filter.addTarget(self, action: #selector(self.filter(_:)), for: UIControl.Event.touchUpInside)
        filterB = UIBarButtonItem.init(customView: filter)

        navigationItem.rightBarButtonItems = [editB, filterB, timeB]
    }
    
    var filterB = UIBarButtonItem.init()
    var timeB = UIBarButtonItem.init()
    
    @objc func time(_ sender: UIView) {
        let actionSheetController = DragDownAlertMenu(title: "Select a time period", subtitle: "", icon: nil, themeColor: ColorUtil.baseAccent, full: true)
        
        let selected = UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "selected")!.menuIcon()

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
        
        let selected = UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "selected")!.menuIcon()
        
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
        
        alert.addTextInput(title: "Search again", icon: UIImage(sfString: SFSymbol.magnifyingglass, overrideString: "search")?.menuIcon(), action: {
            alert.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                let text = alert.getText() ?? ""
                self.search = text
                if let base = self.baseData as? SearchContributionLoader {
                    base.query = self.search
                    base.reset()
                    self.tableView.reloadData()
                    self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y - (self.refreshControl!.frame.size.height)), animated: true)
                    
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2, execute: {
                        self.refreshControl?.beginRefreshing()
                    })
                    base.getData(reload: true)
                    self.navigationItem.titleView = self.setTitle(title: self.search, subtitle: "r/\(self.sub)")
                }
            }
        }, inputPlaceholder: "Edit your search...", inputValue: self.search, inputIcon: UIImage(sfString: SFSymbol.pencil, overrideString: "edit")!.menuIcon(), textRequired: true, exitOnAction: true)
        
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
