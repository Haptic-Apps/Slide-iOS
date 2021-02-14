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
        .hardcodedChangelog(order: [
                                "Auto Cache 2.0",
                                "Desktop Mode",
                                "Account switcher",
                                "Threaded mail",
                                "New link previews",
                                "The details",
                            ], paragraphs: [
                                "Auto Cache 2.0": "AutoCache has been rewritten from the ground up, and Slide has a shiny new backend! Apart from improvements to Offline Mode, these changes will make Slide faster and more fluid",
                                "Desktop Mode": "iPad and M1-Mac users can try out Slide's new Desktop Mode, which keeps Slide's sidebar locked in view and adds right-click support to posts and comments",
                                "Account switcher": "Signed into your alt account but want to reply with your main? Swap into a different account for comment replies with the new account switcher",
                                "Threaded mail": "Your Slide inbox has been cleaned up, and will now display your messages as threads",
                                "New link previews": "Slide has a new text rendering engine, and Haptic (3D) Touch links have been re-written from the ground up! Try long-pressing on usernames to get a quick profile preview",
                                "The details": "• New option to “Hide all Images” in Card Layout settings\n• New “Quote” button for comment and submission replies\n• Slide now uses the iOS 14 image picker and support has been added for “Add Only” image permissions\n• “Hide Read Posts” will now keep your place in the subreddit view\n• Support for searching posts in a Multireddit\n• Support for image flairs in Comments\n• Support for setting your user flair in subreddits\n• Support for setting flair when submitting a new post\n• Rules will now display when posting to a subreddit\n• Fixed videos muting after a rotation\n• Fixed YouTube videos freezing in some cases\n• Fixed freezing issues triggered by some gestures options",
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
            UserDefaults.standard.set(true, forKey: "7.0.0")
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
        UserDefaults.standard.set(true, forKey: "7.0.0")
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
