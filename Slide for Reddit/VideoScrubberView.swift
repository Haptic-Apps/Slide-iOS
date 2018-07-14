//
//  VideoScrubberView.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/13/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit
import CoreMedia
import Anchorage

protocol VideoScrubberViewDelegate {
    func sliderValueChanged(toSeconds: Float)
    func sliderDidBeginDragging()
    func sliderDidEndDragging()
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
        let rect = CGRect(origin: CGPoint(x: 0, y:0), size: CGSize(width: 1, height: 1))
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

    var delegate: VideoScrubberViewDelegate?
    var totalDuration: CMTime = CMTime()
    private var elapsedDuration: CMTime = CMTime()

    var slider: ThickSlider = ThickSlider()
    var timeElapsedLabel = UILabel()
    var timeTotalLabel = UILabel()

    var timeElapsedRightConstraint: NSLayoutConstraint?

    var playButton = UIButton(type: .system)

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 72) // Maybe 48
    }

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
//        slider.minimumTrackTintColor = ColorUtil.accentColorForSub(sub: "")
//        slider.maximumTrackTintColor = ColorUtil.accentColorForSub(sub: "").withAlphaComponent(0.4)
        self.addSubview(slider)

        slider.verticalAnchors == self.verticalAnchors
        slider.horizontalAnchors == self.horizontalAnchors + 16

        timeElapsedLabel.font = UIFont.boldSystemFont(ofSize: 12)
        timeElapsedLabel.textAlignment = .center
        timeElapsedLabel.textColor = UIColor.white
        self.addSubview(timeElapsedLabel)

        timeElapsedLabel.centerYAnchor == slider.centerYAnchor
        timeElapsedLabel.leftAnchor >= slider.leftAnchor ~ .high
//        timeElapsedRightConstraint = timeElapsedLabel.rightAnchor == CGFloat(slider.thumbCenterX - 16) ~ .low
//        slider

        timeTotalLabel.font = UIFont.boldSystemFont(ofSize: 12)
        timeTotalLabel.textAlignment = .center
        timeTotalLabel.textColor = UIColor.white
        self.addSubview(timeTotalLabel)

        timeTotalLabel.centerYAnchor == slider.centerYAnchor
        timeTotalLabel.rightAnchor == slider.rightAnchor - 16

        playButton.setImage(UIImage.init(named: "pause"), for: .normal)
        playButton.tintColor = UIColor.white
        playButton.addTarget(self, action: #selector(playButtonTapped(_:)), for: .touchUpInside)
        self.addSubview(playButton)

        playButton.sizeAnchors == .square(size: 32)
        playButton.leftAnchor == slider.leftAnchor + 16
        playButton.centerYAnchor == slider.centerYAnchor

        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderDidBeginDragging(_:)), for: .editingDidBegin)
        slider.addTarget(self, action: #selector(sliderDidEndDragging(_:)), for: .editingDidEnd)
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
            timeElapsedLabel.text = getTimeString(time)
            timeTotalLabel.text = "-\(getTimeString(1 + duration - time))"
        }
    }

    private func getTimeString(_ time: Float) -> String {
        let totalTime = Int(floor(time))
        var minutes = Double(totalTime) / 60
        let seconds = totalTime % 60
        if(totalTime < 60){
            minutes = 0
        }

        return String(format:"%02d:%02d", minutes, seconds)
    }

}

extension VideoScrubberView {
    func sliderValueChanged(_ sender: ThickSlider) {
        delegate?.sliderValueChanged(toSeconds: sender.value)
    }

    func sliderDidBeginDragging(_ sender: ThickSlider) {
        delegate?.sliderDidBeginDragging()
    }

    func sliderDidEndDragging(_ sender: ThickSlider) {
        delegate?.sliderDidEndDragging()
    }

    func playButtonTapped(_ sender: UIButton) {
        
    }
}

public class ThickSlider : UIControl {

    var minimumValue: Float = 0 {
        didSet {
//            setNeedsDisplay()
        }
    }
    var maximumValue: Float = 1 {
        didSet {
//            setNeedsDisplay()
        }
    }

    var value: Float = 0 {
        didSet {
            setNeedsDisplay()
//            sendActions(for: .valueChanged)
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setValue(_ newValue: Float, animated: Bool) {
        value = newValue
    }

//    func positionForValue(value: Float) -> CGFloat {
//        return bounds.width * CGFloat((value - minimumValue) / (maximumValue - minimumValue))
//    }

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override public func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        ctx!.clear(rect)

        let bgPath = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.size.height / 2)

        // Clip
        let layerMask = CAShapeLayer()
        layerMask.path = bgPath.cgPath
        layer.mask = layerMask

        // Background
        tintColor.withAlphaComponent(0.4).setFill()
        bgPath.fill()

        // Foreground
        tintColor.setFill()
        let prog: CGFloat = CGFloat((value - minimumValue) / (maximumValue - minimumValue))
        let fgRect = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.size.width * prog, height: bounds.size.height)
        let fgPath = UIBezierPath(rect: fgRect)

        fgPath.fill()
    }

    func lerp(low: Float, high: Float, t: Float) -> Float {
        return low * (1 - t) + high * t
    }
}

extension ThickSlider {
    override public func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        sendActions(for: .editingDidBegin)
        return true
    }

    override public func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let loc = touch.location(in: self)

        var v = Float(loc.x) / Float(size.width)
        v = max(v, 0)
        v = min(v, 1)

        value = lerp(low: minimumValue, high: maximumValue, t: v)
        self.setNeedsDisplay()
        sendActions(for: .valueChanged)

        return true
    }

    override public func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        sendActions(for: .editingDidEnd)
    }
//    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//
//        if let touch = touches.first {
//            let loc = touch.location(in: self)
//
//            var v = Float(loc.x) / Float(size.width)
//            v = max(v, 0)
//            v = min(v, 1)
//
//            value = lerp(low: minimumValue, high: maximumValue, t: v)
//            self.setNeedsDisplay()
//            sendActions(for: .valueChanged)
//
//        }
//    }
//    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        sendActions(for: .editingDidBegin)
//    }
//
//    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if touches.count == 0 {
//            sendActions(for: .editingDidEnd)
//        }
//    }
}
