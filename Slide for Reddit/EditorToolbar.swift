//
//  EditorToolbar.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/10/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class EditorToolbar : NSObject {
    
    var textView: UITextView
    
    init(textView: UITextView){
        self.textView = textView
        super.init()
        self.addToolbarToTextView()
    }
    
    func addToolbarToTextView(){
        
        let scrollView = TouchUIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: textView.frame.size.width, height: 50))
        scrollView.contentSize = CGSize.init(width: 50 * 11, height: 50)
        scrollView.autoresizingMask = .flexibleWidth
        scrollView.backgroundColor = ColorUtil.backgroundColor
        var i = 0
        for button in ([
            generateButtons(image: "save", action: #selector(saveDraft(_:))),
            generateButtons(image: "folder", action: #selector(openDrafts(_:))),
            generateButtons(image: "image", action: #selector(uploadImage(_:))),
            generateButtons(image: "draw", action: #selector(draw(_:))),
            generateButtons(image: "link", action: #selector(link(_:))),
            generateButtons(image: "bold", action: #selector(bold(_:))),
            generateButtons(image: "italic", action: #selector(italics(_:))),
            generateButtons(image: "list", action: #selector(list(_:))),
            generateButtons(image: "list_number", action: #selector(numberedList(_:))),
            generateButtons(image: "size", action: #selector(size(_:))),
            generateButtons(image: "strikethrough", action: #selector(strike(_:)))]) {
                button.frame = CGRect.init(x: i * 50, y: 0, width: 50, height: 50);
                scrollView.addSubview(button)
                button.isUserInteractionEnabled = true
                i += 1
        }
        scrollView.delaysContentTouches = false
        textView.inputAccessoryView = scrollView
    }
    
    func generateButtons(image: String, action: Selector) -> UIButton {
        let more = UIButton.init(frame: CGRect.zero)
        more.setImage(UIImage.init(named: image)?.withColor(tintColor: ColorUtil.fontColor).imageResize(sizeChange: CGSize.init(width: 25, height: 25)), for: UIControlState.normal)
        more.addTarget(self, action: action, for: UIControlEvents.touchUpInside)
        return more
    }
    
    func wrapIn(_ value: String){
        textView.replace(textView.selectedTextRange!, withText: value + textView.text(in: textView.selectedTextRange!)! + value)
    }
    
    func replaceIn(_ value: String, with: String){
        
    }

    
    func saveDraft(_ sender: AnyObject){
        
    }
    
    func openDrafts(_ sender: AnyObject){
        
    }
    
    func uploadImage(_ sender: AnyObject){
        
    }
    
    func draw(_ sender: AnyObject){
        
    }
    
    func link(_ sender: AnyObject){
        
    }
    
    func bold(_ sender: AnyObject){
        print("Bold")
        wrapIn("*")
    }
    
    func italics(_ sender: AnyObject){
        wrapIn("**")
    }
    
    func list(_ sender: AnyObject){
        replaceIn("\n", with: "\n* ")
    }
    
    func numberedList(_ sender: AnyObject){
        replaceIn("\n", with: "\n1. ")

    }
    
    func size(_ sender: AnyObject){
        replaceIn("\n", with: "\n#")
    }
    
    func strike(_ sender: AnyObject){
        wrapIn("~~")
    }
    
}

class TouchUIScrollView: UIScrollView {
    
    override func touchesShouldCancel(in view: UIView) -> Bool {
        return true
    }
}
