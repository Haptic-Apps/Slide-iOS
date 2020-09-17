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
    var iconsFile: String?
    var colorsFile: String?
    var totalBackground = true
    var isPro = false
    var transitionDelegateModal: InsetTransitioningDelegate?
    var tempWindow: UIWindow?

    var orientationLock = UIInterfaceOrientationMask.allButUpsideDown

    /**
     Corresponds to USR_DOMAIN in info.plist, which derives its value
     from USR_DOMAIN in the pbxproj build settings. Default is `ccrama.me`.
     */
    lazy var USR_DOMAIN: String = {
        return Bundle.main.object(forInfoDictionaryKey: "USR_DOMAIN") as! String
    }()

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
        if oldSchemaVersion < 26 {
            migration.enumerateObjects(ofType: RSubmission.className()) { (old, new) in
                new?["subreddit_icon"] = ""
            }
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
    
    var launchedURL: URL?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if #available(iOS 13.0, *) { return true } else {
            let window = UIWindow(frame: UIScreen.main.bounds)
            self.window = window
            didFinishLaunching(window: window)
            launchedURL = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL
            let remoteNotif = launchOptions?[UIApplication.LaunchOptionsKey.localNotification] as? UILocalNotification
            
            if remoteNotif != nil {
                if let url = remoteNotif!.userInfo?["permalink"] as? String {
                    VCPresenter.openRedditLink(url, window.rootViewController as? UINavigationController, window.rootViewController)
                } else {
                    VCPresenter.showVC(viewController: InboxViewController(), popupIfPossible: false, parentNavigationController: window.rootViewController as? UINavigationController, parentViewController: window.rootViewController)
                }
            }
            return true
        }
    }
    
    func didFinishLaunching(window: UIWindow) {
        UIPanGestureRecognizer.swizzle()
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentDirectory = paths[0] as! String
        seenFile = documentDirectory.appending("/seen.plist")
        commentsFile = documentDirectory.appending("/comments.plist")
        readLaterFile = documentDirectory.appending("/readlater.plist")
        collectionsFile = documentDirectory.appending("/collections.plist")
        iconsFile = documentDirectory.appending("/icons.plist")
        colorsFile = documentDirectory.appending("/subcolors.plist")

        let config = Realm.Configuration(
                schemaVersion: 28,
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
        
        if !fileManager.fileExists(atPath: iconsFile!) {
            if let bundlePath = Bundle.main.path(forResource: "icons", ofType: "plist") {
                _ = NSMutableDictionary(contentsOfFile: bundlePath)
                do {
                    try fileManager.copyItem(atPath: bundlePath, toPath: iconsFile!)
                } catch {
                    print("copy failure.")
                }
            } else {
                print("file myData.plist not found.")
            }
        } else {
            print("file myData.plist already exits at path.")
        }

        if !fileManager.fileExists(atPath: colorsFile!) {
            if let bundlePath = Bundle.main.path(forResource: "subcolors", ofType: "plist") {
                _ = NSMutableDictionary(contentsOfFile: bundlePath)
                do {
                    try fileManager.copyItem(atPath: bundlePath, toPath: colorsFile!)
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
        Subscriptions.subIcons = NSMutableDictionary.init(contentsOfFile: iconsFile!)!
        Subscriptions.subColors = NSMutableDictionary.init(contentsOfFile: colorsFile!)!

        SettingValues.initialize()
        
        SDImageCache.shared.config.maxDiskAge = 1209600 //2 weeks
        SDImageCache.shared.config.maxDiskSize = 250 * 1024 * 1024
        SDImageCache.shared.config.diskCacheReadingOptions = .mappedIfSafe // Use mmap for disk cache query
       /* SDWebImageManager.shared.optionsProcessor = SDWebImageOptionsProcessor() { url, options, context in
            // Disable Force Decoding in global, may reduce the frame rate
            var mutableOptions = options
            mutableOptions.insert(.avoidDecodeImage)
            return SDWebImageOptionsResult(options: mutableOptions, context: context)
        }*/

        let dictionary = Bundle.main.infoDictionary!
        let build = dictionary["CFBundleVersion"] as! String
        
        let lastVersion = UserDefaults.standard.string(forKey: "LAST_BUILD") ?? ""
        let lastVersionInt: Int = Int(lastVersion) ?? 0
        let currentVersionInt: Int = Int(build) ?? 0
        
        if lastVersionInt < currentVersionInt {
            //Clean up broken videos
            do {
                var dirPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
                var directoryContents: NSArray = try FileManager.default.contentsOfDirectory(atPath: dirPath) as NSArray
                for path in directoryContents {
                    let fullPath = dirPath + "/" + (path as! String)
                    if fullPath.contains(".mp4") {
                        try FileManager.default.removeItem(atPath: fullPath)
                    }
                }
                dirPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0].substring(0, length: dirPath.length - 7)
                directoryContents = try FileManager.default.contentsOfDirectory(atPath: dirPath) as NSArray
                for path in directoryContents {
                    let fullPath = dirPath + "/" + (path as! String)
                    if fullPath.contains(".mp4") {
                        try FileManager.default.removeItem(atPath: fullPath)
                    }
                }
            } catch let e as NSError {
                print(e)
            }
            
            if currentVersionInt == 142 {
                SDImageCache.shared.clearMemory()
                SDImageCache.shared.clearDisk()
                
                do {
                    var cache_path = SDImageCache.shared.diskCachePath
                    cache_path += cache_path.endsWith("/") ? "" : "/"
                    let files = try FileManager.default.contentsOfDirectory(atPath: cache_path)
                    for file in files {
                        if file.endsWith(".mp4") {
                            try FileManager.default.removeItem(atPath: cache_path + file)
                        }
                    }
                } catch {
                    print(error)
                }
            }

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

        UIApplication.shared.applicationIconBadgeNumber = 0
           
        if #available(iOS 14, *) {
            _ = resetStackNew(window: window)
        } else {
            _ = resetStack(window: window)
        }
        
        window.makeKeyAndVisible()
        
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
    }
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print("Received: \(userInfo)")
    }

    var statusBar = UIView()
    var splitVC = CustomSplitController()
    
    func resetStack(_ soft: Bool = false, window: UIWindow?) -> MainViewController {
        guard let window = window else {
            fatalError("Window must exist when resetting the stack!")
        }
        
        if !soft {
            return doHard(window)
        } else if let splitViewController = window.rootViewController as? UISplitViewController {
            if UIDevice.current.userInterfaceIdiom == .pad {
                splitViewController.preferredDisplayMode = .automatic
                splitViewController.presentsWithGesture = true
                
                splitViewController.preferredPrimaryColumnWidthFraction = 0.4
                
                let main = SplitMainViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
                splitViewController.viewControllers = [SwipeForwardNavigationController(rootViewController: NavigationHomeViewController(controller: main)), SwipeForwardNavigationController(rootViewController: main)]

                window.rootViewController = splitViewController
                self.window = window
                window.makeKeyAndVisible()
                return main
            } else {
                splitViewController.preferredDisplayMode = .primaryOverlay
                splitViewController.presentsWithGesture = true
                
                let main = SplitMainViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
                splitViewController.viewControllers = [SwipeForwardNavigationController(rootViewController: NavigationHomeViewController(controller: main)), SwipeForwardNavigationController(rootViewController: main)]
                
                window.rootViewController = splitViewController
                self.window = window
                window.makeKeyAndVisible()
                return main
            }
        } else {
            return doHard(window)
        }
    }
    
    func doHard(_ window: UIWindow) -> MainViewController {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if SettingValues.appMode == .MULTI_COLUMN || SettingValues.appMode == .SINGLE {
                let splitViewController = UISplitViewController()
                splitViewController.preferredDisplayMode = .secondaryOnly
                splitViewController.presentsWithGesture = true
                
                splitViewController.preferredPrimaryColumnWidthFraction = 0.4
                
                let main = SplitMainViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
                splitViewController.viewControllers = [SwipeForwardNavigationController(rootViewController: NavigationHomeViewController(controller: main)), SwipeForwardNavigationController(rootViewController: main)]

                window.rootViewController = splitViewController
                self.window = window
                window.makeKeyAndVisible()
                return main
            } else {
                let splitViewController = UISplitViewController()
                splitViewController.preferredDisplayMode = .automatic
                splitViewController.presentsWithGesture = true
                
                splitViewController.preferredPrimaryColumnWidthFraction = 0.4
                splitViewController.maximumPrimaryColumnWidth = 0.4 * UIScreen.main.bounds.width

                let main = SplitMainViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
                let swipeNav = SwipeForwardNavigationController(rootViewController: NavigationHomeViewController(controller: main))
                swipeNav.pushViewController(main, animated: false)
                splitViewController.viewControllers = [swipeNav, PlaceholderViewController()]

                window.rootViewController = splitViewController
                self.window = window
                window.makeKeyAndVisible()
                return main
            }
        } else {
            let splitViewController = UISplitViewController()
            splitViewController.preferredDisplayMode = .oneOverSecondary
            splitViewController.presentsWithGesture = true

            let main = SplitMainViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
            let navHome = NavigationHomeViewController(controller: main)

            splitViewController.viewControllers = [SwipeForwardNavigationController(rootViewController: navHome), main]
            
            window.rootViewController = splitViewController
            self.window = window
            window.makeKeyAndVisible()
            return main
        }

    }

    @available(iOS 14.0, *)
    func resetStackNew(_ soft: Bool = false, window: UIWindow?) -> MainViewController {
        guard let window = window else {
            fatalError("Window must exist when resetting the stack!")
        }

        if !soft {
            return doHard14(window)
        } else if let oldSplit = window.rootViewController as? UISplitViewController {
            if UIDevice.current.userInterfaceIdiom == .pad {
                if SettingValues.appMode == .MULTI_COLUMN || SettingValues.appMode == .SINGLE {
                    let splitViewController = UISplitViewController(style: .doubleColumn)
                    splitViewController.preferredDisplayMode = .secondaryOnly
                    splitViewController.presentsWithGesture = true
                    splitViewController.preferredSplitBehavior = .overlay
                                 
                    let main = (oldSplit.viewController(for: .supplementary) as! SplitMainViewController)
                    let oldSidebar = (oldSplit.viewController(for: .primary) as! SwipeForwardNavigationController).viewControllers[0]

                    splitViewController.setViewController(SwipeForwardNavigationController(rootViewController: oldSidebar), for: .primary)

                    splitViewController.setViewController(main, for: .secondary)
                    
                    guard let snapshotImageView = window.snapshotView(afterScreenUpdates: true) else {
                        return main
                    }
                    window.addSubview(snapshotImageView)
                    window.rootViewController = splitViewController
                    window.bringSubviewToFront(snapshotImageView)

                    UIView.animate(withDuration: 0.4, animations: { () -> Void in
                        snapshotImageView.alpha = 0
                    }, completion: { (success) -> Void in
                        snapshotImageView.removeFromSuperview()
                    })

                    return main
                } else {
                    let splitViewController = UISplitViewController(style: .tripleColumn)
                    splitViewController.preferredDisplayMode = .automatic
                    splitViewController.presentsWithGesture = true
                    splitViewController.preferredSplitBehavior = .automatic
                    
                    splitViewController.preferredSupplementaryColumnWidthFraction = 0.4
                    splitViewController.maximumSupplementaryColumnWidth = UIScreen.main.bounds.width / 3
                    
                    let main = (oldSplit.viewController(for: .secondary) as! SplitMainViewController)
                    let oldSidebar = (oldSplit.viewController(for: .primary) as! SwipeForwardNavigationController).viewControllers[0]
                    
                    splitViewController.setViewController(SwipeForwardNavigationController(rootViewController: oldSidebar), for: .primary)

                    splitViewController.setViewController(main, for: .supplementary)
                    splitViewController.setViewController(PlaceholderViewController(), for: .secondary)

                    guard let snapshotImageView = window.snapshotView(afterScreenUpdates: true) else {
                        return main
                    }
                    window.addSubview(snapshotImageView)
                    window.rootViewController = splitViewController
                    window.bringSubviewToFront(snapshotImageView)
                    
                    UIView.animate(withDuration: 0.4, animations: { () -> Void in
                        snapshotImageView.alpha = 0
                    }, completion: { (success) -> Void in
                        snapshotImageView.removeFromSuperview()
                    })
                    return main
                }
            } else {
                return doHard14(window)
            }
        } else {
            return doHard14(window)
        }
    }
    
    @available(iOS 14.0, *)
    func doHard14(_ window: UIWindow) -> MainViewController {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if SettingValues.appMode == .MULTI_COLUMN || SettingValues.appMode == .SINGLE {
                let splitViewController = UISplitViewController(style: .doubleColumn)
                splitViewController.preferredDisplayMode = .secondaryOnly
                splitViewController.presentsWithGesture = true
                splitViewController.preferredSplitBehavior = .overlay
                                
                let main = SplitMainViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
                splitViewController.setViewController(SwipeForwardNavigationController(rootViewController: NavigationHomeViewController(controller: main)), for: .primary)

                splitViewController.setViewController(SwipeForwardNavigationController(rootViewController: main), for: .secondary)
                window.rootViewController = splitViewController
                self.window = window
                window.makeKeyAndVisible()
                return main
            } else {
                let splitViewController = UISplitViewController(style: .tripleColumn)
                splitViewController.preferredDisplayMode = .automatic
                splitViewController.presentsWithGesture = true
                splitViewController.preferredSplitBehavior = .automatic
                
                splitViewController.preferredSupplementaryColumnWidthFraction = 0.33
                splitViewController.minimumSupplementaryColumnWidth = UIScreen.main.bounds.width * 0.33
                
                splitViewController.preferredPrimaryColumnWidthFraction = 0.33
                splitViewController.minimumPrimaryColumnWidth = UIScreen.main.bounds.width * 0.33

                let main = SplitMainViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
                splitViewController.setViewController(SwipeForwardNavigationController(rootViewController: NavigationHomeViewController(controller: main)), for: .primary)

                splitViewController.setViewController(SwipeForwardNavigationController(rootViewController: main), for: .supplementary)
                splitViewController.setViewController(PlaceholderViewController(), for: .secondary)
                window.rootViewController = splitViewController
                self.window = window
                window.makeKeyAndVisible()
                return main
            }
        } else {
            let splitViewController = UISplitViewController()
            splitViewController.preferredDisplayMode = .oneOverSecondary
            splitViewController.presentsWithGesture = true
            
            let main = SplitMainViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
            let navHome = NavigationHomeViewController(controller: main)

            splitViewController.viewControllers = [SwipeForwardNavigationController(rootViewController: navHome), main]
            
            window.rootViewController = splitViewController
            self.window = window
            window.makeKeyAndVisible()
            return main
        }
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
                            Subscriptions.subIcons[sub.displayName.lowercased()] = sub.iconImg == "" ? sub.communityIcon : sub.iconImg
                            Subscriptions.subColors[sub.displayName.lowercased()] = sub.keyColor

                            /* Not needed, we pull from the key color now
                            if sub.keyColor.hexString() != "#FFFFFF" {
                                let color = ColorUtil.getClosestColor(hex: sub.keyColor.hexString())
                                if defaults.object(forKey: "color" + sub.displayName) == nil {
                                    defaults.setColor(color: color, forKey: "color+" + sub.displayName)
                                }
                            }*/
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
                            /*if sub.keyColor.hexString() != "#FFFFFF" {
                                let color = ColorUtil.getClosestColor(hex: sub.keyColor.hexString())
                                if defaults.object(forKey: "color" + sub.displayName) == nil {
                                    defaults.setColor(color: color, forKey: "color+" + sub.displayName)
                                }
                            }*/
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
        return handleURL(url)
    }
    
    func handleURL(_ url: URL) -> Bool {
        print("Handling URL \(url)")
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
        if #available(iOS 13.0, *) { return } else {
            didBecomeActive()
        }
    }
    
    func didBecomeActive() {
        if AccountController.current == nil && UserDefaults.standard.string(forKey: "name") != "GUEST" {
            AccountController.initialize()
        }
        
        if let url = launchedURL {
            handleURL(url)
            launchedURL = nil
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
        fetchFromiCloud("readlater", dictionaryToAppend: ReadLater.readLaterIDs) { (record) in
            self.readLaterRecord = record
        }
        fetchFromiCloud("collections", dictionaryToAppend: Collections.collectionIDs) { (record) in
            self.collectionRecord = record
            let removeDict = NSMutableDictionary()
            self.fetchFromiCloud("removed", dictionaryToAppend: removeDict) { (record) in
                self.deletedRecord = record
                let removeKeys = removeDict.allKeys as! [String]
                for item in removeKeys {
                    Collections.collectionIDs.removeObject(forKey: item)
                    ReadLater.readLaterIDs.removeObject(forKey: item)
                }
            }
        }
    }

    var backView: UIView?
    func applicationWillResignActive(_ application: UIApplication) {
        if #available(iOS 13.0, *) { return } else {
            willResignActive()
        }
    }
    
    func willResignActive() {
        if SettingValues.biometrics {
            if backView == nil {
                backView = UIView.init(frame: self.window!.frame)
                backView?.backgroundColor = ColorUtil.theme.backgroundColor
                if let window = self.window {
                    window.insertSubview(backView!, at: 0)
                    backView!.edgeAnchors == window.edgeAnchors
                    backView!.layer.zPosition = 1
                }
            }
            self.backView?.isHidden = false
        }
        totalBackground = false
    }
    
    var readLaterRecord: CKRecord?
    var collectionRecord: CKRecord?
    var deletedRecord: CKRecord?
    
    func saveToiCloud(_ dictionary: NSDictionary, _ key: String, _ record: CKRecord?) {
        let collectionsRecord: CKRecord
        if record != nil {
            collectionsRecord = record!
        } else {
            collectionsRecord = CKRecord(recordType: key)
        }
        do {
            let data: NSData = try PropertyListSerialization.data(fromPropertyList: dictionary, format: PropertyListSerialization.PropertyListFormat.xml, options: 0) as NSData
            if let datastring = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) {
               collectionsRecord.setValue(datastring, forKey: "data_xml")
            } else {
                print("Could not turn nsdata to string")
            }
            
            print("Saving to iCloud \(key)")
            CKContainer(identifier: "iCloud.\(USR_DOMAIN).redditslide").privateCloudDatabase.save(collectionsRecord) { (_, error) in
                if error != nil {
                    print("iCloud error")
                    print(error.debugDescription)
                }
            }
        } catch {
            print("Error serializing dictionary")
        }
    }
    
    func fetchFromiCloud(_ key: String, dictionaryToAppend: NSMutableDictionary, completion: ((_ record: CKRecord) -> Void)? = nil) {
        let privateDatabase = CKContainer(identifier: "iCloud.\(USR_DOMAIN).redditslide").privateCloudDatabase
        
        let query = CKQuery(recordType: CKRecord.RecordType(stringLiteral: key), predicate: NSPredicate(value: true))
        print("Reading from iCloud")
        privateDatabase.perform(query, inZoneWith: nil) { (records, error) in
            if error != nil {
                print("Error fetching records...")
                print(error?.localizedDescription ?? "")
            } else {
                if let unwrappedRecord = records?[0] {
                    if let object = unwrappedRecord.object(forKey: "data_xml") as? String {
                        if let data = object.data(using: String.Encoding.utf8) {
                            do {
                                let dict = try PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.ReadOptions.mutableContainersAndLeaves, format: nil) as? NSMutableDictionary
                                for item in dict ?? [:] {
                                    dictionaryToAppend[item.key] = item.value
                                }
                                completion?(unwrappedRecord)
                                return
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
        if #available(iOS 13.0, *) { return } else {
            didEnterBackground()
        }
    }
        
    func didEnterBackground() {
        totalBackground = true
        History.seenTimes.write(toFile: seenFile!, atomically: true)
        History.commentCounts.write(toFile: commentsFile!, atomically: true)
        ReadLater.readLaterIDs.write(toFile: readLaterFile!, atomically: true)
        Collections.collectionIDs.write(toFile: collectionsFile!, atomically: true)
        Subscriptions.subIcons.write(toFile: iconsFile!, atomically: true)
        Subscriptions.subColors.write(toFile: colorsFile!, atomically: true)

        saveToiCloud(Collections.collectionIDs, "collections", self.collectionRecord)
        saveToiCloud(ReadLater.readLaterIDs, "readlater", self.readLaterRecord)
        saveToiCloud(AppDelegate.removeDict, "removed", self.deletedRecord)
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        self.refreshSession()
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

@available(iOS 13.0, *)
extension AppDelegate: UIWindowSceneDelegate {
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            handleURL(url)
        }
    }
        
    func sceneDidBecomeActive(_ scene: UIScene) {
        didBecomeActive()
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        self.refreshSession()
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        didEnterBackground()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        willResignActive()
    }
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
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
    
    //Siri shortcuts and deep links
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        print(userActivity.userInfo)
        if (userActivity.userInfo?["TYPE"] as? NSString) ?? "" == "SUBREDDIT" {
            VCPresenter.openRedditLink("/r/\(userActivity.title ?? "")", window?.rootViewController as? UINavigationController, window?.rootViewController)
        } else if (userActivity.userInfo?["TYPE"] as? NSString) ?? "" == "INBOX" {
            VCPresenter.showVC(viewController: InboxViewController(), popupIfPossible: false, parentNavigationController: window?.rootViewController as? UINavigationController, parentViewController: window?.rootViewController)
        } else if let url = userActivity.webpageURL {
            handleURL(url)
        }

    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }

        if let url = connectionOptions.urlContexts.first?.url {
            launchedURL = url
        }
        
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            self.window = window

            didFinishLaunching(window: window)
            /* TODO This launchedURL = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL
            let remoteNotif = launchOptions?[UIApplication.LaunchOptionsKey.localNotification] as? UILocalNotification
            
            if remoteNotif != nil {
                if let url = remoteNotif!.userInfo?["permalink"] as? String {
                    VCPresenter.openRedditLink(url, window?.rootViewController as? UINavigationController, window?.rootViewController)
                } else {
                    VCPresenter.showVC(viewController: InboxViewController(), popupIfPossible: false, parentNavigationController: window?.rootViewController as? UINavigationController, parentViewController: window?.rootViewController)
                }
            }*/
        }
    }
}

@available(iOS 10.0, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo as? NSDictionary
        if let url = userInfo?["permalink"] as? String {
            VCPresenter.openRedditLink(url, window?.rootViewController as? UINavigationController, window?.rootViewController)
        } else {
            VCPresenter.showVC(viewController: InboxViewController(), popupIfPossible: false, parentNavigationController: window?.rootViewController as? UINavigationController, parentViewController: window?.rootViewController)
        }
    }
}
