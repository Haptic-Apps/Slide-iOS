//
//  BottomSheetCell.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/1/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

//  Copyright (c) 2015 Xmartlabs ( http://xmartlabs.com )
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Anchorage
import Foundation
import Then
import XLActionController

open class BottomSheetCell: ActionCell {
    
    open lazy var animatableBackgroundView: UIView = { [weak self] in
        let view = UIView(frame: self?.frame ?? CGRect.zero)
        view.backgroundColor = ColorUtil.backgroundColor
        return view
        }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }
    
    func initialize() {
        actionTitleLabel?.textColor = UIColor(white: 0.098, alpha: 1.0)

        selectedBackgroundView = UIView().then {
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.0)
            $0.addSubview(animatableBackgroundView)
        }
    }
    
    open override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                animatableBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.0)
                animatableBackgroundView.frame = CGRect(x: 0, y: 0, width: 30, height: frame.height)
                animatableBackgroundView.center = CGPoint(x: frame.width * 0.5, y: frame.height * 0.5)
                
                UIView.animate(withDuration: 0.5) { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    
                    strongSelf.animatableBackgroundView.frame = CGRect(x: 0, y: 0, width: strongSelf.frame.width, height: strongSelf.frame.height)
                    strongSelf.animatableBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.08)
                }
            } else {
                animatableBackgroundView.backgroundColor = animatableBackgroundView.backgroundColor?.withAlphaComponent(0.0)
            }
        }
    }
}

open class ActionControllerHeader: UICollectionReusableView {
    
    var label = UILabel().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = ColorUtil.foregroundColor
        $0.font = UIFont.boldSystemFont(ofSize: 17)
        $0.textColor = ColorUtil.fontColor
        $0.textAlignment = .center
    }
    
    var bottomLine = UIView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = ColorUtil.backgroundColor
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        let pad = UIScreen.main.traitCollection.userInterfaceIdiom == .pad

        addSubview(label)
        label.verticalAnchors == verticalAnchors
        label.horizontalAnchors == horizontalAnchors + (pad ? 250 : 0)

        addSubview(bottomLine)
        bottomLine.heightAnchor == 1
        bottomLine.bottomAnchor == bottomAnchor
        bottomLine.horizontalAnchors == horizontalAnchors + (pad ? 250 : 0)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

open class BottomSheetActionController: ActionController<BottomSheetCell, ActionData, ActionControllerHeader, String, UICollectionReusableView, Void> {
    
    public override init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: Bundle? = nil) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        collectionViewLayout.minimumLineSpacing = 0
        settings.cancelView.showCancel = true
        settings.cancelView.fontColor = ColorUtil.fontColor
        settings.cancelView.height = 52
        //collectionView.contentInset = UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 12)
        settings.cancelView.backgroundColor = ColorUtil.backgroundColor
        settings.behavior.hideOnScrollDown = false
        settings.behavior.bounces = true
        settings.behavior.hideNavigationBarOnShow = false
        settings.behavior.hideOnTap = true
        settings.animation.scale = nil
        settings.behavior.useDynamics = false
        settings.behavior.scrollEnabled = true
        settings.animation.present.duration = 0.3
        settings.animation.dismiss.duration = 0.3
        settings.animation.dismiss.offset = 30
        
        settings.animation.dismiss.options = .curveLinear
        
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad && !UIApplication.shared.isSplitOrSlideOver {
            settings.collectionView.lateralMargin = 250
        }
        
        cellSpec = .nibFile(nibName: "BSCell", bundle: Bundle(for: BottomSheetCell.self), height: { _ in 52 })
        headerSpec = .cellClass(height: { _ -> CGFloat in return 52 })
        
        onConfigureHeader = { header, title in
            header.label.text = title
        }
        
        //todo this self.header = ButtonsHeader.init(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width - 24, height: 52))
        var doneOnce = false
        onConfigureCellForAction = { cell, action, indexPath in
            cell.setup(action.data?.title, detail: action.data?.subtitle, image: action.data?.image)
            cell.alpha = action.enabled ? 1.0 : 0.5
            cell.actionTitleLabel?.textColor = ColorUtil.fontColor
            cell.actionTitleLabel?.font = UIFont.systemFont(ofSize: 16)
            cell.backgroundColor = ColorUtil.foregroundColor
            
            self.collectionView.backgroundColor = ColorUtil.foregroundColor
            self.collectionView.layer.cornerRadius = 15
            self.collectionView.clipsToBounds = true
            
            if !doneOnce && false { //todo this later maybe
               // self.header!.bottomAnchor == self.collectionView.topAnchor - CGFloat(12)
               // self.header!.widthAnchor == self.collectionView.widthAnchor
               // self.header!.heightAnchor == CGFloat(52)
               // self.header!.leftAnchor == self.collectionView.leftAnchor
               // self.header!.backgroundColor = ColorUtil.foregroundColor
                doneOnce = true
            }
            var corners = UIRectCorner()
            if indexPath.item == 0 {
                corners = [.topLeft, .topRight]
            }
            if indexPath.item == (self.sectionForIndex(0)?.actions.count)! - 1 {
                corners = corners.union([.bottomLeft, .bottomRight])
                cell.contentView.layoutMargins = UIEdgeInsets.init(top: 0, left: 12, bottom: 20, right: 12)
            }

            if corners == .allCorners {
                cell.layer.mask = nil
                cell.layer.cornerRadius = 15.0
            } else {
                let borderMask = CAShapeLayer()
                borderMask.frame = cell.bounds
                borderMask.path = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: 15.0, height: 8.0)).cgPath
                cell.layer.mask = borderMask
            }
        }
    }
        
    //Swift 4 messes up this method for some reason...
    @objc(collectionView:layout:insetForSectionAtIndex:)  override open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad && !UIApplication.shared.isSplitOrSlideOver {
            return UIEdgeInsets.init(top: 0, left: 250, bottom: 0, right: 250)
        }
        return UIEdgeInsets.zero
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public struct ActionData {
    
    public fileprivate(set) var title: String?
    public fileprivate(set) var subtitle: String?
    public fileprivate(set) var image: UIImage?
    
    public init(title: String) {
        self.title = title
    }
    
    public init(title: String, subtitle: String) {
        self.init(title: title)
        self.subtitle = subtitle
    }
    
    public init(title: String, subtitle: String, image: UIImage) {
        self.init(title: title, subtitle: subtitle)
        self.image = image
    }
    
    public init(title: String, image: UIImage) {
        self.init(title: title)
        self.image = image
    }
}

extension UIApplication {
    public var isSplitOrSlideOver: Bool {
        guard let w = self.delegate?.window, let window = w else {
            return false
        }
        return !window.frame.equalTo(window.screen.bounds)
    }
}
