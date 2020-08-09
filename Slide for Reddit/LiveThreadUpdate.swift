//
//  CommentCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/7/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import AudioToolbox
import reddift
import UIKit
import WebKit
import YYText

class LiveThreadUpdate: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    var title: YYLabel!
    var image = UIImageView()
    var web = WKWebView()
    
    func attributedLabel(_ label: YYTextView!, didSelectLinkWith url: URL!) {
        parentViewController?.doShow(url: url, heroView: nil, finalSize: nil, heroVC: nil, link: RSubmission())
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let topmargin = 5
        let bottommargin = 5
        let leftmargin = 5
        let rightmargin = 5
        
        let f = self.contentView.frame
        let fr = f.inset(by: UIEdgeInsets(top: CGFloat(topmargin), left: CGFloat(leftmargin), bottom: CGFloat(bottommargin), right: CGFloat(rightmargin)))
        self.contentView.frame = fr
        self.contentView.layer.cornerRadius = 15
        self.contentView.clipsToBounds = true
    }
    
    var content: NSMutableAttributedString?
    var hasText = false
    
    var full = false
    var estimatedHeight = CGFloat(0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    var imageAnchors =  [NSLayoutConstraint]()
    
    var lsC: [NSLayoutConstraint] = []
    var url = ""
    var imageHeight = 0
    
    func setUpdate(rawJson: JSONAny, parent: UIViewController & MediaVCDelegate, nav: UIViewController?, width: CGFloat) {
        if title == nil {
            self.contentView.layoutMargins = UIEdgeInsets.init(top: 2, left: 0, bottom: 0, right: 0)
            
            self.title = YYLabel()
            title.numberOfLines = 0
            title.lineBreakMode = NSLineBreakMode.byWordWrapping
            title.font = FontGenerator.fontOfSize(size: 14, submission: true)
            
            title.textColor = ColorUtil.theme.fontColor
            
            self.image = UIImageView(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 0))
            image.layer.cornerRadius = 15
            image.clipsToBounds = true
            
            web.layer.cornerRadius = 15
            web.clipsToBounds = true
            
            self.contentView.addSubview(title)
            self.contentView.addSubview(image)
            self.contentView.addSubview(web)

            self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
            title.horizontalAnchors == self.contentView.horizontalAnchors + 8
            image.horizontalAnchors == self.contentView.horizontalAnchors + 8
            image.topAnchor == self.contentView.topAnchor + 4
            web.horizontalAnchors == image.horizontalAnchors
            web.verticalAnchors == image.verticalAnchors
            self.title.topAnchor == self.image.bottomAnchor + 4
            self.title.bottomAnchor == self.contentView.bottomAnchor - 4
            
            let touchLinkAction = { (containerView: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) in
                text.enumerateAttributes(in: range, options: .longestEffectiveRangeNotRequired, using: { (attrs, _, _) in
                    for attr in attrs {
                        if attr.value is YYTextHighlight {
                            if let url = (attr.value as! YYTextHighlight).userInfo?["url"] as? URL {
                                self.parentViewController?.doShow(url: url, heroView: nil, finalSize: nil, heroVC: nil, link: RSubmission())
                                return
                            }
                        }
                    }
                })
            }
            
            let longTouchLinkAction = { (containerView: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) in
                text.enumerateAttributes(in: range, options: .longestEffectiveRangeNotRequired, using: { (attrs, _, _) in
                    for attr in attrs {
                        if attr.value is YYTextHighlight {
                            if let url = (attr.value as! YYTextHighlight).userInfo?["url"] as? URL {
                                let alertController = DragDownAlertMenu(title: "Link options", subtitle: url.absoluteString, icon: url.absoluteString)
                                
                                alertController.addAction(title: "Share URL", icon: UIImage(sfString: SFSymbol.squareAndArrowUp, overrideString: "share")!.menuIcon()) {
                                    let shareItems: Array = [url]
                                    let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
                                    activityViewController.popoverPresentationController?.sourceView = self.contentView
                                    self.parentViewController?.present(activityViewController, animated: true, completion: nil)
                                }
                                
                                alertController.addAction(title: "Copy URL", icon: UIImage(sfString: SFSymbol.docOnDocFill, overrideString: "copy")!.menuIcon()) {
                                    UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
                                    BannerUtil.makeBanner(text: "URL Copied", seconds: 5, context: self.parentViewController)
                                }
                                
                                alertController.addAction(title: "Open in default app", icon: UIImage(sfString: SFSymbol.safariFill, overrideString: "nav")!.menuIcon()) {
                                    if #available(iOS 10.0, *) {
                                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                    } else {
                                        UIApplication.shared.openURL(url)
                                    }
                                }
                                
                                let open = OpenInChromeController.init()
                                if open.isChromeInstalled() {
                                    alertController.addAction(title: "Open in Chrome", icon: UIImage(named: "world")!.menuIcon()) {
                                        _ = open.openInChrome(url, callbackURL: nil, createNewTab: true)
                                    }
                                }
                                
                                if #available(iOS 10.0, *) {
                                    HapticUtility.hapticActionStrong()
                                } else if SettingValues.hapticFeedback {
                                    AudioServicesPlaySystemSound(1519)
                                }
                                
                                alertController.show(self.parentViewController)

                                if #available(iOS 10.0, *) {
                                    HapticUtility.hapticActionStrong()
                                } else if SettingValues.hapticFeedback {
                                    AudioServicesPlaySystemSound(1519)
                                }
                                return
                            }
                        }
                    }
                })
            }
            
            self.title.isUserInteractionEnabled = true
            self.title.highlightLongPressAction = longTouchLinkAction
            self.title.highlightTapAction = touchLinkAction
        }
        
        let json = rawJson as! JSONDictionary
        parentViewController = parent
        if navViewController == nil && nav != nil {
            navViewController = nav
        }
        
        if let url = json["original_url"] as? String {
            self.url = url
            let commentClick = UITapGestureRecognizer(target: self, action: #selector(LiveThreadUpdate.openContent(sender:)))
            commentClick.delegate = self
            self.addGestureRecognizer(commentClick)
        }
        
        content = NSMutableAttributedString(string: "u/\(json["author"] as! String) \(DateFormatter().timeSince(from: NSDate(timeIntervalSince1970: TimeInterval(json["created_utc"] as! Int)), numericDates: true))", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor, NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 14, submission: false)])
        
        var bodyDone = false
        if let body = json["body_html"] as? String {
            if !body.isEmpty() {
                let html = body.unescapeHTML
                content?.append(NSAttributedString(string: "\n"))
               // TODO: - maybe link parsing here?
                content?.append(TextDisplayStackView.createAttributedChunk(baseHTML: html, fontSize: 16, submission: false, accentColor: ColorUtil.baseAccent, fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil))
                let size = CGSize(width: self.contentView.frame.size.width - 18, height: CGFloat.greatestFiniteMagnitude)

                title.attributedText = content
                let layout2 = YYTextLayout(containerSize: size, text: content!)!
                title.textLayout = layout2
                hasText = true
                bodyDone = true
            }
        }
        
        if !bodyDone {
            let size = CGSize(width: self.contentView.frame.size.width - 18, height: CGFloat.greatestFiniteMagnitude)
            
            title.attributedText = content
            let layout2 = YYTextLayout(containerSize: size, text: content!)!
            title.textLayout = layout2
        }
        
        imageHeight = 0
        image.alpha = 0
        web.alpha = 0
        web.loadHTMLString("about://blank", baseURL: nil)

        if json["mobile_embeds"] != nil && !(json["mobile_embeds"] as? JSONArray)!.isEmpty {
            if let embedsB = json["mobile_embeds"] as? JSONArray, let embeds = embedsB[0] as? JSONDictionary, let height = embeds["height"] as? Int, let width = embeds["width"] as? Int {
                image.alpha = 0
                if let url = embeds["url"] as? String {
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
                } else if let web = embeds["html"] as? String {
                    self.web.alpha = 1
                    self.web.configuration.allowsInlineMediaPlayback = true
                    self.web.loadHTMLString(web.decodeHTML().replacingOccurrences(of: "//", with: "https://"), baseURL: URL(string: "https://"))
                }
                let imageSize = CGSize.init(width: width, height: height)
                var aspect = imageSize.width / imageSize.height
                if aspect == 0 || aspect > 10000 || aspect.isNaN {
                    aspect = 1
                }
                
                let h = getHeightFromAspectRatio(imageHeight: height, imageWidth: width)
                if h == 0 {
                    imageHeight = 200
                } else {
                    imageHeight = h
                }
            }
        }
        self.contentView.removeConstraints(imageAnchors)
        imageAnchors = batch {
            self.image.heightAnchor == CGFloat(imageHeight)
        }
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
    public var parentViewController: (UIViewController & MediaVCDelegate)?
    public var navViewController: UIViewController?
    
    @objc func openContent(sender: UITapGestureRecognizer? = nil) {
        parentViewController?.doShow(url: URL.init(string: url)!, heroView: nil, finalSize: nil, heroVC: nil, link: RSubmission())
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToNSAttributedStringDocumentReadingOptionKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.DocumentReadingOptionKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.DocumentReadingOptionKey(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringDocumentAttributeKey(_ input: NSAttributedString.DocumentAttributeKey) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringDocumentType(_ input: NSAttributedString.DocumentType) -> String {
	return input.rawValue
}
