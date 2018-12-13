//
//  WebsiteViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/1/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import reddift
import SafariServices
import UIKit
import WebKit

class WebsiteViewController: MediaViewController, WKNavigationDelegate {
    var url: URL?
    var webView: WKWebView = WKWebView()
    var myProgressView: UIProgressView = UIProgressView()
    var sub: String
    var register: Bool
    
    init(url: URL, subreddit: String) {
        self.url = url
        self.sub = subreddit
        self.register = false
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: subreddit))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.backgroundColor = .white

        if navigationController != nil {
            let sort = UIButton.init(type: .custom)
            sort.setImage(UIImage.init(named: "size")?.navIcon(), for: UIControlState.normal)
            sort.addTarget(self, action: #selector(self.readerMode(_:)), for: UIControlEvents.touchUpInside)
            sort.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
            let sortB = UIBarButtonItem.init(customView: sort)
            
            let nav = UIButton.init(type: .custom)
            nav.setImage(UIImage.init(named: "nav")?.navIcon(), for: UIControlState.normal)
            nav.addTarget(self, action: #selector(self.openExternally(_:)), for: UIControlEvents.touchUpInside)
            nav.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
            let navB = UIBarButtonItem.init(customView: nav)

            navigationItem.rightBarButtonItems = [sortB, navB]
        }

    }
    
    func openExternally(_ sender: UIButton) {
        guard let baseURL = self.webView.url else {
            return
        }
        let alert = UIAlertController.init(title: baseURL.absoluteString, message: "", preferredStyle: .actionSheet)
        let open = OpenInChromeController.init()
        if open.isChromeInstalled() {
            alert.addAction(
                UIAlertAction(title: "Open in Chrome", style: .default) { (_) in
                    open.openInChrome(baseURL, callbackURL: nil, createNewTab: true)
                }
            )
        }
        alert.addAction(
            UIAlertAction(title: "Open in Safari", style: .default) { (_) in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(baseURL, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(baseURL)
                }
            }
        )
        alert.addAction(
            UIAlertAction(title: "Share URL", style: .default) { (_) in
                let shareItems: Array = [baseURL]
                let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
                if let presenter = activityViewController.popoverPresentationController {
                    presenter.sourceView = sender
                    presenter.sourceRect = sender.bounds
                }
                let window = UIApplication.shared.keyWindow!
                if let modalVC = window.rootViewController?.presentedViewController {
                    modalVC.present(activityViewController, animated: true, completion: nil)
                } else {
                    window.rootViewController!.present(activityViewController, animated: true, completion: nil)
                }
            }
        )
        alert.addAction(
            UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            }
        )
        let window = UIApplication.shared.keyWindow!
        alert.modalPresentationStyle = .popover
        
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        
        if let modalVC = window.rootViewController?.presentedViewController {
            modalVC.present(alert, animated: true, completion: nil)
        } else {
            window.rootViewController!.present(alert, animated: true, completion: nil)
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
        if setObserver {
            webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        }
        let myURLRequest: URLRequest = URLRequest(url: URL(string: "about://blank")!)
        webView.load(myURLRequest)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.setToolbarHidden(true, animated: false)

        self.navigationController?.navigationBar.backItem?.title = ""
        webView = WKWebView(frame: self.view.frame)

        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true

        self.view.addSubview(webView)
        webView.edgeAnchors == self.view.edgeAnchors
        myProgressView = UIProgressView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 10))
        myProgressView.progressTintColor = ColorUtil.accentColorForSub(sub: sub)
        self.view.addSubview(myProgressView)

        self.webView.scrollView.frame = self.view.frame
        self.webView.scrollView.setZoomScale(1, animated: false)
        loadUrl()
    }
    
    var setObserver = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        setObserver = true
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            myProgressView.progress = Float(webView.estimatedProgress)
        }
    }
    
    func loadUrl() {
        let myURLRequest: URLRequest = URLRequest(url: url!)
        webView.load(myURLRequest)
        self.title = url!.host
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        if register && (webView.url?.absoluteString ?? "").contains("login.compact") {
            if !(webView.url?.absoluteString ?? "").contains("register") {
                var login = webView.url?.absoluteString ?? ""
                login = login.replacingOccurrences(of: "login.compact", with: "register.compact")
                let myURLRequest: URLRequest = URLRequest(url: URL(string: login)!)
                webView.load(myURLRequest)
                self.register = false
            }
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var request = navigationAction.request
        let url = request.url
        
        if url != nil {
            if (URLComponents(url: url!, resolvingAgainstBaseURL: false))?.scheme == "slide" {
                webView.endEditing(true)
                self.navigationController?.dismiss(animated: true) {
                    _ = OAuth2Authorizer.sharedInstance.receiveRedirect(url!, completion: { (result) -> Void in
                        print(result)
                        switch result {
                            
                        case .failure(let error):
                            print(error)
                        case .success(let token):
                            DispatchQueue.main.async(execute: { () -> Void in
                                do {
                                    try OAuth2TokenRepository.save(token: token, of: token.name)
                                    (UIApplication.shared.delegate as! AppDelegate).login?.setToken(token: token)
                                    NotificationCenter.default.post(name: OAuth2TokenRepositoryDidSaveTokenName, object: nil, userInfo: nil)
                                } catch {
                                    NotificationCenter.default.post(name: OAuth2TokenRepositoryDidFailToSaveTokenName, object: nil, userInfo: nil)
                                    print(error)
                                }
                            })
                        }
                    })
                }
            } else if (url?.absoluteString ?? "").contains("reddit.com/api/v1/authorize") {
                if self.title != "Log in" {
                    self.title = "Log in"
                    self.navigationItem.rightBarButtonItems = []
                    let dataStore = WKWebsiteDataStore.default()
                    dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                        dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                                             for: records.filter { $0.displayName.contains("reddit") },
                                             completionHandler: {})
                    }
                }
            }
        }

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
