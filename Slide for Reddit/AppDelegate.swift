//
//  AppDelegate.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/22/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import UserNotifications
import RealmSwift
import SDWebImage
import BiometricAuthentication

/// Posted when the OAuth2TokenRepository object succeed in saving a token successfully into Keychain.
public let OAuth2TokenRepositoryDidSaveTokenName = Notification.Name(rawValue: "OAuth2TokenRepositoryDidSaveToken")

/// Posted when the OAuth2TokenRepository object failed to save a token successfully into Keychain.
public let OAuth2TokenRepositoryDidFailToSaveTokenName = Notification.Name(rawValue: "OAuth2TokenRepositoryDidFailToSaveToken")

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let name = "reddittoken"
    var session: Session? = nil
    var fetcher: BackgroundFetch? = nil
    var subreddits: [Subreddit] = []
    var paginator = Paginator()
    var login: MainViewController?
    var seenFile: String?
    var commentsFile: String?
    var totalBackground = false
    var isPro = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let settings = UIUserNotificationSettings(types: UIUserNotificationType.alert, categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)

        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentDirectory = paths[0] as! String
        seenFile = documentDirectory.appending("/seen.plist")
        commentsFile = documentDirectory.appending("/comments.plist")

        let config = Realm.Configuration(
                schemaVersion: 11,
                migrationBlock: { migration, oldSchemaVersion in
                    if (oldSchemaVersion < 11) {
                    }
                })

        Realm.Configuration.defaultConfiguration = config
        let fileManager = FileManager.default
        if (!fileManager.fileExists(atPath: seenFile!)) {
            if let bundlePath = Bundle.main.path(forResource: "seen", ofType: "plist") {
                _ = NSMutableDictionary(contentsOfFile: bundlePath)
                do {
                    try fileManager.copyItem(atPath: bundlePath, toPath: seenFile!)
                } catch {
                    print("copy failure.")
                }
            } else {
                print("file myData.plist not found.")
            }
        } else {
            print("file myData.plist already exits at path.")
        }

        if (!fileManager.fileExists(atPath: commentsFile!)) {
            if let bundlePath = Bundle.main.path(forResource: "comments", ofType: "plist") {
                _ = NSMutableDictionary(contentsOfFile: bundlePath)
                do {
                    try fileManager.copyItem(atPath: bundlePath, toPath: commentsFile!)
                } catch {
                    print("copy failure.")
                }
            } else {
                print("file myData.plist not found.")
            }
        } else {
            print("file myData.plist already exits at path.")
        }

        session = Session()
        History.seenTimes = NSMutableDictionary.init(contentsOfFile: seenFile!)!
        History.commentCounts = NSMutableDictionary.init(contentsOfFile: commentsFile!)!

        UIApplication.shared.statusBarStyle = .lightContent
        SettingValues.initialize()
        FontGenerator.initialize()
        AccountController.initialize()
        PostFilter.initialize()
        Drafts.initialize()
        Subscriptions.sync(name: AccountController.currentName, completion: nil)
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
                (granted, error) in
                if ((error) != nil) {
                    print(error!.localizedDescription)
                }
            }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
                (granted, error) in
                if ((error) != nil) {
                    print(error!.localizedDescription)
                }
            }
            UIApplication.shared.registerForRemoteNotifications()
        } else {
            // Fallback on earlier versions
        }
        if !UserDefaults.standard.bool(forKey: "sc" + name) {
            syncColors(subredditController: nil)
        }

        ColorUtil.doInit()

        let textAttributes = [NSForegroundColorAttributeName: UIColor.white]
        UINavigationBar.appearance().titleTextAttributes = textAttributes
        doBios()

        SDWebImageManager.shared().imageCache.maxCacheAge = 1209600 //2 weeks
        SDWebImageManager.shared().imageCache.maxCacheSize = 250 * 1024 * 1024

        UIApplication.shared.applicationIconBadgeNumber = 0

        return true
    }
    
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print("Recived: \(userInfo)")

    }

    var statusBar = UIView()
    

    func doBios() {
        if (SettingValues.biometrics && BioMetricAuthenticator.canAuthenticate()) {
            BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                self.window?.isHidden = false
            }, failure: { [weak self] (error) in

                // do nothing on canceled
                if error == .canceledByUser || error == .canceledBySystem {
                    exit(0)
                }

                BioMetricAuthenticator.authenticateWithPasscode(reason: "Enter your password", cancelTitle: "Exit", success: {
                    self?.window?.isHidden = false
                }, failure: { [weak self] (error) in
                    exit(0)
                })
            })
        }
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        getData(completionHandler);
    }

    func getData(_ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        

        if let session = session {
            do {
                let request = try session.getMessageRequest(.unread)
                let fetcher = BackgroundFetch(current: session,
                        request: request,
                        taskHandler: { (response, dataURL, error) -> Void in
                            if let response = response, let dataURL = dataURL {
                                if response.statusCode == HttpStatus.ok.rawValue {
                                    do {
                                        let data = try Data(contentsOf: dataURL)
                                        
                                        let result = messagesInResult(from: data, response: response)
                                        switch result {
                                        case .success(let listing):
                                            var new : [Message] = []
                                            var children = listing.children
                                            children.reverse()
                                            for m in children.flatMap({$0}){
                                                let message = (m as! Message)
                                                if(Double(message.createdUtc) > (UserDefaults.standard.object(forKey: "lastMessageUpdate") == nil ? NSDate().timeIntervalSince1970 : UserDefaults.standard.double(forKey: "lastMessageUpdate"))){
                                                    new.append(message)
                                                    self.postLocalNotification(message.body, message.author, message.id)
                                                }
                                            }
                                            
                                            UserDefaults.standard.set(NSDate().timeIntervalSince1970, forKey: "lastMessageUpdate")
                                            UserDefaults.standard.synchronize()

                                            DispatchQueue.main.async {
                                                UIApplication.shared.applicationIconBadgeNumber = new.count
                                                completionHandler(.newData)
                                            }
                                            return
                                        case .failure(let error):
                                            print(error)
                                            completionHandler(.failed)
                                        }
                                    } catch {

                                    }
                                } else {
                                    completionHandler(.failed)
                                }
                            } else {
                                completionHandler(.failed)
                            }
                        })
                self.fetcher = fetcher
                fetcher.resume()
            } catch {
                print(error.localizedDescription)
                completionHandler(.failed)
            }
        } else {
            completionHandler(.failed)
        }
    }

    func postLocalNotification(_ message: String, _ author: String = "",  _ id: String = "") {
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()

            let content = UNMutableNotificationContent()
            content.categoryIdentifier = "SlideMail"
            if(author.isEmpty()){
                content.title = "New messages!"
            } else {
                content.title = "New message from \(author)"
            }
            content.body = message
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2,
                    repeats: false)
            let identifier = "SlideNewMessage" + id
            let request = UNNotificationRequest(identifier: identifier,
                    content: content, trigger: trigger)
            center.add(request, withCompletionHandler: { (error) in
                if error != nil {
                    print(error!.localizedDescription)
                    // Something went wrong
                }
            })
        } else {
            // Fallback on earlier versions
        }
    }


    func syncColors(subredditController: MainViewController?) {
        let defaults = UserDefaults.standard
        var toReturn: [String] = []
        defaults.set(true, forKey: "sc" + name)
        defaults.synchronize()
        do {
            if (!AccountController.isLoggedIn) {
                try session?.getSubreddit(.default, paginator: paginator, completion: { (result) -> Void in
                    switch result {
                    case .failure:
                        print(result.error!)
                    case .success(let listing):
                        self.subreddits += listing.children.flatMap({ $0 as? Subreddit })
                        self.paginator = listing.paginator
                        for sub in self.subreddits {
                            toReturn.append(sub.displayName)
                            if (!sub.keyColor.isEmpty) {
                                let color = (UIColor.init(hexString: sub.keyColor))
                                if (defaults.object(forKey: "color" + sub.displayName) == nil) {
                                    defaults.setColor(color: color, forKey: "color+" + sub.displayName)
                                }
                            }
                        }

                    }
                    if (subredditController != nil) {
                        DispatchQueue.main.async(execute: { () -> Void in
                            subredditController?.complete(subs: toReturn)
                        })
                    }
                })

            } else {
                Subscriptions.getSubscriptionsFully(session: session!, completion: { (subs, multis) in
                    for sub in subs {
                        toReturn.append(sub.displayName)
                        if (!sub.keyColor.isEmpty) {
                            let color = (UIColor.init(hexString: sub.keyColor))
                            if (defaults.object(forKey: "color" + sub.displayName) == nil) {
                                defaults.setColor(color: color, forKey: "color+" + sub.displayName)
                            }
                        }
                    }
                    for m in multis {
                        toReturn.append("/m/" + m.displayName)
                        if (!m.keyColor.isEmpty) {

                            let color = (UIColor.init(hexString: m.keyColor))
                            if (defaults.object(forKey: "color" + m.displayName) == nil) {
                                defaults.setColor(color: color, forKey: "color+" + m.displayName)
                            }
                        }
                    }


                    toReturn = toReturn.sorted {
                        $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
                    }
                    toReturn.insert("all", at: 0)
                    toReturn.insert("frontpage", at: 0)
                    if (subredditController != nil) {
                        DispatchQueue.main.async(execute: { () -> Void in
                            subredditController?.complete(subs: toReturn)
                        })
                    }

                })
            }
        } catch {
            print(error)
            if (subredditController != nil) {
                DispatchQueue.main.async(execute: { () -> Void in
                    subredditController?.complete(subs: toReturn)
                })
            }
        }

    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
        print("Returning \(url.absoluteString)")
        var parameters: [String: String] = url.getKeyVals()!

        if let code = parameters["code"], let state = parameters["state"] {
            print(state)
            if code.characters.count > 0 {
                print(code)
            }
        }

        return OAuth2Authorizer.sharedInstance.receiveRedirect(url, completion: { (result) -> Void in
            print(result)
            switch result {

            case .failure(let error):
                print(error)
            case .success(let token):
                DispatchQueue.main.async(execute: { () -> Void in
                    do {
                        try OAuth2TokenRepository.save(token: token, of: token.name)
                        self.login?.setToken(token: token)
                        NotificationCenter.default.post(name: OAuth2TokenRepositoryDidSaveTokenName, object: nil, userInfo: nil)
                    } catch {
                        NotificationCenter.default.post(name: OAuth2TokenRepositoryDidFailToSaveTokenName, object: nil, userInfo: nil)
                        print(error)
                    }
                })
            }
        })
    }

    func killAndReturn() {
        if let rootViewController = UIApplication.topViewController() {
            var navigationArray = rootViewController.viewControllers
            navigationArray.removeAll()
            rootViewController.viewControllers = navigationArray
            rootViewController.pushViewController(MainViewController(coder: NSCoder.init())!, animated: false)
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        if (SettingValues.biometrics) {
            self.window?.isHidden = true
        }
        totalBackground = false
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        totalBackground = true
        History.seenTimes.write(toFile: seenFile!, atomically: true)
        History.commentCounts.write(toFile: commentsFile!, atomically: true)
        application.setMinimumBackgroundFetchInterval(900)

        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        doBios()
        self.refreshSession()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        if (!totalBackground) {
            self.window?.isHidden = false
        }
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        History.seenTimes.write(toFile: seenFile!, atomically: true)
        History.commentCounts.write(toFile: commentsFile!, atomically: true)
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


    func refreshSession() {
        // refresh current session token
        do {
            try self.session?.refreshToken({ (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let token):
                    DispatchQueue.main.async(execute: { () -> Void in
                        print(token)
                        NotificationCenter.default.post(name: OAuth2TokenRepositoryDidSaveTokenName, object: nil, userInfo: nil)
                    })
                }
            })
        } catch {
            print(error)
        }
    }

    func reloadSession() {
        // reddit username is save NSUserDefaults using "currentName" key.
        // create an authenticated or anonymous session object
        if let currentName = UserDefaults.standard.object(forKey: "name") as? String {
            do {
                let token = try OAuth2TokenRepository.token(of: currentName)
                self.session = Session(token: token)
                self.refreshSession()
            } catch {
                print(error)
            }
        } else {
            self.session = Session()
        }

        NotificationCenter.default.post(name: OAuth2TokenRepositoryDidSaveTokenName, object: nil, userInfo: nil)
    }

}

extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UINavigationController? {
        if let nav = base as? UINavigationController {
            return nav
        }
        if let tab = base as? UITabBarController {
            let moreNavigationController = tab.moreNavigationController
            return moreNavigationController
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base?.navigationController
    }
}

extension URL {
    func getKeyVals() -> Dictionary<String, String>? {
        var results = [String: String]()
        let keyValues = self.query?.components(separatedBy: "&")
        if (keyValues?.count)! > 0 {
            for pair in keyValues! {
                let kv = pair.components(separatedBy: "=")
                if kv.count > 1 {
                    results.updateValue(kv[1], forKey: kv[0])
                }
            }

        }
        return results
    }
}


