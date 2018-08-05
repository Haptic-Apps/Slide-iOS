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

    static var upvoteSmall = UIImage()
    static var downvoteSmall = UIImage()

    static var upvoteTinted = UIImage()
    static var downvoteTinted = UIImage()
    static var saveTinted = UIImage()

    static var upvoteTintedSmall = UIImage()
    static var downvoteTintedSmall = UIImage()

    static var votesIcon = UIImage()
    static var commentsIcon = UIImage()

    static var reply = UIImage()
    static var mod = UIImage()
    static var modTinted = UIImage()
    static var hide = UIImage()
    static var edit = UIImage()
    
    static var web = UIImage()
    static var nsfw = UIImage()
    static var reddit = UIImage()
    static var spoiler = UIImage()

    private struct sizes {
        static let small = CGSize(width: 12, height: 12)
        static let medium = CGSize(width: 20, height: 20)
    }

    // TODO: Call this whenever the theme changes.
    public static func initialize() {
        upvote = UIImage(named: "upvote")!.menuIcon()
        upvoteTinted = upvote.getCopy(withColor: ColorUtil.upvoteColor)

        downvote = UIImage(named: "downvote")!.menuIcon()
        downvoteTinted = downvote.getCopy(withColor: ColorUtil.downvoteColor)

        save = UIImage(named: "save")!.menuIcon()
        saveTinted = save.getCopy(withColor: ColorUtil.upvoteColor)

        upvoteSmall = UIImage(named: "up")!.menuIcon()
        upvoteTintedSmall = upvoteSmall.getCopy(withColor: ColorUtil.upvoteColor)
        
        downvoteSmall = UIImage(named: "down")!.menuIcon()
        downvoteTintedSmall = downvoteSmall.getCopy(withColor: ColorUtil.downvoteColor)

        votesIcon = UIImage(named: "upvote")!.smallIcon()
        commentsIcon = UIImage(named: "comments")!.smallIcon()

        reply = UIImage(named: "reply")!.menuIcon()
        hide = UIImage(named: "hide")!.menuIcon()
        edit = UIImage(named: "edit")!.menuIcon()

        mod = UIImage(named: "mod")!.menuIcon()
        modTinted = mod.getCopy(withColor: GMColor.red500Color())
        
        var topColor = ColorUtil.fontColor.add(overlay: ColorUtil.foregroundColor.withAlphaComponent(0.9))
        var nextColor = ColorUtil.fontColor.add(overlay: ColorUtil.foregroundColor.withAlphaComponent(0.8))

        web = UIImage.convertGradientToImage(colors: [topColor, nextColor], frame: CGSize.square(size: 150))
        web = web.overlayWith(image: UIImage(named: "nav")!.getCopy(withSize: CGSize.square(size: 75)), posX: (75 / 2), posY: (75 / 2))

        spoiler = UIImage.convertGradientToImage(colors: [topColor, nextColor], frame: CGSize.square(size: 150))
        spoiler = spoiler.overlayWith(image: UIImage(named: "reports")!.getCopy(withSize: CGSize.square(size: 75)), posX: (75 / 2), posY: (75 / 2))

        reddit = UIImage.convertGradientToImage(colors: [topColor, nextColor], frame: CGSize.square(size: 150))
        reddit = reddit.overlayWith(image: UIImage(named: "reddit")!.getCopy(withSize: CGSize.init(width: 90, height: 75)), posX: 30, posY: (75 / 2))

        topColor = GMColor.red400Color()
        nextColor = GMColor.red600Color()
        
        nsfw = UIImage.convertGradientToImage(colors: [topColor, nextColor], frame: CGSize.square(size: 150))
        nsfw = nsfw.overlayWith(image: UIImage(named: "hide")!.getCopy(withSize: CGSize.square(size: 75)), posX: (75 / 2), posY: (75 / 2))

    }

}
