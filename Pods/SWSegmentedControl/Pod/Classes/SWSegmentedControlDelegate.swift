//
//  SWSegmentedControlDelegate.swift
//  Pods
//
//  Created by Sarun Wongpatcharapakorn on 7/17/17.
//
//

import Foundation

@objc public protocol SWSegmentedControlDelegate {
    
    // Managing Selections
    @objc optional func segmentedControl(_ control: SWSegmentedControl, canSelectItemAtIndex index: Int) -> Bool
    @objc optional func segmentedControl(_ control: SWSegmentedControl, willSelectItemAtIndex index: Int)
    @objc optional func segmentedControl(_ control: SWSegmentedControl, didSelectItemAtIndex index: Int)
    @objc optional func segmentedControl(_ control: SWSegmentedControl, willDeselectItemAtIndex index: Int)
    @objc optional func segmentedControl(_ control: SWSegmentedControl, didDeselectItemAtIndex index: Int)
}
