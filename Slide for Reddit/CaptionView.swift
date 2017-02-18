//
//  ImageCounterView.swift
//  Money
//
//  Created by Kristian Angyal on 07/03/2016.
//  Copyright © 2016 Mail Online. All rights reserved.
//
import UIKit

class CaptionView: UIView {
    
    let captionLabel = UILabel()
    var text: String {
        didSet {
            updateLabel()
        }
    }
    
    override init(frame: CGRect) {
        text = ""
        super.init(frame: frame)
        
        configureLabel()
        updateLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureLabel() {
        self.addSubview(captionLabel)
    }
    
    func updateLabel() {
        captionLabel.numberOfLines = 0
        captionLabel.attributedText = NSAttributedString(string: text, attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 15, submission: false), NSForegroundColorAttributeName: UIColor.white])
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        captionLabel.frame = self.bounds
    }
}
