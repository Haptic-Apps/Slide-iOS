//
//  AlbumCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/9/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

import reddift
import TTTAttributedLabel
import ImageViewer
import MaterialComponents.MaterialProgressView
import SDWebImage

class AlbumCellView: UITableViewCell {
    
    var bannerImage = UIImageView()
    var progressView : MDCProgressView?
    var textView : TTTAttributedLabel?
    var savedConstraints: [NSLayoutConstraint] = []
    var estimatedHeight = CGFloat(0)
    var link: Images?
    
    func setLink(_ link: Images, parent: MediaViewController){
        self.parentViewController = parent
        
       /* maybe in future todo if(progressView != nil){
        progressView = MDCProgressView()
        
        let progressViewHeight = CGFloat(5)
        progressView?.frame = CGRect(x: 0, y: 0, width: self.bannerImage.frame.size.width, height: progressViewHeight)
            self.contentView.addSubview(progressView!)
        }
        
        progressView?.progress = 0*/

        self.link = link
        let preview = "https://imgur.com/\(link.hash!).png"
        let url = URL.init(string: preview)!
        let w = link.width
        let h = link.height
        var text = link.description
        if(text == nil){
            text = ""
        }
        let attr = NSMutableAttributedString(string: text!)
        let font = FontGenerator.fontOfSize(size: 16, submission: false)
        let attr2 = attr.reconstruct(with: font, color: .white, linkColor: ColorUtil.getColorForSub(sub: ""))
        let content = CellContent.init(string:LinkParser.parse(attr2), width:(self.frame.size.width))
        let activeLinkAttributes = NSMutableDictionary(dictionary: textView!.activeLinkAttributes)
        activeLinkAttributes[NSForegroundColorAttributeName] = ColorUtil.accentColorForSub(sub: "")
        textView!.activeLinkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
        textView!.linkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
        
        self.bannerImage.image = nil
        textView!.setText(content.attributedString)
        estimatedHeight = CGFloat(getHeightFromAspectRatio(imageHeight: h!, imageWidth: w!))
        self.removeConstraints(savedConstraints)
        savedConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[banner(bh)]-4-[text(th)]-4-|",
                                                     options: NSLayoutFormatOptions(rawValue: 0),
                                                     metrics: ["bh":estimatedHeight, "th":content.textHeight],
                                                     views: ["banner":bannerImage, "text": textView!])
        savedConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[banner]-0-|",
                                                               options: NSLayoutFormatOptions(rawValue: 0),
                                                               metrics: ["bh":estimatedHeight, "th":content.textHeight],
                                                               views: ["banner":bannerImage, "text": textView!]))
        savedConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-4-[text]-4-|",
                                                               options: NSLayoutFormatOptions(rawValue: 0),
                                                               metrics: ["bh":estimatedHeight, "th":content.textHeight],
                                                               views: ["banner":bannerImage, "text": textView!]))
        self.contentView.addConstraints(savedConstraints)
        

        if(SDWebImageManager.shared().cachedImageExists(for: url)){
            DispatchQueue.main.async {
                let image = SDWebImageManager.shared().imageCache.imageFromDiskCache(forKey: url.absoluteString)
                //self.progressView?.setHidden(true, animated: true)
                self.bannerImage.image = image
            }
        } else {
            SDWebImageDownloader.shared().downloadImage(with: url, options: .allowInvalidSSLCertificates, progress: { (current:NSInteger, total:NSInteger) in
                var average: Float = 0
                average = (Float (current) / Float(total))
              //  self.progressView!.progress = average
            }, completed: { (image, u, error, _) in
                SDWebImageManager.shared().saveImage(toCache: image, for: url)
                DispatchQueue.main.async {
               //     self.progressView?.setHidden(true, animated: true)
                    self.bannerImage.image = image
                }
            })
        }
    }

    func estimateHeight() ->CGFloat {
        return estimatedHeight
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.bannerImage = UIImageView(frame: CGRect(x: 0, y: 8, width: CGFloat.greatestFiniteMagnitude, height: 0))
        self.textView = TTTAttributedLabel.init(frame: CGRect(x: 0, y: 8, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        bannerImage.clipsToBounds = true;
        bannerImage.contentMode = UIViewContentMode.scaleAspectFill
        bannerImage.translatesAutoresizingMaskIntoConstraints = false
        textView!.translatesAutoresizingMaskIntoConstraints = false
        textView?.textColor = .white
        textView?.numberOfLines = 0
        self.contentView.addSubview(bannerImage)
        self.contentView.addSubview(textView!)
        

        addTouch(view: bannerImage, action: #selector(GalleryCellView.openLink(sender:)))
        
        self.contentView.backgroundColor = UIColor.black
    }
    
    func addTouch(view: UIView, action: Selector){
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: action)
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
    var parentViewController: MediaViewController?
    
    func openLink(sender: AnyObject){
        parentViewController?.doShow(url: URL.init(string: "https://imgur.com/\(link!.hash!).png")!)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var thumb = true
    
    func getHeightFromAspectRatio(imageHeight:Int, imageWidth: Int) -> Int {
        let ratio = Double(imageHeight)/Double(imageWidth)
        let width = Double(contentView.frame.size.width);
        return Int(width * ratio)
        
    }
    
    
    /* todo
     func openLink(sender: UITapGestureRecognizer? = nil){
     (parentViewController)?.setLink(lnk: link!)
     }
     
     func openComment(sender: UITapGestureRecognizer? = nil){
     if(!full){
     if(parentViewController is SubredditLinkViewController){
     (parentViewController as! SubredditLinkViewController).savedIndex = (self.superview?.superview as! UITableView).indexPath(for: self)!
     }
     let comment = CommentViewController(submission: link!)
     (self.navViewController as? UINavigationController)?.pushViewController(comment, animated: true)
     }
     }
     */
    
}
