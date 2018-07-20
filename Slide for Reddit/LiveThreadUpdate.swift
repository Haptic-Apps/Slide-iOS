//
//  CommentCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/7/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import reddift
import TTTAttributedLabel
import UIKit

class LiveThreadUpdate: UICollectionViewCell, UIGestureRecognizerDelegate, TTTAttributedLabelDelegate {
    
    var title = UILabel()
    var textView = TTTAttributedLabel.init(frame: CGRect.zero)
    var info = UILabel()
    var image = UIImageView()
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        parentViewController?.doShow(url: url)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let topmargin = 5
        let bottommargin = 5
        let leftmargin = 5
        let rightmargin = 5
        
        let f = self.contentView.frame
        let fr = UIEdgeInsetsInsetRect(f, UIEdgeInsets(top: CGFloat(topmargin), left: CGFloat(leftmargin), bottom: CGFloat(bottommargin), right: CGFloat(rightmargin)))
        self.contentView.frame = fr
    }
    
    var content: NSAttributedString?
    var hasText = false
    
    var full = false
    var estimatedHeight = CGFloat(0)
    
    func estimateHeight() -> CGFloat {
        if estimatedHeight == 0 {
            let framesetterB = CTFramesetterCreateWithAttributedString(content!)
            let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: width - 12, height: CGFloat.greatestFiniteMagnitude), nil)

            estimatedHeight = CGFloat(24) + CGFloat(!hasText ? 0 : textSizeB.height)
        }
        return estimatedHeight
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.layoutMargins = UIEdgeInsets.init(top: 2, left: 0, bottom: 0, right: 0)
        
        self.title = UILabel(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        title.numberOfLines = 0
        title.lineBreakMode = NSLineBreakMode.byWordWrapping
        title.font = FontGenerator.fontOfSize(size: 14, submission: true)
        
        title.textColor = ColorUtil.fontColor
        
        self.textView = TTTAttributedLabel(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        self.textView.delegate = self
        self.textView.isUserInteractionEnabled = true
        self.textView.backgroundColor = .clear
        
        self.info = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        info.numberOfLines = 0
        info.font = FontGenerator.fontOfSize(size: 12, submission: false)
        info.textColor = ColorUtil.fontColor
        info.alpha = 0.87
        
        self.image = UIImageView(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 0))
        image.layer.cornerRadius = 15
        image.clipsToBounds = true
        
        title.translatesAutoresizingMaskIntoConstraints = false
        info.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        image.translatesAutoresizingMaskIntoConstraints = false

        self.contentView.addSubview(title)
        self.contentView.addSubview(textView)
        self.contentView.addSubview(info)
        self.contentView.addSubview(image)

        self.contentView.backgroundColor = ColorUtil.foregroundColor
        
        self.updateConstraints()
        
    }
    var bigConstraint: NSLayoutConstraint?
    
    override func updateConstraints() {
        super.updateConstraints()

        self.contentView.layoutMargins = UIEdgeInsets.init(top: CGFloat(5), left: CGFloat(5), bottom: CGFloat(5), right: CGFloat(5))
        self.contentView.layer.cornerRadius = 15
        self.contentView.clipsToBounds = true

        let metrics=[
            "horizontalMargin": 75,
            "top": 0,
            "bottom": 0,
            "separationBetweenLabels": 0,
            "bh": imageHeight,
            "labelMinHeight": 75,
            ]
        let views=["label": title, "body": textView, "banner": image, "info": info] as [String: Any]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[label]-8-|",
                                                                       options: NSLayoutFormatOptions(rawValue: 0),
                                                                       metrics: metrics,
                                                                       views: views))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[body]-8-|",
                                                                       options: NSLayoutFormatOptions(rawValue: 0),
                                                                       metrics: metrics,
                                                                       views: views))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[info]-8-|",
                                                                       options: NSLayoutFormatOptions(rawValue: 0),
                                                                       metrics: metrics,
                                                                       views: views))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[banner]-8-|",
                                                                       options: NSLayoutFormatOptions(rawValue: 0),
                                                                       metrics: metrics,
                                                                       views: views))

        if !lsC.isEmpty {
            self.contentView.removeConstraints(lsC)
        }
        
        lsC = []
        lsC.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-4-[banner(bh)]-4-[label]-4-[info]-4-[body]-8-|",
                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                              metrics: metrics,
                                                              views: views))
        self.contentView.addConstraints(lsC)
        
    }
    
    var lsC: [NSLayoutConstraint] = []
    var url = ""
    var imageHeight = 0
    
    func setUpdate(rawJson: JSONAny, parent: UIViewController & MediaVCDelegate, nav: UIViewController?, width: CGFloat) {
        let json = rawJson as! JSONDictionary
        parentViewController = parent
        if navViewController == nil && nav != nil {
            navViewController = nav
        }
        title.text = "u/\(json["author"] as! String) \(DateFormatter().timeSince(from: NSDate(timeIntervalSince1970: TimeInterval(json["created_utc"] as! Int)), numericDates: true))"
        title.sizeToFit()
        
        if let url = json["original_url"] as? String {
            self.url = url
            let commentClick = UITapGestureRecognizer(target: self, action: #selector(LiveThreadUpdate.openContent(sender:)))
            commentClick.delegate = self
            self.addGestureRecognizer(commentClick)
        }
        
        let infoString = NSMutableAttributedString()
        info.attributedText = infoString
        
        let accent = ColorUtil.accentColorForSub(sub: "")
        if let body = json["body_html"] as? String {
            if !body.isEmpty() {
                var html = body.gtm_stringByUnescapingFromHTML()!
                do {
                    html = html.trimmed()
                    html = WrapSpoilers.addSpoilers(html)
                    html = WrapSpoilers.addTables(html)
                    let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
                    let font = FontGenerator.fontOfSize(size: 16, submission: false)
                    let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: accent)
                    content = LinkParser.parse(attr2, accent)
                    let framesetterB = CTFramesetterCreateWithAttributedString(content!)
                    let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: width - 16, height: CGFloat.greatestFiniteMagnitude), nil)

                    textView.setText(content)
                    textView.frame.size.height = textSizeB.height
                    hasText = true
                } catch {
                }
            }
        }
        
        if bigConstraint != nil {
            removeConstraint(bigConstraint!)
        }
        imageHeight = 0
        image.alpha = 0

        if json["mobile_embeds"] != nil && !(json["mobile_embeds"] as? JSONArray)!.isEmpty {
            if let embedsB = json["mobile_embeds"] as? JSONArray, let embeds = embedsB[0] as? JSONDictionary, let height = embeds["height"] as? Int, let width = embeds["width"] as? Int, let url = embeds["url"] as? String {
                image.alpha = 0
                let imageSize = CGSize.init(width: width, height: height)
                var aspect = imageSize.width / imageSize.height
                if aspect == 0 || aspect > 10000 || aspect.isNaN {
                    aspect = 1
                }
                bigConstraint = NSLayoutConstraint(item: image, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: image, attribute: NSLayoutAttribute.height, multiplier: aspect, constant: 0.0)
                
                    let h = getHeightFromAspectRatio(imageHeight: height, imageWidth: width)
                    if h == 0 {
                        imageHeight = 200
                    } else {
                        imageHeight = h
                    }

                addConstraint(bigConstraint!)
                image.isUserInteractionEnabled = true
                image.sd_setImage(with: URL.init(string: url), completed: { (image, _, cache, _) in
                    self.image.contentMode = .scaleAspectFill
                    if cache == .none {
                        UIView.animate(withDuration: 0.3, animations: {
                            self.image.alpha = 1
                        })
                    } else {
                        self.image.alpha = 1
                    }
                })
            }
        }
        setNeedsUpdateConstraints()
    }
    
    func getHeightFromAspectRatio(imageHeight: Int, imageWidth: Int) -> Int {
        let ratio = Double(imageHeight) / Double(imageWidth)
        let width = Double(contentView.frame.size.width - 16)
        return Int(width * ratio)
        
    }

    var registered: Bool = false
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var comment: RComment?
    public var parentViewController: UIViewController & MediaVCDelegate?
    public var navViewController: UIViewController?
    
    func openContent(sender: UITapGestureRecognizer? = nil) {
        parentViewController?.doShow(url: URL.init(string: url)!)
    }
}
