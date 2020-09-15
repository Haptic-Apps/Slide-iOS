//
//  OnboardingPageViewController+Pages.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 9/15/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Anchorage
import reddift
import Then
import UIKit

/**
 ViewController for a single page in the OnboardingPageViewController.
 Describes a single feature with text and an image.
 */
class OnboardingFeaturePageViewController: UIViewController {
    let text: String
    let image: UIImage

    init(text: String, image: UIImage) {
        self.text = text
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        self.text = ""
        self.image = UIImage()
        super.init(coder: coder)
    }
}

/**
 ViewController for a single page in the OnboardingPageViewController.
 Describes the app's latest changelog.
 */
class OnboardingChangelogPageViewController: UIViewController {
    let link: Link

    init(link: Link) {
        self.link = link
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        self.link = Link(id: "")
        super.init(coder: coder)
    }
}
