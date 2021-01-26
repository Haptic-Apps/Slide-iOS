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
        // TODO this for 6.1
        .splash(text: "Welcome to\nSlide v7", subText: "Swipe to see what's new", image: UIImage(named: "slide_glow")!),
        .testflight(enabled: true),
        .hardcodedChangelog(order: [
                                "AutoCache 2.0",
                                "Desktop Mode",
                                "Theme Engine revamp",
                                "Text Render revamp",
                                "Inbox and Profile redesign",
                            ], paragraphs: [
                                "AutoCache 2.0": "AutoCache has been rewritten from the ground up, and Slide has a shiny new backend! Apart from improvements to Offline Mode, these changes will make Slide faster and less resource-hungry",
                                "Desktop Mode": "iPad and M1-Mac users can try out Slide's new Desktop Mode, which keeps Slide's sidebar locked in view and adds right-click actions to posts and comments",
                                "Theme Engine revamp": "Night-mode changes on iOS 13 and 14 will be faster and more seamless in v7",
                                "Text Render revamp": "Slide now has a completely custom text rendering system that will improve performance and rendering of complex selftext posts and comments. Haptic Touch on links has been re-written from the ground up, and you can now Haptic Touch on usernames to see a preview of any user's profile!",
                                "Inbox and Profile redesign": "Your Slide Inbox and profile views have been redesigned, with a greater emphasis on Subreddit styling and better use of space ",
                            ]),
    ]

    var pageViewController: OnboardingPageViewController!
    
    var widthSet = false
    static let versionBackgroundColor = UIColor(hexString: "#010014")

    var finishButton = UILabel().then {
        $0.text = "Done"
        $0.accessibilityLabel = "Exit"
        $0.textAlignment = .center
        $0.textColor = .white
        $0.layer.cornerRadius = 20
        $0.clipsToBounds = true
        $0.layer.backgroundColor = UIColor(hexString: "#50ECF6").cgColor
    }
    
    override func accessibilityPerformEscape() -> Bool {
        self.dismiss(animated: true, completion: nil)
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Embed pageViewController
        pageViewController = OnboardingPageViewController(models: models)
        pageViewController.titles = models.map({ (_) -> String in
            return UUID().uuidString
        })
        pageViewController.viewToMux = self.view
        pageViewController.color1 = OnboardingViewController.versionBackgroundColor
        pageViewController.color2 = UIColor.foregroundColor
        view.addSubview(pageViewController.view)
        addChild(pageViewController)
        pageViewController.didMove(toParent: self)
        
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        view.addSubview(finishButton)
        view.backgroundColor = OnboardingViewController.versionBackgroundColor

        setupConstraints()
        
        finishButton.addTapGestureRecognizer { (_) in
            self.dismiss(animated: true, completion: nil)
        }
        
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.fontColor.withAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = UIColor.fontColor
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
        pageViewController.navToMux = self.navigationController?.navigationBar

        if let nav = navigationController as? SwipeForwardNavigationController {
            nav.interactivePushGestureRecognizer?.isEnabled = false
            nav.interactivePopGestureRecognizer?.isEnabled = false
        }
    }

}
