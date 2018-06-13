//
//  WidgetLinkCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/12/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit
import UZTextView
import TTTAttributedLabel
import MaterialComponents
import AudioToolbox
import XLActionController
import reddift
import SafariServices
import RLBAlertsPickers

class WidgetLinkCellView: UICollectionViewCell {
    
    var thumbImage = UIImageView()
    var title = TTTAttributedLabel.init(frame: CGRect.zero)
    var info = UILabel()
    
    var b = UIView()
    var estimatedHeight = CGFloat(0)
    var tagbody = UIView()
    
    func estimateHeight(_ full: Bool, _ reset: Bool = false) -> CGFloat {
        if (estimatedHeight == 0 || reset) {
            var paddingTop = CGFloat(0)
            var paddingBottom = CGFloat(2)
            var paddingLeft = CGFloat(0)
            var paddingRight = CGFloat(0)
            var innerPadding = CGFloat(0)
            if((SettingValues.postViewMode == .CARD || SettingValues.postViewMode == .CENTER) && !full){
                paddingTop = 5
                paddingBottom = 5
                paddingLeft = 5
                paddingRight = 5
            }
            
            let thumbheight = CGFloat(50)  - (SettingValues.postViewMode == .COMPACT ? 15 : 0)
            
            if(thumb){
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between top and thumbnail
                innerPadding += 18 - (SettingValues.postViewMode == .COMPACT ? 4 : 0) //between label and bottom box
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between box and end
            } else {
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8)
                innerPadding += 5 //between label and body
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 12) //between body and box
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between box and end
            }
            
            var estimatedUsableWidth = aspectWidth - paddingLeft - paddingRight
            if(thumb){
                estimatedUsableWidth -= thumbheight //is the same as the width
                estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 16 : 24) //between edge and thumb
                estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between thumb and label
            } else {
                estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 16 : 24) //12 padding on either side
            }
            
            let framesetter = CTFramesetterCreateWithAttributedString(title.attributedText)
            let textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(), nil, CGSize.init(width: estimatedUsableWidth, height: CGFloat.greatestFiniteMagnitude), nil)
            
            let totalHeight = paddingTop + paddingBottom + (thumb ? max(ceil(textSize.height), 50): ceil(textSize.height) + 50) + innerPadding + (full ? CGFloat(10) : CGFloat(0))
            estimatedHeight = totalHeight
        }
        return estimatedHeight
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.thumbImage = UIImageView(frame: CGRect(x: 0, y: 8, width: (SettingValues.largerThumbnail ? 75 : 50) - (SettingValues.postViewMode == .COMPACT ? 15 : 0), height: (SettingValues.largerThumbnail ? 75 : 50) - (SettingValues.postViewMode == .COMPACT ? 15 : 0)))
        thumbImage.layer.cornerRadius = 15;
        thumbImage.backgroundColor = UIColor.white
        thumbImage.clipsToBounds = true;
        thumbImage.contentMode = .scaleAspectFill
        thumbImage.elevate(elevation: 2.0)
        
        
        self.title = TTTAttributedLabel(frame: CGRect(x: 75, y: 8, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude));
        title.numberOfLines = 0
        title.lineBreakMode = NSLineBreakMode.byWordWrapping
        title.font = FontGenerator.fontOfSize(size: 18, submission: true)
        
        self.info = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));
        info.numberOfLines = 2
        info.font = FontGenerator.fontOfSize(size: 12, submission: true)
        info.textColor = .white
        b = info.withPadding(padding: UIEdgeInsets.init(top: 4, left: 10, bottom: 4, right: 10))
        b.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        b.clipsToBounds = true
        b.layer.cornerRadius = 15
        
        thumbImage.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        b.translatesAutoresizingMaskIntoConstraints = false
        tagbody.translatesAutoresizingMaskIntoConstraints = false
        
        self.contentView.addSubview(thumbImage)
        self.contentView.addSubview(title)
        self.contentView.addSubview(b)
        self.contentView.addSubview(tagbody)

        thumbImage.layer.cornerRadius = 10
        thumbImage.backgroundColor = UIColor.white
        thumbImage.clipsToBounds = true;
        thumbImage.contentMode = .scaleAspectFill
        
    }
    
    var thumb = true
    var submissionHeight: Int = 0
    var addTouch = false
    
    override func updateConstraints() {
        super.updateConstraints()
    }
    
    func getHeightFromAspectRatio(imageHeight: Int, imageWidth: Int) -> Int {
        let ratio = Double(imageHeight) / Double(imageWidth)
        let width = Double(contentView.frame.size.width);
        return Int(width * ratio)
        
    }
    
    var big = false
    var thumbConstraint: [NSLayoutConstraint] = []
    
    func refreshLink(_ submission: RSubmission) {
        self.link = submission
        title.setText(CachedTitle.getTitle(submission: submission, full: false, true, false))
        refresh()
    }
    
    var link: RSubmission?
    var aspectWidth = CGFloat(0)
    
    func setLink(submission: RSubmission, baseSub: String) {
            self.contentView.backgroundColor = ColorUtil.foregroundColor
            title.textColor = ColorUtil.Theme.LIGHT.fontColor
        
        self.link = submission
        
        title.setText(CachedTitle.getTitle(submission: submission, full: false, false
            , false))
        
        let activeLinkAttributes = NSMutableDictionary(dictionary: title.activeLinkAttributes)
        activeLinkAttributes[NSForegroundColorAttributeName] = ColorUtil.accentColorForSub(sub: submission.subreddit)
        title.activeLinkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
        title.linkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
        
        thumb = submission.thumbnail
        
        submissionHeight = submission.height
        
        var type = ContentType.getContentType(baseUrl: submission.url!)
        if (submission.isSelf) {
            type = .SELF
        }
        
            big = false
            thumb = true
        
        if (type == .SELF && SettingValues.hideImageSelftext) {
            big = false
            thumb = false
        }
        
        if (submissionHeight < 50) {
            thumb = true
            big = false
        }
        
        let shouldShowLq = SettingValues.dataSavingEnabled && submission.lQ && !(SettingValues.dataSavingDisableWiFi && LinkCellView.checkWiFi())
        if (type == ContentType.CType.SELF && SettingValues.hideImageSelftext
            || SettingValues.noImages && submission.isSelf) {
            big = false
            thumb = false
        }
        
        if (big || !submission.thumbnail) {
            thumb = false
        }
        
        if (submission.nsfw && (!SettingValues.nsfwPreviews || SettingValues.hideNSFWCollection && (baseSub == "all" || baseSub == "frontpage" || baseSub.contains("/m/") || baseSub.contains("+") || baseSub == "popular"))) {
            big = false
            thumb = true
        }
        
        
        if (SettingValues.noImages) {
            big = false
            thumb = false
        }
        
        if (thumb && type == .SELF) {
            thumb = false
        }
        
        if (!big && !thumb && submission.type != .SELF && submission.type != .NONE) { //If a submission has a link but no images, still show the web thumbnail
            thumb = true
            thumbImage.image = UIImage.init(named: "web")
        } else if (thumb && !big) {
            if (submission.nsfw) {
                thumbImage.image = UIImage.init(named: "nsfw")
            } else if (submission.thumbnailUrl == "web" || submission.thumbnailUrl.isEmpty) {
                thumbImage.image = UIImage.init(named: "web")
            } else {
                thumbImage.sd_setImage(with: URL.init(string: submission.thumbnailUrl), placeholderImage: UIImage.init(named: "web"))
            }
        } else {
            thumbImage.sd_setImage(with: URL.init(string: ""))
            self.thumbImage.frame.size.width = 0
        }
        
        aspectWidth = self.contentView.frame.size.width
        
        let mo = History.commentsSince(s: submission)
        doConstraints()
        refresh()

        if (type != .IMAGE && type != .SELF && !thumb) {
            b.isHidden = false
            var text = ""
            switch (type) {
            case .ALBUM:
                text = ("Album")
                break
            case .EXTERNAL:
                text = "External Link"
                break
            case .LINK, .EMBEDDED, .NONE:
                text = "Link"
                break
            case .DEVIANTART:
                text = "Deviantart"
                break
            case .TUMBLR:
                text = "Tumblr"
                break
            case .XKCD:
                text = ("XKCD")
                break
            case .GIF:
                text = ("GIF")
                break
            case .IMGUR:
                text = ("Imgur")
                break
            case .VIDEO:
                text = "YouTube"
                break
            case .STREAMABLE:
                text = "Streamable"
                break
            case .VID_ME:
                text = ("Vid.me")
                break
            case .REDDIT:
                text = ("Reddit content")
                break
            default:
                text = "Link"
                break
            }
        } else {
            b.isHidden = true
            tagbody.isHidden = true
        }
    }
    
    var currentType: CurrentType = .none
    
    //This function will update constraints if they need to be changed to change the display type
    func doConstraints() {
        var target = CurrentType.none
        
        if (thumb && !big) {
            target = .thumb
        } else if (big) {
            target = .banner
        } else {
            target = .text
        }
        
        print(currentType == target)
        
        if (currentType == target && target != .banner) {
            return //work is already done
        }
        var topmargin = 0
        var bottommargin = 2
        var leftmargin = 0
        var rightmargin = 0
        var innerpadding = 0
        var radius = 0
        
        self.contentView.layoutMargins = UIEdgeInsets.init(top: CGFloat(topmargin), left: CGFloat(leftmargin), bottom: CGFloat(bottommargin), right: CGFloat(rightmargin))
        
        let metrics = ["horizontalMargin": 75, "ctwelve": 6, "ceight": 4, "top": topmargin, "bottom": bottommargin, "separationBetweenLabels": 0, "labelMinHeight": 75, "bannerHeight": submissionHeight, "left": leftmargin, "padding": innerpadding] as [String: Int]
        let views = ["label": title, "image": thumbImage, "info":info, "image":thumbImage] as [String: Any]
        
        self.contentView.removeConstraints(thumbConstraint)
        thumbConstraint = []
        
        if (target == .thumb) {
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(ceight)-[image(thumb)]",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            if (SettingValues.leftThumbnail) {
                thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(ctwelve)-[image(thumb)]-(ceight)-[label]-(ctwelve)-|",
                                                                                  options: NSLayoutFormatOptions(rawValue: 0),
                                                                                  metrics: metrics,
                                                                                  views: views))
            } else {
                thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(ctwelve)-[label]-(ceight)-[image(thumb)]-(ctwelve)-|",
                                                                                  options: NSLayoutFormatOptions(rawValue: 0),
                                                                                  metrics: metrics,
                                                                                  views: views))
            }
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(ceight)-[label]-10-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        } else {
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(ceight)-[image(0)]",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(ctwelve)-[label]-(ctwelve)-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(ctwelve)-[label]-(ctwelve)-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        }
        self.contentView.addConstraints(thumbConstraint)
        currentType = target
    }
    
    
    func refresh() {
        let link = self.link!
        var attrs: [String: Any] = [:]
        
        var scoretext = (link.score >= 10000 && SettingValues.abbreviateScores) ? String(format: " %0.1fk", (Double(link.score) / Double(1000))) : " \(link.score)"
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let topmargin = 0
        let bottommargin = 2
        let leftmargin = 0
        let rightmargin = 0
        
        let f = self.contentView.frame
        let fr = UIEdgeInsetsInsetRect(f, UIEdgeInsetsMake(CGFloat(topmargin), CGFloat(leftmargin), CGFloat(bottommargin), CGFloat(rightmargin)))
        self.contentView.frame = fr
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public static var imageDictionary: NSMutableDictionary = NSMutableDictionary.init()
    
}
