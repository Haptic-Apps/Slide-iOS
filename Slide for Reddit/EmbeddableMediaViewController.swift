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
    var buttons: Bool = true
}

class EmbeddableMediaViewController: UIViewController {

    var data: EmbeddableMediaDataModel!
    var contentType: ContentType.CType!
    var progressView: VerticalAlignedLabel = VerticalAlignedLabel()
    var bottomButtons = UIStackView()

    var commentCallback: (() -> Void)?
    var upvoteCallback: (() -> Void)?
    var isUpvoted = false
    var failureCallback: ((_ url: URL) -> Void)? 

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
        progressView = VerticalAlignedLabel()
        self.view.addSubview(progressView)
        progressView.widthAnchor == 90
        progressView.heightAnchor == 80
        progressView.centerAnchors == self.view.centerAnchors
        progressView.layer.cornerRadius = 30
        progressView.alpha = 0.5
        progressView.isHidden = true
        updateProgress(0, "")
        progressView.font = UIFont.boldSystemFont(ofSize: 12)
        progressView.textColor = .white
        setProgressViewVisible(true)
        progressView.textAlignment = .center
        progressView.contentMode = .bottom
    }
    
    func updateProgress(_ percent: CGFloat, _ total: String) {
        let startAngle = -CGFloat.pi / 2

        let center = CGPoint (x: 90 / 2, y: 60 / 2)
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
        if !total.isEmpty {
            progressView.text = total
        }
    }

    func setProgressViewVisible(_ visible: Bool) {
        // Bring the loading indicator to the front
        self.view.bringSubviewToFront(progressView)
        if visible {
            progressView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            progressView.isHidden = false
            UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                self.progressView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
        } else {
            UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                self.progressView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            }, completion: { _ in
                self.progressView.isHidden = true
            })
        }
    }
    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }

}

// MARK: - Actions
extension EmbeddableMediaViewController {
    
    @objc func openComments(_ sender: AnyObject) {
        if commentCallback != nil {
            var viewToMove: UIView
            if self is ImageMediaViewController {
                viewToMove = (self as! ImageMediaViewController).imageView
            } else {
                viewToMove = (self as! VideoMediaViewController).isYoutubeView ? (self as! VideoMediaViewController).youtubeView : (self as! VideoMediaViewController).videoView
            }
            var newFrame = viewToMove.frame
            newFrame.origin.y = -newFrame.size.height * 0.2
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
                viewToMove.frame = newFrame
                self.parent?.view.alpha = 0
                self.dismiss(animated: true)
            }) { (_) in
                self.commentCallback!()
            }
        }
    }
    
    @objc func upvote(_ sender: AnyObject) {
        if upvoteCallback != nil {
            self.upvoteCallback!()
            var viewToMove: UIView
            if self is ImageMediaViewController {
                viewToMove = (self as! ImageMediaViewController).imageView
            } else {
                viewToMove = (self as! VideoMediaViewController).isYoutubeView ? (self as! VideoMediaViewController).youtubeView : (self as! VideoMediaViewController).videoView
            }
            var newFrame = viewToMove.frame
            newFrame.origin.y = -newFrame.size.height * 0.2
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
                viewToMove.frame = newFrame
                self.parent?.view.alpha = 0
                self.dismiss(animated: true)
            }) { (_) in
            }
        }
    }
}
class VerticalAlignedLabel: UILabel {
    
    override func drawText(in rect: CGRect) {
        var newRect = rect
        switch contentMode {
        case .top:
            newRect.size.height = sizeThatFits(rect.size).height
        case .bottom:
            let size = sizeThatFits(rect.size)
            let height = size.height
            newRect.origin.y += rect.size.height - height
            newRect.size.height = height
            newRect.size.width = size.width
            newRect.origin.x = (rect.size.width / 2) - (size.width / 2)
        default:
            ()
        }
        
        super.drawText(in: newRect)
    }
}
