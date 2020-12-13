//
//  OnboardingViewController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 9/15/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Anchorage
import Then
import UIKit

class OnboardingViewController: UIViewController {

     let models: [OnboardingPageViewModel] = [
        //TODO this for 6.1
        .splash(text: "Welcome to\nSlide v6.1", subText: "Swipe to see what's new", image: UIImage(named: "ic_retroapple")!),
        .hardcodedChangelog(order: [
                                "AutoCache, Revamped",
                            ], paragraphs: [
                                "AutoCache, Revamped": "Something here",
                            ]),
    ]

    var pageViewController: OnboardingPageViewController!
    
    var widthSet = false

    var finishButton = UILabel().then {
        $0.text = "Done"
        $0.accessibilityLabel = "Exit"
        $0.textAlignment = .center
        $0.textColor = ColorUtil.theme.fontColor
        $0.layer.cornerRadius = 20
        $0.clipsToBounds = true
        $0.layer.backgroundColor = ColorUtil.theme.backgroundColor.cgColor
    }
    
    override func accessibilityPerformEscape() -> Bool {
        self.dismiss(animated: true, completion: nil)
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Embed pageViewController
        pageViewController = OnboardingPageViewController(models: models)
        view.addSubview(pageViewController.view)
        addChild(pageViewController)
        pageViewController.didMove(toParent: self)
        
        view.addSubview(finishButton)

        setupConstraints()
        
        finishButton.addTapGestureRecognizer { (_) in
            self.dismiss(animated: true, completion: nil)
        }
        
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = ColorUtil.theme.fontColor.withAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = ColorUtil.theme.fontColor
    }

    private func setupConstraints() {
        batch {
            // Page view controller
            pageViewController.view.topAnchor /==/ view.safeAreaLayoutGuide.topAnchor
            pageViewController.view.horizontalAnchors /==/ view.horizontalAnchors

            // Finish button
            finishButton.topAnchor /==/ pageViewController.view.bottomAnchor
            finishButton.heightAnchor /==/ 40
            finishButton.centerXAnchor /==/ view.centerXAnchor
            finishButton.bottomAnchor /==/ view.safeAreaLayoutGuide.bottomAnchor - 16
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !widthSet {
            widthSet = true
            finishButton.widthAnchor /==/ min(max(200, self.view.frame.size.width - 32), 400)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UserDefaults.standard.set(true, forKey: Bundle.main.releaseVersionNumber!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let nav = navigationController as? SwipeForwardNavigationController {
            nav.interactivePushGestureRecognizer?.isEnabled = false
            nav.interactivePopGestureRecognizer?.isEnabled = false
        }
    }

}
