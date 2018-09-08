//
//  ProgressBarView.swift
//  progressBar
//
//  Created by ashika shanthi on 1/4/18.
//  Copyright © 2018 ashika shanthi. All rights reserved.
//
//  adapted from https://github.com/ashika01/ios-tutorials/blob/master/CustomProgressBar/progressBar/ProgressBarView.swift
//

import UIKit

class ProgressBarView: UIView {
    var cPath: UIBezierPath!
    var baseLayer: CAShapeLayer!
    var progressLayer: CAShapeLayer!
    
    var progress: Float = 0 {
        willSet(newValue) {
            progressLayer.strokeEnd = CGFloat(newValue)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        cPath = UIBezierPath()
        self.addShapeLayers()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        cPath = UIBezierPath()
        self.addShapeLayers()
    }
    
    func addShapeLayers() {
        createCirclePath(startAngle: -1 * CGFloat.pi / 2, endAngle: 3 * CGFloat.pi / 2, clockwise: true)
        
        baseLayer = CAShapeLayer()
        baseLayer.path = cPath.cgPath
        baseLayer.lineWidth = self.frame.width / 6
        baseLayer.fillColor = nil
        baseLayer.strokeColor = UIColor(hexString: "#FF8b60").withAlphaComponent(0.4).cgColor
        
        progressLayer = CAShapeLayer()
        progressLayer.path = cPath.cgPath
        progressLayer.lineCap = kCALineCapRound
        progressLayer.lineWidth = self.frame.width / 6
        progressLayer.fillColor = nil
        progressLayer.strokeColor = UIColor(hexString: "#FF8b60").cgColor
        progressLayer.strokeEnd = 0.0
        
        self.layer.addSublayer(baseLayer)
        self.layer.addSublayer(progressLayer)
    }
    
    private func createCirclePath(startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool) {
        let x = self.frame.width / 2
        let y = self.frame.height / 2
        let center = CGPoint(x: x, y: y)
        cPath.removeAllPoints()
        cPath.addArc(withCenter: center, radius: x * 2 / 3, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
        cPath.close()
    }
    
    func setMode(upvote: Bool) {
        if upvote {
            createCirclePath(startAngle: -1 * CGFloat.pi / 2, endAngle: 3 * CGFloat.pi / 2, clockwise: true)
            baseLayer.path = cPath.cgPath
            baseLayer.strokeColor = UIColor(hexString: "#FF8b60").withAlphaComponent(0.4).cgColor
            progressLayer.path = cPath.cgPath
            progressLayer.strokeColor = UIColor(hexString: "#FF8b60").cgColor
        } else {
            createCirclePath(startAngle: 3 * CGFloat.pi / 2, endAngle: -1 * CGFloat.pi / 2, clockwise: false)
            baseLayer.path = cPath.cgPath
            baseLayer.strokeColor = UIColor(hexString: "#9494FF").withAlphaComponent(0.4).cgColor
            progressLayer.path = cPath.cgPath
            progressLayer.strokeColor = UIColor(hexString: "#9494FF").cgColor
        }
    }
}
