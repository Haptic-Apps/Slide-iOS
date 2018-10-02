//
//  TopLockViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 10/2/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import BiometricAuthentication
import UIKit

public class TopLockViewController: UIViewController {
    var imageView = UIImageView()
    var unlockButton = UIButton()
    
    public static var presented = false
    
    public override func viewDidLoad() {
        imageView.image = UIImage(named: "roundicon")
        unlockButton.backgroundColor = .clear
        unlockButton.setTitle("Unlock Slide", for: .normal)
        unlockButton.setTitleColor(ColorUtil.fontColor, for: .normal)
        unlockButton.addTarget(self, action: #selector(doBios), for: .touchUpInside)
        self.view.backgroundColor = ColorUtil.backgroundColor
        self.view.addSubviews(imageView, unlockButton)
        
        imageView.widthAnchor == 150
        imageView.heightAnchor == 150
        imageView.centerAnchors == self.view.centerAnchors
        
        unlockButton.centerXAnchor == self.view.centerXAnchor
        unlockButton.bottomAnchor == self.view.safeBottomAnchor - 16
        unlockButton.isHidden = true
        TopLockViewController.presented = true
    }
    
    deinit {
        TopLockViewController.presented = false
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        doBios()
    }
    
    func doBios() {
        if SettingValues.biometrics && BioMetricAuthenticator.canAuthenticate() {
            BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                self.dismiss(animated: true, completion: nil)
            }, failure: { [weak self] (error) in
                
                // do nothing on canceled
                if error == .canceledByUser || error == .canceledBySystem {
                    self?.unlockButton.isHidden = false
                }
                
                BioMetricAuthenticator.authenticateWithPasscode(reason: "Enter your password", cancelTitle: "Exit", success: {
                    self?.dismiss(animated: true, completion: nil)
                }, failure: { (_) in
                    self?.unlockButton.isHidden = false
                })
            })
        }
    }
    

}

extension UIWindow {
    func topViewController() -> UIViewController? {
        var top = self.rootViewController
        while true {
            if let presented = top?.presentedViewController {
                top = presented
            } else if let nav = top as? UINavigationController {
                top = nav.visibleViewController
            } else if let tab = top as? UITabBarController {
                top = tab.selectedViewController
            } else {
                break
            }
        }
        return top
    }
}
