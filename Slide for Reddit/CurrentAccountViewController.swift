//
//  CurrentAccountViewController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 1/9/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import Anchorage
import SDWebImage
import Then
import UIKit

protocol CurrentAccountViewControllerDelegate: AnyObject {
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestSettingsMenu: Void)
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestAccountChange: Void)
}

class CurrentAccountViewController: UIViewController {

    weak var delegate: CurrentAccountViewControllerDelegate?

    var backgroundView: UIView!

    var settingsButton = UIButton(type: .custom).then {
        $0.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        $0.setImage(UIImage(named: "settings")!.getCopy(withSize: .square(size: 30), withColor: .white), for: UIControlState.normal)
        $0.isUserInteractionEnabled = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()
        configureConstraints()
        configureActions()
    }
}

// MARK: - Setup
extension CurrentAccountViewController {
    func configureViews() {
        backgroundView = UIView().then {
            $0.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        }
        view.addSubview(backgroundView)

        // Add blur
        if #available(iOS 11, *) {
            let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
            let blurView = UIVisualEffectView(frame: .zero)
            blurEffect.setValue(3, forKeyPath: "blurRadius")
            blurView.effect = blurEffect
            backgroundView.insertSubview(blurView, at: 0)
            blurView.edgeAnchors == backgroundView.edgeAnchors
        }

        backgroundView.addSubview(settingsButton)
    }

    func configureConstraints() {
        backgroundView.edgeAnchors == view.edgeAnchors

        settingsButton.topAnchor == backgroundView.safeTopAnchor + 4
        settingsButton.rightAnchor == backgroundView.safeRightAnchor - 16
    }

    func configureActions() {
        let bgTap = UITapGestureRecognizer(target: self, action: #selector(didRequestClose))
        backgroundView.addGestureRecognizer(bgTap)

        let sTap = UITapGestureRecognizer(target: self, action: #selector(settingsButtonPressed))
        settingsButton.addGestureRecognizer(sTap)
    }
}

// MARK: - Actions
extension CurrentAccountViewController {
    @objc func didRequestClose() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func settingsButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.delegate?.currentAccountViewController(self, didRequestSettingsMenu: ())
        }
    }
}
