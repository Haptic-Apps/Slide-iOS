//
//  TodayViewController.swift
//  SubredditWidget
//
//  Created by Carlos Crane on 6/12/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    var tableView: UICollectionView!
    let sectionInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    let itemsPerRow: CGFloat = 3
    var links = [RSubmission]()
    
    func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
        <#code#>
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = sectionInsets
        
        tableView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WidgetLinkCellView.classForCoder(), forCellWithReuseIdentifier: "thumb")
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return max(links.count, 5)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath)
        cell.backgroundColor = .blue
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        // toggle height in case of more/less button event
        if activeDisplayMode == .compact {
            self.preferredContentSize = CGSize(width: 0, height: 110)
        } else {
            self.preferredContentSize = CGSize(width: 0, height: 220)
        }
    }
}
