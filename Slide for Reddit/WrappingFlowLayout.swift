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
}

class WrappingFlowLayout: UICollectionViewLayout {
    var delegate: WrappingFlowLayoutDelegate!
    
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
        return collectionView!.bounds.width - (insets.left + insets.right)
    }
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    func reset() {
        cache = []
        prepare()
        var portraitCount = SettingValues.multiColumnCount / 2
        if portraitCount == 0 {
            portraitCount = 1
        }
        
        let pad = UIScreen.main.traitCollection.userInterfaceIdiom == .pad
        if portraitCount == 1 && pad {
            portraitCount = 2
        }
        if pad && UIApplication.shared.keyWindow?.frame != UIScreen.main.bounds {
            numberOfColumns = 1
        }
        if SettingValues.multiColumn {
            if UIApplication.shared.statusBarOrientation.isPortrait || !SettingValues.isPro {
                if UIScreen.main.traitCollection.userInterfaceIdiom != .pad || !SettingValues.isPro {
                    numberOfColumns = 1
                } else {
                    numberOfColumns = portraitCount
                }
            } else {
                numberOfColumns = SettingValues.multiColumnCount
            }
        } else {
            numberOfColumns = 1
        }
        
        cellPadding = (numberOfColumns > 1 && (SettingValues.postViewMode != .LIST) && (SettingValues.postViewMode != .COMPACT) ) ? CGFloat(3) : ((SettingValues.postViewMode == .LIST) ? CGFloat(1) : CGFloat(0))

    }
    
    override func prepare() {
        // 1
        if cache.isEmpty {
            // 2
            let columnWidth = contentWidth / CGFloat(numberOfColumns)
            var xOffset = [CGFloat]()
            for column in 0 ..< numberOfColumns {
                xOffset.append(CGFloat(column) * columnWidth )
            }
            var column = 0
            var yOffset = [CGFloat](repeating: 0, count: numberOfColumns)
            
            // 3
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
