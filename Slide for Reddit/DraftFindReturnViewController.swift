//
//  DraftFindReturnViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/1/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import Anchorage
import UIKit

class DraftFindReturnViewController: MediaTableViewController, UIGestureRecognizerDelegate {
    
    var baseDrafts: [String] = []

    var callback: (_ draft: String) -> Void?
    
    init(callback: @escaping (_ sub: String) -> Void) {
        self.callback = callback
        super.init(nibName: nil, bundle: nil)
        baseDrafts = Drafts.drafts as [String]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if let indexPathForSelectedRow = tableView.indexPathForSelectedRow,
            indexPathForSelectedRow == indexPath {
            tableView.deselectRow(at: indexPath, animated: false)
            return nil
        }
        return indexPath
    }

    override func loadView() {
        super.loadView()
        self.automaticallyAdjustsScrollViewInsets = false
        self.tableView.register(DraftCellView.classForCoder(), forCellReuseIdentifier: "draft")
        
        tableView.backgroundColor = .clear
        tableView.separatorColor = ColorUtil.theme.backgroundColor
        tableView.separatorInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        
        tableView.reloadData()
        tableView.allowsMultipleSelection = true
    }
    
    class DraftCellView: UITableViewCell {
        var value = ""
        var label = UILabel()
        
        var separator = UIView()
        
        func setDraft(_ string: String) {
            label.text = string
            self.value = string
            label.preferredMaxLayoutWidth = label.frame.size.width
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            configureViews()
            configureLayout()
        }
        
        func configureViews() {
            
            self.label = UILabel()
            self.label.font = FontGenerator.fontOfSize(size: 16, submission: false)
            self.label.backgroundColor = .clear
            self.label.layer.cornerRadius = 5
            
            self.contentView.backgroundColor = .clear
            self.backgroundColor = .clear
            self.label.textColor = ColorUtil.theme.fontColor
            self.label.numberOfLines = 0
            self.label.clipsToBounds = true
            
            self.separator = UIView().then {
                $0.backgroundColor = ColorUtil.theme.fontColor.withAlphaComponent(0.5)
            }
            
            self.contentView.addSubviews(label, separator)
        }
        
        func configureLayout() {
            batch {
                label.leftAnchor == contentView.leftAnchor + 2
                label.rightAnchor == contentView.rightAnchor - 2
                label.topAnchor == contentView.topAnchor + 8
                separator.topAnchor == label.bottomAnchor + 8
                separator.horizontalAnchors == contentView.horizontalAnchors
                separator.bottomAnchor == contentView.bottomAnchor
                separator.heightAnchor == CGFloat(1)
            }
        }
        
        override func setSelected(_ selected: Bool, animated: Bool) {
            if selected {
                self.label.backgroundColor = ColorUtil.baseAccent.withAlphaComponent(0.2)
            } else {
                self.label.backgroundColor = .clear
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.title = "Drafts"
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return baseDrafts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thing = baseDrafts[indexPath.row]
        let c = tableView.dequeueReusableCell(withIdentifier: "draft", for: indexPath) as! DraftCellView
        c.setDraft(thing)
        if (self.tableView.indexPathsForSelectedRows ?? []).contains(indexPath) {
            c.label.backgroundColor = ColorUtil.baseAccent.withAlphaComponent(0.2)
        } else {
            c.label.backgroundColor = .clear
        }
        return c
    }
    
}
