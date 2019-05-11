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
        let actionSheetController: UIAlertController = UIAlertController(title: "Time period", message: "", preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Close", style: .cancel) { _ -> Void in
        }
        actionSheetController.addAction(cancelActionButton)
        
        let selected = UIImage(named: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)

        for t in SearchTimePeriod.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: t.path.firstUppercased, style: .default) { _ -> Void in
                (self.baseData as! SearchContributionLoader).time = t
                self.refresh()
            }
            if (baseData as! SearchContributionLoader).time == t {
                saveActionButton.setValue(selected, forKey: "image")
            }
            
            actionSheetController.addAction(saveActionButton)
        }
        
        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    @objc func filter(_ sender: UIView) {
        let actionSheetController: UIAlertController = UIAlertController(title: "Search sort", message: "", preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Close", style: .cancel) { _ -> Void in
        }
        actionSheetController.addAction(cancelActionButton)
        
        let selected = UIImage(named: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)
        
        for t in SearchSortBy.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: t.path.firstUppercased, style: .default) { _ -> Void in
                (self.baseData as! SearchContributionLoader).sorting = t
                self.refresh()
            }
            if (baseData as! SearchContributionLoader).sorting == t {
                saveActionButton.setValue(selected, forKey: "image")
            }
            
            actionSheetController.addAction(saveActionButton)
        }
        
        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        
        self.present(actionSheetController, animated: true, completion: nil)
    }

    var searchText: String?

    @objc func edit(_ sender: AnyObject) {
        let alert = AlertController(title: "Edit search", message: "", preferredStyle: .alert)

        let config: TextField.Config = { textField in
            textField.becomeFirstResponder()
            textField.textColor = ColorUtil.theme.fontColor
            textField.attributedPlaceholder = NSAttributedString(string: "Search for a post...", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor.withAlphaComponent(0.3)])
            textField.left(image: UIImage.init(named: "search"), color: ColorUtil.theme.fontColor)
            textField.layer.borderColor = ColorUtil.theme.fontColor.withAlphaComponent(0.3) .cgColor
            textField.backgroundColor = ColorUtil.theme.backgroundColor
            textField.text = self.search
            textField.leftViewPadding = 12
            textField.layer.borderWidth = 1
            textField.layer.cornerRadius = 8
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.returnKeyType = .done
            textField.action { textField in
                self.searchText = textField.text
            }
        }
        let textField = OneTextFieldViewController(vInset: 12, configuration: config).view!
        
        alert.setupTheme()
        
        alert.attributedTitle = NSAttributedString(string: "Edit search", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        
        alert.contentView.addSubview(textField)
        
        textField.edgeAnchors == alert.contentView.edgeAnchors
        textField.heightAnchor == CGFloat(44 + 12)

        alert.addAction(AlertAction(title: "Search again", style: .preferred, handler: { (_) in
            let text = self.searchText ?? ""
            let search = SearchViewController.init(subreddit: self.sub, searchFor: text)
            self.navigationController?.popViewController(animated: true)
            VCPresenter.showVC(viewController: search, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
        }))

        alert.addCancelButton()
        alert.addBlurView()
        
        present(alert, animated: true, completion: nil)

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
