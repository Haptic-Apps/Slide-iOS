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
    var progressType: SettingValues.SubmissionAction!
    
    var progress: Float = 0 {
        didSet(newValue) {
            progressLayer.strokeEnd = CGFloat(newValue)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        progressType = .NONE
        cPath = UIBezierPath()
        self.addShapeLayers()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        progressType = .NONE
        cPath = UIBezierPath()
        self.addShapeLayers()
    }
    
    func addShapeLayers() {
        createLinePath(xStart: 0, xEnd: self.frame.width)
        
        baseLayer = CAShapeLayer()
        baseLayer.path = cPath.cgPath
        baseLayer.lineWidth = self.frame.height
        baseLayer.fillColor = nil
        baseLayer.strokeColor = UIColor(hexString: "#A5A4A4").withAlphaComponent(0.3).cgColor
        
        progressLayer = CAShapeLayer()
        progressLayer.path = cPath.cgPath
        progressLayer.lineCap = kCALineCapButt
        progressLayer.lineWidth = self.frame.height
        progressLayer.fillColor = nil
        progressLayer.strokeColor = UIColor(hexString: "#A5A4A4").withAlphaComponent(0.6).cgColor
        progressLayer.strokeEnd = 0.0
        
        self.layer.addSublayer(baseLayer)
        self.layer.addSublayer(progressLayer)
    }
    
    private func createLinePath(xStart: CGFloat, xEnd: CGFloat) {
        cPath.removeAllPoints()
        cPath.move(to: CGPoint(x: xStart, y: self.frame.height / 2))
        cPath.addLine(to: CGPoint(x: xEnd, y: self.frame.height / 2))
    }
    
    func setMode(type: SettingValues.SubmissionAction, flip: Bool = false) {
        progressType = type
        var xStart: CGFloat!
        var xEnd: CGFloat!
        var color: UIColor!
        
        if flip {
            xStart = self.frame.width
            xEnd = 0
        } else {
            xStart = 0
            xEnd = self.frame.width
        }
        color = type.getColor()
        
        if type == .NONE {
            color = ColorUtil.foregroundColor
        }

        if flip {
            createLinePath(xStart: xStart, xEnd: xEnd)
            baseLayer.path = cPath.cgPath
            progressLayer.path = cPath.cgPath
        }
        
        progressLayer.strokeColor = type == .NONE ? color.withAlphaComponent(0).cgColor : color.cgColor
    }
}
