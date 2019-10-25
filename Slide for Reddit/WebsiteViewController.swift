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
    var blocking11 = false
    
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
            sort.setImage(UIImage(sfString: SFSymbol.textformatAlt, overrideString: "size")?.navIcon(), for: UIControl.State.normal)
            sort.addTarget(self, action: #selector(self.readerMode(_:)), for: UIControl.Event.touchUpInside)
            sort.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
            let sortB = UIBarButtonItem.init(customView: sort)
            
            let nav = UIButton.init(type: .custom)
            nav.setImage(UIImage(sfString: SFSymbol.safariFill, overrideString: "nav")?.navIcon(), for: UIControl.State.normal)
            nav.addTarget(self, action: #selector(self.openExternally(_:)), for: UIControl.Event.touchUpInside)
            nav.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
            let navB = UIBarButtonItem.init(customView: nav)

            navigationItem.rightBarButtonItems = [sortB, navB]
        }

    }
    
    @objc func openExternally(_ sender: UIButton) {
        guard let baseURL = self.webView.url else {
            return
        }
        let alert = DragDownAlertMenu(title: "Link options", subtitle: baseURL.absoluteString, icon: baseURL.absoluteString)
        let open = OpenInChromeController.init()
        if open.isChromeInstalled() {
            alert.addAction(title: "Open in Chrome", icon: UIImage(named: "world")?.menuIcon()) {
                open.openInChrome(baseURL, callbackURL: nil, createNewTab: true)
            }
        }
        
        alert.addAction(title: "Open in default app", icon: UIImage(sfString: SFSymbol.safariFill, overrideString: "nav")?.menuIcon(), action: {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(baseURL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            } else {
                UIApplication.shared.openURL(baseURL)
            }
        })
        
        alert.addAction(title: "Share URL", icon: UIImage(sfString: SFSymbol.squareAndArrowUp, overrideString: "share")?.menuIcon()) {
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

        let window = UIApplication.shared.keyWindow!
        
        if let modalVC = window.rootViewController?.presentedViewController {
            alert.show(modalVC)
        } else {
            alert.show(window.rootViewController)
        }
    }

    func exit() {
        self.navigationController?.popViewController(animated: true)
        if navigationController!.modalPresentationStyle == .pageSheet {
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func readerMode(_ sender: AnyObject) {
        let safariVC = SFHideSafariViewController(url: webView.url!, entersReaderIfAvailable: true)
        present(safariVC, animated: true, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
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
        if #available(iOS 11, *) {
            if UserDefaults.standard.bool(forKey: "adblock-loaded") {
                WKContentRuleListStore.default().lookUpContentRuleList(forIdentifier: "slide-ad-blocking") { [weak self] (contentRuleList, error) in
                    guard let strongSelf = self else {return}
                    if let error = error {
                        print(error.localizedDescription)
                        UserDefaults.standard.set(false, forKey: "adblock-loaded")
                        strongSelf.setupBlocking()
                        return
                    }
                    if let list = contentRuleList {
                        strongSelf.blocking11 = true
                        strongSelf.webView.configuration.userContentController.add(list)
                    }
                }
            } else {
                setupBlocking()
            }
        }
        loadUrl()
    }
    
    @available(iOS 11.0, *)
    func setupBlocking() {
        if let jsonFilePath = Bundle.main.path(forResource: "adaway.json", ofType: nil),
            let jsonFileContent = try? String(contentsOfFile: jsonFilePath, encoding: String.Encoding.utf8) {
            WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "slide-ad-blocking", encodedContentRuleList: jsonFileContent) { [weak self] (contentRuleList, error) in
                guard let strongSelf = self else {return}
                if let error = error {
                    strongSelf.blocking11 = false
                    print(error.localizedDescription)
                    return
                }
                if let list = contentRuleList {
                    strongSelf.blocking11 = true
                    strongSelf.webView.configuration.userContentController.add(list)
                    UserDefaults.standard.set(true, forKey: "adblock-loaded")
                }
            }
        }
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
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Fix for "target=_blank" links not opening
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let request = navigationAction.request
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

        if !blocking11 {
            if url == nil || !(isAd(url: url!)) {
                
                decisionHandler(WKNavigationActionPolicy.allow)
                
                } else {
                
                decisionHandler(WKNavigationActionPolicy.cancel)
            }
        } else {
            decisionHandler(WKNavigationActionPolicy.allow)
        }
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
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
    func stringByEvaluatingJavaScriptFromString(script: String) -> String? {
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
            RunLoop.current.run(mode: RunLoop.Mode.default, before: NSDate.distantFuture)
        }
        return resultString
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value) })
}
