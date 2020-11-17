//
//  UIResponder+Extensions.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 10/18/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

extension UIResponder {
    private weak static var _currentFirstResponder: UIResponder? = nil

    public static var isFirstResponderTextField: Bool {
        var isTextField = false
        if let firstResponder = UIResponder.currentFirstResponder {
            isTextField = firstResponder.isKind(of: UITextField.self) || firstResponder.isKind(of: UITextView.self) || firstResponder.isKind(of: UISearchBar.self)
        }

        return isTextField
    }

    public static var currentFirstResponder: UIResponder? {
        UIResponder._currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(findFirstResponder(sender:)), to: nil, from: nil, for: nil)
        return UIResponder._currentFirstResponder
    }

    @objc internal func findFirstResponder(sender: AnyObject) {
        UIResponder._currentFirstResponder = self
    }
}
