//
//  GalleryCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/18/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

class GalleryCellView: UITableViewCell {
    
    var bannerImage = UIImageView()
    var typeImage = UIImageView()
    var commentsImage = UIImageView()
    
    var estimatedHeight = CGFloat(0)
    var link: SubmissionObject?
    
    func setLink(_ link: SubmissionObject, parent: UIViewController & MediaVCDelegate) {
        self.bannerImage = UIImageView(frame: CGRect(x: 0, y: 8, width: CGFloat.greatestFiniteMagnitude, height: 0))
        bannerImage.clipsToBounds = true
        bannerImage.contentMode = UIView.ContentMode.scaleAspectFit

        self.commentsImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        self.commentsImage.image = UIImage(sfString: SFSymbol.bubbleLeftAndBubbleRightFill, overrideString: "comments")?.navIcon(true)

        self.typeImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))

        bannerImage.translatesAutoresizingMaskIntoConstraints = false
        commentsImage.translatesAutoresizingMaskIntoConstraints = false
        typeImage.translatesAutoresizingMaskIntoConstraints = false

        self.contentView.addSubview(bannerImage)
        self.contentView.addSubview(commentsImage)
        self.contentView.addSubview(typeImage)

        commentsImage.addTapGestureRecognizer { (_) in
            VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: self.link!.permalink)!), popupIfPossible: true, parentNavigationController: self.parentViewController?.navigationController, parentViewController: self.parentViewController)
        }
        bannerImage.addTapGestureRecognizer { (_) in
            parent.setLink(link: self.link!, shownURL: nil, lq: false, saveHistory: true, heroView: self.bannerImage, finalSize: self.bannerImage.image?.size, heroVC: parent, upvoteCallbackIn: nil)
        }

        self.contentView.backgroundColor = UIColor.black
        self.updateConstraints()

        self.parentViewController = parent
        self.link = link
        let preview = link.bannerUrl ?? ""
        let w = link.imageWidth
        let h = link.imageHeight
        estimatedHeight = CGFloat(getHeightFromAspectRatio(imageHeight: h, imageWidth: w))
        bannerImage.sd_setImage(with: URL.init(string: preview))
        
        switch ContentType.getContentType(submission: link) {
        case .ALBUM, .REDDIT_GALLERY:
            typeImage.image = UIImage(sfString: SFSymbol.photoFillOnRectangleFill, overrideString: "image")?.navIcon(true)
        case .EXTERNAL, .LINK, .REDDIT:
            typeImage.image = UIImage(named: "world")?.navIcon(true)
        case .SELF:
            typeImage.image = UIImage(sfString: SFSymbol.textbox, overrideString: "size")?.navIcon(true)
        case .EMBEDDED, .GIF, .STREAMABLE, .VIDEO, .VID_ME:
            typeImage.image = UIImage(sfString: SFSymbol.playFill, overrideString: "play")?.navIcon(true)
        default:
            typeImage.image = UIImage()
        }
    }
    
    func estimateHeight() -> CGFloat {
        return estimatedHeight
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    func addTouch(view: UIView, action: Selector) {
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: action)
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
    weak var parentViewController: (UIViewController & MediaVCDelegate)?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var thumb = true
    
    override func updateConstraints() {
        super.updateConstraints()
        
        let views = ["banner": bannerImage, "comments": commentsImage, "type": typeImage] as [String: Any]

        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-2-[banner]-2-|",
                                                          options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                          metrics: [:],
                                                          views: views))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-2-[banner]-2-|",
                                                                       options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                       metrics: [:],
                                                                       views: views))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[comments]-8-|",
                                                                       options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                       metrics: [:],
                                                                       views: views))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[type]-8-|",
                                                                       options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                       metrics: [:],
                                                                       views: views))

        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[type]-8-[comments]-8-|",
                                                                       options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                       metrics: [:],
                                                                       views: views))
        
    }
    
    func getHeightFromAspectRatio(imageHeight: Int, imageWidth: Int) -> Int {
        let ratio = Double(imageHeight) / Double(imageWidth)
        let width = Double(contentView.frame.size.width)
        return Int(width * ratio)
        
    }
}
