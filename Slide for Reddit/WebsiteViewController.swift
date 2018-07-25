//
//  WebsiteViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/1/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import SafariServices
import UIKit
import WebKit

class WebsiteViewController: MediaViewController, WKNavigationDelegate {
    var url: URL?
    var webView: WKWebView = WKWebView()
    var myProgressView: UIProgressView = UIProgressView()
    var sub: String
    
    init(url: URL, subreddit: String) {
        self.url = url
        self.sub = subreddit
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: subreddit))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.backgroundColor = .white

        if navigationController != nil {
            let sort = UIButton.init(type: .custom)
            sort.setImage(UIImage.init(named: "size")?.getCopy(withSize: .square(size: 25)), for: UIControlState.normal)
            sort.addTarget(self, action: #selector(self.readerMode(_:)), for: UIControlEvents.touchUpInside)
            sort.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
            let sortB = UIBarButtonItem.init(customView: sort)
            navigationItem.rightBarButtonItems = [ sortB]
        }

    }
    
    func exit() {
        self.navigationController?.popViewController(animated: true)
        if navigationController!.modalPresentationStyle == .pageSheet {
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func readerMode(_ sender: AnyObject) {
        let safariVC = SFHideSafariViewController(url: webView.url!, entersReaderIfAvailable: true)
        present(safariVC, animated: true, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: false)

        self.navigationController?.navigationBar.backItem?.title = ""
        webView = WKWebView(frame: self.view.frame)

        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true

        self.view.addSubview(webView)
        myProgressView = UIProgressView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 10))
        myProgressView.progressTintColor = ColorUtil.accentColorForSub(sub: sub)
        self.view.addSubview(myProgressView)

        self.webView.scrollView.frame = self.view.frame
        self.webView.scrollView.setZoomScale(1, animated: false)
        loadUrl()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)

    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            myProgressView.progress = Float(webView.estimatedProgress)
        }
    }
    
    func loadUrl() {
        print(url!.absoluteString)
        let myURLRequest: URLRequest = URLRequest(url: url!)
        webView.load(myURLRequest)
        self.title = url!.host
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var request = navigationAction.request
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

    func isAd(url: URL) -> Bool {
      let host = url.host
        print(host ?? "nil")
       return host != nil && !host!.isEmpty && hostMatches(host: host!)
    }
    
    func hostMatches(host: String) -> Bool {
        if AdDictionary.hosts.isEmpty {
           AdDictionary.doInit()
        }
        let firstPeriod = host.indexOf(".")
        return firstPeriod == nil || AdDictionary.hosts.contains(host) || firstPeriod! + 1 < host.length && AdDictionary.hosts.contains(host.substring(firstPeriod! + 1, length: host.length - (firstPeriod! + 1)))
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
extension WKWebView {
    func stringByEvaluatingJavaScriptFromString(script: String) -> String {
        var resultString: String?
        var finished: Bool = false
        self.evaluateJavaScript(script, completionHandler: {(result: Any?, error: Error?) -> Void in
            if error == nil {
                if result != nil {
                    resultString = "\(error.debugDescription)"
                }
            } else {
            }
            finished = true
        })
        while !finished {
            RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: NSDate.distantFuture)
        }
        return resultString!
    }
}
