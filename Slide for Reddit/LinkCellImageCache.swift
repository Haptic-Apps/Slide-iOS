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
    static var menu = UIImage()
    static var share = UIImage()

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
    static var readLater = UIImage()
    static var readLaterTinted = UIImage()
    static var hide = UIImage()
    static var edit = UIImage()
    
    static var web = UIImage()
    static var webBig = UIImage()
    static var nsfw = UIImage()
    static var nsfwUp = UIImage()
    static var reddit = UIImage()
    static var spoiler = UIImage()
    
    private struct sizes {
        static let small = CGSize(width: 12, height: 12)
        static let medium = CGSize(width: 20, height: 20)
    }

    // TODO: - Call this whenever the theme changes.
    public static func initialize() {        
        upvote = UIImage(sfString: SFSymbol.arrowUp, overrideString: "upvote")!.menuIcon()
        upvoteTinted = upvote.getCopy(withColor: ColorUtil.upvoteColor)

        downvote = UIImage(sfString: SFSymbol.arrowDown, overrideString: "downvote")!.menuIcon()
        downvoteTinted = downvote.getCopy(withColor: ColorUtil.downvoteColor)

        save = UIImage(sfString: SFSymbol.starFill, overrideString: "save")!.menuIcon()
        saveTinted = save.getCopy(withColor: ColorUtil.upvoteColor)

        share = UIImage(sfString: SFSymbol.paperplaneFill, overrideString: "send")!.menuIcon()

        upvoteSmall = UIImage(sfString: SFSymbol.chevronUp, overrideString: "up")!.menuIcon()
        upvoteTintedSmall = upvoteSmall.getCopy(withColor: ColorUtil.upvoteColor)
        
        downvoteSmall = UIImage(sfString: SFSymbol.chevronDown, overrideString: "down")!.menuIcon()
        downvoteTintedSmall = downvoteSmall.getCopy(withColor: ColorUtil.downvoteColor)

        votesIcon = UIImage(sfString: SFSymbol.arrowUp, overrideString: "upvote")!.smallIcon()
        commentsIcon = UIImage(sfString: SFSymbol.bubbleRightFill, overrideString: "comments")!.smallIcon()
        menu = UIImage(sfString: SFSymbol.ellipsis, overrideString: "ic_more_vert_white")!.menuIcon()

        reply = UIImage(sfString: SFSymbol.arrowshapeTurnUpLeftFill, overrideString: "reply")!.menuIcon()
        hide = UIImage(sfString: SFSymbol.xmark, overrideString: "hide")!.menuIcon()
        edit = UIImage(sfString: SFSymbol.pencil, overrideString: "edit")!.menuIcon()

        mod = UIImage(sfString: SFSymbol.shieldLefthalfFill, overrideString: "mod")!.menuIcon()
        modTinted = mod.getCopy(withColor: GMColor.red500Color())

        readLater = UIImage(sfString: SFSymbol.trayAndArrowDownFill, overrideString: "readLater")!.menuIcon()
        readLaterTinted = readLater.getCopy(withColor: GMColor.green500Color())
        
        var topColor = UIColor.fontColorOverlaid(withForeground: true, 0.9)
        var nextColor = UIColor.fontColorOverlaid(withForeground: true, 0.9)

        web = UIImage.convertGradientToImage(colors: [topColor, nextColor], frame: CGSize.square(size: 150))
        web = web.overlayWith(image: UIImage(sfString: SFSymbol.safariFill, overrideString: "nav")!.getCopy(withSize: CGSize.square(size: 75), withColor: .white), posX: (75 / 2), posY: (75 / 2))

        webBig = UIImage.convertGradientToImage(colors: [topColor, nextColor], frame: CGSize(width: 400, height: 275))
        webBig = webBig.overlayWith(image: UIImage(sfString: SFSymbol.safariFill, overrideString: "nav")!.getCopy(withSize: CGSize.square(size: 75), withColor: .white), posX: ((400 - 75) / 2), posY: (200 / 2))

        spoiler = UIImage.convertGradientToImage(colors: [topColor, nextColor], frame: CGSize.square(size: 150))
        spoiler = spoiler.overlayWith(image: UIImage(sfString: SFSymbol.exclamationmarkCircleFill, overrideString: "reports")!.getCopy(withSize: CGSize.square(size: 75), withColor: UIColor.white), posX: (75 / 2), posY: (75 / 2))

        reddit = UIImage.convertGradientToImage(colors: [topColor, nextColor], frame: CGSize.square(size: 150))
        reddit = reddit.overlayWith(image: UIImage(named: "reddit")!.getCopy(withSize: CGSize.init(width: 90, height: 75)), posX: 30, posY: (75 / 2))

        topColor = GMColor.red400Color()
        nextColor = GMColor.red600Color()
        
        let nsfwimg = UIImage(sfString: SFSymbol.eyeSlashFill, overrideString: "hide")!.getCopy(withSize: CGSize.square(size: 75), withColor: .white)
        let nsfwimg2 = UIImage(sfString: SFSymbol.eyeSlashFill, overrideString: "hide")!.getCopy(withSize: CGSize.square(size: 75), withColor: .white)
        nsfw = UIImage.convertGradientToImage(colors: [topColor, nextColor], frame: CGSize.square(size: 150))
        nsfwUp = UIImage.convertGradientToImage(colors: [topColor, nextColor], frame: CGSize.square(size: 150))
        nsfw = nsfw.overlayWith(image: nsfwimg, posX: ((150 - (nsfwimg.size.width)) / 2), posY: ((150 - (nsfwimg.size.height)) / 2))
        nsfwUp = nsfwUp.overlayWith(image: nsfwimg2, posX: ((150 - (nsfwimg2.size.width)) / 2), posY: ((125 - (nsfwimg2.size.height)) / 2))
    }
}
