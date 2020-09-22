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
        .splash(text: "Welcome to Slide v6", subText: "Swipe to see what's new", image: UIImage(named: "ic_retroapple")!),
        .video(text: "Subreddits have a new home!", subText: "Swipe from the left edge of the homepage to access your profile, search, and communities.", video: "v6howtonavigate", aspectRatio: 0.679)
    ]

    var pageViewController: OnboardingPageViewController!

    var finishButton = UIButton().then {
        $0.setTitle("Done", for: .normal)
        $0.accessibilityLabel = "Done"
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
    }

    private func setupConstraints() {
        batch {
            // Page view controller
            pageViewController.view.topAnchor == view.safeAreaLayoutGuide.topAnchor
            pageViewController.view.horizontalAnchors == view.horizontalAnchors

            // Finish button
            finishButton.topAnchor == pageViewController.view.bottomAnchor
            finishButton.horizontalAnchors == view.horizontalAnchors
            finishButton.bottomAnchor == view.safeAreaLayoutGuide.bottomAnchor
        }
    }

}
