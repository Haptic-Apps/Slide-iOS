//
//  Deprecated.swift
//  MisterFusion
//
//  Created by marty-suzuki on 2017/05/05.
//  Copyright © 2017年 Taiki Suzuki. All rights reserved.
//

import UIKit

//@available(*, deprecated, message: "Those methods will be removed since 3.0.0, please use view.mf.xxx instead.")
extension UIView {
    //MARK: - addConstraint()
    @discardableResult
    public func addLayoutConstraint(_ misterFusion: MisterFusion) -> NSLayoutConstraint? {
        return _addLayoutConstraint(misterFusion)
    }
    
    @discardableResult
    public func addLayoutConstraints(_ misterFusions: [MisterFusion]) -> [NSLayoutConstraint] {
        return _addLayoutConstraints(misterFusions)
    }
    
    @discardableResult
    public func addLayoutConstraints(_ misterFusions: MisterFusion...) -> [NSLayoutConstraint] {
        return _addLayoutConstraints(misterFusions)
    }
    
    //MARK: - addSubview()
    @discardableResult
    public func addLayoutSubview(_ subview: UIView, andConstraint misterFusion: MisterFusion) -> NSLayoutConstraint? {
        return _addLayoutSubview(subview, andConstraint: misterFusion)
    }
    
    @discardableResult
    public func addLayoutSubview(_ subview: UIView, andConstraints misterFusions: [MisterFusion]) -> [NSLayoutConstraint] {
        return _addLayoutSubview(subview, andConstraints: misterFusions)
    }
    
    @discardableResult
    public func addLayoutSubview(_ subview: UIView, andConstraints misterFusions: MisterFusion...) -> [NSLayoutConstraint] {
        return _addLayoutSubview(subview, andConstraints: misterFusions)
    }
    
    //MARK: - insertSubview(_ at:_)
    @objc(insertLayoutSubview:atIndex:andConstraint:)
    @discardableResult
    public func insertLayoutSubview(_ subview: UIView, at index: Int, andConstraint misterFusion: MisterFusion) -> NSLayoutConstraint? {
        return _insertLayoutSubview(subview, at: index, andConstraint: misterFusion)
    }
    
    @objc(insertLayoutSubview:atIndex:andConstraints:)
    @discardableResult
    public func insertLayoutSubview(_ subview: UIView, at index: Int, andConstraints misterFusions: [MisterFusion]) -> [NSLayoutConstraint] {
        return _insertLayoutSubview(subview, at: index, andConstraints: misterFusions)
    }
    
    @discardableResult
    public func insertLayoutSubview(_ subview: UIView, at index: Int, andConstraints misterFusions: MisterFusion...) -> [NSLayoutConstraint] {
        return _insertLayoutSubview(subview, at: index, andConstraints: misterFusions)
    }
    
    //MARK: - insertSubview(_ belowSubview:_)
    @discardableResult
    public func insertLayoutSubview(_ subview: UIView, belowSubview siblingSubview: UIView, andConstraint misterFusion: MisterFusion) -> NSLayoutConstraint? {
        return _insertLayoutSubview(subview, belowSubview: siblingSubview, andConstraint: misterFusion)
    }
    
    @discardableResult
    public func insertLayoutSubview(_ subview: UIView, belowSubview siblingSubview: UIView, andConstraints misterFusions: [MisterFusion]) -> [NSLayoutConstraint] {
        return _insertLayoutSubview(subview, belowSubview: siblingSubview, andConstraints: misterFusions)
    }
    
    @discardableResult
    public func insertLayoutSubview(_ subview: UIView, belowSubview siblingSubview: UIView, andConstraints misterFusions: MisterFusion...) -> [NSLayoutConstraint] {
        return _insertLayoutSubview(subview, belowSubview: siblingSubview, andConstraints: misterFusions)
    }
    
    //MARK: - insertSubview(_ aboveSubview:_)
    @discardableResult
    public func insertLayoutSubview(_ subview: UIView, aboveSubview siblingSubview: UIView, andConstraint misterFusion: MisterFusion) -> NSLayoutConstraint? {
        return _insertLayoutSubview(subview, aboveSubview: siblingSubview, andConstraint: misterFusion)
    }

    @discardableResult
    public func insertLayoutSubview(_ subview: UIView, aboveSubview siblingSubview: UIView, andConstraints misterFusions: [MisterFusion]) -> [NSLayoutConstraint] {
        return _insertLayoutSubview(subview, aboveSubview: siblingSubview, andConstraints: misterFusions)
    }
    
    @discardableResult
    public func insertLayoutSubview(_ subview: UIView, aboveSubview siblingSubview: UIView, andConstraints misterFusions: MisterFusion...) -> [NSLayoutConstraint] {
        return _insertLayoutSubview(subview, aboveSubview: siblingSubview, andConstraints: misterFusions)
    }
}
