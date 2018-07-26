//
//  EmbeddableMediaViewController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/9/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import MaterialComponents.MaterialProgressView
import Then
import UIKit

struct EmbeddableMediaDataModel {
    var baseURL: URL?
    var lqURL: URL?
    var text: String?
    var inAlbum: Bool = false
}

class EmbeddableMediaViewController: UIViewController {

    var data: EmbeddableMediaDataModel!
    var contentType: ContentType.CType!
    var progressView: UIView = UIView()
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
        progressView = UIView()
        self.view.addSubview(progressView)
        progressView.widthAnchor == 60
        progressView.heightAnchor == 60
        progressView.centerAnchors == self.view.centerAnchors
        progressView.layer.cornerRadius = 30
        progressView.alpha = 0.5
        progressView.isHidden = true
        updateProgress(0)
        setProgressViewVisible(true)
    }
    
    func updateProgress(_ percent: CGFloat) {
        print("Updating to \(percent)")
        let startAngle = -CGFloat.pi / 2

        let center = CGPoint (x: 60 / 2, y: 60 / 2)
        let radius = CGFloat(60 / 2)
        let arc = CGFloat.pi * CGFloat(2) * percent
        
        let cPath = UIBezierPath()
        cPath.move(to: center)
        cPath.addLine(to: CGPoint(x: center.x + radius * cos(startAngle), y: center.y + radius * sin(startAngle)))
        cPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: arc + startAngle, clockwise: true)
        cPath.addLine(to: CGPoint(x: center.x, y: center.y))
        
        let circleShape = CAShapeLayer()
        circleShape.path = cPath.cgPath
        circleShape.strokeColor = UIColor.white.cgColor
        circleShape.fillColor = UIColor.white.cgColor
        circleShape.lineWidth = 1.5
        // add sublayer
        for layer in progressView.layer.sublayers ?? [CALayer]() {
            layer.removeFromSuperlayer()
        }
        progressView.layer.addSublayer(circleShape)
    }

    func setProgressViewVisible(_ visible: Bool) {
        // Bring the loading indicator to the front
        self.view.bringSubview(toFront: progressView)
        if visible {
            progressView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            progressView.isHidden = false
            UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                self.progressView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
        } else {
            UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                self.progressView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            }) {
                (_) in
                self.progressView.isHidden = true
            }
        }
    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }

}

// MARK: - Actions
extension EmbeddableMediaViewController {
    
    func openComments(_ sender: AnyObject) {
        if commentCallback != nil {
            self.dismiss(animated: true) {
                self.commentCallback!()
            }
        }
    }

}
