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

    func size(with: UIFont) -> CGSize {
        let fontAttribute = [NSFontAttributeName: with]
        let size = self.size(attributes: fontAttribute)  // for Single Line
        return size
    }
    
    func toBase64() -> String? {
        guard let data = self.data(using: String.Encoding.utf8) else {
            return nil
        }
        
        return data.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
    }
}
