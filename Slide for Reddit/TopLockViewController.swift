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
        unlockButton.setTitle("Tap to Unlock Slide", for: .normal)
        unlockButton.setTitleColor(ColorUtil.theme.fontColor, for: .normal)
        unlockButton.addTarget(self, action: #selector(doBios), for: .touchUpInside)
        self.view.backgroundColor = ColorUtil.theme.backgroundColor
        self.view.addSubviews(imageView, unlockButton)
        
        imageView.widthAnchor /==/ 150
        imageView.heightAnchor /==/ 150
        imageView.centerAnchors /==/ self.view.centerAnchors
        
        unlockButton.centerXAnchor /==/ self.view.centerXAnchor
        unlockButton.bottomAnchor /==/ self.view.safeBottomAnchor - 16
        unlockButton.isHidden = true
        TopLockViewController.presented = true
    }
    
    deinit {
        TopLockViewController.presented = false
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            UIView.animate(withDuration: 0.25, animations: {
                delegate.backView?.alpha = 0
            }, completion: { (_) in
                delegate.backView?.alpha = 1
                delegate.backView?.isHidden = true
            })
        }
        doBios()
    }
    
    @objc func doBios() {
        if SettingValues.biometrics && BioMetricAuthenticator.canAuthenticate() {
            BioMetricAuthenticator.authenticateWithBioMetrics(reason: "") {[weak self] (result) in
                if let strongSelf = self {
                    switch result {
                    case .success:
                        strongSelf.dismiss(animated: true, completion: nil)
                    case .failure(let error):
                        // do nothing on canceled
                        if error == .canceledByUser || error == .canceledBySystem {
                            strongSelf.unlockButton.isHidden = false
                        }
                        BioMetricAuthenticator.authenticateWithPasscode(reason: "Enter your password to unlock Slide", cancelTitle: "Exit", completion: { [weak self](result) in
                            if let strongSelf = self {
                                switch result {
                                case .success:
                                    strongSelf.dismiss(animated: true, completion: nil)
                                case .failure:
                                    strongSelf.unlockButton.isHidden = false
                                }
                            }
                        })
                    }
                }
            }
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
