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
        for item in self.extensionContext!.inputItems as! [NSExtensionItem] {
            for provider in item.attachments! {
                if provider.hasItemConformingToTypeIdentifier("public.url") {
                    provider.loadItem(forTypeIdentifier: "public.url", options: nil, completionHandler: { (url, _) -> Void in
                        if let shareURL = url as? NSURL {
                            print("Got URL!")
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
