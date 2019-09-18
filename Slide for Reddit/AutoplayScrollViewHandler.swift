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

protocol AutoplayScrollViewDelegate {
    func didScrollExtras(_ currentY: CGFloat) -> Void
    var isScrollingDown: Bool { get set }
    var lastScrollDirectionWasDown: Bool {get set}
    var lastYUsed: CGFloat {get set}
    var lastY: CGFloat { get set }
    var currentPlayingIndex: IndexPath? {get set}
    func getTableView() -> UICollectionView
}

class AutoplayScrollViewHandler {

    var delegate: AutoplayScrollViewDelegate
    init(delegate: AutoplayScrollViewDelegate) {
        self.delegate = delegate
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentY = scrollView.contentOffset.y

        delegate.isScrollingDown = currentY > delegate.lastY
        delegate.didScrollExtras(currentY)
        
        delegate.lastScrollDirectionWasDown = delegate.isScrollingDown
        let center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)

        delegate.lastYUsed = currentY
        delegate.lastY = currentY

        if SettingValues.autoPlayMode == .ALWAYS || (SettingValues.autoPlayMode == .WIFI && LinkCellView.cachedCheckWifi) {
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
            
            var needsReplace = false
            if let currentIndex = delegate.currentPlayingIndex, let currentCell = delegate.getTableView().cellForItem(at: currentIndex) as? AutoplayBannerLinkCellView {
                let videoViewCenter = currentCell.videoView.convert(currentCell.videoView.bounds, to: nil)
                if delegate.isScrollingDown {
                    //print("Diff for scroll down is \(abs(videoViewCenter.y - center.y)) and \(scrollView.frame.size.height / 4 )")
                    if abs(videoViewCenter.midY - center.y) > scrollView.frame.size.height / 3 {
                        needsReplace = true
                    }
                } else {
                    //print("Diff for scroll up is \(abs(videoViewCenter.y - center.y)) and \(scrollView.frame.size.height * (3 / 4))")
                    if abs(videoViewCenter.midY - center.y) < scrollView.frame.size.height * (2 / 3) {
                        needsReplace = true
                    }
                }
            } else {
                needsReplace = true
            }
            
            if needsReplace {
                var chosenPlayItem: (index: IndexPath, cell: LinkCellView)?
                for item in mapping {
                    if let currentCell = item.cell as? AutoplayBannerLinkCellView {
                        let videoViewCenter = currentCell.videoView.convert(currentCell.videoView.bounds, to: nil)
                        if delegate.isScrollingDown {
                            if abs(videoViewCenter.midY - center.y) > scrollView.frame.size.height / 2 {
                                continue
                            }
                        } else {
                            if abs(videoViewCenter.midY - center.y) > scrollView.frame.size.height / 2 {
                                continue
                            }
                        }
                        chosenPlayItem = item
                        break
                    }
                }
                
                if let overridePath = chosenPlayItem {
                    if delegate.currentPlayingIndex == nil || delegate.currentPlayingIndex! != overridePath.index {
                        delegate.currentPlayingIndex = overridePath.index
                        (overridePath.cell as! AutoplayBannerLinkCellView).doLoadVideo()
                    }
                    
                    for item in mapping {
                        if item.index != overridePath.index && item.cell is AutoplayBannerLinkCellView {
                            item.cell.endVideos()
                        }
                    }
                } else {
                    delegate.currentPlayingIndex = nil
                    for item in mapping {
                        if item.cell is AutoplayBannerLinkCellView {
                            item.cell.endVideos()
                        }
                    }
                }
            }
        }

    }
    
    func autoplayOnce() {
        //todo this
    }

}
