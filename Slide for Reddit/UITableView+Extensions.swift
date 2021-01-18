//
//  UITableView+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 6/26/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

extension UITableView {
    func reloadData(with animation: UITableView.RowAnimation) {
        reloadSections(IndexSet(integersIn: 0..<numberOfSections), with: animation)
    }
}

public extension UITableViewCell {
    func configure(text: String, imageName: String, sfSymbolName: SFSymbol, imageColor: UIColor) {
        textLabel?.text = text
        imageView?.image = UIImage(sfString: sfSymbolName, overrideString: imageName)?.menuIcon()
        imageView?.tintColor = imageColor
        
        accessoryType = .none
        backgroundColor = UIColor.foregroundColor
        textLabel?.textColor = UIColor.fontColor
        layer.cornerRadius = 5
        clipsToBounds = true
    }
    func configure(text: String, image: UIImage) {
        textLabel?.text = text
        imageView?.image = image
        
        accessoryType = .none
        backgroundColor = UIColor.foregroundColor
        textLabel?.textColor = UIColor.fontColor
        contentView.layer.cornerRadius = 5
        contentView.clipsToBounds = true
    }
}
