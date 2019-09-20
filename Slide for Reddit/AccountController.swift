//
//  AccountController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/7/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import reddift
import SafariServices

class AccountController {
    @objc static func didSaveToken(_ notification: Notification) {
        AccountController.reload()
    }

    static func reload() {
        AccountController.names.removeAll(keepingCapacity: false)
        AccountController.names += LocalKeystore.savedNames
        print(AccountController.names)
    }

    static func switchAccount(name: String) {
        changed = true
        ActionStates.upVotedFullnames.removeAll()
        ActionStates.downVotedFullnames.removeAll()
        ActionStates.savedFullnames.removeAll()
        ActionStates.unvotedFullnames.removeAll()
        ActionStates.unSavedFullnames.removeAll()
        
        UserDefaults.standard.set(name, forKey: "name")
        UserDefaults.standard.synchronize()
        initialize()
    }

    static var isLoggedIn = false
    static var isGold = false
    static var changed = false
    static var modSubs: [String] = []

    static var current: Account?

    static func delete(name: String) {
        do {
            try LocalKeystore.removeToken(of: name)
            try OAuth2TokenRepository.removeToken(of: name)

            names.remove(at: names.firstIndex(of: name)!)
            UserDefaults.standard.set(name, forKey: "GUEST")
            UserDefaults.standard.synchronize()

        } catch {
            print(error)
        }
    }

    static var currentName = "GUEST"

    static func initialize() {
        names.removeAll(keepingCapacity: false)
        names += LocalKeystore.savedNames
        
        names = names.unique()

        NotificationCenter.default.addObserver(self, selector: #selector(AccountController.didSaveToken(_:)), name: OAuth2TokenRepositoryDidSaveTokenName, object: nil)
        if let name = UserDefaults.standard.string(forKey: "name") {
            print("Name is \(name)")
            if name == "GUEST" {
                AccountController.isLoggedIn = false
                AccountController.isGold = false
                AccountController.current = nil
                AccountController.currentName = name
                (UIApplication.shared.delegate as! AppDelegate).session = Session()
                NotificationCenter.default.post(name: .onAccountChangedToGuest, object: nil)
            } else {
                do {
                    AccountController.isLoggedIn = true
                    AccountController.currentName = name
                    let token: OAuth2Token
                    if !isMigrated(name) {
                        token = try OAuth2TokenRepository.token(of: name)
                        try LocalKeystore.save(token: token, of: name)
                    } else {
                        token = try LocalKeystore.token(of: name)
                    }
                    
                    let session = Session(token: token)
                    (UIApplication.shared.delegate as! AppDelegate).session = session
                    try session.getUserProfile(name, completion: { (result) in
                        switch result {
                        case .failure(let error):
                            print(error)
                        case .success(let account):
                            AccountController.current = account
                            NotificationCenter.default.post(name: .onAccountChanged, object: nil, userInfo: [
                                "Account": account,
                                ])
                            if AccountController.currentName == name {
                                AccountController.isGold = account.isGold
                            }
                        }
                    })
                    UserDefaults.standard.set(name, forKey: "name")
                    UserDefaults.standard.synchronize()
                } catch {
                    print(error)
                    (UIApplication.shared.delegate as! AppDelegate).session = Session()
                    AccountController.isLoggedIn = false
                    AccountController.isGold = false
                }
            }
        } else {
            (UIApplication.shared.delegate as! AppDelegate).session = Session()
            AccountController.isLoggedIn = false
            AccountController.isGold = false
        }
        NotificationCenter.default.post(name: OAuth2TokenRepositoryDidSaveTokenName, object: nil, userInfo: nil)
    }

    public static var names: [String] = []

    static func addAccount(context: UIViewController, register: Bool) {
        try! AccountController.challengeWithAllScopes(context, register: register)
    }

    public static var canShowNSFW: Bool {
        return AccountController.isLoggedIn && SettingValues.nsfwEnabled
    }
    
    /**
     Open OAuth2 page to try to authorize with all scopes in Safari.app.
     */
    public static func challengeWithAllScopes(_ context: UIViewController, register: Bool) throws {
        do {
            try self.challengeWithScopes(["identity", "edit", "flair", "history", "modconfig", "modflair", "modlog", "modposts", "modwiki", "mysubreddits", "privatemessages", "read", "report", "save", "submit", "subscribe", "vote", "wikiedit", "wikiread"], context, register: register)
        } catch {
            throw error
        }
    }
    
    /**
     Open OAuth2 page to try to authorize with user specified scopes in Safari.app.
     
     - parameter scopes: Scope you want to get authorizing. You can check all scopes at https://www.reddit.com/dev/api/oauth.
     */
    public static func challengeWithScopes(_ scopes: [String], _ context: UIViewController, register: Bool) throws {
        let commaSeparatedScopeString = scopes.joined(separator: ",")
        
        let length = 64
        let mutableData = NSMutableData(length: Int(length))
        if let data = mutableData {
            let a = OpaquePointer(data.mutableBytes)
            let ptr = UnsafeMutablePointer<UInt8>(a)
            _ = SecRandomCopyBytes(kSecRandomDefault, length, ptr)
            OAuth2Authorizer.sharedInstance.state = data.base64EncodedString(options: .endLineWithLineFeed)
            guard let authorizationURL = URL(string: "https://www.reddit.com/api/v1/authorize.compact?client_id=r1JeYb6X0P2QOg&response_type=code&state=" + OAuth2Authorizer.sharedInstance.state + "&redirect_uri=slide://ccrama&duration=permanent&scope=" + commaSeparatedScopeString)
                else { throw ReddiftError.canNotCreateURLRequestForOAuth2Page as NSError }
            let vc: UIViewController
            let web = WebsiteViewController(url: authorizationURL, subreddit: "")
            web.register = register
            vc = web
            VCPresenter.showVC(viewController: vc, popupIfPossible: false, parentNavigationController: nil, parentViewController: context)
        } else {
            throw ReddiftError.canNotAllocateDataToCreateURLForOAuth2 as NSError
        }
    }

    static func doModOf() {
        DispatchQueue.main.async {
            let session = (UIApplication.shared.delegate as! AppDelegate).session!
            getSubscriptionsFully(session: session) { (subs: [Subreddit]) in
                for sub in subs {
                    modSubs.append(sub.displayName)
                }
            }
        }
    }
    
    public static func formatUsername(input: String, small: Bool) -> String {
        if SettingValues.nameScrubbing && input == AccountController.currentName {
            return "you"
        } else {
            if small {
                return input
            }
            return "u/\(input)"
        }
    }
    
    public static func isMigrated(_ name: String) -> Bool {
        return UserDefaults.standard.data(forKey: "AUTH+\(name)") != nil
    }
    
    public static func formatUsernamePosessive(input: String, small: Bool) -> String {
        if SettingValues.nameScrubbing && input == AccountController.currentName {
            return "Your"
        } else {
            if small {
                return input
            }
            return "u/\(input)'s"
        }
    }

    public static func getSubscriptionsUntilCompletion(session: Session, p: Paginator, tR: [Subreddit], completion: @escaping (_ result: [Subreddit]) -> Void) {
        var toReturn = tR
        var paginator = p
        do {
            try session.getUserRelatedSubreddit(.moderator, paginator: paginator, completion: { (result) -> Void in
                switch result {
                case .failure:
                    print(result.error!.localizedDescription)
                    completion(toReturn)
                case .success(let listing):
                    toReturn += listing.children.compactMap({ $0 as? Subreddit })
                    paginator = listing.paginator
                    if paginator.hasMore() {
                        getSubscriptionsUntilCompletion(session: session, p: paginator, tR: toReturn, completion: completion)
                    } else {
                        completion(toReturn)
                    }
                }
            })
        } catch {
            completion(toReturn)
        }

    }

    public static func getSubscriptionsFully(session: Session, completion: @escaping (_ result: [Subreddit]) -> Void) {
        let toReturn: [Subreddit] = []
        let paginator = Paginator()
        getSubscriptionsUntilCompletion(session: session, p: paginator, tR: toReturn, completion: completion)
    }

}
extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: [Iterator.Element: Bool] = [:]
        return self.filter { seen.updateValue(true, forKey: $0) == nil }
    }
}

extension Notification.Name {
    static let onAccountChangedToGuest = Notification.Name("on-account-changed-to-guest")
    static let onAccountChanged = Notification.Name("on-account-changed")
    static let onAccountMailCountChanged = Notification.Name("on-account-mail-count-changed")
    static let accountRefreshRequested = Notification.Name("account-refresh-requested")
}
