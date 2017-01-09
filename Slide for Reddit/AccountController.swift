//
//  AccountController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/7/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import reddift

class AccountController{
    @objc static func didSaveToken(_ notification: Notification) {
        AccountController.reload()
    }
    
    static func reload() {
        AccountController.names.removeAll(keepingCapacity: false)
        AccountController.names += OAuth2TokenRepository.savedNames
    }
    
    static func switchAccount(name: String){
        changed = true
        UserDefaults.standard.set(name, forKey: "name")
        UserDefaults.standard.synchronize()
        initialize()
    }
    
    static var isLoggedIn = false
    static var changed = false
    
    static func delete(name: String){
        do{
            try OAuth2TokenRepository.removeToken(of: name)
            names.remove(at: names.index(of: name)!)
            UserDefaults.standard.set(name, forKey: "GUEST")
            UserDefaults.standard.synchronize()

        } catch {
            print(error)
        }
    }
    
    static var currentName = "GUEST"
    
    static func initialize(){
        names.removeAll(keepingCapacity: false)
        names += OAuth2TokenRepository.savedNames
        NotificationCenter.default.addObserver(self, selector: #selector(AccountController.didSaveToken(_:)), name: OAuth2TokenRepositoryDidSaveTokenName, object: nil)
        if let name = UserDefaults.standard.string(forKey: "name") {
            print("Name is \(name)")
            if(name == "GUEST"){
                AccountController.isLoggedIn = false
                AccountController.currentName = name
                (UIApplication.shared.delegate as! AppDelegate).session = Session()
            } else {
                do{
                    AccountController.isLoggedIn = true
                    AccountController.currentName = name
                    let token = try OAuth2TokenRepository.token(of: name)
                    (UIApplication.shared.delegate as! AppDelegate).session = Session(token: token)
                    UserDefaults.standard.set(name, forKey: "name")
                    UserDefaults.standard.synchronize()
                } catch {
                    print(error)
                    (UIApplication.shared.delegate as! AppDelegate).session = Session()
                }
            }
        } else {
            (UIApplication.shared.delegate as! AppDelegate).session = Session()
            AccountController.isLoggedIn = false
        }
    }
    
    public static var names: [String] = []
    
    static func addAccount(){
        try! OAuth2Authorizer.sharedInstance.challengeWithAllScopes()
    }
    
}
