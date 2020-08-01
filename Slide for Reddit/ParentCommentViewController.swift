//
//  ParentCommentViewController.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 7/29/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//
import Foundation
import UIKit

class ParentCommentViewController: UIViewController {
    var childView = UIView()
    var scrollView = UIScrollView()
    var estimatedSize: CGSize
    var parentContext: String = ""
    var dismissHandler: (() -> Void)?
    
    init(view: UIView, size: CGSize) {
        self.estimatedSize = size
        super.init(nibName: nil, bundle: nil)
        self.childView = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView = UIScrollView().then {
            $0.backgroundColor = ColorUtil.theme.foregroundColor
            $0.isUserInteractionEnabled = true
        }
        self.view.addSubview(scrollView)
//        scrollView.edgeAnchors == self.view.edgeAnchors
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollView.addSubview(childView)
        // TODO: Fix: Not able to do this.
//        childView.widthAnchor == estimatedSize.width
//        childView.heightAnchor == estimatedSize.height
        childView.topAnchor == scrollView.topAnchor
        scrollView.contentSize = estimatedSize
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissHandler?()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
