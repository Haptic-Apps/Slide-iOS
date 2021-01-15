//
//  Slide for Reddit
//
//  Modified by Carlos Crane on 11/18/20.
//

//
//  AsyncTextAttachment.swift
//  Attachments
//
//  Created by Oliver Drobnik on 01/09/2016.
//  Copyright © 2016 Cocoanetics. All rights reserved.
//

import MobileCoreServices
import SDWebImage
import UIKit

@objc public protocol AsyncTextAttachmentDelegate {
    /// Called when the image has been loaded
    func textAttachmentDidLoadImage(textAttachment: AsyncTextAttachment, displaySizeChanged: Bool)
}

/// An image text attachment that gets loaded from a remote URL
public class AsyncTextAttachment: NSTextAttachment {
    /// Remote URL for the image
    public var imageURL: URL?
    
    /// Whether to round the image corners
    public var rounded: Bool
    
    /// Color for background of image
    public var backgroundColor: UIColor?
    
    /// To specify an absolute display size.
    public var displaySize: CGSize?
    
    /// if determining the display size automatically this can be used to specify a maximum width. If it is not set then the text container's width will be used
    public var maximumDisplayWidth: CGFloat?
    
    /// A delegate to be informed of the finished download
    public weak var delegate: AsyncTextAttachmentDelegate?
    
    /// Remember the text container from delegate message, the current one gets updated after the download
    weak var textContainer: NSTextContainer?
    
    /// The size of the downloaded image. Used if we need to determine display size
    private var originalImageSize: CGSize?
    
    /// Designated initializer
    public init(imageURL: URL? = nil, delegate: AsyncTextAttachmentDelegate? = nil, rounded: Bool, backgroundColor: UIColor?) {
        self.imageURL = imageURL
        self.delegate = delegate
        self.rounded = rounded
        self.backgroundColor = backgroundColor
        
        super.init(data: nil, ofType: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var image: UIImage? {
        didSet {
            originalImageSize = image?.size
        }
    }
    
    // MARK: - Helpers
    
    private func startAsyncImageDownload() {
        guard let imageURL = imageURL else {
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            if let image = self.getCacheImage(with: imageURL) {
                self.display(image, with: image.pngData(), url: imageURL)
            } else {
                self.downloadImage(with: imageURL)
            }
        }
    }
    
    private func getCacheImage(with: URL) -> UIImage? {
        return SDImageCache.shared.imageFromCache(forKey: with.absoluteString + "-round")
    }
    
    private func downloadImage(with: URL) {
        SDWebImageDownloader.shared.downloadImage(with: with, options: [.decodeFirstFrameOnly], progress: nil) { (image, data, _, _) in
            let roundedImage = image?.circleCorners(finalSize: self.bounds.size)
            DispatchQueue.global(qos: .background).async {
                SDImageCache.shared.storeImage(toMemory: roundedImage, forKey: with.absoluteString + "-round")
            }

            self.display(roundedImage, with: data, url: with)
        }
    }
    
    public func display(_ image: UIImage?, with: Data?, url: URL) {
        let ext = url.pathExtension as CFString
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext, nil) {
            self.fileType = uti.takeRetainedValue() as String
        }
        if let image = image { //2 was causing weird clipping
            let imageSize = image.size
                           
            self.originalImageSize = imageSize
        }
        
        DispatchQueue.main.async {
            self.textContainer?.layoutManager?.setNeedsDisplay(forAttachment: self)

            self.delegate?.textAttachmentDidLoadImage(textAttachment: self, displaySizeChanged: false)
        }
    }
    
    public override func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        if let image = image { return image }
        
        guard let url = imageURL, let image = getCacheImage(with: url) else {
            // remember reference so that we can update it later
            self.textContainer = textContainer
            
            startAsyncImageDownload()
            
            return nil
        }
        
        return image
    }
    
    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        return self.bounds
    }
}

extension NSLayoutManager {
    /// Determine the character ranges for an attachment
    private func rangesForAttachment(attachment: NSTextAttachment) -> [NSRange]? {
        guard let attributedString = self.textStorage else {
            return nil
        }
        
        // find character range for this attachment
        let range = NSRange(location: 0, length: attributedString.length)
        
        var refreshRanges = [NSRange]()
        
        attributedString.enumerateAttribute(NSAttributedString.Key.attachment, in: range, options: []) { (value, effectiveRange, _) in
            
            guard let foundAttachment = value as? NSTextAttachment, foundAttachment == attachment else {
                return
            }
            
            // add this range to the refresh ranges
            refreshRanges.append(effectiveRange)
        }
        
        if refreshRanges.count == 0 {
            return nil
        }
        
        return refreshRanges
    }
    
    /// Trigger a relayout for an attachment
    public func setNeedsLayout(forAttachment attachment: NSTextAttachment) {
        guard let ranges = rangesForAttachment(attachment: attachment) else {
            return
        }

        // invalidate the display for the corresponding ranges
        for range in ranges.reversed() {
            self.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)

            // also need to trigger re-display or already visible images might not get updated
            self.invalidateDisplay(forCharacterRange: range)
        }
    }
    
    /// Trigger a re-display for an attachment
    public func setNeedsDisplay(forAttachment attachment: NSTextAttachment) {
        guard let ranges = rangesForAttachment(attachment: attachment) else {
            return
        }

        // invalidate the display for the corresponding ranges
        for range in ranges.reversed() {
            self.invalidateDisplay(forCharacterRange: range)
        }
    }
}

public class AsyncTextAttachmentNoLoad: NSTextAttachment {
    /// Remote URL for the image
    public var imageURL: URL?
    
    /// Whether to round the image corners
    public var rounded: Bool
    
    /// Color for background of image
    public var backgroundColor: UIColor?
    
    /// To specify an absolute display size.
    public var displaySize: CGSize?
    
    /// if determining the display size automatically this can be used to specify a maximum width. If it is not set then the text container's width will be used
    public var maximumDisplayWidth: CGFloat?
    
    /// A delegate to be informed of the finished download
    public weak var delegate: AsyncTextAttachmentDelegate?
    
    /// Remember the text container from delegate message, the current one gets updated after the download
    weak var textContainer: NSTextContainer?
    
    /// The size of the downloaded image. Used if we need to determine display size
    private var originalImageSize: CGSize?
    
    /// Designated initializer
    public init(imageURL: URL? = nil, delegate: AsyncTextAttachmentDelegate? = nil, rounded: Bool, backgroundColor: UIColor?) {
        self.imageURL = imageURL
        self.delegate = delegate
        self.rounded = rounded
        self.backgroundColor = backgroundColor
        super.init(data: nil, ofType: nil)
        self.image = UIImage()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var image: UIImage? {
        didSet {
            originalImageSize = image?.size
        }
    }
                    
    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        return self.bounds
    }
}
