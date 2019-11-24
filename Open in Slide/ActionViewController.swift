//
//  ActionViewController.swift
//  Open in Slide
//
//  Created by Carlos Crane on 1/21/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import MobileCoreServices
import UIKit

class ActionViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Get the item[s] we're handling from the extension context.
        
        // For example, look for an image and place it into an image view.
        // Replace this with something appropriate for the type[s] your extension supports.
        var urlFound = false
        var count = 0
        let length = self.extensionContext!.inputItems.count
        for item in self.extensionContext!.inputItems as! [NSExtensionItem] {
            count += 1
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier("public.url") {
                    provider.loadItem(forTypeIdentifier: "public.url", options: nil, completionHandler: { (url, _) -> Void in
                        if let shareURL = url as? NSURL {
                            let absolute = shareURL.absoluteString ?? ""
                            
                            if !absolute.matches(regex: "(?i)redd\\.it/\\w+") && !absolute.matches(regex: "(?i)reddit\\.com/[^/]*") {
                                //Not a Reddit URL
                                //causing crashes, need to revisit self.extensionContext?.cancelRequest(withError: NSError())
                                return
                            }
                            
                            urlFound = true
                            
                            var comps = URLComponents(url: shareURL as URL, resolvingAgainstBaseURL: false)!
                            comps.scheme = "slide"
                            let newUrl = comps.url!
                            
                            if self.openURL(newUrl) {
                                self.extensionContext!.cancelRequest(withError: NSError())
                            } else {
                                self.extensionContext!.cancelRequest(withError: NSError())
                            }
                        }
                    })
                    break
                } else if count == length && !urlFound {
                    self.extensionContext!.cancelRequest(withError: NSError())
                }
            }
            
            if urlFound {
                //Only do first link
                break
            }
        }
    }
    
    @objc func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            responder = responder?.next
        }
        self.extensionContext!.cancelRequest(withError: NSError())
        return false
    }

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

}

extension String {
    func matches(regex: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let results = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.length))
            return results.count > 0
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return false
        }
    }
    mutating func stringByRemovingRegexMatches(pattern: String, replaceWith: String = "") {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSRange(location: 0, length: self.length)
            self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
        } catch {
            return
        }
    }
    var length: Int {
        return self.count
    }
}
