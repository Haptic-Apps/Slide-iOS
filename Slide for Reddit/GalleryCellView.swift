//
//  GalleryCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/18/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import TTTAttributedLabel


class GalleryCellView: UITableViewCell {
    
    var bannerImage = UIImageView()
    var typeImage = UIImageView()
    var commentsImage = UIImageView()
    
    var estimatedHeight = CGFloat(0)
    var link: RSubmission?
    
    func setLink(_ link: RSubmission, parent: MediaViewController){
        self.bannerImage = UIImageView(frame: CGRect(x: 0, y: 8, width: CGFloat.greatestFiniteMagnitude, height: 0))
        bannerImage.clipsToBounds = true;
        bannerImage.contentMode = UIViewContentMode.scaleAspectFit

        self.commentsImage = UIImageView(frame: CGRect(x:0, y:0, width: 40, height: 40))
        self.commentsImage.image = UIImage.init(named: "comments")?.navIcon()

        self.typeImage = UIImageView(frame: CGRect(x:0, y:0, width: 40, height: 40))

        bannerImage.translatesAutoresizingMaskIntoConstraints = false
        commentsImage.translatesAutoresizingMaskIntoConstraints = false
        typeImage.translatesAutoresizingMaskIntoConstraints = false

        self.contentView.addSubview(bannerImage)
        self.contentView.addSubview(commentsImage)
        self.contentView.addSubview(typeImage)

        commentsImage.addTapGestureRecognizer {
            VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: self.link!.permalink)!), popupIfPossible: true, parentNavigationController: self.parentViewController?.navigationController, parentViewController: self.parentViewController)
        }
        bannerImage.addTapGestureRecognizer {
            parent.setLink(lnk: self.link!, shownURL: nil, lq: false, saveHistory: true)
        }

        self.contentView.backgroundColor = UIColor.black
        self.updateConstraints()

        self.parentViewController = parent
        self.link = link
        let preview = link.bannerUrl
        let w = link.width
        let h = link.height
        estimatedHeight = CGFloat(getHeightFromAspectRatio(imageHeight: h, imageWidth: w))
        bannerImage.sd_setImage(with: URL.init(string: preview))
        
        switch(ContentType.getContentType(submission: link)){
        case .ALBUM:
            typeImage.image = UIImage.init(named: "image")?.navIcon()
            break;
        case .EXTERNAL, .LINK, .REDDIT:
            typeImage.image = UIImage.init(named: "world")?.navIcon()
            break;
        case .SELF:
            typeImage.image = UIImage.init(named: "size")?.navIcon()
            break;
        case .EMBEDDED, .GIF, .STREAMABLE, .VIDEO, .VID_ME:
            typeImage.image = UIImage.init(named: "play")?.navIcon()
            break;
        default:
            typeImage.image = UIImage()
            break;

        }
    }
    
    func estimateHeight() ->CGFloat {
        return estimatedHeight
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    func addTouch(view: UIView, action: Selector){
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: action)
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
    var parentViewController: MediaViewController?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var thumb = true
    
    override func updateConstraints() {
        super.updateConstraints()
        
        let views=["banner": bannerImage, "comments" : commentsImage, "type":typeImage] as [String : Any]

        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-2-[banner]-2-|",
                                                          options: NSLayoutFormatOptions(rawValue: 0),
                                                          metrics: [:],
                                                          views: views))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-2-[banner]-2-|",
                                                                       options: NSLayoutFormatOptions(rawValue: 0),
                                                                       metrics: [:],
                                                                       views: views))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[comments]-8-|",
                                                                       options: NSLayoutFormatOptions(rawValue: 0),
                                                                       metrics: [:],
                                                                       views: views))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[type]-8-|",
                                                                       options: NSLayoutFormatOptions(rawValue: 0),
                                                                       metrics: [:],
                                                                       views: views))

        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[type]-8-[comments]-8-|",
                                                                       options: NSLayoutFormatOptions(rawValue: 0),
                                                                       metrics: [:],
                                                                       views: views))

        
    }
    
    func getHeightFromAspectRatio(imageHeight:Int, imageWidth: Int) -> Int {
        let ratio = Double(imageHeight)/Double(imageWidth)
        let width = Double(contentView.frame.size.width);
        return Int(width * ratio)
        
    }
}
