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
    var login: SubredditsViewController?
    var seenFile: String?
    var commentsFile: String?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)

        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentDirectory = paths[0] as! String
        seenFile = documentDirectory.appending("/seen.plist")
        commentsFile = documentDirectory.appending("/comments.plist")

        let config = Realm.Configuration(
            schemaVersion: 5,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 5) {
                }
        })
        
        Realm.Configuration.defaultConfiguration = config
        application.setMinimumBackgroundFetchInterval(TimeInterval.init(900))
        let fileManager = FileManager.default
        if(!fileManager.fileExists(atPath: seenFile!)){
            if let bundlePath = Bundle.main.path(forResource: "seen", ofType: "plist"){
                _ = NSMutableDictionary(contentsOfFile: bundlePath)
                do{
                    try fileManager.copyItem(atPath: bundlePath, toPath: seenFile!)
                }catch{
                    print("copy failure.")
                }
            }else{
                print("file myData.plist not found.")
            }
        }else{
            print("file myData.plist already exits at path.")
        }

        if(!fileManager.fileExists(atPath: commentsFile!)){
            if let bundlePath = Bundle.main.path(forResource: "comments", ofType: "plist"){
                _ = NSMutableDictionary(contentsOfFile: bundlePath)
                do{
                    try fileManager.copyItem(atPath: bundlePath, toPath: commentsFile!)
                }catch{
                    print("copy failure.")
                }
            }else{
                print("file myData.plist not found.")
            }
        }else{
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
                if((error) != nil){
                    print(error!.localizedDescription)
                }
            }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
                (granted, error) in
                if((error) != nil){
                    print(error!.localizedDescription)
                }
            }
            UIApplication.shared.registerForRemoteNotifications()
        } else {
            // Fallback on earlier versions
        }
        if !UserDefaults.standard.bool(forKey: "sc" + name){
            syncColors(subredditController: nil)
        }

        ColorUtil.doInit()
        let textAttributes = [NSForegroundColorAttributeName:UIColor.white]
        UINavigationBar.appearance().titleTextAttributes = textAttributes
        if(SettingValues.biometrics && BioMetricAuthenticator.canAuthenticate()) {
            BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {



            }, failure: { [weak self] (error) in

                // do nothing on canceled
                if error == .canceledByUser || error == .canceledBySystem {
                    return
                }

                // device does not support biometric (face id or touch id) authentication
                else if error == .biometryNotAvailable {
                    //todo self?.showErrorAlert(message: error.message())
                }

                // show alternatives on fallback button clicked
                else if error == .fallback {

                    //todo a fallback?
                }

                // No biometry enrolled in this device, ask user to register fingerprint or face
                else if error == .biometryNotEnrolled {
                    //ignore
                }

                // Biometry is locked out now, because there were too many failed attempts.
                // Need to enter device passcode to unlock.
                else if error == .biometryLockedout {
                    //todo on lockout
                }

                // show error on authentication failed
                else {
                    //todo  self?.showErrorAlert(message: error.message())
                }
            })
        }
        return true
    }
    
    var statusBar = UIView()

    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let session = session {
            do {
                let request = try session.requestForGettingProfile()
                let fetcher = BackgroundFetch(current: session,
                                              request: request,
                                              taskHandler: { (response, dataURL, error) -> Void in
                                                print("Doing")

                                                if let response = response, let dataURL = dataURL {
                                                    
                                                    if response.statusCode == HttpStatus.ok.rawValue {
                                                        
                                                        do {
                                                            let data = try Data(contentsOf: dataURL)
                                                            let result = accountInResult(from: data, response: response)
                                                            switch result {
                                                            case .success(let account):
                                                                print(account)
                                                                UIApplication.shared.applicationIconBadgeNumber = account.inboxCount
                                                                self.postLocalNotification("You have \(account.inboxCount) new messages.")
                                                                completionHandler(.newData)
                                                                return
                                                            case .failure(let error):
                                                                print(error)
                                                                self.postLocalNotification("\(error)")
                                                                completionHandler(.failed)
                                                            }
                                                        }
                                                        catch {
                                                            
                                                        }
                                                    }
                                                    else {
                                                        self.postLocalNotification("response code \(response.statusCode)")
                                                        completionHandler(.failed)
                                                    }
                                                } else {
                                                    self.postLocalNotification("Error can not parse response and data.")
                                                    completionHandler(.failed)
                                                }
                })
                fetcher.resume()
                self.fetcher = fetcher
            } catch {
                print(error.localizedDescription)
                postLocalNotification("\(error)")
                completionHandler(.failed)
            }
        } else {
            print("Fail")
            postLocalNotification("session is not available.")
            completionHandler(.failed)
        }
    }
    
    func postLocalNotification(_ message: String) {
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
       
        let content = UNMutableNotificationContent()
        content.title = "New messages!"
        content.body = message
        content.sound = UNNotificationSound.default()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300,
                                                        repeats: false)
        let identifier = "SlideMSGNotif"
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
    

    func syncColors(subredditController: SubredditsViewController?) {
        let defaults = UserDefaults.standard
        var toReturn: [String] = []
        defaults.set(true, forKey: "sc" + name)
        defaults.synchronize()
        do {
            if(!AccountController.isLoggedIn){
                try session?.getSubreddit(.default, paginator:paginator, completion: { (result) -> Void in
                switch result {
                case .failure:
                    print(result.error!)
                case .success(let listing):
                    self.subreddits += listing.children.flatMap({$0 as? Subreddit})
                    self.paginator = listing.paginator
                    for sub in self.subreddits{
                        toReturn.append(sub.displayName)
                        if(!sub.keyColor.isEmpty){
                            let color = (UIColor.init(hexString: sub.keyColor))
                            if(defaults.object(forKey: "color" + sub.displayName) == nil){
                                defaults.setColor(color: color , forKey: "color+" + sub.displayName)
                            }
                        }
                        }
                    
                }
                    if(subredditController != nil){
                        DispatchQueue.main.async (execute: { () -> Void in
                        subredditController?.complete(subs: toReturn)
                        })
                    }
            })

            } else {
                Subscriptions.getSubscriptionsFully(session: session!, completion: { (subs, multis) in
                    for sub in subs {
                        toReturn.append(sub.displayName)
                        if(!sub.keyColor.isEmpty){
                        let color = (UIColor.init(hexString: sub.keyColor))
                        if(defaults.object(forKey: "color" + sub.displayName) == nil){
                            defaults.setColor(color: color , forKey: "color+" + sub.displayName)
                        }
                        }
                    }
                    for m in multis {
                        toReturn.append("/m/" + m.displayName)
                        if(!m.keyColor.isEmpty){

                        let color = (UIColor.init(hexString: m.keyColor))
                        if(defaults.object(forKey: "color" + m.displayName) == nil){
                            defaults.setColor(color: color , forKey: "color+" + m.displayName)
                        }
                        }
                    }
                    

                    toReturn = toReturn.sorted{ $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending }
                    toReturn.insert("all", at: 0)
                    toReturn.insert("slide_ios", at: 0)
                    toReturn.insert("frontpage", at: 0)
                    if(subredditController != nil){
                        DispatchQueue.main.async (execute: { () -> Void in
                            subredditController?.complete(subs: toReturn)
                        })
                    }

                })
            }
        } catch {
            print(error)
            if(subredditController != nil){
                DispatchQueue.main.async (execute: { () -> Void in
                    subredditController?.complete(subs: toReturn)
                })
            }
        }
        
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        print("Returning \(url.absoluteString)")
        var parameters: [String:String] = url.getKeyVals()!
        
        if let code = parameters["code"], let state = parameters["state"] {
            print(state)
            if code.characters.count > 0 {
                    print(code)
            }
        }

        return OAuth2Authorizer.sharedInstance.receiveRedirect(url, completion: {(result) -> Void in
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
    
    func killAndReturn(){
        if let rootViewController = UIApplication.topViewController() {
            var navigationArray = rootViewController.viewControllers
            navigationArray.removeAll()
            rootViewController.viewControllers = navigationArray
            rootViewController.pushViewController(SubredditsViewController(coder: NSCoder.init())!, animated: false)
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("background")
        History.seenTimes.write(toFile: seenFile!, atomically: true)
        History.commentCounts.write(toFile: commentsFile!, atomically: true)
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        if(SettingValues.biometrics && BioMetricAuthenticator.canAuthenticate()) {
            BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {



            }, failure: { [weak self] (error) in

                // do nothing on canceled
                if error == .canceledByUser || error == .canceledBySystem {
                    return
                }

                // device does not support biometric (face id or touch id) authentication
                else if error == .biometryNotAvailable {
                    //todo self?.showErrorAlert(message: error.message())
                }

                // show alternatives on fallback button clicked
                else if error == .fallback {

                    //todo a fallback?
                }

                // No biometry enrolled in this device, ask user to register fingerprint or face
                else if error == .biometryNotEnrolled {
                    //ignore
                }

                // Biometry is locked out now, because there were too many failed attempts.
                // Need to enter device passcode to unlock.
                else if error == .biometryLockedout {
                    //todo on lockout
                }

                // show error on authentication failed
                else {
                    //todo  self?.showErrorAlert(message: error.message())
                }
            })
        }
        self.refreshSession()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {

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
        } catch { print(error) }
    }
    
    func reloadSession() {
        // reddit username is save NSUserDefaults using "currentName" key.
        // create an authenticated or anonymous session object
        if let currentName = UserDefaults.standard.object(forKey: "name") as? String {
            do {
                let token = try OAuth2TokenRepository.token(of: currentName)
                self.session = Session(token: token)
                self.refreshSession()
            } catch { print(error) }
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
        var results = [String:String]()
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
