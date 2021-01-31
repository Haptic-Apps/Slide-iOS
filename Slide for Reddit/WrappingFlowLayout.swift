//
//  WrappingFlowLayout.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/18/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation

protocol WrappingFlowLayoutDelegate: class {
    func collectionView(_ collectionView: UICollectionView, width: CGFloat, indexPath: IndexPath) -> CGSize
    func headerOffset() -> Int
}

class WrappingFlowLayout: UICollectionViewLayout {
    weak var delegate: WrappingFlowLayoutDelegate!
    
    // 2
    var numberOfColumns = 0
    
    override func invalidateLayout() {
        cache.removeAll()
        super.invalidateLayout()
    }
    
    var cellPadding = CGFloat(0)
    
    // 3
    private var cache = [UICollectionViewLayoutAttributes]()
    
    // 4
    private var contentHeight: CGFloat = 0.0
    private var contentWidth: CGFloat {
        let insets = collectionView!.contentInset
        var cvWidth = collectionView!.bounds.width
        if cvWidth <= 0 {
            cvWidth = UIScreen.main.bounds.size.width
        }
        return cvWidth - (insets.left + insets.right)
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    func reset(modal: Bool, vc: UIViewController, isGallery: Bool) {
        cache = []
        contentHeight = 0
        var portraitCount = SettingValues.portraitMultiColumnCount
        let pad = UIApplication.shared.respectIpadLayout()
        
        if SettingValues.appMode == .MULTI_COLUMN || UIApplication.shared.isMac() {
            if (UIApplication.shared.statusBarOrientation.isPortrait && !UIApplication.shared.isMac()) || (vc.presentingViewController != nil && (vc.modalPresentationStyle == .pageSheet || vc.modalPresentationStyle == .fullScreen)) {
                if !pad {
                    numberOfColumns = SettingValues.portraitMultiColumnCount
                } else {
                    if SettingValues.disableMulticolumnCollections {
                        numberOfColumns = 1
                    } else {
                        numberOfColumns = portraitCount
                    }
                }
            } else {
                numberOfColumns = SettingValues.multiColumnCount
            }
        } else {
            numberOfColumns = 1
        }
        
        if !UIApplication.shared.isMac() {
            if pad && UIApplication.shared.keyWindow?.frame != UIScreen.main.bounds || UIApplication.shared.isSplitOrSlideOver {
                numberOfColumns = 1
            }
        }
                
        if vc is ContentListingViewController && numberOfColumns > 2 {
            numberOfColumns = 2
            portraitCount = 1
        }
        if isGallery {
            numberOfColumns = SettingValues.galleryCount
        }
        cellPadding = (numberOfColumns > 1 && (SettingValues.postViewMode != .LIST) && (SettingValues.postViewMode != .COMPACT)) ? CGFloat(3) : ((SettingValues.postViewMode == .LIST) ? CGFloat(1) : CGFloat(0))
        prepare()
    }
    
    override func prepare() {
        // 1
        if cache.isEmpty && collectionView!.numberOfItems(inSection: 0) != 0 {
            // 2
            let columnWidth = contentWidth / CGFloat(numberOfColumns)
            var xOffset = [CGFloat]()
            for column in 0 ..< numberOfColumns {
                xOffset.append(CGFloat(column) * columnWidth )
            }
            var column = 0
            var yOffset = [CGFloat](repeating: 0, count: numberOfColumns)
            
            // 3
            if yOffset.isEmpty {
                return
            }
            
            for item in 0 ..< collectionView!.numberOfItems(inSection: 0) {
                
                let indexPath = IndexPath.init(row: item, section: 0)
                
                // 4
                let width = columnWidth - (cellPadding * 2)

                let height1 = delegate.collectionView(collectionView!, width: width, indexPath: indexPath).height
                let height = cellPadding + height1 + cellPadding

                if (yOffset[(column >= (numberOfColumns - 1)) ? 0 : column + 1] + (0.75 * height)) < yOffset[column] {
                    column = (column >= (numberOfColumns - 1)) ? 0 : column + 1
                }

                let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: height)
                let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
                
                // 5
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                if insetFrame.origin.x > 999999 {
                    return
                }
                attributes.frame = insetFrame
                cache.append(attributes)
                
                // 6
                contentHeight = max(contentHeight, frame.maxY)

                yOffset[column] = yOffset[column] + height
                let col = column >= (numberOfColumns - 1)
                if col {
                    column = 0
                } else {
                    column += 1
                }
            }
        }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                layoutAttributes.append(attributes)
            }
        }
        return layoutAttributes
    }
}
