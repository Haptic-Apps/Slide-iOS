//
//  AppDelegate.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/22/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import Anchorage
import AVKit
import BiometricAuthentication
import CloudKit
import DTCoreText
import RealmSwift
import reddift
import SDWebImage
import UIKit
import UserNotifications
import WatchConnectivity
#if !os(iOS)
import WatchKit
#endif

/// Posted when the OAuth2TokenRepository object succeed in saving a token successfully into Keychain.
public let OAuth2TokenRepositoryDidSaveTokenName = Notification.Name(rawValue: "OAuth2TokenRepositoryDidSaveToken")

/// Posted when the OAuth2TokenRepository object failed to save a token successfully into Keychain.
public let OAuth2TokenRepositoryDidFailToSaveTokenName = Notification.Name(rawValue: "OAuth2TokenRepositoryDidFailToSaveToken")

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let name = "reddittoken"
    var session: Session?
    var fetcher: BackgroundFetch?
    var subreddits: [Subreddit] = []
    var paginator = Paginator()
    var login: MainViewController?
    var seenFile: String?
    var commentsFile: String?
    var readLaterFile: String?
    var collectionsFile: String?
    var totalBackground = true
    var isPro = false
    
    var orientationLock = UIInterfaceOrientationMask.allButUpsideDown

    let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
        if oldSchemaVersion < 13 {
            /*
             - Property 'RComment.gilded' has been changed from 'int' to 'bool'.
             - Property 'RComment.gold' has been added.
             - Property 'RComment.silver' has been added.
             - Property 'RComment.platinum' has been added.
             - Property 'RSubmission.gilded' has been changed from 'int' to 'bool'.
             - Property 'RSubmission.gold' has been added.
             - Property 'RSubmission.silver' has been added.
             */
            migration.enumerateObjects(ofType: RSubmission.className()) { (old, new) in
                // Change gilded from Int to Bool
                guard let gildedCount = old?["gilded"] as? Int else {
                    fatalError("Old gilded value should Int, but is not.")
                }
                new?["gilded"] = gildedCount > 0

                // Set new properties
                new?["gold"] = gildedCount
                new?["silver"] = 0
                new?["platinum"] = 0
                new?["oc"] = false
            }
            migration.enumerateObjects(ofType: RComment.className(), { (old, new) in
                // Change gilded from Int to Bool
                guard let gildedCount = old?["gilded"] as? Int else {
                    fatalError("Old gilded value should Int, but is not.")
                }
                new?["gilded"] = gildedCount > 0

                // Set new properties
                new?["gold"] = gildedCount
                new?["silver"] = 0
                new?["platinum"] = 0

            })
        }
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }

    struct AppUtility {
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.orientationLock = orientation
            }
        }

        static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation: UIInterfaceOrientation) {
            self.lockOrientation(orientation)
            UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        }
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        if let url = notification.userInfo?["permalink"] as? String {
            VCPresenter.openRedditLink(url, window?.rootViewController as? UINavigationController, window?.rootViewController)
        } else {
            VCPresenter.showVC(viewController: InboxViewController(), popupIfPossible: false, parentNavigationController: window?.rootViewController as? UINavigationController, parentViewController: window?.rootViewController)
        }
    }
    
    static var removeDict = NSMutableDictionary()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //let settings = UIUserNotificationSettings(types: UIUserNotificationType.alert, categories: nil)
        //UIApplication.shared.registerUserNotificationSettings(settings)

        UIPanGestureRecognizer.swizzle()
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentDirectory = paths[0] as! String
        seenFile = documentDirectory.appending("/seen.plist")
        commentsFile = documentDirectory.appending("/comments.plist")
        readLaterFile = documentDirectory.appending("/readlater.plist")
        collectionsFile = documentDirectory.appending("/collections.plist")

        let config = Realm.Configuration(
                schemaVersion: 22,
                migrationBlock: migrationBlock,
                deleteRealmIfMigrationNeeded: true)

        Realm.Configuration.defaultConfiguration = config
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: seenFile!) {
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

        if !fileManager.fileExists(atPath: readLaterFile!) {
            if let bundlePath = Bundle.main.path(forResource: "readlater", ofType: "plist") {
                _ = NSMutableDictionary(contentsOfFile: bundlePath)
                do {
                    try fileManager.copyItem(atPath: bundlePath, toPath: readLaterFile!)
                } catch {
                    print("copy failure.")
                }
            } else {
                print("file myData.plist not found.")
            }
        } else {
            print("file myData.plist already exits at path.")
        }

        if !fileManager.fileExists(atPath: collectionsFile!) {
            if let bundlePath = Bundle.main.path(forResource: "collections", ofType: "plist") {
                _ = NSMutableDictionary(contentsOfFile: bundlePath)
                do {
                    try fileManager.copyItem(atPath: bundlePath, toPath: collectionsFile!)
                } catch {
                    print("copy failure.")
                }
            } else {
                print("file myData.plist not found.")
            }
        } else {
            print("file myData.plist already exits at path.")
        }

        if !fileManager.fileExists(atPath: commentsFile!) {
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
        ReadLater.readLaterIDs = NSMutableDictionary.init(contentsOfFile: readLaterFile!)!
        Collections.collectionIDs = NSMutableDictionary.init(contentsOfFile: collectionsFile!)!

        fetchFromiCloud("readlater", dictionaryToAppend: ReadLater.readLaterIDs)
        fetchFromiCloud("collections", dictionaryToAppend: Collections.collectionIDs) { () in
            let removeDict = NSMutableDictionary()
            self.fetchFromiCloud("removed", dictionaryToAppend: removeDict) { () in
                let removeKeys = removeDict.allKeys as! [String]
                for item in removeKeys {
                    Collections.collectionIDs.removeObject(forKey: item)
                    ReadLater.readLaterIDs.removeObject(forKey: item)
                }
            }
        }

        SettingValues.initialize()
        
        let dictionary = Bundle.main.infoDictionary!
        let build = dictionary["CFBundleVersion"] as! String
        
        let lastVersion = UserDefaults.standard.string(forKey: "LAST_BUILD") ?? ""
        let lastVersionInt = Int(lastVersion) ?? 0
        let currentVersionInt = Int(build) ?? 0
        
        if lastVersionInt < currentVersionInt {
            //Migration block for build 115
            if currentVersionInt == 115 {
                if UserDefaults.standard.string(forKey: "theme") == "custom" {
                    var colorString = "slide://colors"
                    colorString += ("#Theme Backup v3.5").addPercentEncoding
                    let foregroundColor = UserDefaults.standard.colorForKey(key: "customForeground") ?? UIColor.white
                    let backgroundColor = UserDefaults.standard.colorForKey(key: "customBackground") ?? UIColor(hexString: "#e5e5e5")
                    let fontColor = UserDefaults.standard.colorForKey(key: "customFont") ?? UIColor(hexString: "#000000").withAlphaComponent(0.87)
                    let navIconColor = UserDefaults.standard.colorForKey(key: "customNavicon") ?? UIColor(hexString: "#000000").withAlphaComponent(0.87)
                    let statusbarEnabled = UserDefaults.standard.bool(forKey: "customStatus")

                    colorString += (foregroundColor.toHexString() + backgroundColor.toHexString() + fontColor.toHexString() + navIconColor.toHexString() + "#ffffff" + "#ffffff" + "#" + String(statusbarEnabled)).addPercentEncoding
                    
                    UserDefaults.standard.set(colorString, forKey: "Theme+" + ("Theme Backup v3.5").addPercentEncoding)
                    UserDefaults.standard.set("Theme Backup v3.5", forKey: "theme")
                    UserDefaults.standard.synchronize()
                }
            }
            
            UserDefaults.standard.set(build, forKey: "LAST_BUILD")
        }

        DTCoreTextFontDescriptor.asyncPreloadFontLookupTable()
        FontGenerator.initialize()
        AccountController.initialize()
        PostFilter.initialize()
        Drafts.initialize()
        RemovalReasons.initialize()
        Subscriptions.sync(name: AccountController.currentName, completion: nil)

        if !UserDefaults.standard.bool(forKey: "sc" + name) {
            syncColors(subredditController: nil)
        }

        _ = ColorUtil.doInit()

        SDImageCache.shared.config.maxDiskAge = 1209600 //2 weeks
        SDImageCache.shared.config.maxDiskSize = 250 * 1024 * 1024

        UIApplication.shared.applicationIconBadgeNumber = 0

        self.window = UIWindow(frame: UIScreen.main.bounds)
        resetStack()
        window?.makeKeyAndVisible()
        
        let remoteNotif = launchOptions?[UIApplication.LaunchOptionsKey.localNotification] as? UILocalNotification
        
        if remoteNotif != nil {
            if let url = remoteNotif!.userInfo?["permalink"] as? String {
                VCPresenter.openRedditLink(url, window?.rootViewController as? UINavigationController, window?.rootViewController)
            } else {
                VCPresenter.showVC(viewController: InboxViewController(), popupIfPossible: false, parentNavigationController: window?.rootViewController as? UINavigationController, parentViewController: window?.rootViewController)
            }
        }

        WatchSessionManager.sharedManager.doInit()

        if SettingValues.notifications {
            UIApplication.shared.setMinimumBackgroundFetchInterval(60 * 10) // 10 minute interval
            print("Application background refresh minimum interval: \(60 * 10) seconds")
            print("Application background refresh status: \(UIApplication.shared.backgroundRefreshStatus.rawValue)")
        } else {
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
            print("Application background refresh minimum set to never")
        }

        #if DEBUG
        SettingValues.isPro = true
        UserDefaults.standard.set(true, forKey: SettingValues.pref_pro)
        UserDefaults.standard.synchronize()
        UIApplication.shared.isIdleTimerDisabled = true
        #endif
        
        //Stop first video from muting audio
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient, options: [])
        } catch {
            
        }
        
        return true
    }
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print("Received: \(userInfo)")
    }

    var statusBar = UIView()
    var splitVC = CustomSplitController()

    /**
     Rebuilds the nav stack for the currently selected App Mode (split, multi column, etc.)
     */
    func resetStack() {
        guard let window = self.window else {
            fatalError("Window must exist when resetting the stack!")
        }
        let rootController: UIViewController!
        if UIDevice.current.userInterfaceIdiom == .pad && SettingValues.appMode == .SPLIT {
            rootController = splitVC
            splitVC.preferredDisplayMode = .allVisible
            (rootController as! UISplitViewController).viewControllers = [UINavigationController(rootViewController: MainViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil))]
        } else {
            rootController = UINavigationController(rootViewController: MainViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil))
        }

        window.setRootViewController(rootController, animated: false)
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if let url = shortcutItem.userInfo?["sub"] {
            VCPresenter.openRedditLink("/r/\(url)", window?.rootViewController as? UINavigationController, window?.rootViewController)
        } else if shortcutItem.userInfo?["clipboard"] != nil {
            var clipUrl: URL?
            if let url = UIPasteboard.general.url {
                if ContentType.getContentType(baseUrl: url) == .REDDIT {
                    clipUrl = url
                }
            }
            if clipUrl == nil {
                if let urlS = UIPasteboard.general.string {
                    if let url = URL.init(string: urlS) {
                        if ContentType.getContentType(baseUrl: url) == .REDDIT {
                            clipUrl = url
                        }
                    }
                }
            }
            
            if clipUrl != nil {
                VCPresenter.openRedditLink(clipUrl!.absoluteString, window?.rootViewController as? UINavigationController, window?.rootViewController)
            }

        }
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        getData(completionHandler)
    }

    var backgroundTaskId: UIBackgroundTaskIdentifier?

    func getData(_ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        self.backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "Download New Messages") {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskId!)
            self.backgroundTaskId = UIBackgroundTaskIdentifier(rawValue: convertFromUIBackgroundTaskIdentifier(UIBackgroundTaskIdentifier.invalid))
        }

        func cleanup() {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskId!)
            self.backgroundTaskId = UIBackgroundTaskIdentifier(rawValue: convertFromUIBackgroundTaskIdentifier(UIBackgroundTaskIdentifier.invalid))
        }

        print("getData running...")
        guard let session = session,
            let request = try? session.getMessageRequest(.unread) else {
            completionHandler(.failed)
            cleanup()
            return
        }

        func handler (_ response: HTTPURLResponse?, _ dataURL: URL?, _ error: NSError?) {
            guard error == nil else {
                print(String(describing: error?.localizedDescription))
                completionHandler(.failed)
                cleanup()
                return
            }

            guard let response = response,
                let dataURL = dataURL,
                response.statusCode == HttpStatus.ok.rawValue else {
                    completionHandler(.failed)
                    cleanup()
                    return
            }

            let data: Data
            do {
                data = try Data(contentsOf: dataURL)
            } catch {
                print(error.localizedDescription)
                completionHandler(.failed)
                cleanup()
                return
            }

            switch messagesInResult(from: data, response: response) {

            case .success(let listing):
                var newCount: Int = 0
                let lastMessageUpdateTime = UserDefaults.standard.object(forKey: "lastMessageUpdate") as? TimeInterval ?? Date().timeIntervalSince1970

                for case let message as Message in listing.children.reversed() {
                    if Double(message.createdUtc) > lastMessageUpdateTime {
                        newCount += 1
                        // TODO: - If there's more than one new notification, maybe just post
                        // a message saying "You have new unread messages."
                        postLocalNotification(message.body, message.author, message.wasComment ? message.context : nil, message.id)
                    }
                }

                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastMessageUpdate")

                print("Unread count: \(newCount)")

                DispatchQueue.main.sync {
                    UIApplication.shared.applicationIconBadgeNumber = newCount
                }

                if newCount > 0 {
                    print("getData completed with new data.")
                    completionHandler(.newData)
                } else {
                    print("getData completed with no new data.")
                    completionHandler(.noData)
                }
                cleanup()
                return

            case .failure(let error):
                print(error.localizedDescription)
                completionHandler(.failed)
                cleanup()
                return
            }

        }

        if self.fetcher == nil {
            self.fetcher = BackgroundFetch(current: session,
                                           request: request,
                                           taskHandler: handler)
        }
        self.fetcher?.resume()

    }
    
    func postLocalNotification(_ message: String, _ author: String = "", _ permalink: String? = nil, _ id: String) {
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()

            let content = UNMutableNotificationContent()
            content.categoryIdentifier = "SlideMail"
            if author.isEmpty() {
                content.title = "New message!"
            } else {
                content.title = "New message from \(author)"
            }
            content.body = message
            if permalink != nil {
                content.userInfo = ["permalink": "https://www.reddit.com" + permalink!]
            }
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
            if !AccountController.isLoggedIn {
                try session?.getSubreddit(.default, paginator: paginator, completion: { (result) -> Void in
                    switch result {
                    case .failure:
                        print(result.error!)
                    case .success(let listing):
                        self.subreddits += listing.children.compactMap({ $0 as? Subreddit })
                        self.paginator = listing.paginator
                        for sub in self.subreddits {
                            toReturn.append(sub.displayName)
                            if sub.keyColor.hexString() != "#FFFFFF" {
                                let color = ColorUtil.getClosestColor(hex: sub.keyColor.hexString())
                                if defaults.object(forKey: "color" + sub.displayName) == nil {
                                    defaults.setColor(color: color, forKey: "color+" + sub.displayName)
                                }
                            }
                        }

                    }
                    if subredditController != nil {
                        DispatchQueue.main.async(execute: { () -> Void in
                            subredditController?.complete(subs: toReturn)
                        })
                    }
                })

            } else {
                if UserDefaults.standard.array(forKey: "subs" + (subredditController?.tempToken?.name ?? "")) != nil {
                    Subscriptions.sync(name: (subredditController?.tempToken?.name ?? ""), completion: nil)
                    if subredditController != nil {
                        DispatchQueue.main.async(execute: { () -> Void in
                            subredditController?.complete(subs: Subscriptions.subreddits)
                        })
                    }
                } else {
                    Subscriptions.getSubscriptionsFully(session: session!, completion: { (subs, multis) in
                        for sub in subs {
                            toReturn.append(sub.displayName)
                            if sub.keyColor.hexString() != "#FFFFFF" {
                                let color = ColorUtil.getClosestColor(hex: sub.keyColor.hexString())
                                if defaults.object(forKey: "color" + sub.displayName) == nil {
                                    defaults.setColor(color: color, forKey: "color+" + sub.displayName)
                                }
                            }
                        }
                        for m in multis {
                            toReturn.append("/m/" + m.displayName)
                            if !m.keyColor.isEmpty {
                                
                                let color = (UIColor.init(hexString: m.keyColor))
                                if defaults.object(forKey: "color" + m.displayName) == nil {
                                    defaults.setColor(color: color, forKey: "color+" + m.displayName)
                                }
                            }
                        }
                        
                        toReturn = toReturn.sorted {
                            $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
                        }
                        toReturn.insert("all", at: 0)
                        toReturn.insert("frontpage", at: 0)
                        if subredditController != nil {
                            DispatchQueue.main.async(execute: { () -> Void in
                                subredditController?.complete(subs: toReturn)
                            })
                        }
                    })
                }
            }
        } catch {
            print(error)
            if subredditController != nil {
                DispatchQueue.main.async(execute: { () -> Void in
                    subredditController?.complete(subs: toReturn)
                })
            }
        }

    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        
        let bUrl = url.absoluteString
        if bUrl.startsWith("googlechrome://") || bUrl.startsWith("firefox://") || bUrl.startsWith("opera-http://") {
            return false
        }
        
        if url.absoluteString.contains("/r/") {
            VCPresenter.openRedditLink(url.absoluteString.replacingOccurrences(of: "slide://", with: ""), window?.rootViewController as? UINavigationController, window?.rootViewController)
            return true
        } else if url.absoluteString.contains("colors") {
            let themeName = url.absoluteString.removingPercentEncoding!.split("#")[1]
            let alert = UIAlertController(title: "Save \"\(themeName.replacingOccurrences(of: "<H>", with: "#"))\"", message: "You can set it as your theme in Settings > Theme\n\n\n\n\n", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (_) in
                let colorString = url.absoluteString.removingPercentEncoding!
                
                let title = colorString.split("#")[1]
                UserDefaults.standard.set(colorString, forKey: "Theme+" + title)
            }))
            alert.addCancelButton()
            let themeView = ThemeCellView().then {
                $0.setTheme(colors: url.absoluteString.removingPercentEncoding!)
            }
            let cv = themeView.contentView
            alert.view.addSubview(cv)
            cv.leftAnchor == alert.view.leftAnchor + 8
            cv.rightAnchor == alert.view.rightAnchor - 8
            cv.topAnchor == alert.view.topAnchor + 90
            cv.heightAnchor == 60
        
            alert.showWindowless()
            return true
        } else if url.absoluteString.contains("reddit.com") || url.absoluteString.contains("google.com/amp") || url.absoluteString.contains("redd.it") {
                VCPresenter.openRedditLink(url.absoluteString.replacingOccurrences(of: "slide://", with: ""), window?.rootViewController as? UINavigationController, window?.rootViewController)
                return true
        } else if url.query?.components(separatedBy: "&").count ?? 0 < 0 {
            print("Returning \(url.absoluteString)")
            let parameters: [String: String] = url.getKeyVals()!
            
            if let code = parameters["code"], let state = parameters["state"] {
                print(state)
                if code.length > 0 {
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
                            try LocalKeystore.save(token: token, of: token.name)
                            self.login?.setToken(token: token)
                            NotificationCenter.default.post(name: OAuth2TokenRepositoryDidSaveTokenName, object: nil, userInfo: nil)
                        } catch {
                            NotificationCenter.default.post(name: OAuth2TokenRepositoryDidFailToSaveTokenName, object: nil, userInfo: nil)
                            print(error)
                        }
                    })
                }
            })
        } else {
            return true
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        if AccountController.current == nil && UserDefaults.standard.string(forKey: "name") != "GUEST" {
            AccountController.initialize()
        }
        UIView.animate(withDuration: 0.25, animations: {
            self.backView?.alpha = 0
        }, completion: { (_) in
            self.backView?.alpha = 1
            self.backView?.isHidden = true
        })
        if totalBackground && SettingValues.biometrics && !TopLockViewController.presented {
            let topLock = TopLockViewController()
            topLock.modalPresentationStyle = .overFullScreen
            UIApplication.shared.keyWindow?.topViewController()?.present(topLock, animated: false, completion: nil)
        }
    }

    var backView: UIView?
    func applicationWillResignActive(_ application: UIApplication) {
        if SettingValues.biometrics {
            if backView == nil {
                backView = UIView.init(frame: self.window!.frame)
                backView?.backgroundColor = ColorUtil.theme.backgroundColor
                if let window = self.window {
                    window.addSubview(backView!)
                    backView!.edgeAnchors == window.edgeAnchors
                }
            }
                self.backView?.isHidden = false
        }
        totalBackground = false
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func saveToiCloud(_ dictionary: NSDictionary, _ key: String) {
        let collectionsRecord = CKRecord(recordType: key)
        do {
            if let data: NSData = try PropertyListSerialization.data(fromPropertyList: dictionary, format: PropertyListSerialization.PropertyListFormat.xml, options: 0) as NSData {
                if let datastring = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) {
                   collectionsRecord.setValue(datastring, forKey: "data_xml")
               } else {
                   print("Could not turn nsdata to string")
               }
            }
            
            print("Saving to iCloud \(key)")
            CKContainer(identifier: "iCloud.ccrama.me.redditslide").privateCloudDatabase.save(collectionsRecord) { (_, error) in
                if error != nil {
                    print("iCloud error")
                    print(error.debugDescription)
                }
            }
        } catch {
            print("Error serializing dictionary")
        }
    }
    
    func fetchFromiCloud(_ key: String, dictionaryToAppend: NSMutableDictionary, completion: (() -> Void)? = nil) {
        let privateDatabase = CKContainer(identifier: "iCloud.ccrama.me.redditslide").privateCloudDatabase
        
        let query = CKQuery(recordType: CKRecord.RecordType(stringLiteral: key), predicate: NSPredicate(value: true))
        print("Reading from iCloud")
        privateDatabase.perform(query, inZoneWith: nil) { (records, error) in
            if error != nil {
                print("Error fetching records...")
                print(error?.localizedDescription)
            } else {
                if let unwrappedRecord = records?[0] {
                    if let object = unwrappedRecord.object(forKey: "data_xml") as? String {
                        if let data = object.data(using: String.Encoding.utf8) {
                            do {
                                let dict = try PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.ReadOptions.mutableContainersAndLeaves, format: nil) as? NSMutableDictionary
                                for item in dict ?? [:] {
                                    dictionaryToAppend[item.key] = item.value
                                }
                                completion?()
                            } catch {
                                print("Could not de-serialize list")
                            }
                        }
                    }
                } else {
                    print("No record found!")
                }
            }
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        totalBackground = true
        History.seenTimes.write(toFile: seenFile!, atomically: true)
        History.commentCounts.write(toFile: commentsFile!, atomically: true)
        ReadLater.readLaterIDs.write(toFile: readLaterFile!, atomically: true)
        Collections.collectionIDs.write(toFile: collectionsFile!, atomically: true)
        
        saveToiCloud(Collections.collectionIDs, "collections")
        saveToiCloud(ReadLater.readLaterIDs, "readlater")
        saveToiCloud(AppDelegate.removeDict, "removed")
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        self.refreshSession()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        History.seenTimes.write(toFile: seenFile!, atomically: true)
        History.commentCounts.write(toFile: commentsFile!, atomically: true)
        ReadLater.readLaterIDs.write(toFile: readLaterFile!, atomically: true)
        Collections.collectionIDs.write(toFile: collectionsFile!, atomically: true)
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func refreshSession() {
        // refresh current session token
        do {
            try self.session?.refreshTokenLocal({ (result) -> Void in
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
                let token: OAuth2Token
                if AccountController.isMigrated(currentName) {
                    token = try LocalKeystore.token(of: currentName)
                } else {
                    token = try OAuth2TokenRepository.token(of: currentName)
                }
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

extension URL {
    func getKeyVals() -> [String: String]? {
        var results = [String: String]()
        let keyValues = self.query?.components(separatedBy: "&")
        if (keyValues?.count) ?? 0 > 0 {
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
extension Session {
    /**
     Refresh own token.
     
     - parameter completion: The completion handler to call when the load request is complete.
     */
    public func refreshTokenLocal(_ completion: @escaping (Result<Token>) -> Void) throws {
        guard let currentToken = token as? OAuth2Token
            else { throw ReddiftError.tokenIsNotAvailable as NSError }
        do {
            try currentToken.refresh({ (result) -> Void in
                switch result {
                case .failure(let error):
                    completion(Result(error: error as NSError))
                case .success(let newToken):
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.token = newToken
                        do {
                            try LocalKeystore.save(token: newToken)
                            completion(Result(value: newToken))
                        } catch { completion(Result(error: error as NSError)) }
                    })
                }
            })
        } catch { throw error }
    }
    
    /**
     Revoke own token. After calling this function, this object must be released becuase it has lost any conection.
     
     - parameter completion: The completion handler to call when the load request is complete.
     */
    public func revokeTokenLocal(_ completion: @escaping (Result<Token>) -> Void) throws {
        guard let currentToken = token as? OAuth2Token
            else { throw ReddiftError.tokenIsNotAvailable as NSError }
        do {
            try currentToken.revoke({ (result) -> Void in
                switch result {
                case .failure(let error):
                    completion(Result(error: error as NSError))
                case .success:
                    DispatchQueue.main.async(execute: { () -> Void in
                        do {
                            try LocalKeystore.removeToken(of: currentToken.name)
                            completion(Result(value: currentToken))
                        } catch { completion(Result(error: error as NSError)) }
                    })
                }
            })
        } catch { throw error }
    }
    
    /**
     Set an expired token to self.
     This method is implemented in order to test codes to automatiaclly refresh an expired token.
     */
    public func setDummyExpiredToken() {
        if let path = Bundle.main.path(forResource: "expired_token.json", ofType: nil), let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] {
                    let token = OAuth2Token(json)
                    self.token = token
                }
            } catch { print(error) }
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromUIBackgroundTaskIdentifier(_ input: UIBackgroundTaskIdentifier) -> Int {
	return input.rawValue
}

class CustomSplitController: UISplitViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight && SettingValues.reduceColor {
                        if #available(iOS 13, *) {
                return .darkContent
            } else {
                return .default
            }

        } else {
            return .lightContent
        }
    }
}
