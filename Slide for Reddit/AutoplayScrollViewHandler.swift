//
//  AutoplayScrollViewHandler.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/17/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import UIKit

//Abstracts logic for playing AutoplayBannerLinkCellView videos
/* To enable on any vc, include this line
     func scrollViewDidScroll(_ scrollView: UIScrollView) {
         scrollDelegate.scrollViewDidScroll(scrollView)
     }
*/

protocol AutoplayScrollViewDelegate: class {
    func didScrollExtras(_ currentY: CGFloat)
    var isScrollingDown: Bool { get set }
    var lastScrollDirectionWasDown: Bool { get set }
    var lastYUsed: CGFloat { get set }
    var lastY: CGFloat { get set }
    var currentPlayingIndex: [IndexPath] { get set }
    func getTableView() -> UICollectionView
}

class AutoplayScrollViewHandler {

    weak var delegate: AutoplayScrollViewDelegate?
    init(delegate: AutoplayScrollViewDelegate) {
        self.delegate = delegate
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentY = scrollView.contentOffset.y

        guard let delegate = self.delegate else {
            return
        }
        delegate.isScrollingDown = currentY > delegate.lastY
        delegate.didScrollExtras(currentY)
        
        delegate.lastScrollDirectionWasDown = delegate.isScrollingDown
        let center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)

        delegate.lastYUsed = currentY
        delegate.lastY = currentY

        if #available(iOS 12.0, *) {
            if SettingValues.autoPlayMode == .ALWAYS || (SettingValues.autoPlayMode == .WIFI && NetworkMonitor.shared.online) {
                let visibleVideoIndices = delegate.getTableView().indexPathsForVisibleItems
                
                let mapping: [(index: IndexPath, cell: LinkCellView)] = visibleVideoIndices.compactMap { index in
                    // Collect just cells that are autoplay video
                    if let cell = delegate.getTableView().cellForItem(at: index) as? LinkCellView {
                        return (index, cell)
                    } else {
                        return nil
                    }
                }.sorted { (item1, item2) -> Bool in
                    delegate.isScrollingDown ? item1.index.row > item2.index.row : item1.index.row < item2.index.row
                }
                
                for currentIndex in delegate.currentPlayingIndex {
                    if let currentCell = delegate.getTableView().cellForItem(at: currentIndex) as? LinkCellView, currentCell is AutoplayBannerLinkCellView || currentCell is GalleryLinkCellView {
                        let videoViewCenter = currentCell.videoView.convert(currentCell.videoView.bounds, to: nil)
                        //print("Diff for scroll down is \(abs(videoViewCenter.y - center.y)) and \(scrollView.frame.size.height / 4 )")
                        if abs(videoViewCenter.midY - center.y) > scrollView.frame.size.height / 2 && currentCell.videoView.player != nil {
                            currentCell.endVideos()
                        }
                    }
                }
                
                var chosenPlayItems = [(index: IndexPath, cell: LinkCellView)]()
                for item in mapping {
                    if item.cell is AutoplayBannerLinkCellView || item.cell is GalleryLinkCellView {
                        let videoViewCenter = item.cell.videoView.convert(item.cell.videoView.bounds, to: nil)
                        if abs(videoViewCenter.midY - center.y) > scrollView.frame.size.height / 2 {
                            continue
                        }
                        chosenPlayItems.append(item)
                    }
                }
                
                for item in chosenPlayItems {
                    if !delegate.currentPlayingIndex.contains(where: { (index2) -> Bool in
                        return item.index.row == index2.row
                    }) {
                        item.cell.doLoadVideo()
                    }
                }
                
                delegate.currentPlayingIndex = chosenPlayItems.map({ (item) -> IndexPath in
                    return item.index
                })
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func autoplayOnce(_ scrollView: UICollectionView) {
        guard let delegate = self.delegate else {
            return
        }
        if #available(iOS 12.0, *) {
            if SettingValues.autoPlayMode == .ALWAYS || (SettingValues.autoPlayMode == .WIFI && NetworkMonitor.shared.online) {
                let visibleVideoIndices = delegate.getTableView().indexPathsForVisibleItems
                        
                let mapping: [(index: IndexPath, cell: LinkCellView)] = visibleVideoIndices.compactMap { index in
                    // Collect just cells that are autoplay video
                    if let cell = delegate.getTableView().cellForItem(at: index) as? LinkCellView {
                        return (index, cell)
                    } else {
                        return nil
                    }
                }.sorted { (item1, item2) -> Bool in
                    delegate.isScrollingDown ? item1.index.row > item2.index.row : item1.index.row < item2.index.row
                }
                            
                var chosenPlayItems = [(index: IndexPath, cell: LinkCellView)]()
                for item in mapping {
                    if item.cell is AutoplayBannerLinkCellView {
                        chosenPlayItems.append(item)
                    }
                }
                
                for item in chosenPlayItems {
                    if !delegate.currentPlayingIndex.contains(where: { (index2) -> Bool in
                        return item.index.row == index2.row
                    }) {
                        (item.cell as! AutoplayBannerLinkCellView).doLoadVideo()
                    }
                }
                
                delegate.currentPlayingIndex = chosenPlayItems.map({ (item) -> IndexPath in
                    return item.index
                })
            }
        } else {
            // fallback here
        }
    }

}
