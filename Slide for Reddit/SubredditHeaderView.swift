//
//  SubredditHeaderView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import UZTextView

class SubredditHeaderView: UIView, UZTextViewDelegate, UIViewControllerPreviewingDelegate {
    
    var back: UIView = UIView()
    var title: UILabel = UILabel()
    var subscribers: UILabel = UILabel()
    var here: UILabel = UILabel()
    var desc: UZTextView = UZTextView()
    var info: UZTextView = UZTextView()

    var subscribe: UITableViewCell = UITableViewCell()
    var theme = UITableViewCell()
    var submit = UITableViewCell()

    override init(frame: CGRect) {
        super.init(frame:frame)
        
        self.subscribe.textLabel?.text = "Subscribed"
        self.subscribe.accessoryType = .none
        self.subscribe.backgroundColor = ColorUtil.foregroundColor
        self.subscribe.textLabel?.textColor = ColorUtil.fontColor
        self.subscribe.imageView?.image = UIImage.init(named: "subscribe")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.subscribe.imageView?.tintColor = ColorUtil.fontColor
        
        self.theme.textLabel?.text = "Subreddit theme"
        self.theme.accessoryType = .none
        self.theme.backgroundColor = ColorUtil.foregroundColor
        self.theme.textLabel?.textColor = ColorUtil.fontColor
        self.theme.imageView?.image = UIImage.init(named: "theme")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.theme.imageView?.tintColor = ColorUtil.fontColor
        
        self.submit.textLabel?.text = "New post"
        self.submit.accessoryType = .none
        self.submit.backgroundColor = ColorUtil.foregroundColor
        self.submit.textLabel?.textColor = ColorUtil.fontColor
        self.submit.imageView?.image = UIImage.init(named: "submit")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.submit.imageView?.tintColor = ColorUtil.fontColor

        self.desc = UZTextView(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        self.desc.delegate = self
        self.desc.isUserInteractionEnabled = true
        self.desc.backgroundColor = .clear
        
        self.info = UZTextView(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        self.info.delegate = self
        self.info.isUserInteractionEnabled = true
        self.info.backgroundColor = .clear

        self.title = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));
        title.numberOfLines = 1
        title.font = UIFont.boldSystemFont(ofSize: 20)
        title.textColor = UIColor.white
        
        self.subscribers = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));
        subscribers.numberOfLines = 1
        subscribers.font = UIFont.systemFont(ofSize: 16)
        subscribers.textColor = UIColor.white

        self.here = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));
        here.numberOfLines = 1
        here.font = UIFont.systemFont(ofSize: 16)
        here.textColor = UIColor.white

        self.back = UIImageView(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        

        let aTap = UITapGestureRecognizer(target: self, action: #selector(self.subscribe(_:)))
        subscribe.addGestureRecognizer(aTap)
        subscribe.isUserInteractionEnabled = true
        
        let pTap = UITapGestureRecognizer(target: self, action: #selector(self.theme(_:)))
        theme.addGestureRecognizer(pTap)
        theme.isUserInteractionEnabled = true
        
        let sTap = UITapGestureRecognizer(target: self, action: #selector(self.submit(_:)))
        submit.addGestureRecognizer(sTap)
        submit.isUserInteractionEnabled = true
        
        
        theme.translatesAutoresizingMaskIntoConstraints = false
        submit.translatesAutoresizingMaskIntoConstraints = false
        subscribe.translatesAutoresizingMaskIntoConstraints = false
        back.translatesAutoresizingMaskIntoConstraints = false
        desc.translatesAutoresizingMaskIntoConstraints = false
        info.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        subscribers.translatesAutoresizingMaskIntoConstraints = false
        here.translatesAutoresizingMaskIntoConstraints = false

        addSubview(theme)
        addSubview(submit)
        addSubview(subscribe)
        addSubview(back)
        addSubview(info)
        back.addSubview(title)
        back.addSubview(subscribers)
        back.addSubview(here)
        back.addSubview(desc)
        
        navigationBar = UINavigationBar.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 56))
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
        let navItem = UINavigationItem(title: "")

        navigationBar.setItems([navItem], animated: false)
        addSubview(navigationBar)


        self.clipsToBounds = true
        updateConstraints()

    }
    
    func exit(){
        parentController?.dismiss(animated: true, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func subscribe(_ sender: AnyObject){
    }
    
    func theme(_ sender: AnyObject){

    }
    func submit(_ sender: AnyObject){

    }
    
    var content: CellContent?
    var textHeight : CGFloat = 0
    var descHeight: CGFloat = 0
    var contentInfo: CellContent?
    var parentController: MediaViewController?
    
    func setSubreddit(subreddit: Subreddit, parent: MediaViewController, _ width: CGFloat){
        self.subreddit = subreddit
        self.parentController = parent
        back.backgroundColor = ColorUtil.getColorForSub(sub: subreddit.displayName)
        title.text = subreddit.displayName
        subscribers.text = "\(subreddit.subscribers) subscribers"
        here.text = "\(subreddit.accountsActive) here"

        if(!subreddit.publicDescription.isEmpty()){
            let html = subreddit.publicDescriptionHtml.preprocessedHTMLStringBeforeNSAttributedStringParsing
            do {
                let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
                let font = UIFont(name: ".SFUIText-Light", size: 16) ?? UIFont.systemFont(ofSize: 16)
                let attr2 = attr.reconstruct(with: font, color: .white, linkColor: ColorUtil.accentColorForSub(sub: subreddit.displayName))
                content = CellContent.init(string:LinkParser.parse(attr2, ColorUtil.accentColorForSub(sub: subreddit.displayName)), width: width - 24)
                desc.attributedString = content?.attributedString
                textHeight = (content?.textHeight)!
            } catch {
            }
        }
        
        if(!subreddit.descriptionHtml.isEmpty()){
            let html = subreddit.descriptionHtml.preprocessedHTMLStringBeforeNSAttributedStringParsing
            do {
                let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
                let font = UIFont(name: ".SFUIText-Light", size: 16) ?? UIFont.systemFont(ofSize: 16)
                let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: ColorUtil.accentColorForSub(sub: subreddit.displayName))
                contentInfo = CellContent.init(string:LinkParser.parse(attr2, ColorUtil.accentColorForSub(sub: subreddit.displayName)), width: width - 24)
                info.attributedString = contentInfo?.attributedString
                descHeight = (contentInfo?.textHeight)!
                info.backgroundColor = UIColor.green
                
                print("Height sidebar is \(descHeight)")
            } catch {
                
            }
            parentController?.registerForPreviewing(with: self, sourceView: info)
        }
        
        updateConstraints()
    }
    
    var navigationBar: UINavigationBar = UINavigationBar()
  
    var subreddit: Subreddit?
    var constraint:[NSLayoutConstraint] = []

    override func updateConstraints() {
        super.updateConstraints()

        let metrics=["topMargin": 0, "bh" : CGFloat(130 + textHeight), "dh":descHeight, "b": textHeight + 30]
        let views=["theme": theme, "submit":submit, "subscribe": subscribe, "back":back, "desc":desc, "nav": navigationBar, "info":info, "title":title, "subscribers":subscribers, "here":here] as [String : Any]
        
        

        back.removeConstraints(constraint)
        constraint = []
        
        
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[back]-(0)-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[submit]-(12)-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[subscribe]-(12)-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[theme]-(12)-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))

        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[desc]-(12)-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[info]-(12)-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[title]-(12)-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[subscribers]-(12)-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))

        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[here]-(12)-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))

        addConstraints(constraint)
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[nav]-8-[title]-8-[subscribers]-2-[here]-2-[desc(d)]-4-|",
                                                           options: NSLayoutFormatOptions(rawValue: 0),
                                                           metrics: metrics,
                                                           views: views))
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[back(bh)]-(2)-[subscribe(50)]-(2)-[theme(50)]-(2)-[submit(50)]-(8)-[info(dh)]-(4)-|",
                                                      options: NSLayoutFormatOptions(rawValue: 0),
                                                      metrics: metrics,
                                                      views: views))

    }
    
    func getEstHeight()-> CGFloat{
        return CGFloat(60 + textHeight) + ((contentInfo == nil) ? 0 : descHeight) + (50*9)
    }
    
    func textView(_ textView: UZTextView, didLongTapLinkAttribute value: Any?) {
        if let attr = value as? [String: Any]{
            if let url = attr[NSLinkAttributeName] as? URL {
                if parentController != nil{
                    let sheet = UIAlertController(title: url.absoluteString, message: nil, preferredStyle: .actionSheet)
                    sheet.addAction(
                        UIAlertAction(title: "Close", style: .cancel) { (action) in
                            sheet.dismiss(animated: true, completion: nil)
                        }
                    )
                    let open = OpenInChromeController.init()
                    if(open.isChromeInstalled()){
                        sheet.addAction(
                            UIAlertAction(title: "Open in Chrome", style: .default) { (action) in
                                open.openInChrome(url, callbackURL: nil, createNewTab: true)
                            }
                        )
                    }
                    sheet.addAction(
                        UIAlertAction(title: "Open in Safari", style: .default) { (action) in
                            if #available(iOS 10.0, *) {
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            } else {
                                UIApplication.shared.openURL(url)
                            }
                            sheet.dismiss(animated: true, completion: nil)
                        }
                    )
                    sheet.addAction(
                        UIAlertAction(title: "Open", style: .default) { (action) in
                            /* let controller = WebViewController(nibName: nil, bundle: nil)
                             controller.url = url
                             let nav = UINavigationController(rootViewController: controller)
                             self.present(nav, animated: true, completion: nil)*/
                        }
                    )
                    sheet.addAction(
                        UIAlertAction(title: "Copy URL", style: .default) { (action) in
                            UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
                            sheet.dismiss(animated: true, completion: nil)
                        }
                    )
                    //todo make this work on ipad
                    parentController?.present(sheet, animated: true, completion: nil)
                }
            }
        }
    }
    
    func textView(_ textView: UZTextView, didClickLinkAttribute value: Any?) {
        print("Clicked")
        if((parentController) != nil){
            if let attr = value as? [String: Any] {
                if let url = attr[NSLinkAttributeName] as? URL {
                    parentController?.doShow(url: url)
                }
            }
        }
    }
    
    func selectionDidEnd(_ textView: UZTextView) {
    }
    
    func selectionDidBegin(_ textView: UZTextView) {
    }
    
    func didTapTextDoesNotIncludeLinkTextView(_ textView: UZTextView) {
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
            let locationInTextView = info.convert(location, to: info)
            
            if let (url, rect) = getInfo(locationInTextView: locationInTextView) {
                previewingContext.sourceRect = info.convert(rect, from: info)
                if let controller = parentController?.getControllerForUrl(baseUrl: url){
                    return controller
                }
            }
        return nil
    }
    
    func getInfo(locationInTextView: CGPoint) -> (URL, CGRect)? {
        if let attr = info.attributes(at: locationInTextView) {
            if let url = attr[NSLinkAttributeName] as? URL,
                let value = attr[UZTextViewClickedRect] as? CGRect {
                return (url, value)
            }
        }
        return nil
    }
    
    
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        parentController?.show(viewControllerToCommit, sender: parentController )
    }

}
extension UIImage {
    
    func addImagePadding(x: CGFloat, y: CGFloat) -> UIImage {
        let width: CGFloat = self.size.width + x;
        let height: CGFloat = self.size.width + y;
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0);
        let context: CGContext = UIGraphicsGetCurrentContext()!;
        UIGraphicsPushContext(context);
        let origin: CGPoint = CGPoint(x: (width - self.size.width) / 2, y: (height - self.size.height) / 2);
        self.draw(at: origin)
        UIGraphicsPopContext();
        let imageWithPadding = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return imageWithPadding!
    }
}

