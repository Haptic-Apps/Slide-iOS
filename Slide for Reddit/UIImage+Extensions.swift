//
//  UIImage+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 6/26/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

extension UIImage {

    func getCopy(withSize size: CGSize) -> UIImage {
        let maxWidth = size.width
        let maxHeight = size.height
        
        let imgWidth = self.size.width
        let imgHeight = self.size.height

        let widthRatio = maxWidth / imgWidth
        
        let heightRatio = maxHeight / imgHeight
        
        let bestRatio = min(widthRatio, heightRatio)

        let newWidth = imgWidth * bestRatio,
            newHeight = imgHeight * bestRatio

        let biggerSize = CGSize(width: newWidth, height: newHeight)
        var newImage: UIImage

        if #available(iOS 10.0, *) {
            let renderFormat = UIGraphicsImageRendererFormat.default()
            renderFormat.opaque = false
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: biggerSize.width, height: biggerSize.height), format: renderFormat)
            newImage = renderer.image { (_) in
                self.draw(in: CGRect(x: 0, y: 0, width: biggerSize.width, height: biggerSize.height))
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: biggerSize.width, height: biggerSize.height), false, 0)
            self.draw(in: CGRect(x: 0, y: 0, width: biggerSize.width, height: biggerSize.height))
            newImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }
        
        return newImage
    }
    func cropImageByAlpha() -> UIImage {
        let cgImage = self.cgImage
        let context = createARGBBitmapContextFromImage(inImage: cgImage!)
        let height = cgImage!.height
        let width = cgImage!.width
        
        var rect: CGRect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        context?.draw(cgImage!, in: rect)
        
        let pixelData = self.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        var minX = width
        var minY = height
        var maxX: Int = 0
        var maxY: Int = 0
        
        //Filter through data and look for non-transparent pixels.
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (width * y + x) * 4 /* 4 for A, R, G, B */
                
                if data[Int(pixelIndex)] != 0 { //Alpha value is not zero pixel is not transparent.
                    if x < minX {
                        minX = x
                    }
                    if x > maxX {
                        maxX = x
                    }
                    if y < minY {
                        minY = y
                    }
                    if y > maxY {
                        maxY = y
                    }
                }
            }
        }
        
        rect = CGRect( x: CGFloat(minX), y: CGFloat(minY), width: CGFloat(maxX - minX), height: CGFloat(maxY - minY))
        let imageScale: CGFloat = self.scale
        let cgiImage = self.cgImage?.cropping(to: rect)
        return UIImage(cgImage: cgiImage!, scale: imageScale, orientation: self.imageOrientation)
    }
    
    private func createARGBBitmapContextFromImage(inImage: CGImage) -> CGContext? {
        
        let width = cgImage!.width
        let height = cgImage!.height
        
        let bitmapBytesPerRow = width * 4
        let bitmapByteCount = bitmapBytesPerRow * height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let bitmapData = malloc(bitmapByteCount)
        if bitmapData == nil {
            return nil
        }
        
        let context = CGContext(data: bitmapData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bitmapBytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        return context
    }
    convenience init?(sfString: SFSymbol, overrideString: String) {
        if #available(iOS 13, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 15, weight: UIImage.SymbolWeight.regular, scale: UIImage.SymbolScale.small)
            self.init(systemName: sfString.rawValue, withConfiguration: config)
        } else {
            self.init(named: overrideString)
        }
    }

    convenience init?(sfStringHQ: SFSymbol, overrideString: String) {
        if #available(iOS 13, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 30, weight: UIImage.SymbolWeight.regular, scale: UIImage.SymbolScale.large)
            self.init(systemName: sfStringHQ.rawValue, withConfiguration: config)
        } else {
            self.init(named: overrideString)
        }
    }

    func getCopy(withColor color: UIColor) -> UIImage {
        if #available(iOS 10, *) {
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                color.setFill()
                self.draw(at: .zero)
                context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height), blendMode: .sourceAtop)
            }
        } else {
            var image = withRenderingMode(.alwaysTemplate)
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            color.set()
            image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return image
        }
    }

    func getCopy(withSize size: CGSize, withColor color: UIColor) -> UIImage {
        return self.getCopy(withSize: size).getCopy(withColor: color)
    }

    // TODO: - These should make only one copy and do in-place operations on those
    func navIcon(_ white: Bool = false) -> UIImage {
        if #available(iOS 13.0, *) {
            let lightImage = navIconThemed(white, night: false)
            if !SettingValues.nightModeEnabled {
                return lightImage
            }
            let darkImage = navIconThemed(white, night: true)
            
            let asset = UIImageAsset(lightModeImage: lightImage, darkModeImage: darkImage)
            return asset.image()
        } else {
            return self.getCopy(withSize: CGSize(width: 25, height: 25), withColor: SettingValues.reduceColor && !white ? UIColor.navIconColor : .white)
        }
    }

    func navIconThemed(_ white: Bool = false, night: Bool) -> UIImage {
        return self.getCopy(withSize: CGSize(width: 25, height: 25), withColor: SettingValues.reduceColor && !white ? (night ? ColorUtil.getNightTheme().navIconColor : ColorUtil.getDayTheme().navIconColor) : .white)
    }
    
    func smallIcon() -> UIImage {
        if #available(iOS 13.0, *) {
            let lightImage = smallIconThemed(night: false)
            if !SettingValues.nightModeEnabled {
                return lightImage
            }
            let darkImage = smallIconThemed(night: true)
            
            let asset = UIImageAsset(lightModeImage: lightImage, darkModeImage: darkImage)
            return asset.image()
        } else {
            return self.getCopy(withSize: CGSize(width: 12, height: 12), withColor: UIColor.navIconColor)
        }
    }

    func smallIconThemed(night: Bool) -> UIImage {
        return self.getCopy(withSize: CGSize(width: 12, height: 12), withColor: night ? ColorUtil.getNightTheme().navIconColor : ColorUtil.getDayTheme().navIconColor)
    }

    func toolbarIcon() -> UIImage {
        if #available(iOS 13.0, *) {
            let lightImage = toolbarIconThemed(night: false)
            if !SettingValues.nightModeEnabled {
                return lightImage
            }
            let darkImage = toolbarIconThemed(night: true)
            
            let asset = UIImageAsset(lightModeImage: lightImage, darkModeImage: darkImage)
            return asset.image()
        } else {
            return self.getCopy(withSize: CGSize(width: 25, height: 25), withColor: UIColor.navIconColor)
        }
    }
    
    func toolbarIconThemed(night: Bool) -> UIImage {
        return self.getCopy(withSize: CGSize(width: 25, height: 25), withColor: night ? ColorUtil.getNightTheme().navIconColor : ColorUtil.getDayTheme().navIconColor)
    }

    func menuIcon() -> UIImage {
        if #available(iOS 13.0, *) {
            let lightImage = menuIconThemed(night: false)
            if !SettingValues.nightModeEnabled {
                return lightImage
            }

            let darkImage = menuIconThemed(night: true)
            
            let asset = UIImageAsset(lightModeImage: lightImage, darkModeImage: darkImage)
            return asset.image()
        } else {
            return self.getCopy(withSize: CGSize(width: 20, height: 20), withColor: UIColor.navIconColor)
        }
    }
    
    func menuIconThemed(night: Bool) -> UIImage {
        return self.getCopy(withSize: CGSize(width: 20, height: 20), withColor: night ? ColorUtil.getNightTheme().navIconColor : ColorUtil.getDayTheme().navIconColor)
    }

    func cropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {

        let contextImage: UIImage = UIImage(cgImage: image.cgImage!)

        let contextSize: CGSize = contextImage.size

        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)

        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }

        let rect: CGRect = CGRect.init(x: posX, y: posY, width: cgwidth, height: cgheight)

        // Create bitmap image from context using the rect
        let imageRef: CGImage = (contextImage.cgImage?.cropping(to: rect)!)!

        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage.init(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)

        return image
    }
    
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }

    func overlayWith(image: UIImage, posX: CGFloat, posY: CGFloat) -> UIImage {
        let newWidth = size.width < posX + image.size.width ? posX + image.size.width : size.width
        let newHeight = size.height < posY + image.size.height ? posY + image.size.height : size.height
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(origin: CGPoint.zero, size: size))
        image.draw(in: CGRect(origin: CGPoint(x: posX, y: posY), size: image.size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    class func convertGradientToImage(colors: [UIColor], frame: CGSize) -> UIImage {
        let rect = CGRect.init(x: 0, y: 0, width: frame.width, height: frame.height)
        // start with a CAGradientLayer
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = rect

        // add colors as CGCologRef to a new array and calculate the distances
        var colorsRef = [CGColor]()
        var locations = [NSNumber]()

        for i in 0 ..< colors.count {
            colorsRef.append(colors[i].cgColor as CGColor)
            locations.append(NSNumber(value: Float(i) / Float(colors.count - 1)))
        }

        gradientLayer.colors = colorsRef

        let x: CGFloat = 135.0 / 360.0
        let a: CGFloat = pow(sin(2.0 * CGFloat.pi * ((x + 0.75) / 2.0)), 2.0)
        let b: CGFloat = pow(sin(2.0 * CGFloat.pi * ((x + 0.00) / 2.0)), 2.0)
        let c: CGFloat = pow(sin(2.0 * CGFloat.pi * ((x + 0.25) / 2.0)), 2.0)
        let d: CGFloat = pow(sin(2.0 * CGFloat.pi * ((x + 0.50) / 2.0)), 2.0)

        gradientLayer.endPoint = CGPoint(x: c, y: d)
        gradientLayer.startPoint = CGPoint(x: a, y: b)

        // now build a UIImage from the gradient
        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // return the gradient image
        return gradientImage!
    }

    func areaAverage() -> UIColor {
        var bitmap = [UInt8](repeating: 0, count: 4)
        
        if #available(iOS 9.0, *) {
            // Get average color.
            let context = CIContext()
            let inputImage: CIImage = ciImage ?? CoreImage.CIImage(cgImage: cgImage!)
            let extent = inputImage.extent
            let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
            let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: inputExtent])!
            let outputImage = filter.outputImage!
            let outputExtent = outputImage.extent
            assert(outputExtent.size.width == 1 && outputExtent.size.height == 1)
            
            // Render to bitmap.
            context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: CIFormat.RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        } else {
            // Create 1x1 context that interpolates pixels when drawing to it.
            let context = CGContext(data: &bitmap, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            let inputImage = cgImage ?? CIContext().createCGImage(ciImage!, from: ciImage!.extent)
            
            // Render to bitmap.
            context.draw(inputImage!, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        
        // Compute result.
        let result = UIColor(red: CGFloat(bitmap[0]) / 255.0, green: CGFloat(bitmap[1]) / 255.0, blue: CGFloat(bitmap[2]) / 255.0, alpha: CGFloat(bitmap[3]) / 255.0)
        return result
    }
    
    /**
     https://stackoverflow.com/a/62862742/3697225
     Rounds corners of UIImage
     - Parameter proportion: Proportion to minimum paramter (width or height)
                             in order to have the same look of corner radius independetly
                             from aspect ratio and actual size
     */
    func roundCorners(proportion: CGFloat) -> UIImage {
        let minValue = min(self.size.width, self.size.height)
        let radius = minValue / proportion
        
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: self.size)
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)
        UIBezierPath(roundedRect: rect, cornerRadius: radius).addClip()
        self.draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return image
    }
    
    func circleCorners(finalSize: CGSize) -> UIImage {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: finalSize)
        UIGraphicsBeginImageContextWithOptions(finalSize, false, 0)
        UIBezierPath(ovalIn: rect).addClip()
        self.draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIImage {
    func withBackground(color: UIColor, opaque: Bool = true) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)

        guard let ctx = UIGraphicsGetCurrentContext(), let image = cgImage else { return self }
        defer { UIGraphicsEndImageContext() }

        let rect = CGRect(origin: .zero, size: size)
        ctx.setFillColor(color.cgColor)
        ctx.fill(rect)
        ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
        ctx.draw(image, in: rect)

        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

extension UIImage {
    func withPadding(_ padding: CGFloat) -> UIImage? {
        return withPadding(x: padding, y: padding)
    }

    func withPadding(x: CGFloat, y: CGFloat) -> UIImage? {
        let newWidth = size.width + 2 * x
        let newHeight = size.height + 2 * y
        let newSize = CGSize(width: newWidth, height: newHeight)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        let origin = CGPoint(x: (newWidth - size.width) / 2, y: (newHeight - size.height) / 2)
        draw(at: origin)
        let imageWithPadding = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return imageWithPadding
    }
}

@available(iOS 13.0, *)
public extension UIImageAsset {

    /// Creates an image asset with registration of tht eimages with the light and dark trait collections.
    /// - Parameters:
    ///   - lightModeImage: The image you want to register with the image asset with light user interface style.
    ///   - darkModeImage: The image you want to register with the image asset with dark user interface style.
    convenience init(lightModeImage: UIImage?, darkModeImage: UIImage?) {
        self.init()
        register(lightModeImage: lightModeImage, darkModeImage: darkModeImage)
    }

    /// Register an images with the light and dark trait collections respectively.
    /// - Parameters:
    ///   - lightModeImage: The image you want to register with the image asset with light user interface style.
    ///   - darkModeImage: The image you want to register with the image asset with dark user interface style.
    func register(lightModeImage: UIImage?, darkModeImage: UIImage?) {
        register(lightModeImage, for: UITraitCollection(traitsFrom: [.current, UITraitCollection(userInterfaceStyle: .light)]))
        register(darkModeImage, for: UITraitCollection(traitsFrom: [.current, UITraitCollection(userInterfaceStyle: .dark)]))
    }

    /// Register an image with the specified trait collection.
    /// - Parameters:
    ///   - image: The image you want to register with the image asset.
    ///   - traitCollection: The traits to associate with image.
    func register(_ image: UIImage?, for traitCollection: UITraitCollection) {
        guard let image = image else {
            return
        }
        register(image, with: traitCollection)
    }

    /// Returns the variant of the image that best matches the current trait collection. For early SDKs returns the image for light user interface style.
    func image() -> UIImage {
        return image(with: .current)
    }
}
