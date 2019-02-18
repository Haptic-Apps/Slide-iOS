//
//  AlbumViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/2/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import RLBAlertsPickers
import SDWebImage
import UIKit

class AlbumViewController: SwipeDownModalVC, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var urlStringKeys = [String]()
    var embeddableMediaDataCache = [String: EmbeddableMediaDataModel]()
    var baseURL: URL?
    var bottomScroll = UIScrollView()
    var failureCallback: ((_ url: URL) -> Void)?
    var albumHash: String = ""
    
    public init(urlB: URL) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        
        self.baseURL = urlB
    }
    
    func cutEnds(s: String) -> String {
        if s.endsWith("/") {
            return s.substring(0, length: s.length - 1)
        } else {
            return s
        }
    }
    
    func splitHashes(_ raw: String) {
        self.spinnerIndicator.stopAnimating()
        self.spinnerIndicator.isHidden = true
        for hash in raw.split(",") {
            self.thumbs.append(URL(string: "https://imgur.com/\(hash)s.jpg")!)
            let urlStringkey = "https://imgur.com/\(hash).png"
            self.urlStringKeys.append(urlStringkey)
            self.embeddableMediaDataCache[urlStringkey] = EmbeddableMediaDataModel(
                baseURL: URL.init(string: urlStringkey)!,
                lqURL: URL.init(string: "https://imgur.com/\(hash)m.png"),
                text: nil,
                inAlbum: true
            )
        }
        let prefetcher = SDWebImagePrefetcher.shared()
        prefetcher.prefetchURLs(thumbs)

        let firstViewController = ModalMediaViewController(model: self.embeddableMediaDataCache[self.urlStringKeys[0]]!)
        
        self.setViewControllers([firstViewController],
                                direction: .forward,
                                animated: true,
                                completion: nil)
        self.navItem?.title = "1/\(self.urlStringKeys.count)"
        let overview = UIButton.init(type: .custom)
        overview.setImage(UIImage.init(named: "grid")?.navIcon(true), for: UIControl.State.normal)
        overview.addTarget(self, action: #selector(self.overview(_:)), for: UIControl.Event.touchUpInside)
        overview.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let gridB = UIBarButtonItem.init(customView: overview)

        navItem?.rightBarButtonItem = gridB
    }
    
    func getAlbum(hash: String) {
        let urlString = "http://imgur.com/ajaxalbums/getimages/\(hash)/hit.json?all=true"
        let url = URL(string: urlString)!
        if FileManager.default.fileExists(atPath: getKeyFromURL(url)) {
            do {
                if let data = try String(contentsOf: URL(fileURLWithPath: getKeyFromURL(url)), encoding: String.Encoding.utf8).data(using: String.Encoding.utf8) {
                    self.parseData(data)
                    return
                }
            } catch {
                print(error)
            }
        }
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            if error != nil || data == nil {
                print(error ?? "Error loading album...")
                self.dismiss(animated: true, completion: {
                    self.failureCallback?(self.baseURL!)
                })
            } else {
                do {
                    try data!.write(to: URL.init(fileURLWithPath: self.getKeyFromURL(url)))
                } catch {
                    print(error)
                }
                self.parseData(data!)
            }
            
            }.resume()
    }
    
    var thumbs = [URL]()
    
    func parseData(_ data: Data) {
        DispatchQueue.main.async {
            self.spinnerIndicator.stopAnimating()
            self.spinnerIndicator.isHidden = true
        }
        if(NSString(data: data, encoding: String.Encoding.utf8.rawValue)?.contains("[]"))! {
            //single album image
            DispatchQueue.main.async {
                let urlStringkey = "https://imgur.com/\(self.albumHash).png"
                self.urlStringKeys.append(urlStringkey)
                self.embeddableMediaDataCache[urlStringkey] = EmbeddableMediaDataModel(
                    baseURL: URL.init(string: urlStringkey)!,
                    lqURL: URL.init(string: "https://imgur.com/\(self.albumHash)m.png"),
                    text: nil,
                    inAlbum: false
                )
                let firstViewController = ModalMediaViewController(model: self.embeddableMediaDataCache[self.urlStringKeys[0]]!)
                
                self.setViewControllers([firstViewController],
                                        direction: .forward,
                                        animated: true,
                                        completion: nil)
                self.navItem?.title = ""
            }
        } else {
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary else {
                    return
                }
                
                let album = AlbumJSONBase.init(dictionary: json)
                DispatchQueue.main.async {
                    for image in (album?.data?.images)! {
                        self.thumbs.append(URL(string: "https://imgur.com/\(image.hash!)s.jpg")!)
                        let urlStringkey = "https://imgur.com/\(image.hash!)\(image.ext!)"
                        self.urlStringKeys.append(urlStringkey)
                        self.embeddableMediaDataCache[urlStringkey] = EmbeddableMediaDataModel(
                            baseURL: URL.init(string: urlStringkey)!,
                            lqURL: URL.init(string: "https://imgur.com/\(image.hash!)\(image.ext! != ".gif" ? "m":"")\(image.ext!)"),
                            text: image.description,
                            inAlbum: true
                        )
                    }
                    let firstViewController = ModalMediaViewController(model: self.embeddableMediaDataCache[self.urlStringKeys[0]]!)
                    
                    self.setViewControllers([firstViewController],
                                            direction: .forward,
                                            animated: true,
                                            completion: nil)
                    self.navItem?.title = "\(self.urlStringKeys.index(of: ((self.viewControllers!.first! as! ModalMediaViewController).embeddedVC.data.baseURL?.absoluteString)!)! + 1)/\(self.urlStringKeys.count)"
                    let overview = UIButton.init(type: .custom)
                    overview.setImage(UIImage.init(named: "grid")?.navIcon(true), for: UIControl.State.normal)
                    overview.addTarget(self, action: #selector(self.overview(_:)), for: UIControl.Event.touchUpInside)
                    overview.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
                    let gridB = UIBarButtonItem.init(customView: overview)

                    self.navItem?.rightBarButtonItem = gridB
                }
                let prefetcher = SDWebImagePrefetcher.shared()
                prefetcher.prefetchURLs(thumbs)
            } catch {
                print(error)
                //todo fallback
            }
        }
    }
    
    func getHash(sS: String) -> String {
        var s = sS
        if s.contains("/comment/") {
            s = s.substring(0, length: s.indexOf("/comment")!)
        }
        print(s)
        if s.endsWith("?") {
            s = s.substring(0, length: s.length - 1)
        }
        print(s)
        var next = s.substring(s.lastIndexOf("/")!, length: s.length - s.lastIndexOf("/")!)
        if next.contains(".") {
            next = next.substring(0, length: next.indexOf(".")!)
        }
        if next.startsWith("/") {
            next = next.substring(1, length: next.length - 1)
        }
        if next.length < 5 {
            return getHash(sS: s.replacingOccurrences(of: next, with: ""))
        } else {
            return next
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.automaticallyAdjustsScrollViewInsets = false
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        self.view.backgroundColor = UIColor.clear
        setNeedsStatusBarAppearanceUpdate()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    var navItem: UINavigationItem?
    var spinnerIndicator = UIActivityIndicatorView()
    
    @objc func exit() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        self.navigationController?.view.backgroundColor = UIColor.clear
        
        let navigationBar = UINavigationBar.init(frame: CGRect.init(x: 0, y: 5 + (UIApplication.shared.statusBarView?.frame.size.height ?? 20), width: self.view.frame.size.width, height: 56))
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
        navigationBar.tintColor = .white
        navItem = UINavigationItem(title: "Loading album...")
        navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.white])

        let close = UIButton.init(type: .custom)
        close.setImage(UIImage.init(named: "close")?.navIcon(true), for: UIControl.State.normal)
        close.addTarget(self, action: #selector(self.exit), for: UIControl.Event.touchUpInside)
        close.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let closeB = UIBarButtonItem.init(customView: close)
        navItem?.leftBarButtonItem = closeB
        
        spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
        spinnerIndicator.center = self.view.center
        spinnerIndicator.color = UIColor.white
        self.view.addSubview(spinnerIndicator)
        spinnerIndicator.startAnimating()
        
        navigationBar.setItems([navItem!], animated: false)
        self.view.addSubview(navigationBar)
        
        navigationBar.topAnchor == self.view.safeTopAnchor
        navigationBar.horizontalAnchors == self.view.horizontalAnchors
        navigationBar.heightAnchor == 56
        
        var url = baseURL!.absoluteString
        if url.contains("/layout/") {
            url = url.substring(0, length: (url.indexOf("/layout")!))
        }
        if url.contains("/new") {
            url = url.substring(0, length: (url.indexOf("/new")!))
        }
        var rawDat = cutEnds(s: url)

        if rawDat.endsWith("/") {
            rawDat = rawDat.substring(0, length: rawDat.length - 1)
        }
        
        if rawDat.contains("/") && (rawDat.length - (rawDat.lastIndexOf("/")!+1)) < 4 {
            rawDat = rawDat.replacingOccurrences(of: rawDat.substring(rawDat.lastIndexOf("/")!, length: rawDat.length - (rawDat.lastIndexOf("/")!+1)), with: "")
        }

        if rawDat.contains("?") {
            rawDat = rawDat.substring(0, length: rawDat.indexOf("?")!)
        }
        
        if rawDat.contains(",") {
            let index = rawDat.lastIndexOf("/") ?? -1
            let split = rawDat.substring(index + 1, length: rawDat.length - index - 1)
            splitHashes(split)
        } else {
            albumHash = getHash(sS: rawDat)
            getAlbum(hash: albumHash)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        SDImageCache.shared().clearMemory()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SDImageCache.shared().clearMemory()
    }
    
    @objc func overview(_ sender: UIBarButtonItem) {
        let alert: UIAlertController
        if UIDevice.current.userInterfaceIdiom == .pad {
            alert = UIAlertController(style: .alert)
        } else {
            alert = UIAlertController(style: .actionSheet)
        }
        alert.addAsyncImagePicker(
            flow: .vertical,
            paging: false,
            images: self.thumbs,
            selection: .single(action: { [unowned self] image in
                let firstViewController = ModalMediaViewController(model: self.embeddableMediaDataCache[self.urlStringKeys[image!]]!)
                
                self.setViewControllers([firstViewController],
                                        direction: .forward,
                                        animated: true,
                                        completion: nil)
                self.navItem?.title = "\((image ?? 0) + 1)/\(self.urlStringKeys.count)"
                alert.dismiss(animated: true, completion: nil)
            }))
        
        alert.addAction(title: "Close", style: .cancel)
        alert.showWindowless()
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating: Bool, previousViewControllers: [UIViewController], transitionCompleted: Bool) {
        navItem?.title = "\(urlStringKeys.index(of: ((viewControllers!.first! as! ModalMediaViewController).embeddedVC.data.baseURL?.absoluteString)!)! + 1)/\(urlStringKeys.count)"
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = urlStringKeys.index(of: ((viewController as! ModalMediaViewController).embeddedVC.data.baseURL?.absoluteString)!) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard urlStringKeys.count > previousIndex else {
            return nil
        }
        
        return ModalMediaViewController(model: self.embeddableMediaDataCache[self.urlStringKeys[previousIndex]]!)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = urlStringKeys.index(of: ((viewController as! ModalMediaViewController).embeddedVC.data.baseURL?.absoluteString)!) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = urlStringKeys.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return ModalMediaViewController(model: self.embeddableMediaDataCache[self.urlStringKeys[nextIndex]]!)
    }
    
    func getKeyFromURL(_ url: URL) -> String {
        let disallowedChars = CharacterSet.urlPathAllowed.inverted
        var key = url.absoluteString.components(separatedBy: disallowedChars).joined(separator: "_")
        key = key.replacingOccurrences(of: ":", with: "")
        key = key.replacingOccurrences(of: "/", with: "")
        key = key.replacingOccurrences(of: ".", with: "")
        if key.length > 200 {
            key = key.substring(0, length: 200)
        }
        
        return (SDImageCache.shared().makeDiskCachePath(key) ?? "") + ".mp4"
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}
