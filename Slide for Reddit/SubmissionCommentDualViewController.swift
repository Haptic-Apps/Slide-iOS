//
//  SubmissionCommentDualViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 10/2/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import UIKit

public class SubmissionCommentDualViewController: UIViewController {
    
    var leftContainerView = UIView()
    var rightContainerView = UIView()

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        view.addSubview(leftContainerView)
        view.addSubview(rightContainerView)
        
        leftContainerView.widthAnchor == self.view.widthAnchor * 0.33
        
        leftContainerView.leftAnchor == self.view.leftAnchor
        leftContainerView.verticalAnchors == self.view.verticalAnchors
        rightContainerView.leftAnchor == self.leftContainerView.rightAnchor
        rightContainerView.rightAnchor == self.view.rightAnchor
        rightContainerView.verticalAnchors == self.view.verticalAnchors
    }

    var submissionsViewController: SingleSubredditViewController? {
        willSet {
            guard let child = submissionsViewController else { return }
            child.willMove(toParentViewController: nil)
            child.view.removeFromSuperview()
            child.removeFromParentViewController()
        }
        
        didSet {
            guard let child = submissionsViewController else { return }
            
            loadViewIfNeeded() // Make sure the view is loaded
            addChildViewController(child)
            leftContainerView.addSubview(child.view)
            child.view.edgeAnchors == self.leftContainerView.edgeAnchors
            child.didMove(toParentViewController: self)
        }
    }
    
    var commentsViewController: UIViewController? {
        willSet {
            guard let child = commentsViewController else { return }
            child.willMove(toParentViewController: nil)
            child.view.removeFromSuperview()
            child.removeFromParentViewController()
        }
        
        didSet {
            guard let child = commentsViewController else { return }
            
            loadViewIfNeeded() // Make sure the view is loaded
            addChildViewController(child)
            rightContainerView.addSubview(child.view)
            child.view.edgeAnchors == self.rightContainerView.edgeAnchors
            child.didMove(toParentViewController: self)
        }
    }
}
