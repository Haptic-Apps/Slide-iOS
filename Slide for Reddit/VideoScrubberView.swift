//
//  VideoScrubberView.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/13/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import CoreMedia
import UIKit

protocol VideoScrubberViewDelegate: class {
    func sliderValueChanged(toSeconds: Float)
    func sliderDidBeginDragging()
    func sliderDidEndDragging()
    func toggleReturnPlaying() -> Bool
}

//extension UISlider {
//    var thumbCenterX: CGFloat {
//        let trackRect = self.trackRect(forBounds: frame)
//        let thumbRect = self.thumbRect(forBounds: bounds, trackRect: trackRect, value: value)
//        return thumbRect.midX
//    }
//}

extension UIImage {
    class func image(with color: UIColor) -> UIImage {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 1, height: 1))
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!

        context.setFillColor(color.cgColor)
        context.fill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image!
    }
}

class VideoScrubberView: UIView {

    weak var delegate: VideoScrubberViewDelegate?
    var totalDuration: CMTime = CMTime()
    private var elapsedDuration: CMTime = CMTime()
    private let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()

    var slider: ThickSlider = ThickSlider()
    var timeElapsedLabel = UILabel()
    var timeTotalLabel = UILabel()

    var timeElapsedRightConstraint: NSLayoutConstraint?

    var playButton = UIButton(type: .system)

    let playButtonImage = UIImage(named: "play")?.getCopy(withSize: .square(size: 45))
    let pauseButtonImage = UIImage(named: "pause")?.getCopy(withSize: .square(size: 45))
    let largeThumbImage = UIImage(named: "circle")?.getCopy(withSize: .square(size: 30), withColor: .white)
    let smallThumbImage = UIImage(named: "circle")?.getCopy(withSize: .square(size: 20), withColor: .white)
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        slider.tintColor = ColorUtil.accentColorForSub(sub: "")
//        slider.setThumbImage(UIImage(named: "circle")?.getCopy(withSize: .square(size: 72), withColor: slider.tintColor), for: .normal)
        slider.minimumValue = 0
        slider.maximumValue = 1
//        slider.isContinuous = true
//        slider.setThumbImage(UIImage(), for: .normal)
//        slider.setMinimumTrackImage(UIImage.image(with: slider.tintColor).getCopy(withSize: .square(size: 72)), for: .normal)
//        slider.setMaximumTrackImage(UIImage.image(with: slider.tintColor.withAlphaComponent(0.4)).getCopy(withSize: .square(size: 72)), for: .normal)
//        slider.thumbTintColor = ColorUtil.accentColorForSub(sub: "")
        slider.minimumTrackTintColor = ColorUtil.accentColorForSub(sub: "")
        slider.maximumTrackTintColor = ColorUtil.accentColorForSub(sub: "").withAlphaComponent(0.4)
        slider.setThumbImage(UIImage.init(named: "circle")?.getCopy(withSize: CGSize.square(size: 20), withColor: .white), for: .normal)
        self.addSubview(slider)
        
        self.addSubview(playButton)
        self.addSubview(timeTotalLabel)
        slider.rightAnchor == self.rightAnchor - 8
        slider.heightAnchor == 24
        slider.bottomAnchor == self.bottomAnchor - 4
        slider.leftAnchor == timeTotalLabel.rightAnchor + 8
        
        //timeElapsedLabel.font = UIFont.boldSystemFont(ofSize: 12)
        //timeElapsedLabel.textAlignment = .center
        //timeElapsedLabel.textColor = UIColor.white
        //self.addSubview(timeElapsedLabel)
        //timeElapsedLabel.centerYAnchor == slider.centerYAnchor
        //timeElapsedLabel.leftAnchor >= slider.leftAnchor ~ .high
//        timeElapsedRightConstraint = timeElapsedLabel.rightAnchor == CGFloat(slider.thumbCenterX - 16) ~ .low
//        slider

        timeTotalLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: UIFont.Weight(rawValue: 10))
        timeTotalLabel.textAlignment = .center
        timeTotalLabel.textColor = UIColor.white

        timeTotalLabel.centerYAnchor == slider.centerYAnchor + 1
        timeTotalLabel.leftAnchor == self.leftAnchor + 8

        playButton.setImage(UIImage.init(named: "pause")?.getCopy(withSize: CGSize.square(size: 45)), for: .normal)
        playButton.tintColor = UIColor.white
        playButton.addTarget(self, action: #selector(playButtonTapped(_:)), for: .touchUpInside)

        playButton.sizeAnchors == .square(size: 60)
        playButton.clipsToBounds = true
        playButton.layer.cornerRadius = 30
        playButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderDidBeginDragging(_:)), for: .touchDown)
        slider.addTarget(self, action: #selector(sliderDidEndDragging(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
        
        let blurView = UIVisualEffectView(frame: UIScreen.main.bounds)
        blurEffect.setValue(3, forKeyPath: "blurRadius")
        blurView.effect = blurEffect
        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = 30
        //self.insertSubview(blurView, at: 0)
       // blurView.edgeAnchors == playButton.edgeAnchors
       // self.bringSubview(toFront: playButton)
    }
    
    func updateWithTime(elapsedTime: CMTime) {
        if CMTIME_IS_INVALID(elapsedTime) {
            slider.minimumValue = 0.0
            return
        }
        elapsedDuration = elapsedTime
        let duration = Float(CMTimeGetSeconds(totalDuration))
        let time = Float(CMTimeGetSeconds(elapsedTime))
        
        if duration.isFinite && duration > 0 {
            slider.minimumValue = 0.0
            slider.maximumValue = duration
            slider.setValue(time, animated: true)
            timeTotalLabel.text = "-\(getTimeString(Int(floor(1 + duration - time))))"
        }
    }

    fileprivate func getTimeString(_ time: Int) -> String {
        let h = time / 3600
        let m = (time % 3600) / 60
        let s = (time % 3600) % 60
        return h > 0 ? String(format: "%1d:%02d:%02d", h, m, s) : String(format: "%1d:%02d", m, s)
    }

    func setPlayButton() {
        playButton.setImage(playButtonImage, for: .normal)
    }

    func setPauseButton() {
        playButton.setImage(pauseButtonImage, for: .normal)
    }
}

extension VideoScrubberView {
    @objc func sliderValueChanged(_ sender: ThickSlider) {
        delegate?.sliderValueChanged(toSeconds: sender.value)
        timeTotalLabel.text = "+\(getTimeString(Int(floor(sender.value))))"
    }

    @objc func sliderDidBeginDragging(_ sender: ThickSlider) {
        delegate?.sliderDidBeginDragging()
        slider.setThumbImage(largeThumbImage, for: .normal)
        UIView.animate(withDuration: 0.3) {
            self.playButton.isHidden = true
        }
    }

    @objc func sliderDidEndDragging(_ sender: ThickSlider) {
        delegate?.sliderDidEndDragging()
        slider.setThumbImage(smallThumbImage, for: .normal)
        UIView.animate(withDuration: 0.3) {
            self.playButton.isHidden = false
        }
    }

    @objc func playButtonTapped(_ sender: UIButton) {
        if let delegate = delegate {
            if delegate.toggleReturnPlaying() {
                setPauseButton()
            } else {
                setPlayButton()
            }
        }
    }
}

public class ThickSlider: UISlider {
    override public func trackRect(forBounds bounds: CGRect) -> CGRect {
        var result = super.trackRect(forBounds: bounds)
        result.size.height = 4
        return result
    }
}
