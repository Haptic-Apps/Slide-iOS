//
//  OnboardingPageViewController.swift
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
 The type of content you want a page created for.
 If you make a new case, make a new VC in `OnboardingPageViewController+Pages.swift`.
 */
enum OnboardingPageViewModel {
    case feature(text: String, image: UIImage)
    case video(text: String, video: String)
    case changelog(link: Link)

    var viewController: UIViewController {
        switch self {
        case .feature(let text, let image):
            return OnboardingFeaturePageViewController(text: text, image: image)
        case .changelog(let link):
            return OnboardingChangelogPageViewController(link: link)
        case .video(let text, let video):
            return OnboardingVideoPageViewController(text: text, video: video)
        }
    }
}

class OnboardingPageViewController: UIPageViewController {

    private let models: [OnboardingPageViewModel]
    private let pages: [UIViewController]

    init(models: [OnboardingPageViewModel]) {
        self.models = models
        pages = models.map { $0.viewController }

        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }

    // Disable normal initializer
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        self.models = []
        self.pages = []
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
    }

}

extension OnboardingPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.indexes(of: viewController).first,
              index != 0 // Not at the first page
        else { return nil }
        return pages[index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.indexes(of: viewController).first,
              index != pages.count - 1 // Not at the last page
        else { return nil }

        return pages[index + 1]
    }
}
