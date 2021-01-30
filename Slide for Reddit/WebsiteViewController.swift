//
//  WebsiteViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/1/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Alamofire
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
    var needsReload = false
    var completionFound = false
    var csrfToken = ""
    var progressObservation: NSKeyValueObservation?

    var savedChallengeURL: String? // Used for login with Apple
    public var reloadCallback: (() -> Void)?
    
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
            let sort = UIButton(buttonImage: UIImage(sfString: SFSymbol.textformatAlt, overrideString: "size"))
            sort.addTarget(self, action: #selector(self.readerMode(_:)), for: UIControl.Event.touchUpInside)
            let sortB = UIBarButtonItem.init(customView: sort)
            
            let nav = UIButton(buttonImage: UIImage(sfString: SFSymbol.safariFill, overrideString: "nav"))
            nav.addTarget(self, action: #selector(self.openExternally(_:)), for: UIControl.Event.touchUpInside)
            let navB = UIBarButtonItem.init(customView: nav)

            navigationItem.rightBarButtonItems = [sortB, navB]
        }
        
        updateToolbar()

        navigationController?.setToolbarHidden(false, animated: false)
        navigationController?.toolbar.barTintColor = UIColor.backgroundColor
        navigationController?.toolbar.tintColor = UIColor.fontColor
    }
    
    func updateToolbar() {
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        var items: [UIBarButtonItem] = []
        
        let back = UIButton(buttonImage: UIImage(sfString: SFSymbol.chevronLeft, overrideString: "back"), toolbar: true)
        back.accessibilityLabel = "Go to last page"
        back.addTarget(self, action: #selector(goBack), for: UIControl.Event.touchUpInside)
        let backB = UIBarButtonItem(customView: back)
        
        if !webView.canGoBack {
            backB.isEnabled = false
            back.alpha = 0.5
        }

        let forward = UIButton(buttonImage: UIImage(sfString: SFSymbol.chevronRight, overrideString: "next"), toolbar: true)
        forward.accessibilityLabel = "Go forward"
        forward.addTarget(self, action: #selector(goNext), for: UIControl.Event.touchUpInside)
        let forwardB = UIBarButtonItem(customView: forward)

        if !webView.canGoForward {
            forwardB.isEnabled = false
            forward.alpha = 0.5
        }

        items.append(space)
        items.append(backB)
        items.append(space)
        items.append(forwardB)
        items.append(space)

        toolbarItems = items
    }
    
    @objc func goBack() {
        webView.goBack()
        updateToolbar()
    }
    
    @objc func goNext() {
        webView.goForward()
        updateToolbar()
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
                UIApplication.shared.open(baseURL, options: [:], completionHandler: nil)
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
        if let url = webView.url ?? url {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true
            let safariVC = SFHideSafariViewController(url: url, configuration: config)
            present(safariVC, animated: true, completion: nil)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
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
        webView.allowsBackForwardNavigationGestures = false

        self.view.addSubview(webView)
        webView.edgeAnchors /==/ self.view.edgeAnchors
        myProgressView = UIProgressView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 10))
        myProgressView.progressTintColor = ColorUtil.accentColorForSub(sub: sub)
        self.view.addSubview(myProgressView)

        self.webView.scrollView.frame = self.view.frame
        self.webView.scrollView.setZoomScale(1, animated: false)
        if #available(iOS 11, *) {
            if UserDefaults.standard.bool(forKey: "adblock-loaded") {
                WKContentRuleListStore.default().lookUpContentRuleList(forIdentifier: "slide-ad-blocking") { [weak self] (contentRuleList, error) in
                    guard let strongSelf = self else { return }
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
                guard let strongSelf = self else { return }
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
        
        progressObservation = webView.observe(\.estimatedProgress, options: .new, changeHandler: { (webView, _) in
            self.myProgressView.progress = Float(webView.estimatedProgress)
            if webView.estimatedProgress > 0.98 {
                self.myProgressView.isHidden = true
                if self.needsReload { // Show a loader and wait for NSURLSession cache to sync Cookies. 3 seconds worked for me, but there is no event handler for this
                    self.needsReload = false
                    webView.alpha = 0
                    webView.superview?.backgroundColor = UIColor.backgroundColor
                    let pending = UIAlertController(title: "Syncing with Reddit...", message: nil, preferredStyle: .alert)

                    let indicator = UIActivityIndicatorView(frame: pending.view.bounds)
                    indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]

                    pending.view.addSubview(indicator)
                    indicator.isUserInteractionEnabled = false
                    indicator.startAnimating()

                    self.present(pending, animated: true, completion: nil)
                    
                    self.checkCookiesUntilCompletion {
                        self.completionFound = true

                        self.webView.reload()
                        self.webView.alpha = 1
                        pending.dismiss(animated: false, completion: nil)
                    }
                }
            } else {
                self.myProgressView.isHidden = false
            }
        })
        setObserver = true
    }
    
    func checkCookiesUntilCompletion(tries: Int = 0, _ completion: @escaping () -> Void) {
        if completionFound {
            return
        }
        let shared = HTTPCookieStorage.shared
        shared.cookies?.forEach({ (cookie) in
            if cookie.name == "reddit_session" {
                completion()
                return
            }
        })
        
        if tries == 6 {
            completion()
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.checkCookiesUntilCompletion(tries: tries + 1, completion)
        }
    }
    
    func loadUrl() {
        if url?.host == "twitter.com" && UIApplication.shared.respectIpadLayout() {
            webView.customUserAgent = "Googlebot/2.1 (+http://www.google.com/bot.html)"
        }
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
                    self.navigationController?.setToolbarHidden(true, animated: false)
                    self.savedChallengeURL = url?.absoluteString
                    let button = UIBarButtonItem(title: "Log in with Apple", style: UIBarButtonItem.Style.plain, target: self, action: #selector(loginWithApple))
                    self.navigationItem.rightBarButtonItems = [button]
                }
            }
        }

        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8), bodyString.contains("id_token"), let base = savedChallengeURL { // Response from Apple login
            var params = queryDictionaryForQueryString(query: bodyString)
            params["csrf_token"] = csrfToken // Used stored csrfToken
            params["check_existing_user"] = true
            params["create_user"] = true

            do {
                if #available(iOS 13.0, *) {
                    // Let Reddit create new reddit_session Cookie from data returned from Apple Login
                    let jsonData = try JSONSerialization.data(withJSONObject: params, options: .withoutEscapingSlashes)
                    AF.request("https://www.reddit.com/account/identity_provider_login", method: .post, parameters: [:], encoding: String(data: jsonData, encoding: .utf8)!, headers: nil).responseJSON { (response) in
                        switch response.result {
                        case .success(let JSON):
                            let token = (JSON as? [String: Any])?["token"] as? String ?? ""
                            // New token generated, new reddit_session Cookie should exist now
                            print("TOKEN IS \(token)")
                            
                            // Force reload page
                            self.webView.load(URLRequest(url: URL(string: base)!))
                            self.needsReload = true
                        case .failure(let error):
                            print(error)
                        }
                    }
                } else {
                    // Fallback on earlier versions
                }
            } catch {
                
            }

            decisionHandler(WKNavigationActionPolicy.cancel)
            return
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
        updateToolbar()
        
    }
    
    // Force save Cookies
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard
            let response = navigationResponse.response as? HTTPURLResponse,
            let url = navigationResponse.response.url
        else {
            decisionHandler(.cancel)
            return
        }

        if let headerFields = response.allHeaderFields as? [String: String] {
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
            cookies.forEach { (cookie) in
                 HTTPCookieStorage.shared.setCookie(cookie)
            }
        }

        decisionHandler(.allow)
    }
    
    func queryDictionaryForQueryString(query: String) -> [String: Any] {
        var dictionary = [String: String]()

        query.components(separatedBy: "&").forEach {
            let componants = $0.components(separatedBy: "=")
            guard let name = componants[0].removingPercentEncoding, let value = componants[1].removingPercentEncoding else {
                return
            }
            dictionary[name] = value
        }

        return dictionary
    }
    
    // Get user csrf token for Alamofire, which will be used to authorize next
    @objc func loginWithApple() {
        AF.request("https://www.reddit.com/account/login/?mobile_ui=on&experiment_mweb_sso_login_link=enabled&experiment_mweb_google_onetap=onetap_auto&experiment_mweb_am_refactoring=enabled", method: .get, parameters: [:], encoding: URLEncoding.default, headers: nil).response { (response) in
            
            if let data = response.data, let stringBody = String(data: data, encoding: .utf8) {
                // Get token out of body HTML
                let split = stringBody.substring((stringBody.indexOf("csrf_token\" value=\"") ?? 0) + 19, length: 50)
                let secondSplit = split.substring(0, length: split.indexOf("\"") ?? 0)
                self.csrfToken = secondSplit
            }
            
            self.promptLoginScreen()
        }
    }

    // Prompts Sign in with Apple screen using Reddit's auth parameters
    @objc func promptLoginScreen() {
        let queryItems = [
            URLQueryItem(name: "client_id", value: "com.reddit.RedditAppleSSO"),
            URLQueryItem(name: "redirect_uri", value: "https://www.reddit.com"),
            URLQueryItem(name: "response_type", value: "code id_token"),
            URLQueryItem(name: "scope", value: "email"),
            URLQueryItem(name: "response_mode", value: "form_post"),
        ]

        var urlComps = URLComponents(string: "https://appleid.apple.com/auth/authorize")!
        urlComps.queryItems = queryItems

        guard let authURL = urlComps.url else {
            return
        }

        let myURLRequest: URLRequest = URLRequest(url: authURL)
        webView.load(myURLRequest)
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
                    resultString = result as? String
                }
            } else {
                resultString = "\(error.debugDescription)"
            }
            finished = true
        })
        while !finished {
            RunLoop.current.run(mode: RunLoop.Mode.default, before: NSDate.distantFuture)
        }
        return resultString
    }

    // From https://stackoverflow.com/a/54573361/3697225
    func cleanAllCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }

    func refreshCookies() {
        self.configuration.processPool = WKProcessPool()
    }

}

extension WebsiteViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "logHandler" {
            print("LOG: \(message.body)")
        }
    }
}

extension WKWebView {

    private var httpCookieStore: WKHTTPCookieStore { return WKWebsiteDataStore.default().httpCookieStore }

    func getCookies(for domain: String? = nil, completion: @escaping ([String: Any]) -> Void) {
        var cookieDict = [String: AnyObject]()
        httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                if let domain = domain {
                    if cookie.domain.contains(domain) {
                        cookieDict[cookie.name] = cookie.properties as AnyObject?
                    }
                } else {
                    cookieDict[cookie.name] = cookie.properties as AnyObject?
                }
            }
            completion(cookieDict)
        }
    }
}
extension String: ParameterEncoding {

    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.httpBody = data(using: .utf8, allowLossyConversion: false)
        return request
    }

}
