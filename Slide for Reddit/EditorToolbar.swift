//
//  EditorToolbar.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/10/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class EditorToolbar {
    
    var textView: UITextView
    
    init(textView: UITextView){
        self.textView = textView
        addToolbarToTextView()
    }
    
    func addToolbarToTextView(){
        
        let scrollView = TouchUIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: textView.frame.size.width, height: 50))
        scrollView.contentSize = CGSize.init(width: 50 * 11, height: 50)
        scrollView.autoresizingMask = .flexibleWidth
        scrollView.backgroundColor = ColorUtil.backgroundColor
        var i = 0
        for button in ([
            generateButtons(image: "save", action: #selector(self.saveDraft(_:))),
            generateButtons(image: "folder", action: #selector(self.openDrafts(_:))),
            generateButtons(image: "image", action: #selector(self.uploadImage(_:))),
            generateButtons(image: "draw", action: #selector(self.draw(_:))),
            generateButtons(image: "link", action: #selector(self.link(_:))),
            generateButtons(image: "bold", action: #selector(self.bold(_:))),
            generateButtons(image: "italic", action: #selector(self.italics(_:))),
            generateButtons(image: "list", action: #selector(self.list(_:))),
            generateButtons(image: "list_number", action: #selector(self.numberedList(_:))),
            generateButtons(image: "size", action: #selector(self.size(_:))),
            generateButtons(image: "strikethrough", action: #selector(self.strike(_:)))]) {
                button.frame = CGRect.init(x: i * 50, y: 0, width: 50, height: 50);
                scrollView.addSubview(button)
                i += 1
        }
        textView.inputAccessoryView = scrollView
    }
    
    func generateButtons(image: String, action: Selector) -> UIButton {
        let more = UIButton.init(frame: CGRect.zero)
        more.setImage(UIImage.init(named: image)?.withColor(tintColor: ColorUtil.fontColor).imageResize(sizeChange: CGSize.init(width: 25, height: 25)), for: UIControlState.normal)
        more.addTarget(self, action: action, for: UIControlEvents.touchUpInside)
        more.isUserInteractionEnabled = true
        return more
    }
    
    func wrapIn(_ value: String){
        textView.replace(textView.selectedTextRange!, withText: value + textView.text(in: textView.selectedTextRange!)! + value)
    }
    
    func replaceIn(_ value: String, with: String){
        
    }

    
    @objc func saveDraft(_ sender: AnyObject){
        
    }
    
    @objc func openDrafts(_ sender: AnyObject){
        
    }
    
    @objc func uploadImage(_ sender: AnyObject){
        
    }
    
    @objc func draw(_ sender: AnyObject){
        
    }
    
    @objc func link(_ sender: AnyObject){
        
    }
    
    @objc func bold(_ sender: AnyObject){
        print("Bold")
        wrapIn("*")
    }
    
    @objc func italics(_ sender: AnyObject){
        wrapIn("**")
    }
    
    @objc func list(_ sender: AnyObject){
        replaceIn("\n", with: "\n* ")
    }
    
    @objc func numberedList(_ sender: AnyObject){
        replaceIn("\n", with: "\n1. ")

    }
    
    @objc func size(_ sender: AnyObject){
        replaceIn("\n", with: "\n#")
    }
    
    @objc func strike(_ sender: AnyObject){
        wrapIn("~~")
    }
    
}

class TouchUIScrollView: UIScrollView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        return false
    }
}
