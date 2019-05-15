//
//  OfflineOverviewViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 11/8/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import reddift
import UIKit
import UserNotifications

class OfflineOverviewViewController: UITableViewController {
    
    var subs: [String]
    
    init(subs: [String]) {
        self.subs = subs
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
        self.navigationItem.titleView = setTitle(title: "Offline content", subtitle: "No internet connection detected")
    }
    
    override func loadView() {
        super.loadView()
        
        self.view.backgroundColor = ColorUtil.theme.backgroundColor
        // set the title
        self.title = "Offline content"
        self.tableView.separatorStyle = .none
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "sub")
        
        cell.textLabel?.textColor = ColorUtil.theme.fontColor
        cell.textLabel?.font = FontGenerator.boldFontOfSize(size: 16, submission: true)
        cell.backgroundColor = ColorUtil.theme.foregroundColor
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.accessoryType = .disclosureIndicator
        cell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        cell.detailTextLabel?.numberOfLines = 0
        
       // if indexPath.row == 0 {
       //     cell.textLabel?.text = "Read later articles"
       //     cell.detailTextLabel?.text = "\(ReadLater.readLaterIDs.count)"
       // } else {
            var row = indexPath.row
           // row -= 1
            cell.textLabel?.text = subs[row]
       // }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        VCPresenter.openRedditLink("/r/\(subs[indexPath.row])", self.navigationController, self)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return self.subs.count //+ 1
        default: fatalError("Unknown number of sections")
        }
    }
    
}
