//
//  ImageMediaViewController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/9/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import SDCAlertView
import SDWebImage
import Then
import UIKit

class ImageMediaViewController: EmbeddableMediaViewController {

    var imageView = UIImageView()
    var scrollView = UIScrollView()
    var size = UILabel()

    var menuButton = UIButton()
    var downloadButton = UIButton()
    var viewInHDButton = UIButton()
    var goToCommentsButton = UIButton()
    var showTitleButton = UIButton()
    
    var overrideSize: CGSize?

    var forceHD = false

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()
        configureLayout()
        connectActions()
        loadContent()
    }
    
    var shouldReloadContent = false
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.imageView.image = nil
        shouldReloadContent = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldReloadContent {
            loadContent()
            shouldReloadContent = false
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateConstraintsForSize(view.bounds.size)
        let height = view.bounds.size.height
        let width = view.bounds.size.width
        let size = CGSize(width: width, height: height - bottomButtons.bounds.size.height)
        updateMinZoomScaleForSize(size, overrideSize: overrideSize)
    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }

    func configureViews() {

        scrollView = UIScrollView().then {
            $0.delegate = self
            $0.backgroundColor = .clear
        }
        self.view.addSubview(scrollView)

        imageView = UIImageView().then {
            $0.contentMode = .scaleAspectFill
        }
        scrollView.addSubview(imageView)
        
        if let parent = parent as? ModalMediaViewController, let gesture = parent.panGestureRecognizer {
            scrollView.panGestureRecognizer.require(toFail: gesture)
            gesture.delegate = self
        } else if let parent = parent as? SwipeDownModalVC, let gesture = parent.panGestureRecognizer {
            scrollView.panGestureRecognizer.require(toFail: gesture)
            gesture.delegate = self
        }
        
        // Buttons along bottom

        bottomButtons = UIStackView().then {
            $0.accessibilityIdentifier = "Bottom Buttons"
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 8
        }
        gradientView.addSubview(bottomButtons)
        view.addSubview(gradientView)

        if data.buttons {
            menuButton = UIButton().then {
                $0.accessibilityIdentifier = "More Button"
                $0.setImage(UIImage(sfString: SFSymbol.ellipsis, overrideString: "moreh")?.navIcon(true), for: [])
                $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            }
            
            downloadButton = UIButton().then {
                $0.accessibilityIdentifier = "Download Button"
                $0.setImage(UIImage(sfString: SFSymbol.squareAndArrowDownFill, overrideString: "download")?.navIcon(true), for: [])
                $0.isHidden = true // The button will be unhidden once the content has loaded.
                $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            }
            
            upvoteButton = UIButton().then {
                $0.accessibilityIdentifier = "Upvote Button"
                $0.setImage(UIImage(sfString: SFSymbol.arrowUp, overrideString: "upvote")?.navIcon(true).getCopy(withColor: isUpvoted ? ColorUtil.upvoteColor : UIColor.white), for: [])
                $0.isHidden = upvoteCallback == nil // The button will be unhidden once the content has loaded.
                $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            }

            goToCommentsButton = UIButton().then {
                $0.accessibilityIdentifier = "Go to Comments Button"
                $0.setImage(UIImage(sfString: SFSymbol.bubbleLeftAndBubbleRightFill, overrideString: "comments")?.navIcon(true), for: [])
                $0.isHidden = commentCallback == nil
                $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            }
            
            viewInHDButton = UIButton().then {
                $0.accessibilityIdentifier = "View in HD Button"
                $0.setImage(UIImage(named: "hd")?.navIcon(true), for: [])
                $0.isHidden = true // The button will be unhidden if we load lq content
                $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            }
            
            showTitleButton = UIButton().then {
                $0.accessibilityIdentifier = "Show Title Button"
                $0.setImage(UIImage(sfString: SFSymbol.textJustifyleft, overrideString: "size")?.navIcon(true), for: [])
                $0.isHidden = !(data.text != nil && !(data.text!.isEmpty))
                $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            }
            
            size = UILabel().then {
                $0.accessibilityIdentifier = "File size"
                $0.font = UIFont.boldSystemFont(ofSize: 12)
                $0.textAlignment = .center
                $0.textColor = .white
            }
            
            bottomButtons.addArrangedSubviews(showTitleButton, goToCommentsButton, upvoteButton, viewInHDButton, size, UIView.flexSpace(), downloadButton, menuButton)
        }
    }

    func configureLayout() {
        scrollView.edgeAnchors == view.edgeAnchors
        bottomButtons.horizontalAnchors == gradientView.safeHorizontalAnchors + CGFloat(8)
        bottomButtons.topAnchor == gradientView.topAnchor + 20
        bottomButtons.bottomAnchor == gradientView.safeBottomAnchor - 8
        gradientView.horizontalAnchors == view.horizontalAnchors
        gradientView.bottomAnchor == view.bottomAnchor
    }
    
    @objc func fullscreen(_ sender: AnyObject) {
        if let strongParent = parent as? ModalMediaViewController, strongParent.fullscreen {
            strongParent.unFullscreen(self)
        } else if let strongParent = parent as? ModalMediaViewController {
            strongParent.fullscreen(self, true)
        }
    }

    func connectActions() {
        let dtap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapScrollView(recognizer:)))
        dtap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(dtap)
        if parent is ModalMediaViewController {
            let tap = UITapGestureRecognizer(target: self, action: #selector(fullscreen(_:)))
            tap.require(toFail: dtap)
            view.addGestureRecognizer(tap)
        }
        
        imageView.addLongTapGestureRecognizer {
            self.shareImage(sender: self.menuButton)
        }

        menuButton.addTarget(self, action: #selector(showContextMenu(_:)), for: .touchUpInside)
        downloadButton.addTarget(self, action: #selector(downloadImageToLibrary(_:)), for: .touchUpInside)
        goToCommentsButton.addTarget(self, action: #selector(openComments(_:)), for: .touchUpInside)
        upvoteButton.addTarget(self, action: #selector(upvote(_:)), for: .touchUpInside)
        viewInHDButton.addTarget(self, action: #selector(viewInHD(_:)), for: .touchUpInside)
        showTitleButton.addTarget(self, action: #selector(showTitle(_:)), for: .touchUpInside)
    }

    func loadContent() {
        let shouldShowLq = SettingValues.dataSavingEnabled && !(SettingValues.dataSavingDisableWiFi) && NetworkMonitor.shared.online
        let imageURL: URL
        if let lqURL = data.lqURL, !SettingValues.loadContentHQ && shouldShowLq && !forceHD {
            imageURL = lqURL
            viewInHDButton.isHidden = false
        } else {
            if ContentType.isImgurLink(uri: data.baseURL!) {
                let urlString = "\(data.baseURL!).png"
                imageURL = URL.init(string: urlString)!
            } else {
                imageURL = data.baseURL!
            }
            viewInHDButton.isHidden = true
        }

        setProgressViewVisible(true)

        loadImage(imageURL: imageURL) { [weak self] (image, isPreview, finalSize) in
            if let strongSelf = self {
                if strongSelf.imageView.image != nil, !isPreview {
                    // If replacing a preview with a full-quality image,
                    // only replace the image (don't redo layout).
                    // This lets us invisibly swap in-place.
                    strongSelf.imageView.image = image
                } else if !(isPreview && finalSize == .zero) {
                    if let size = finalSize, finalSize != CGSize.zero {
                        strongSelf.imageView.image = image
                        let maxFrame = strongSelf.view.frame.size
                        var newSize = maxFrame

                        let minWidth = maxFrame.width / size.width
                        let minHeight = maxFrame.height / size.height
                        
                        if minHeight < minWidth {
                            newSize.width = newSize.height / size.height * size.width
                        } else if minWidth < minHeight {
                            newSize.height = newSize.width / size.width * size.height
                        }

                        var newFrame = strongSelf.imageView.frame
                        newFrame.size = size
                        strongSelf.imageView.frame = newFrame
                        strongSelf.scrollView.contentSize = size
                        strongSelf.overrideSize = size
                    } else {
                        strongSelf.imageView.contentMode = .scaleAspectFit
                        strongSelf.imageView.image = image
                        strongSelf.imageView.sizeToFit()
                        strongSelf.scrollView.contentSize = image.size
                        strongSelf.view.setNeedsLayout()
                    }
                    
                    strongSelf.imageView.setNeedsLayout()
                }
                // Update UI
                strongSelf.setProgressViewVisible(false)
                strongSelf.downloadButton.isHidden = false
                strongSelf.size.isHidden = true
            }
        }
    }

    func loadImage(imageURL: URL, completion: @escaping ((UIImage, Bool, CGSize?) -> Void) ) {

        // If the full-size image is already in the cache, just use that.
        if let image = SDImageCache.shared.imageFromDiskCache(forKey: imageURL.absoluteString) {
            DispatchQueue.main.async {
                completion(image, false, nil)
            }
        } else {
            // If the image isn't cached, call the completion with the preview
            // image, then load the full-resolution image and call the completion
            // with it when done.
            if let parent = parent as? ModalMediaViewController,
                let previewImage = parent.previewImage {
                self.setProgressViewVisible(true)
                self.downloadButton.isHidden = true
                self.size.isHidden = false
                completion(previewImage, true, parent.finalSize)
            }
            SDWebImageDownloader.shared.downloadImage(
                with: imageURL,
                options: [.allowInvalidSSLCertificates, .scaleDownLargeImages],
                progress: { (current: NSInteger, total: NSInteger, _) in

                    var average: Float = 0
                    average = (Float(current) / Float(total))
                    let countBytes = ByteCountFormatter()
                    countBytes.allowedUnits = [.useMB]
                    countBytes.countStyle = .file
                    let fileSize = countBytes.string(fromByteCount: Int64(total))
                    if average > 0 {
                        DispatchQueue.main.async {
                            self.size.text = fileSize
                            if total == 0 {
                                self.parent?.dismiss(animated: true, completion: {
                                    self.failureCallback?(imageURL)
                                })
                            }
                        }
                    }

                    DispatchQueue.main.async {
                        self.updateProgress(CGFloat(average), "")
                    }

                },
                completed: { (image, data, _, _) in
                    // Cache the full-size image.
                    SDImageCache.shared.store(image, imageData: data, forKey: imageURL.absoluteString, toDisk: true, completion: nil)
                    DispatchQueue.main.async {
                        if let image = image {
                            completion(image, false, nil)
                        }
                    }
                })
        }
    }

}

// MARK: - Actions
extension ImageMediaViewController {
    @IBAction func handleDoubleTapScrollView(recognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            let zoomRect = zoomRectForScale(scale: scrollView.minimumZoomScale, center: recognizer.location(in: recognizer.view))
            scrollView.zoom(to: zoomRect, animated: true)
//            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let height = view.bounds.size.height
            let width = view.bounds.size.width
            let size = CGSize(width: width, height: height - bottomButtons.bounds.size.height)
            let zoomRect = zoomRectForScale(scale: getFitZoomScale(size), center: recognizer.location(in: recognizer.view))
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }

    @objc func downloadImageToLibrary(_ sender: AnyObject) {
        if let image = self.imageView.image {
            DispatchQueue.global(qos: .userInteractive).async {
                CustomAlbum.shared.save(image: image, parent: self)
            }
        } else {
            print("No image exists to be downloaded!")
        }
    }

    // Reloads the image with the HQ version of the image.
    @objc func viewInHD(_ sender: AnyObject) {
        forceHD = true
        loadContent()
    }

    @objc func showTitle(_ sender: AnyObject) {
        let alert = AlertController.init(title: "Caption", message: nil, preferredStyle: .alert)
        
        alert.setupTheme()
        alert.attributedTitle = NSAttributedString(string: "Caption", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        
        alert.attributedMessage = TextDisplayStackView.createAttributedChunk(baseHTML: data.text!.trimmed(), fontSize: 14, submission: false, accentColor: ColorUtil.baseAccent, fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil)
        
        alert.addCloseButton()
        alert.addBlurView()
        present(alert, animated: true, completion: nil)
    }

    @objc func showContextMenu(_ sender: UIButton) {
        guard let url = self.data.baseURL else {
            return
        }
        
        let alertController = DragDownAlertMenu(title: "Image options", subtitle: url.absoluteString, icon: url.absoluteString)
        
        alertController.addAction(title: "Share image URL", icon: UIImage(sfString: SFSymbol.link, overrideString: "share")!.menuIcon()) {
            let shareItems: Array = [url]
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
            if let presenter = activityViewController.popoverPresentationController {
                presenter.sourceView = sender
                presenter.sourceRect = sender.bounds
            }
            let window = UIApplication.shared.keyWindow!
            if let modalVC = window.rootViewController?.presentedViewController {
                modalVC.present(activityViewController, animated: true, completion: nil)
            } else {
                window.rootViewController!.present(activityViewController, animated: true, completion: nil)
            }
        }
        
        alertController.addAction(title: "Share image", icon: UIImage(sfString: SFSymbol.squareAndArrowUp, overrideString: "image")!.menuIcon(), action: {
            self.shareImage(sender: sender)
        })
        
        alertController.addAction(title: "Copy URL", icon: UIImage(sfString: SFSymbol.docOnDocFill, overrideString: "copy")!.menuIcon()) {
            UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
            BannerUtil.makeBanner(text: "URL Copied", seconds: 5, context: self)
        }
        
        alertController.addAction(title: "Open in default app", icon: UIImage(sfString: SFSymbol.safariFill, overrideString: "nav")!.menuIcon()) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
        
        let open = OpenInChromeController.init()
        if open.isChromeInstalled() {
            alertController.addAction(title: "Open in Chrome", icon: UIImage(named: "world")!.menuIcon()) {
                open.openInChrome(url, callbackURL: nil, createNewTab: true)
            }
        }

        if let topController = UIApplication.topViewController(base: self) {
            alertController.show(topController)
        } else {
            alertController.show(self)
        }
    }
    
    func shareImage(sender: UIView) {
        let shareItems: Array = [self.imageView.image!]
        let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        if let presenter = activityViewController.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        if let topController = UIApplication.topViewController(base: self) {
            topController.present(activityViewController, animated: true, completion: nil)
        } else {
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
}

extension ImageMediaViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func updateMinZoomScaleForSize(_ size: CGSize, overrideSize: CGSize?) {
        let widthScale = (size.width / (overrideSize?.width ?? imageView.image?.size.width ?? imageView.bounds.width))
        let heightScale = (size.height / (overrideSize?.height ?? imageView.image?.size.height ?? imageView.bounds.height))
        let minScale = min(widthScale, heightScale)
        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
    }

    func getFitZoomScale(_ size: CGSize) -> CGFloat {
        let widthScale = (size.width / (imageView.image?.size.width ?? imageView.bounds.width))
        let heightScale = (size.height / (imageView.image?.size.height ?? imageView.bounds.height))
        let maxScale = max(widthScale, heightScale)
        return maxScale
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForSize(view.bounds.size)
    }

    func updateConstraintsForSize(_ size: CGSize) {
        let imageViewSize = imageView.frame.size
        let scrollViewSize = scrollView.bounds.size
        let verticalInset = imageViewSize.height < scrollViewSize.height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0
        let horizontalInset = imageViewSize.width < scrollViewSize.width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0
        scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }

    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width = imageView.frame.size.width / scale
        let newCenter = imageView.convert(center, from: scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
}

extension ImageMediaViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return scrollView.zoomScale == min(scrollView.minimumZoomScale, 1)
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value) })
}

extension UIApplication {
    
    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
