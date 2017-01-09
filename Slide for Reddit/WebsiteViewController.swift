//
//  WebsiteViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/1/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import AMScrollingNavbar
import WebKit

class WebsiteViewController: MediaViewController, WKNavigationDelegate {
    var url: URL?
    var webView: WKWebView = WKWebView()
    var myProgressView: UIProgressView = UIProgressView()
    
    var theBool: Bool = false
    var myTimer: Timer = Timer()

    init(url: URL, subreddit: String){
        self.url = url
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: subreddit))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.backItem?.title = ""
        webView = WKWebView(frame: CGRect(x:0, y:0, width: UIScreen.main.bounds.width, height:UIScreen.main.bounds.height))
       // self.shyNavBarManager.scrollView = self.webView.scrollView
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true

        self.view.addSubview(webView)
        myProgressView = UIProgressView(frame: CGRect(x:0, y:webView.frame.origin.y, width: UIScreen.main.bounds.width, height:10))

        self.view.addSubview(myProgressView)
        
        loadUrl()
        if let navigationController = self.navigationController as? ScrollingNavigationController {
            navigationController.followScrollView(self.webView, delay: 50.0)
        }

    }
    
    func loadUrl(){
        let myURLRequest:URLRequest = URLRequest(url: url!)
        webView.load(myURLRequest)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.theBool = true
        self.title = webView.stringByEvaluatingJavaScriptFromString(script: "document.title");
        UIApplication.shared.isNetworkActivityIndicatorVisible = false

    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var request = navigationAction.request;
        let url = request.url
        
        if url == nil || !(isAd(url: url!)) {
            
            decisionHandler(WKNavigationActionPolicy.allow)
            
            } else {
            
            decisionHandler(WKNavigationActionPolicy.cancel)
        }

    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return request.url == nil || !(isAd(url: request.url!))
    }

    func isAd(url: URL) -> Bool{
      let host = url.host
        print(host ?? "nil")
       return host != nil && !host!.isEmpty && hostMatches(host: host!)
    }
    
    func hostMatches(host: String) -> Bool{
        if(AdDictionary.hosts.isEmpty){
           //todo AdDictionary.doInit()
        }
        let firstPeriod = host.indexOf(".")
        return firstPeriod == nil || AdDictionary.hosts.contains(host) || firstPeriod! + 1 < host.length && AdDictionary.hosts.contains(host.substring(firstPeriod! + 1, length: host.length - (firstPeriod! + 1)))
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        self.myProgressView.progress = 0.0
        self.theBool = false
        self.myTimer = Timer.scheduledTimer(timeInterval: 0.01667, target: self, selector: #selector(WebsiteViewController.timerCallback(_:)), userInfo: nil, repeats: true)
    }
    

    func timerCallback(_ sender: AnyObject) {
        if self.theBool {
            if self.myProgressView.progress >= 1 {
                self.myProgressView.isHidden = true
                self.myTimer.invalidate()
            } else {
                self.myProgressView.progress += 0.1
            }
        } else {
            self.myProgressView.progress += 0.05
            if self.myProgressView.progress >= 0.95 {
                self.myProgressView.progress = 0.95
            }
        }
    }


    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
extension WKWebView {
    func stringByEvaluatingJavaScriptFromString(script: String) -> String {
        var resultString: String? = nil
        var finished: Bool = false
        self.evaluateJavaScript(script, completionHandler: {(result: Any?, error: Error?) -> Void in
            if error == nil {
                if result != nil {
                    resultString = "\(result)"
                }
            }
            else {
            }
            finished = true
        })
        while !finished {
            RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: NSDate.distantFuture)
        }
        return resultString!
    }
}
