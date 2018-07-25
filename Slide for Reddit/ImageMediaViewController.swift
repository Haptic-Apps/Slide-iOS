//
//  ImageMediaViewController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/9/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
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

    var forceHD = false

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()
        configureLayout()
        connectActions()
        loadContent()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateConstraintsForSize(view.bounds.size)
        let height = view.bounds.size.height
        let width = view.bounds.size.width
        let size = CGSize(width: width, height: height - bottomButtons.bounds.size.height)
        updateMinZoomScaleForSize(size)
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
            $0.contentMode = .scaleAspectFit
        }
        scrollView.addSubview(imageView)

        // Buttons along bottom

        bottomButtons = UIStackView().then {
            $0.accessibilityIdentifier = "Bottom Buttons"
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 8
        }
        view.addSubview(bottomButtons)

        menuButton = UIButton().then {
            $0.accessibilityIdentifier = "More Button"
            $0.setImage(UIImage(named: "moreh")?.navIcon(), for: [])
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }

        downloadButton = UIButton().then {
            $0.accessibilityIdentifier = "Download Button"
            $0.setImage(UIImage(named: "download")?.navIcon(), for: [])
            $0.isHidden = true // The button will be unhidden once the content has loaded.
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }

        goToCommentsButton = UIButton().then {
            $0.accessibilityIdentifier = "Go to Comments Button"
            $0.setImage(UIImage(named: "comments")?.navIcon(), for: [])
            $0.isHidden = commentCallback == nil
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }

        viewInHDButton = UIButton().then {
            $0.accessibilityIdentifier = "View in HD Button"
            $0.setImage(UIImage(named: "hd")?.navIcon(), for: [])
            $0.isHidden = true // The button will be unhidden if we load lq content
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }

        showTitleButton = UIButton().then {
            $0.accessibilityIdentifier = "Show Title Button"
            $0.setImage(UIImage(named: "size")?.navIcon(), for: [])
            $0.isHidden = !(data.text != nil && !(data.text!.isEmpty))
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }
        
        size = UILabel().then {
            $0.accessibilityIdentifier = "File size"
            $0.font = UIFont.boldSystemFont(ofSize: 12)
            $0.textAlignment = .center
            $0.textColor = .white
        }

        bottomButtons.addArrangedSubviews(showTitleButton, goToCommentsButton, viewInHDButton, size, UIView.flexSpace(), downloadButton, menuButton)

    }

    func configureLayout() {
        scrollView.edgeAnchors == view.edgeAnchors

        bottomButtons.horizontalAnchors == view.safeHorizontalAnchors + CGFloat(8)
        bottomButtons.bottomAnchor == view.safeBottomAnchor - CGFloat(8)
    }
    
    func fullscreen(_ sender: AnyObject) {
        if (parent as! ModalMediaViewController).fullscreen {
            (parent as! ModalMediaViewController).unFullscreen(self)
        } else {
            (parent as! ModalMediaViewController).fullscreen(self)
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

        menuButton.addTarget(self, action: #selector(showContextMenu(_:)), for: .touchUpInside)
        downloadButton.addTarget(self, action: #selector(downloadImageToLibrary(_:)), for: .touchUpInside)
        goToCommentsButton.addTarget(self, action: #selector(openComments(_:)), for: .touchUpInside)
        viewInHDButton.addTarget(self, action: #selector(viewInHD(_:)), for: .touchUpInside)
        showTitleButton.addTarget(self, action: #selector(showTitle(_:)), for: .touchUpInside)
    }

    func loadContent() {
        let shouldShowLq = SettingValues.dataSavingEnabled && !(SettingValues.dataSavingDisableWiFi && LinkCellView.checkWiFi())
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

        loadImage(imageURL: imageURL) { [weak self] (image) in
            if let strongSelf = self {
                strongSelf.imageView.image = image
                strongSelf.imageView.sizeToFit()
                strongSelf.scrollView.contentSize = image.size
                strongSelf.view.setNeedsLayout()

                // Update UI
                strongSelf.setProgressViewVisible(false)
                strongSelf.progressView.isHidden = true
                strongSelf.downloadButton.isHidden = false
                strongSelf.size.isHidden = true

            }
        }
    }

    func loadImage(imageURL: URL, completion: @escaping ((UIImage) -> Void) ) {

        if SDWebImageManager.shared().cachedImageExists(for: imageURL) {
            DispatchQueue.main.async {
                if let image = SDWebImageManager.shared().imageCache.imageFromDiskCache(forKey: imageURL.absoluteString) {
                    completion(image)
                }
            }
        } else {
            SDWebImageDownloader.shared().downloadImage(with: imageURL, options: .allowInvalidSSLCertificates, progress: { (current: NSInteger, total: NSInteger) in

                var average: Float = 0
                average = (Float(current) / Float(total))
                let countBytes = ByteCountFormatter()
                countBytes.allowedUnits = [.useMB]
                countBytes.countStyle = .file
                let fileSize = countBytes.string(fromByteCount: Int64(total))
                if average > 0 {
                    self.size.text = fileSize
                }
                self.progressView.progress = average

            }, completed: { (image, _, _, _) in

                SDWebImageManager.shared().saveImage(toCache: image, for: imageURL)
                DispatchQueue.main.async {
                    if let image = image {
                        completion(image)
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
            let zoomRect = zoomRectForScale(scale: scrollView.maximumZoomScale, center: recognizer.location(in: recognizer.view))
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }

    func downloadImageToLibrary(_ sender: AnyObject) {
        if let image = imageView.image {
            CustomAlbum.shared.save(image: image, parent: self)
        } else {
            print("No image exists to be downloaded!")
        }
    }

    // Reloads the image with the HQ version of the image.
    func viewInHD(_ sender: AnyObject) {
        forceHD = true
        loadContent()
    }

    func showTitle(_ sender: AnyObject) {
        let alertController = UIAlertController.init(title: "Caption", message: nil, preferredStyle: .alert)
        alertController.addTextViewer(text: .text(data.text!))
        alertController.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    func showContextMenu(_ sender: UIButton) {
        guard let baseURL = self.data.baseURL else {
            return
        }
        let alert = UIAlertController.init(title: baseURL.absoluteString, message: "", preferredStyle: .actionSheet)
        let open = OpenInChromeController.init()
        if open.isChromeInstalled() {
            alert.addAction(
                UIAlertAction(title: "Open in Chrome", style: .default) { (_) in
                    open.openInChrome(baseURL, callbackURL: nil, createNewTab: true)
                }
            )
        }
        alert.addAction(
            UIAlertAction(title: "Open in Safari", style: .default) { (_) in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(baseURL, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(baseURL)
                }
            }
        )
        alert.addAction(
            UIAlertAction(title: "Share URL", style: .default) { (_) in
                let shareItems: Array = [baseURL]
                let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
                let window = UIApplication.shared.keyWindow!
                if let modalVC = window.rootViewController?.presentedViewController {
                    modalVC.present(activityViewController, animated: true, completion: nil)
                } else {
                    window.rootViewController!.present(activityViewController, animated: true, completion: nil)
                }
            }
        )
        alert.addAction(
            UIAlertAction(title: "Share Image", style: .default) { (_) in
                let shareItems: Array = [self.imageView.image!]
                let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
                let window = UIApplication.shared.keyWindow!
                if let modalVC = window.rootViewController?.presentedViewController {
                    modalVC.present(activityViewController, animated: true, completion: nil)
                } else {
                    window.rootViewController!.present(activityViewController, animated: true, completion: nil)
                }
            }
        )
        alert.addAction(
            UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            }
        )
        let window = UIApplication.shared.keyWindow!
        alert.modalPresentationStyle = .popover

        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }

        if let modalVC = window.rootViewController?.presentedViewController {
            modalVC.present(alert, animated: true, completion: nil)
        } else {
            window.rootViewController!.present(alert, animated: true, completion: nil)
        }
    }
}

extension ImageMediaViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func updateMinZoomScaleForSize(_ size: CGSize) {
        let widthScale = size.width / (imageView.image?.size.width ?? imageView.bounds.width)
        let heightScale = size.height / (imageView.image?.size.height ?? imageView.bounds.height)
        let minScale = min(widthScale, heightScale)
        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
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

}
