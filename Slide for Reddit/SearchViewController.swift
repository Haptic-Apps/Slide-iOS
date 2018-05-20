//
//  SearchViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class SearchViewController: ContentListingViewController {

    var search = ""
    var sub = ""
    init(subreddit: String, searchFor: String){
        super.init(dataSource: SearchContributionLoader.init(query: searchFor, sub: subreddit))
        baseData.delegate = self
        self.title = searchFor
        setBarColors(color: ColorUtil.getColorForSub(sub: subreddit))
        search = searchFor
        sub = subreddit
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let edit = UIButton.init(type: .custom)
        edit.setImage(UIImage.init(named: "edit")?.navIcon(), for: UIControlState.normal)
        edit.addTarget(self, action: #selector(self.edit(_:)), for: UIControlEvents.touchUpInside)
        edit.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let editB = UIBarButtonItem.init(customView: edit)

        navigationItem.rightBarButtonItems = [editB]

    }


    func edit(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Edit search", message: "", preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.text = self.search
        }

        alert.addAction(UIAlertAction(title: "Search again", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            let search = SearchViewController.init(subreddit: self.sub, searchFor: (textField?.text!)!)
            self.navigationController?.popViewController(animated: true)
            VCPresenter.showVC(viewController: search, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
        }))

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
