//
//  MediaDisplayViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/2/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialProgressView
import SDWebImage

class MediaDisplayViewController: VideoDisplayer, UIScrollViewDelegate, UIGestureRecognizerDelegate {

    var baseURL: URL?
    var loadedURL: URL?
    var type: ContentType.CType = ContentType.CType.UNKNOWN
    var lqURL: URL?
    var text: String?

    var imageView = UIImageView()
    var menuB: UIBarButtonItem?
    var inAlbum = false

    init(url: URL, text: String?, lqURL: URL?, inAlbum: Bool = false) {
        super.init(nibName: nil, bundle: nil)
        self.baseURL = url
        self.lqURL = lqURL
        self.text = text
        self.inAlbum = inAlbum
        type = ContentType.getContentType(baseUrl: url)
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func displayImage(baseImage: UIImage?) {
        if (baseImage == nil) {

        }
        if let image = baseImage {
            self.imageLoaded = true
            if (image.size.height > image.size.width ||  UIApplication.shared.statusBarOrientation != .portrait) {
                self.scrollView.contentSize = CGSize.init(width: min(self.view.frame.size.width, getWidthFromAspectRatio(imageHeight: image.size.height, imageWidth: image.size.width)), height: self.view.frame.size.height)
            } else {
                self.scrollView.contentSize = CGSize.init(width: self.view.frame.size.width, height: min(self.view.frame.size.height, getHeightFromAspectRatio(imageHeight: image.size.height, imageWidth: image.size.width)))
            }
            self.scrollView.delegate = self

            let dtap = UITapGestureRecognizer.init(target: self, action: #selector(handleDoubleTapScrollView(recognizer:)))
            dtap.numberOfTapsRequired = 2
            self.scrollView.addGestureRecognizer(dtap)

            if (!inAlbum) {
                let tap = UITapGestureRecognizer.init(target: self, action: #selector(close(recognizer:)))
                tap.require(toFail: dtap)
                self.scrollView.addGestureRecognizer(tap)
            }

            imageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
            imageView.contentMode = .scaleAspectFit
            self.scrollView.addSubview(imageView)
            imageView.image = image

            if (showHQ) {
                var items: [UIBarButtonItem] = []
                if (text != nil && !(text!.isEmpty)) {
                    let textB = UIBarButtonItem(image: UIImage(named: "size")?.navIcon(), style: .plain, target: self, action: #selector(MediaDisplayViewController.showTitle(_:)))
                    items.append(textB)
                }
                let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
                let hdB = UIBarButtonItem(image: UIImage(named: "hd")?.navIcon(), style: .plain, target: self, action: #selector(MediaDisplayViewController.hd(_:)))
                items.append(hdB)
                items.append(space)
                items.append(UIBarButtonItem(image: UIImage(named: "download")?.navIcon(), style: .plain, target: self, action: #selector(MediaDisplayViewController.download(_:))))
                menuB = UIBarButtonItem(image: UIImage(named: "moreh")?.navIcon(), style: .plain, target: self, action: #selector(MediaDisplayViewController.showImageMenu(_:)))
                items.append(menuB!)


                toolbar.items = items

            }
        }
    }

    func close(recognizer: UITapGestureRecognizer) {
        self.parent?.dismiss(animated: true, completion: nil)
    }

    func hd(_ sender: AnyObject) {
        size?.isHidden = false
        var items: [UIBarButtonItem] = []
        if (text != nil && !(text!.isEmpty)) {
            let textB = UIBarButtonItem(image: UIImage(named: "size")?.navIcon(), style: .plain, target: self, action: #selector(MediaDisplayViewController.showTitle(_:)))
            items.append(textB)
        }
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        items.append(space)
        items.append(UIBarButtonItem(image: UIImage(named: "download")?.navIcon(), style: .plain, target: self, action: #selector(MediaDisplayViewController.download(_:))))
        menuB = UIBarButtonItem(image: UIImage(named: "moreh")?.navIcon(), style: .plain, target: self, action: #selector(MediaDisplayViewController.showImageMenu(_:)))
        items.append(menuB!)
        toolbar.items = items

        progressView?.setHidden(false, animated: true, completion: nil)
        showHQ = false
        loadImage(imageURL: baseURL!)
    }

    @IBAction func handleDoubleTapScrollView(recognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale == 1 {
            scrollView.zoom(to: zoomRectForScale(scale: 2.5, center: recognizer.location(in: recognizer.view)), animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)
        }
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


    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func loadImage(imageURL: URL) {
        loadedURL = imageURL
        if (SDWebImageManager.shared().cachedImageExists(for: imageURL)) {
            DispatchQueue.main.async {
                let image = SDWebImageManager.shared().imageCache.imageFromDiskCache(forKey: imageURL.absoluteString)
                self.progressView?.setHidden(true, animated: true)
                self.size?.isHidden = true
                self.displayImage(baseImage: image)
            }

        } else {
            SDWebImageDownloader.shared().downloadImage(with: imageURL, options: .allowInvalidSSLCertificates, progress: { (current: NSInteger, total: NSInteger) in
                var average: Float = 0
                average = (Float(current) / Float(total))
                let countBytes = ByteCountFormatter()
                countBytes.allowedUnits = [.useMB]
                countBytes.countStyle = .file
                let fileSize = countBytes.string(fromByteCount: Int64(total))
                self.size!.text = fileSize
                self.progressView!.progress = average
            }, completed: { (image, _, error, _) in
                SDWebImageManager.shared().saveImage(toCache: image, for: imageURL)
                DispatchQueue.main.async {
                    self.progressView?.setHidden(true, animated: true)
                    self.size?.isHidden = true
                    self.displayImage(baseImage: image)
                }
            })
        }
    }

    func getHeightFromAspectRatio(imageHeight: CGFloat, imageWidth: CGFloat) -> CGFloat {
        let ratio = Double(imageHeight) / Double(imageWidth)
        let width = Double(view.frame.size.width);
        return CGFloat(width * ratio)
    }

    func getWidthFromAspectRatio(imageHeight: CGFloat, imageWidth: CGFloat) -> CGFloat {
        let ratio = Double(imageWidth) / Double(imageHeight)
        let height = Double(view.frame.size.height);
        return CGFloat(height * ratio)
    }

    var toolbar = UIToolbar()


    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView = UIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        self.scrollView.contentSize = CGSize.init(width: self.view.frame.width, height: self.view.frame.height)
        self.scrollView.delegate = self

        self.scrollView.minimumZoomScale = 1
        self.scrollView.maximumZoomScale = 6.0
        self.scrollView.backgroundColor = .clear
        self.view.addSubview(scrollView)


        (parent as? SwipeDownModalVC)?.background?.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toolbar = UIToolbar.init(frame: CGRect.init(x: 0, y: self.view.frame.size.height - 35, width: self.view.frame.size.width, height: 30))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        var items: [UIBarButtonItem] = []
        if (text != nil && !(text!.isEmpty)) {
            var textB = UIBarButtonItem(image: UIImage(named: "size")?.navIcon(), style: .plain, target: self, action: #selector(MediaDisplayViewController.showTitle(_:)))
            items.append(textB)
        }
        items.append(UIBarButtonItem(image: UIImage(named: "fullscreen")?.navIcon(), style: .plain, target: self, action: #selector(MediaDisplayViewController.fullscreen(_:))))

        items.append(space)
        items.append(UIBarButtonItem(image: UIImage(named: "download")?.navIcon(), style: .plain, target: self, action: #selector(MediaDisplayViewController.download(_:))))
        menuB = UIBarButtonItem(image: UIImage(named: "moreh")?.navIcon(), style: .plain, target: self, action: #selector(MediaDisplayViewController.showImageMenu(_:)))
        items.append(menuB!)
        toolbar.items = items
        toolbar.setBackgroundImage(UIImage(),
                forToolbarPosition: .any,
                barMetrics: .default)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        toolbar.tintColor = UIColor.white

        size = UILabel(frame: CGRect(x: 55, y: toolbar.bounds.height - 40, width: 250, height: 50))
        size?.textAlignment = .left
        size?.textColor = .white
        size?.text = "mb"
        size?.font = UIFont.boldSystemFont(ofSize: 12)
        toolbar.addSubview(size!)

        progressView = MDCProgressView()
        progressView?.progress = 0
        let progressViewHeight = CGFloat(5)
        progressView?.frame = CGRect(x: 0, y: 5 + (UIApplication.shared.statusBarView?.frame.size.height ?? 20), width: toolbar.bounds.width, height: progressViewHeight)
        self.view.addSubview(progressView!)

        self.view.addSubview(toolbar)

        startDisplay()
    }

    func showTitle(_ sender: AnyObject) {
        let alertController = MDCAlertController(title: nil, message: text!)
        let action = MDCAlertAction(title: "DONE") { (action) in
            print("OK")
        }
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }

    func fullscreen(_ sender: AnyObject) {
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            (self.parent as? SwipeDownModalVC)?.background?.backgroundColor = UIColor.black
            self.toolbar.alpha = 0

        }, completion: {finished in
            self.toolbar.isHidden = true

        })

    }



    func download(_ sender: AnyObject) {
        if(imageLoaded){
            if(imageView.image != nil){
                CustomAlbum.shared.save(image: imageView.image!)
            }
        } else {
            if(displayedVideo != nil){
                CustomAlbum.shared.saveMovieToLibrary(movieURL: displayedVideo!)
            }
        }
    }

    func showImageMenu(_ sender: AnyObject) {
        let alert = UIAlertController.init(title: baseURL?.absoluteString, message: "", preferredStyle: .actionSheet)
        let open = OpenInChromeController.init()
        if (open.isChromeInstalled()) {
            alert.addAction(
                    UIAlertAction(title: "Open in Chrome", style: .default) { (action) in
                        open.openInChrome(self.baseURL!, callbackURL: nil, createNewTab: true)
                    }
            )
        }
        alert.addAction(
                UIAlertAction(title: "Open in Safari", style: .default) { (action) in
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(self.baseURL!, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(self.baseURL!)
                    }
                }
        )
        alert.addAction(
                UIAlertAction(title: "Share URL", style: .default) { (action) in
                    let shareItems: Array = [self.baseURL!]
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
                UIAlertAction(title: "Share Image", style: .default) { (action) in
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
                UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                }
        )
        let window = UIApplication.shared.keyWindow!
        alert.modalPresentationStyle = .popover

        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = (menuB!.value(forKey: "view") as! UIView)
            presenter.sourceRect = (menuB!.value(forKey: "view") as! UIView).bounds
        }


        if let modalVC = window.rootViewController?.presentedViewController {
            modalVC.present(alert, animated: true, completion: nil)
        } else {
            window.rootViewController!.present(alert, animated: true, completion: nil)
        }
    }

    var showHQ = false
    var imageLoaded = false
    var savedColor : UIColor?

    override func viewWillAppear(_ animated: Bool) {
        savedColor = UIApplication.shared.statusBarView?.backgroundColor
        UIApplication.shared.statusBarView?.backgroundColor = .clear

        super.viewWillAppear(animated)
    }

    func startDisplay() {
        if (type == .IMAGE) {
            let shouldShowLq = SettingValues.dataSavingEnabled && !(SettingValues.dataSavingDisableWiFi && LinkCellView.checkWiFi())
            if (lqURL != nil && !SettingValues.loadContentHQ && shouldShowLq) {
                loadImage(imageURL: lqURL!)
                showHQ = true
            } else {
                loadImage(imageURL: baseURL!)
            }
        } else if (type == .GIF || type == .STREAMABLE || type == .VID_ME) {
            getGif(urlS: baseURL!.absoluteString)
        } else if (type == .IMGUR) {
            loadImage(imageURL: URL.init(string: baseURL!.absoluteString + ".png")!)
        } else if (type == .VIDEO) {
            toolbar.isHidden = true
            let he = getYTHeight()
            ytPlayer = YTPlayerView.init(frame: CGRect.init(x: 0, y: (self.view.frame.size.height - he) / 2, width: self.view.frame.size.width, height: he))
            ytPlayer.isHidden = true
            self.view.addSubview(ytPlayer)
            getYouTube(ytPlayer, urlS: baseURL!.absoluteString)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if(savedColor != nil){
            UIApplication.shared.statusBarView?.backgroundColor = savedColor
        }


        if (MediaDisplayViewController.videoPlayer != nil) {
            MediaDisplayViewController.videoPlayer!.pause()
        }

    }

    override var prefersStatusBarHidden: Bool {
        return true
    }


    /// Prevents delivery of touch gestures to AVPlayerViewController's gesture recognizer,
    /// which would cause controls to hide immediately after being shown.
    ///
    /// `-[AVPlayerViewController _handleSingleTapGesture] goes like this:
    ///
    ///     if self._showsPlaybackControlsView() {
    ///         _hidePlaybackControlsViewIfPossibleUntilFurtherUserInteraction()
    ///     } else {
    ///         _showPlaybackControlsViewIfNeededAndHideIfPossibleAfterDelayIfPlaying()
    ///     }
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if !playerVC.showsPlaybackControls {
            // print("\nshouldBeRequiredToFailByGestureRecognizer? \(otherGestureRecognizer)")
            if let tapGesture = otherGestureRecognizer as? UITapGestureRecognizer {
                if tapGesture.numberOfTouchesRequired == 1 {
                    return true
                }
            }
        }
        return false
    }

}
