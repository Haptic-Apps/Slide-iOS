//
//  AlbumViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/2/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class AlbumViewController: SwipeDownModalVC, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var vCs: [UIViewController] = [ClearVC()]
    var baseURL: URL?
    public init(urlB: URL) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)

        self.baseURL = urlB
        var url = urlB.absoluteString
        if(url.contains("/layout/")) {
            url = url.substring(0, length: (url.indexOf("/layout")!))
        }
        var rawDat = cutEnds(s: url)
        
        if (rawDat.endsWith("/")) {
            rawDat = rawDat.substring(0, length: rawDat.length - 1)
        }
        if (rawDat.contains("/") && (rawDat.length - (rawDat.lastIndexOf("/")!+1)) < 4) {
            rawDat = rawDat.replacingOccurrences(of: rawDat.substring(rawDat.lastIndexOf("/")!, length: rawDat.length - (rawDat.lastIndexOf("/")!+1)), with: "")
        }
        if (rawDat.contains("?")) {
            rawDat = rawDat.substring(0, length: rawDat.length - rawDat.indexOf("?")!)
        }
        
        let hash = getHash(sS: rawDat)
        
        getAlbum(hash: hash)
        
    }
    func cutEnds(s: String) -> String {
        if (s.endsWith("/")) {
            return s.substring(0, length: s.length - 1)
        }
        else {
            return s
        }
    }
    
    func getAlbum(hash: String) {
        let urlString = "http://imgur.com/ajaxalbums/getimages/\(hash)/hit.json?all=true"
        print(urlString)
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!) { (data, _, error) in
            if error != nil {
                print(error ?? "Error loading album...")
            }
            else {
                do {
                    if(NSString(data: data!, encoding: String.Encoding.utf8.rawValue)?.contains("[]"))! {
                        //single album image
                        let media = ModalMediaViewController(model: EmbeddableMediaDataModel(
                            baseURL: URL(string: "https://imgur.com/\(hash).png")!,
                            lqURL: URL(string: "https://imgur.com/\(hash)m.png"),
                            text: nil,
                            inAlbum: false
                        ))
                        self.vCs.append(media)
                        let firstViewController = self.vCs[1]
                        
                        self.setViewControllers([firstViewController],
                                                direction: .forward,
                                                animated: true,
                                                completion: nil)
                    }
                    else {
                        guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                            return
                        }
                        
                        let album = AlbumJSONBase.init(dictionary: json)
                        DispatchQueue.main.async {
                            for image in (album?.data?.images)! {

                                let media = ModalMediaViewController(model: EmbeddableMediaDataModel(
                                    baseURL: URL.init(string: "https://imgur.com/\(image.hash!)\(image.ext!)")!,
                                    lqURL: URL.init(string: "https://imgur.com/\(image.hash!)\(image.ext! != ".gif" ? "m":"")\(image.ext!)"),
                                    text: image.description,
                                    inAlbum: true
                                ))
                                self.vCs.append(media)
                            }
                            let firstViewController = self.vCs[1]
                            
                            self.setViewControllers([firstViewController],
                                               direction: .forward,
                                               animated: true,
                                               completion: nil)
                            self.navItem?.title = "\(self.vCs.index(of: self.viewControllers!.first!)!)/\(self.vCs.count - 1)"
                            
                        }
                    }
                }
                catch let error as NSError {
                    print(error)
                }
            }
            
            }.resume()
    }
    func getHash(sS: String) -> String {
        var s = sS
        if(s.contains("/comment/")) {
            s = s.substring(0, length: s.indexOf("/comment")!)
        }
        var next = s.substring(s.lastIndexOf("/")!, length: s.length - s.lastIndexOf("/")!)
        if (next.contains(".")) {
            next = next.substring(0, length: next.indexOf(".")!)
        }
        if (next.startsWith("/")) {
            next = next.substring(1, length: next.length - 1)
        }
        if (next.length < 5) {
            return getHash(sS: s.replacingOccurrences(of: next, with: ""))
        }
        else {
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
    }
    
    var navItem: UINavigationItem?
    
    func exit() {
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
        navItem = UINavigationItem(title: "")
        let close = UIButton.init(type: .custom)
        close.setImage(UIImage.init(named: "close")?.navIcon(), for: UIControlState.normal)
        close.addTarget(self, action: #selector(self.exit), for: UIControlEvents.touchUpInside)
        close.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let closeB = UIBarButtonItem.init(customView: close)
        navItem?.leftBarButtonItem = closeB
        
        var gridB = UIBarButtonItem(image: UIImage(named: "grid")?.navIcon().withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(overview(_:)))

       // navItem?.rightBarButtonItem = gridB

        navigationBar.setItems([navItem!], animated: false)
        self.view.addSubview(navigationBar)
        
    }
    
    func overview(_ sender: AnyObject) {
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating: Bool, previousViewControllers: [UIViewController], transitionCompleted: Bool) {
        if(pageViewController.viewControllers?.first == vCs[0]) {
            self.dismiss(animated: true, completion: nil)
        }
        navItem?.title = "\(vCs.index(of: viewControllers!.first!)!)/\(vCs.count - 1)"
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = vCs.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard vCs.count > previousIndex else {
            return nil
        }

        return vCs[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = vCs.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = vCs.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }

        return vCs[nextIndex]
    }
    
}
