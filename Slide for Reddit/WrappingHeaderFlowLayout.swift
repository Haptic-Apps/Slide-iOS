//
//  WrappingHeaderFlowLayout.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/26/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation
protocol WrappingHeaderFlowLayoutDelegate: class {
    func collectionView(_ collectionView: UICollectionView, indexPath: IndexPath) -> CGSize
}

class WrappingHeaderFlowLayout: UICollectionViewFlowLayout {
    weak var delegate: WrappingHeaderFlowLayoutDelegate!
    
    var xOffset = [CGFloat]()

    private var cache = [UICollectionViewLayoutAttributes]()
    
    private var contentHeight: CGFloat = 40.0
    private var contentWidth: CGFloat = 0.0
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    func reset() {
        cache = []
        contentWidth = 0
        
        prepare()
    }
    
    override func prepare() {
        if cache.isEmpty && collectionView!.numberOfItems(inSection: 0) != 0 {
            
            xOffset = [CGFloat](repeating: 0, count: collectionView!.numberOfItems(inSection: 0))
            for item in 0 ..< collectionView!.numberOfItems(inSection: 0) {
                
                let indexPath = IndexPath.init(row: item, section: 0)
                
                let width = delegate.collectionView(collectionView!, indexPath: indexPath).width
                
                let height = contentHeight
                
                var calculatedOffset = CGFloat(0)
                for index in 0..<item {
                    calculatedOffset += xOffset[index]
                }

                let frame = CGRect(x: calculatedOffset, y: 0, width: width, height: height)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = frame
                cache.append(attributes)
                
                xOffset[item] = width + 24
                contentWidth += width + 24
            }
        }
    }
    
    func offsetAt(_ index: Int) -> CGFloat {
        var calculatedOffset = CGFloat(0)
        if index < 0 {
            return 0
        }
        for ind in 0...index {
            calculatedOffset += xOffset[ind]
        }
        return calculatedOffset
    }
    
    func widthAt(_ index: Int) -> CGFloat {
        if index < 0 {
            return 0
        }
         return xOffset[index]
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if cache.isEmpty {
            return nil
        }
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
