//
//  EmbeddableMediaViewController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/9/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit
import Then
import Anchorage
import MaterialComponents.MaterialProgressView

struct EmbeddableMediaDataModel {
    var baseURL: URL?
    var lqURL: URL?
    var text: String?
    var inAlbum: Bool = false
}

class EmbeddableMediaViewController: UIViewController {

    var data: EmbeddableMediaDataModel!
    var contentType: ContentType.CType!
    var progressView: MDCProgressView = MDCProgressView()
    var bottomButtons = UIStackView()

    var commentCallback: (() -> Void)?

    init(model: EmbeddableMediaDataModel, type: ContentType.CType) {
        super.init(nibName: nil, bundle: nil)
        self.data = model
        self.contentType = type
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure views
        progressView.progress = 0
        progressView.trackTintColor = ColorUtil.accentColorForSub(sub: "").withAlphaComponent(0.3)
        progressView.progressTintColor = ColorUtil.accentColorForSub(sub: "")
//        progressView.frame = CGRect(x: 0, y: 5 + (UIApplication.shared.statusBarView?.frame.size.height ?? 20), width: 20, height: CGFloat(5))
        self.view.addSubview(progressView)

        progressView.topAnchor == view.safeTopAnchor
        progressView.horizontalAnchors == view.safeHorizontalAnchors
        progressView.heightAnchor == 5

        setProgressViewVisible(true)
    }

    func setProgressViewVisible(_ visible: Bool) {
        // Bring the loading indicator to the front
        self.view.bringSubview(toFront: progressView)
        progressView.setHidden(!visible, animated: true, completion: nil)
    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }

}

// MARK: - Actions
extension EmbeddableMediaViewController {
    
    func openComments(_ sender: AnyObject){
        if(commentCallback != nil){
            self.dismiss(animated: true) {
                self.commentCallback!()
            }
        }
    }

}
