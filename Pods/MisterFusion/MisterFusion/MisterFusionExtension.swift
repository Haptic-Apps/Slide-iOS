//
//  MisterFusionExtension.swift
//  MisterFusion
//
//  Created by Taiki Suzuki on 2017/01/20.
//  Copyright © 2017年 Taiki Suzuki. All rights reserved
//

import UIKit

public protocol MisterFusionCompatible {
    associatedtype CompatibleType
    var mf: CompatibleType { get }
}

public extension MisterFusionCompatible {
    public var mf: MisterFusionExtension<Self> {
        return MisterFusionExtension(self)
    }
}

public final class MisterFusionExtension<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

extension UIView: MisterFusionCompatible {}

extension MisterFusionExtension where Base: UIView {
    //MARK: - addConstraint()
    @discardableResult
    public func addConstraint(_ misterFusion: MisterFusion) -> NSLayoutConstraint? {
        return base._addLayoutConstraint(misterFusion)
    }
    
    @discardableResult
    public func addConstraints(_ misterFusions: [MisterFusion]) -> [NSLayoutConstraint] {
        return base._addLayoutConstraints(misterFusions)
    }
    
    @discardableResult
    public func addConstraints(_ misterFusions: MisterFusion...) -> [NSLayoutConstraint] {
        return base._addLayoutConstraints(misterFusions)
    }
    
    //MARK: - addSubview()
    @discardableResult
    public func addSubview(_ subview: UIView, andConstraint misterFusion: MisterFusion) -> NSLayoutConstraint? {
        return base._addLayoutSubview(subview, andConstraint: misterFusion)
    }
    
    @discardableResult
    public func addSubview(_ subview: UIView, andConstraints misterFusions: [MisterFusion]) -> [NSLayoutConstraint] {
        return base._addLayoutSubview(subview, andConstraints: misterFusions)
    }
    
    @discardableResult
    public func addSubview(_ subview: UIView, andConstraints misterFusions: MisterFusion...) -> [NSLayoutConstraint] {
        return base._addLayoutSubview(subview, andConstraints: misterFusions)
    }
    
    //MARK: - insertSubview(_ at:_)
    @discardableResult
    public func insertSubview(_ subview: UIView, at index: Int, andConstraint misterFusion: MisterFusion) -> NSLayoutConstraint? {
        return base._insertLayoutSubview(subview, at: index, andConstraint: misterFusion)
    }
    
    @discardableResult
    public func insertSubview(_ subview: UIView, at index: Int, andConstraints misterFusions: [MisterFusion]) -> [NSLayoutConstraint] {
        return base._insertLayoutSubview(subview, at: index, andConstraints: misterFusions)
    }
    
    @discardableResult
    public func insertSubview(_ subview: UIView, at index: Int, andConstraints misterFusions: MisterFusion...) -> [NSLayoutConstraint] {
        return base._insertLayoutSubview(subview, at: index, andConstraints: misterFusions)
    }
    
    //MARK: - insertSubview(_ belowSubview:_)
    @discardableResult
    public func insertSubview(_ subview: UIView, belowSubview siblingSubview: UIView, andConstraint misterFusion: MisterFusion) -> NSLayoutConstraint? {
        return base._insertLayoutSubview(subview, belowSubview: siblingSubview, andConstraint: misterFusion)
    }
    
    @discardableResult
    public func insertSubview(_ subview: UIView, belowSubview siblingSubview: UIView, andConstraints misterFusions: [MisterFusion]) -> [NSLayoutConstraint] {
        return base._insertLayoutSubview(subview, belowSubview: siblingSubview, andConstraints: misterFusions)
    }
    
    @discardableResult
    public func insertSubview(_ subview: UIView, belowSubview siblingSubview: UIView, andConstraints misterFusions: MisterFusion...) -> [NSLayoutConstraint] {
        return base._insertLayoutSubview(subview, belowSubview: siblingSubview, andConstraints: misterFusions)
    }
    
    //MARK: - insertSubview(_ aboveSubview:_)
    @discardableResult
    public func insertSubview(_ subview: UIView, aboveSubview siblingSubview: UIView, andConstraint misterFusion: MisterFusion) -> NSLayoutConstraint? {
        return base._insertLayoutSubview(subview, aboveSubview: siblingSubview, andConstraint: misterFusion)
    }
    
    @discardableResult
    public func insertSubview(_ subview: UIView, aboveSubview siblingSubview: UIView, andConstraints misterFusions: [MisterFusion]) -> [NSLayoutConstraint] {
        return base._insertLayoutSubview(subview, aboveSubview: siblingSubview, andConstraints: misterFusions)
    }
    
    @discardableResult
    public func insertSubview(_ subview: UIView, aboveSubview siblingSubview: UIView, andConstraints misterFusions: MisterFusion...) -> [NSLayoutConstraint] {
        return base._insertLayoutSubview(subview, aboveSubview: siblingSubview, andConstraints: misterFusions)
    }
}
