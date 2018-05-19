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
            generateButtons(image: "save", action: #selector(EditorToolbar.saveDraft(_:))),
            generateButtons(image: "folder", action: #selector(EditorToolbar.openDrafts(_:))),
            generateButtons(image: "image", action: #selector(EditorToolbar.uploadImage(_:))),
            generateButtons(image: "draw", action: #selector(EditorToolbar.draw(_:))),
            generateButtons(image: "link", action: #selector(EditorToolbar.link(_:))),
            generateButtons(image: "bold", action: #selector(EditorToolbar.bold(_:))),
            generateButtons(image: "italic", action: #selector(EditorToolbar.italics(_:))),
            generateButtons(image: "list", action: #selector(EditorToolbar.list(_:))),
            generateButtons(image: "list_number", action: #selector(EditorToolbar.numberedList(_:))),
            generateButtons(image: "size", action: #selector(EditorToolbar.size(_:))),
            generateButtons(image: "strikethrough", action: #selector(EditorToolbar.strike(_:)))]) {
                button.0.frame = CGRect.init(x: i * 50, y: 0, width: 50, height: 50)
                button.0.isUserInteractionEnabled = true
                button.0.addTarget(self, action: button.1, for: UIControlEvents.touchUpInside)
                scrollView.addSubview(button.0)
                i += 1
        }
        scrollView.delaysContentTouches = false
        textView.inputAccessoryView = scrollView
    }
    
    func generateButtons(image: String, action: Selector) -> (UIButton, Selector) {
        let more = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 50, height: 50))
        more.setImage(UIImage.init(named: image)?.menuIcon(), for: UIControlState.normal)
        return (more, action)
    }
    
    func wrapIn(_ value: String){
        textView.replace(textView.selectedTextRange!, withText: value + textView.text(in: textView.selectedTextRange!)! + value)
    }
    
    func replaceIn(_ value: String, with: String){
        
    }

    
    func saveDraft(_ sender: UIButton!){
        
    }
    
    func openDrafts(_ sender: UIButton!){
        
    }
    
    func uploadImage(_ sender: UIButton!){
        
    }
    
    func draw(_ sender: UIButton!){
        
    }
    
    func link(_ sender: UIButton!){
        
    }
    
    func bold(_ sender: UIButton!){
        print("Bold")
        wrapIn("*")
    }
    
    func italics(_ sender: UIButton!){
        wrapIn("**")
    }
    
    func list(_ sender: UIButton!){
        replaceIn("\n", with: "\n* ")
    }
    
    func numberedList(_ sender: UIButton!){
        replaceIn("\n", with: "\n1. ")

    }
    
    func size(_ sender: UIButton!){
        replaceIn("\n", with: "\n#")
    }
    
    func strike(_ sender: UIButton!){
        wrapIn("~~")
    }
    
}

class TouchUIScrollView: UIScrollView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        return true
    }
}
