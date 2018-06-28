//
//  String+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 6/26/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation

extension String {
    func toAttributedString() -> NSAttributedString? {
        guard let data = self.data(using: String.Encoding.utf8, allowLossyConversion: false) else {
            return nil
        }

        let htmlString = try? NSMutableAttributedString(data: data, options: [NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue, NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)

        return htmlString
    }
}
