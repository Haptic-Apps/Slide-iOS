//
//  ModalMediaViewController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/9/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import Then
import UIKit

class ModalMediaViewController: UIViewController {

//    var loadedURL: URL?

    var embeddedVC: EmbeddableMediaViewController!
    var fullscreen = false

    private var savedColor: UIColor?

    init(model: EmbeddableMediaDataModel) {
        super.init(nibName: nil, bundle: nil)
        
        let contentType = ContentType.getContentType(baseUrl: model.baseURL)
        embeddedVC = ModalMediaViewController.getVCForContent(ofType: contentType, withModel: model)
        if embeddedVC == nil {
            fatalError("embeddedVC should be populated!")
        }
    }
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
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
        
        if parent is AlbumViewController || parent is ShadowboxLinkViewController {
            self.embeddedVC.navigationBar.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 11.0, *) {
            self.setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
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

        embeddedVC.navigationBar = UINavigationBar.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: 56))
        embeddedVC.navigationBar.setBackgroundImage(UIImage(), for: .default)
        embeddedVC.navigationBar.shadowImage = UIImage()
        embeddedVC.navigationBar.isTranslucent = true
        let navItem = UINavigationItem(title: "")
        let close = UIButton.init(type: .custom)
        close.setImage(UIImage.init(named: "close")?.navIcon(), for: UIControlState.normal)
        close.addTarget(self, action: #selector(self.exit), for: UIControlEvents.touchUpInside)
        close.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let closeB = UIBarButtonItem.init(customView: close)
        navItem.leftBarButtonItem = closeB
        
        embeddedVC.navigationBar.setItems([navItem], animated: false)
        self.view.addSubview(embeddedVC.navigationBar)
        
        embeddedVC.navigationBar.topAnchor == self.view.safeTopAnchor
        embeddedVC.navigationBar.horizontalAnchors == self.view.horizontalAnchors
    }
    
    func exit() {
        self.dismiss(animated: true, completion: nil)
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

            (self.parent as? SwipeDownModalVC)?.background?.alpha = 1
            self.embeddedVC.bottomButtons.alpha = 0
            self.embeddedVC.navigationBar.alpha = 0.2
        }, completion: {_ in
            self.embeddedVC.bottomButtons.isHidden = true
        })
    }

    func unFullscreen(_ sender: AnyObject) {
        fullscreen = false
        self.embeddedVC.bottomButtons.isHidden = false
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
            statusBar.isHidden = false
            self.embeddedVC.navigationBar.alpha = 1

            (self.parent as? SwipeDownModalVC)?.background?.alpha = 0.6
            self.embeddedVC.bottomButtons.alpha = 1
            self.embeddedVC.progressView.alpha = 0.7

        }, completion: {_ in
        })
    }
    
}
