//
//  LinkCellImageCache.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/26/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

public class LinkCellImageCache {
    static var upvote = UIImage()
    static var downvote = UIImage()
    static var save = UIImage()
    static var upvoteTinted = UIImage()
    static var downvoteTinted = UIImage()
    static var saveTinted = UIImage()
    
    public static func initialize(){
        LinkCellImageCache.upvote = UIImage.init(named: "upvote")!.menuIcon()
        LinkCellImageCache.downvote = UIImage.init(named: "downvote")!.menuIcon()
        LinkCellImageCache.save = UIImage.init(named: "save")!.menuIcon()
        
        LinkCellImageCache.upvoteTinted = (UIImage.init(named: "upvote")?.withColor(tintColor: ColorUtil.upvoteColor).imageResize(sizeChange: CGSize.init(width: 20, height: 20)))!
        LinkCellImageCache.downvoteTinted = (UIImage.init(named: "downvote")?.withColor(tintColor: ColorUtil.downvoteColor).imageResize(sizeChange: CGSize.init(width: 20, height: 20)))!
        LinkCellImageCache.saveTinted = (UIImage.init(named: "save")?.withColor(tintColor: GMColor.yellow500Color()).imageResize(sizeChange: CGSize.init(width: 20, height: 20)))!
    }
}
