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
        self.addToolbarToTextView()
    }
    
    func addToolbarToTextView(){
        
        let scrollView = TouchUIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: textView.frame.size.width, height: 50))
        scrollView.contentSize = CGSize.init(width: 50 * 11, height: 50)
        scrollView.autoresizingMask = .flexibleWidth
        scrollView.backgroundColor = ColorUtil.backgroundColor
        var i = 0
        for button in ([
            generateButtons(image: "save", action: #selector(EditorToolbar.saveDraft)),
            generateButtons(image: "folder", action: #selector(EditorToolbar.openDrafts)),
            generateButtons(image: "image", action: #selector(EditorToolbar.uploadImage)),
            generateButtons(image: "draw", action: #selector(EditorToolbar.draw)),
            generateButtons(image: "link", action: #selector(EditorToolbar.link)),
            generateButtons(image: "bold", action: #selector(EditorToolbar.bold)),
            generateButtons(image: "italic", action: #selector(EditorToolbar.italics)),
            generateButtons(image: "list", action: #selector(EditorToolbar.list)),
            generateButtons(image: "list_number", action: #selector(EditorToolbar.numberedList)),
            generateButtons(image: "size", action: #selector(EditorToolbar.size)),
            generateButtons(image: "strikethrough", action: #selector(EditorToolbar.strike))]) {
                button.0.frame = CGRect.init(x: i * 50, y: 0, width: 50, height: 50);
                scrollView.addSubview(button.0)
                button.0.isUserInteractionEnabled = true
                button.0.addTarget(self, action: button.1, for: UIControlEvents.touchUpInside)
                i += 1
        }
        scrollView.delaysContentTouches = false
        textView.inputAccessoryView = scrollView
    }
    
    func generateButtons(image: String, action: Selector) -> (UIButton, Selector) {
        let more = UIButton.init(frame: CGRect.zero)
        more.setImage(UIImage.init(named: image)?.withColor(tintColor: ColorUtil.fontColor).imageResize(sizeChange: CGSize.init(width: 25, height: 25)), for: UIControlState.normal)
        return (more, action)
    }
    
    func wrapIn(_ value: String){
        textView.replace(textView.selectedTextRange!, withText: value + textView.text(in: textView.selectedTextRange!)! + value)
    }
    
    func replaceIn(_ value: String, with: String){
        
    }

    
    @objc func saveDraft(){
        
    }
    
    @objc func openDrafts(){
        
    }
    
    @objc func uploadImage(){
        
    }
    
    @objc func draw(){
        
    }
    
    @objc func link(){
        
    }
    
    @objc func bold(){
        print("Bold")
        wrapIn("*")
    }
    
    @objc func italics(){
        wrapIn("**")
    }
    
    @objc func list(){
        replaceIn("\n", with: "\n* ")
    }
    
    @objc func numberedList(){
        replaceIn("\n", with: "\n1. ")

    }
    
    @objc func size(){
        replaceIn("\n", with: "\n#")
    }
    
    @objc func strike(){
        wrapIn("~~")
    }
    
}

class TouchUIScrollView: UIScrollView {
    
    override func touchesShouldCancel(in view: UIView) -> Bool {
        return true
    }
}
