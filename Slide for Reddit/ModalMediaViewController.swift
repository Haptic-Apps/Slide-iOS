//
//  ModalMediaViewController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/9/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit
import Then
import Anchorage

class ModalMediaViewController: UIViewController {

//    var loadedURL: URL?

    var embeddedVC: EmbeddableMediaViewController!
    var fullscreen = false

    private var savedColor : UIColor?

    init(model: EmbeddableMediaDataModel) {
        super.init(nibName: nil, bundle: nil)
        
        let contentType = ContentType.getContentType(baseUrl: model.baseURL)
        embeddedVC = ModalMediaViewController.getVCForContent(ofType: contentType, withModel: model)
        if embeddedVC == nil {
            fatalError("embeddedVC should be populated!")
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()
        configureLayout()
        connectGestures()
    }

    override func viewWillAppear(_ animated: Bool) {
        savedColor = UIApplication.shared.statusBarView?.backgroundColor
        UIApplication.shared.statusBarView?.backgroundColor = .clear
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        UIApplication.shared.statusBarView?.isHidden = false
        if savedColor != nil {
            UIApplication.shared.statusBarView?.backgroundColor = savedColor
        }
    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }

    func configureViews() {

        self.addChildViewController(embeddedVC)
        embeddedVC.didMove(toParentViewController: self)
        self.view.addSubview(embeddedVC.view)

    }

    func configureLayout() {
        embeddedVC.view.edgeAnchors == self.view.edgeAnchors
    }

    func connectGestures() {
        (parent as? SwipeDownModalVC)?.didStartPan = { [weak self] result in
            if let strongSelf = self {
                strongSelf.unFullscreen(strongSelf.embeddedVC.view)
            }
        }
    }

    static func getVCForContent(ofType type: ContentType.CType, withModel model: EmbeddableMediaDataModel) -> EmbeddableMediaViewController? {
        switch type {
        case .IMAGE, .IMGUR:
            // Still image (possibly low quality)
            return ImageMediaViewController(model: model, type: type)
        case .GIF, .STREAMABLE, .VID_ME, .VIDEO:
            // Gif / video / youtube video
            return VideoMediaViewController(model: model, type: type)
        default:
            return nil
        }
    }

}

// MARK: - Actions
extension ModalMediaViewController {

    func fullscreen(_ sender: AnyObject) {
        fullscreen = true
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
            statusBar.isHidden = true

            (self.parent as? SwipeDownModalVC)?.background?.backgroundColor = UIColor.black
            //            self.toolbar.alpha = 0

        }, completion: {finished in
            //            self.toolbar.isHidden = true

        })
    }

    func unFullscreen(_ sender: AnyObject) {
        fullscreen = false
        //        self.toolbar.isHidden = false
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
            statusBar.isHidden = false

            (self.parent as? SwipeDownModalVC)?.background?.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            //            self.toolbar.alpha = 1

        }, completion: {finished in
        })
    }
    
}
