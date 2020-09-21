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
        .video(text: "Welcome to slide v6", video: "v6howtonavigate")
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
