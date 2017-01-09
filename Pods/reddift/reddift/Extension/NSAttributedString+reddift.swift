//
//  NSAttributedString+reddift.swift
//  reddift
//
//  Created by sonson on 2015/10/18.
//  Copyright © 2015年 sonson. All rights reserved.
//

import Foundation

/// import to use NSFont/UIFont
#if os(iOS) || os(tvOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

/// Shared font and color class
#if os(iOS) || os(tvOS)
    private typealias _Font = UIFont
    private typealias _Color = UIColor
#elseif os(macOS)
    private typealias _Font = NSFont
    private typealias _Color = NSColor
#endif

/// Enum, attributes for NSAttributedString
private enum Attribute {
    case link(URL, Int, Int)
    case bold(Int, Int)
    case italic(Int, Int)
    case superscript(Int, Int)
    case strike(Int, Int)
    case code(Int, Int)
}

/// Extension for NSParagraphStyle
extension NSParagraphStyle {
    /**
    Returns default paragraph style for reddift framework.
    - parameter fontSize: Font size
    - returns: Paragraphyt style, which is created.
    */
    static func defaultReddiftParagraphStyle(with fontSize: CGFloat) -> NSParagraphStyle {
#if os(iOS) || os(tvOS)
        guard let paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            else { return NSParagraphStyle.default }
#elseif os(macOS)
        guard let paragraphStyle = NSParagraphStyle.default().mutableCopy() as? NSMutableParagraphStyle
            else { return NSParagraphStyle.default() }
#endif
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .left
        paragraphStyle.maximumLineHeight = fontSize + 2
        paragraphStyle.minimumLineHeight = fontSize + 2
        paragraphStyle.lineSpacing = 1
        paragraphStyle.paragraphSpacing = 1
        paragraphStyle.paragraphSpacingBefore = 1
        paragraphStyle.lineHeightMultiple = 0
        return paragraphStyle
    }
}

/// shared regular expression
private let regexForHasImageFileExtension: NSRegularExpression! = {
    do {
        return try NSRegularExpression(pattern: "^/.+\\.(jpg|jpeg|gif|png)$", options: .caseInsensitive)
    } catch {
        assert(false, "Fatal error: \(#file) \(#line) - \(error)")
        return nil
    }
}()

/// Extension for NSAttributedString
extension String {
    /**
    Returns HTML string whose del and blockquote tag is replaced with font size tag in order to extract these tags using NSAttribtedString class method.
    
    - returns: String, which is processed.
    */
    public var preprocessedHTMLStringBeforeNSAttributedStringParsing: String {
        get {
            var temp = self.replacingOccurrences(of: "<del>", with: "<font size=\"5\">")
            temp = temp.replacingOccurrences(of: "<blockquote>", with: "<cite>")
            temp = temp.replacingOccurrences(of: "</blockquote>", with: "</cite>")
            return temp.replacingOccurrences(of: "</del>", with: "</font>")
        }
    }
}

/// Extension for NSAttributedString.includedImageURL
extension URLComponents {
    
    /// Returns true when URL's filename has image's file extension(such as gif, jpg, png).
    public var hasImageFileExtension: Bool {
        let path = self.path
            if let r = regexForHasImageFileExtension.firstMatch(in: path, options: [], range: NSRange(location: 0, length: path.characters.count)) {
                return r.rangeAt(1).length > 0
            }
        return false
    }
}

/// Extension for NSAttributedString
extension NSAttributedString {
    /// Returns list of URLs that were included in NSAttributedString as NSLinkAttributeName's array.
    public var includedURL: [URL] {
        get {
            var values: [AnyObject] = []
            self.enumerateAttribute(
                NSLinkAttributeName,
                in: NSRange(location:0, length:self.length),
                options: [],
                using: { (value: Any?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                if let value = value {
                    values.append(value as AnyObject)
                }
            })
            return values.flatMap { $0 as? URL }
        }
    }
    
    /// Returns list of image URLs(like gif, jpg, png) that were included in NSAttributedString as NSLinkAttributeName's array.
    public var includedImageURL: [URL] {
        get {
            return self
                .includedURL
                .flatMap {URLComponents(url: $0, resolvingAgainstBaseURL: false)}
                .flatMap {($0.hasImageFileExtension && $0.scheme != "applewebdata") ? $0.url : nil}
        }
    }
    
#if os(iOS) || os(tvOS)
    /**
    Reconstructs attributed string for rendering using UZTextView or UITextView.
    - parameter normalFont : Specified UIFont you want to use when the object is rendered.
    - parameter color : Specified UIColor of strings.
    - parameter linkColor : Specified UIColor of strings have NSLinkAttributeName as an attribute.
    - parameter codeBackgroundColor : Specified UIColor of background of strings that are included in <code>.
    - returns : NSAttributedString object to render using UZTextView or UITextView.
    */
    public func reconstruct(with normalFont: UIFont, color: UIColor, linkColor: UIColor, codeBackgroundColor: UIColor = UIColor.lightGray) -> NSAttributedString {
        return __reconstruct(with: normalFont, color:color, linkColor:linkColor, codeBackgroundColor:codeBackgroundColor)
    }
#elseif os(macOS)
    /**
    Reconstructs attributed string for rendering it.
    - parameter normalFont : Specified NSFont you want to use when the object is rendered.
    - parameter color : Specified NSColor of strings.
    - parameter linkColor : Specified NSColor of strings have NSLinkAttributeName as an attribute.
    - parameter codeBackgroundColor : Specified NSColor of background of strings that are included in <code>.
    - returns : NSAttributedString object.
    */
    public func reconstruct(with normalFont: NSFont, color: NSColor, linkColor: NSColor, codeBackgroundColor: NSColor = NSColor.lightGray) -> NSAttributedString {
        return __reconstruct(with: normalFont, color:color, linkColor:linkColor, codeBackgroundColor:codeBackgroundColor)
    }
#endif
    
    
    /**
     Reconstruct attributed string, intrinsic function. This function is for encapsulating difference of font and color class.
     - parameter normalFont : Specified NSFont/UIFont you want to use when the object is rendered.
     - parameter color : Specified NSColor/UIColor of strings.
     - parameter linkColor : Specified NSColor/UIColor of strings have NSLinkAttributeName as an attribute.
     - parameter codeBackgroundColor : Specified NSColor/UIColor of background of strings that are included in <code>.
     - returns : NSAttributedString object.
     */
    private func __reconstruct(with normalFont: _Font, color: _Color, linkColor: _Color, codeBackgroundColor: _Color) -> NSAttributedString {
        let attributes = self.attributesForReddift
        let (italicFont, boldFont, codeFont, superscriptFont, _) = createDerivativeFonts(normalFont)
        
        let output = NSMutableAttributedString(string: string)
        
        // You can set default paragraph style, here.
        // output.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSRange(0, output.length))
        output.addAttribute(NSFontAttributeName, value: normalFont, range: NSRange(location: 0, length: output.length))
        output.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange(location: 0, length: output.length))
        attributes.forEach {
            switch $0 {
            case .link(let URL, let loc, let len):
                output.addAttribute(NSLinkAttributeName, value:URL, range: NSRange(location: loc, length: len))
                output.addAttribute(NSForegroundColorAttributeName, value: linkColor, range: NSRange(location: loc, length: len))
            case .bold(let loc, let len):
                output.addAttribute(NSFontAttributeName, value:boldFont, range: NSRange(location: loc, length: len))
            case .italic(let loc, let len):
                output.addAttribute(NSFontAttributeName, value:italicFont, range: NSRange(location: loc, length: len))
            case .superscript(let loc, let len):
                output.addAttribute(NSFontAttributeName, value:superscriptFont, range: NSRange(location: loc, length: len))
            case .strike(let loc, let len):
                output.addAttribute(NSStrikethroughStyleAttributeName, value:NSNumber(value:1), range: NSRange(location: loc, length: len))
            case .code(let loc, let len):
                output.addAttribute(NSFontAttributeName, value:codeFont, range: NSRange(location: loc, length: len))
                output.addAttribute(NSBackgroundColorAttributeName, value: codeBackgroundColor, range: NSRange(location: loc, length: len))
            }
        }
        return output
    }
    
    /**
     Create fonts which is derivative of specified font object.
     - parameter normalFont : Source font from which new font objects are generated. The new font objects' size are as same as source one.
     - returns : Four font objects as a tuple, that are italic, bold, code, superscript and pargraph style.
     */
    private func createDerivativeFonts(_ normalFont: _Font) -> (_Font, _Font, _Font, _Font, NSParagraphStyle) {
        #if os(iOS) || os(tvOS)
            let traits = normalFont.fontDescriptor.symbolicTraits
            let italicFontDescriptor = normalFont.fontDescriptor.withSymbolicTraits([traits, .traitItalic])
            let boldFontDescriptor = normalFont.fontDescriptor.withSymbolicTraits([traits, .traitBold])
            let italicFont = _Font(descriptor: italicFontDescriptor!, size: normalFont.fontDescriptor.pointSize)
            let boldFont = _Font(descriptor: boldFontDescriptor!, size: normalFont.fontDescriptor.pointSize)
            let codeFont = _Font(name: "Courier", size: normalFont.fontDescriptor.pointSize) ?? normalFont
            let superscriptFont = _Font(descriptor: normalFont.fontDescriptor, size: normalFont.fontDescriptor.pointSize/2)
            let paragraphStyle = NSParagraphStyle.defaultReddiftParagraphStyle(with: normalFont.fontDescriptor.pointSize)
        #elseif os(macOS)
            let traits = normalFont.fontDescriptor.symbolicTraits
            let italicFontDescriptor = normalFont.fontDescriptor.withSymbolicTraits(traits & NSFontSymbolicTraits(NSFontItalicTrait))
            let boldFontDescriptor = normalFont.fontDescriptor.withSymbolicTraits(traits & NSFontSymbolicTraits(NSFontBoldTrait))
            let italicFont = _Font(descriptor: italicFontDescriptor, size: normalFont.fontDescriptor.pointSize) ?? normalFont
            let boldFont = _Font(descriptor: boldFontDescriptor, size: normalFont.fontDescriptor.pointSize) ?? normalFont
            let codeFont = _Font(name: "Courier", size: normalFont.fontDescriptor.pointSize) ?? normalFont
            let superscriptFont = _Font(descriptor: normalFont.fontDescriptor, size: normalFont.fontDescriptor.pointSize/2) ?? normalFont
            let paragraphStyle = NSParagraphStyle.defaultReddiftParagraphStyle(with: normalFont.fontDescriptor.pointSize)
        #endif
        return (italicFont, boldFont, codeFont, superscriptFont, paragraphStyle)
    }
    
    /**
     Extract attributes from NSAttributedString in order to set attributes and values again to new NSAttributedString for rendering.
     - returns : Attribute's array to set a new NSAttributedString.
     */
    private var attributesForReddift: [Attribute] {
        var attributes: [Attribute] = []
        
        self.enumerateAttribute(NSLinkAttributeName, in: NSRange(location:0, length:self.length), options: [], using: { (value: Any?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            if let URL = value as? URL {
                attributes.append(Attribute.link(URL, range.location, range.length))
            }
            })
        
        self.enumerateAttribute(NSFontAttributeName, in: NSRange(location:0, length:self.length), options: [], using: { (value: Any?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            if let font = value as? _Font {
                switch font.fontName {
                case "TimesNewRomanPS-BoldItalicMT":
                    attributes.append(Attribute.italic(range.location, range.length))
                    attributes.append(Attribute.bold(range.location, range.length))
                case "TimesNewRomanPS-ItalicMT":
                    attributes.append(Attribute.italic(range.location, range.length))
                case "TimesNewRomanPS-BoldMT":
                    attributes.append(Attribute.bold(range.location, range.length))
                case "Courier":
                    attributes.append(Attribute.code(range.location, range.length))
                default:
                    do {}
                }
                if font.pointSize < 12 {
                    attributes.append(Attribute.superscript(range.location, range.length))
                } else if font.pointSize > 12 {
                    attributes.append(Attribute.strike(range.location, range.length))
                }
            }
            })
        return attributes
    }
}
