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
        .splash(text: "Welcome to\nSlide v6", subText: "Swipe to see what's new", image: UIImage(named: "ic_retroapple")!),
        .video(text: "Subreddits have a new home!", subText: "Swipe from the left edge of the homepage to access your profile, search, and communities.", video: "v6howtonavigate", aspectRatio: 0.679),
        .hardcodedChangelog(order: ["Subreddits have a new home", "iOS 14 ready", "Your subreddits have a new look", "The details"], paragraphs: ["Subreddits have a new home": "Navigating your subreddits and favorite Slide features has never been easier! Simply swipe from the left edge of the homepage to view the new-and-improved navigation menu. \nClosed something by accident? Swipe from the right edge of any toolbar to go back to where you were!", "iOS 14 ready": "Cover your homescreen in widgets yet? We sure have. Be sure to check out the new Subreddit Shortcut and Hot Posts widgets!", "Your subreddits have a new look": "Subreddit colors and branding really come through in v6. Slide has already pulled themes from your favorite communities, but you can create your own styles using the improved Subreddit theme editor.", "The details": "• Search improvements across the board, including more accurate subreddit search results and quick previews of top search results when browsing posts\n• Gestures have been revamped, with a new style on submissions and improvements to the Gestures settings page\n• Pin your most-used Slide features to the navigation menu\n• Improved r/random support with a new navigation menu button\n• Media views will now show the title of the post you clicked from\n• New sorting indicators on the homepage and comments views\n• Added a History browser\n• Subreddit support for Siri Shortcuts\n• Redesigned split-page layout for iPad\n• Redesigned gestures system\n• Support for Reddit Galleries and Polls\n• Support for iPad Magic Keyboard\n• Pull-to-refresh is easier to do now\n• Reduced Slide’s memory usage by up to 70%\n• Bugs were squashed, performance was improved\n• Removed many bags of coffee (from my kitchen)"])
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
