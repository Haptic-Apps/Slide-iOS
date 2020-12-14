//
//  ViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 01/04/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import reddift
import SDWebImage
import Starscream
import UIKit
import YYText

class LiveThreadViewController: MediaViewController, UICollectionViewDelegate, WrappingFlowLayoutDelegate, UICollectionViewDataSource {
    func headerOffset() -> Int {
        return 0
    }
    
    var tableView: UICollectionView!
    var id: String

    init(id: String) {
        self.id = id
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: GMColor.red500Color())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(true, animated: false)
        socket?.connect()
        UIApplication.shared.isIdleTimerDisabled = true
    }

    var flowLayout: WrappingFlowLayout = WrappingFlowLayout.init()

    override func viewDidLoad() {
        super.viewDidLoad()
        flowLayout.delegate = self
        let frame = self.view.bounds
        self.tableView = UICollectionView(frame: frame, collectionViewLayout: flowLayout)
        tableView.contentInset = UIEdgeInsets.init(top: 4, left: 0, bottom: 56, right: 0)
        self.view = UIView.init(frame: CGRect.zero)

        self.view.addSubview(tableView)

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(LiveThreadUpdate.classForCoder(), forCellWithReuseIdentifier: "live")

        tableView.backgroundColor = ColorUtil.theme.backgroundColor
        session = (UIApplication.shared.delegate as! AppDelegate).session

        refresh()
    }
    
    var session: Session?

    var content = [JSONDictionary]()

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return content.count
    }

    func collectionView(_ tableView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let c = tableView.dequeueReusableCell(withReuseIdentifier: "live", for: indexPath) as! LiveThreadUpdate
        c.setUpdate(rawJson: content[indexPath.row], parent: self, nav: self.navigationController, width: self.view.frame.size.width)
        return c
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        socket?.disconnect()
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    deinit {
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    var doneOnce = false
    func startPulse(_ complete: Bool) {
        if !doneOnce {
            doneOnce = true
            let progressDot = UIView()
            progressDot.alpha = 0.7
            progressDot.backgroundColor = .clear
            
            let startAngle = -CGFloat.pi / 2
            
            let center = CGPoint(x: 20 / 2, y: 20 / 2)
            let radius = CGFloat(20 / 2)
            let arc = CGFloat.pi * CGFloat(2) * 1
            
            let cPath = UIBezierPath()
            cPath.move(to: center)
            cPath.addLine(to: CGPoint(x: center.x + radius * cos(startAngle), y: center.y + radius * sin(startAngle)))
            cPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: arc + startAngle, clockwise: true)
            cPath.addLine(to: CGPoint(x: center.x, y: center.y))
            
            let circleShape = CAShapeLayer()
            circleShape.path = cPath.cgPath
            circleShape.strokeColor = GMColor.red500Color().cgColor
            circleShape.fillColor = GMColor.red500Color().cgColor
            circleShape.lineWidth = 1.5
            // add sublayer
            for layer in progressDot.layer.sublayers ?? [CALayer]() {
                layer.removeFromSuperlayer()
            }
            progressDot.layer.removeAllAnimations()
            progressDot.layer.addSublayer(circleShape)
            
            let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
            pulseAnimation.duration = 0.5
            pulseAnimation.toValue = 1.2
            pulseAnimation.fromValue = 0.2
            pulseAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            pulseAnimation.autoreverses = false
            pulseAnimation.repeatCount = Float.greatestFiniteMagnitude
            
            let fadeAnimation = CABasicAnimation(keyPath: "opacity")
            fadeAnimation.duration = 0.5
            fadeAnimation.toValue = 0
            fadeAnimation.fromValue = 2.5
            fadeAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            fadeAnimation.autoreverses = false
            fadeAnimation.repeatCount = Float.greatestFiniteMagnitude
            
            progressDot.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            let liveB = UIBarButtonItem.init(customView: progressDot)
            let more = UIButton(buttonImage: UIImage(sfString: SFSymbol.infoCircle, overrideString: "info"))
            more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControl.Event.touchUpInside)
            let moreB = UIBarButtonItem.init(customView: more)
            if complete {
                navigationItem.rightBarButtonItem = moreB
            } else {
                self.navigationItem.rightBarButtonItems = [moreB, liveB]
            }
            
            progressDot.layer.add(pulseAnimation, forKey: "scale")
            progressDot.layer.add(fadeAnimation, forKey: "fade")
        }
    }

    func collectionView(_ collectionView: UICollectionView, width: CGFloat, indexPath: IndexPath) -> CGSize {
        let data = content[indexPath.row]
        let itemWidth = width - 10
        let id = data["id"] as! String
        if estimatedHeights[id] == nil {
            let content = NSMutableAttributedString(string: "u/\(data["author"] as! String) \(DateFormatter().timeSince(from: NSDate(timeIntervalSince1970: TimeInterval(data["created_utc"] as! Int)), numericDates: true))", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor, NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 14, submission: false)])
            
            if let body = data["body_html"] as? String {
                if !body.isEmpty() {
                    let html = body.unescapeHTML
                    content.append(NSAttributedString(string: "\n"))
                   // TODO: - maybe link parsing here?
                    content.append(TextDisplayStackView.createAttributedChunk(baseHTML: html, fontSize: 16, submission: false, accentColor: ColorUtil.baseAccent, fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil))
                }
            }

            var imageHeight = 0
            if data["mobile_embeds"] != nil && !(data["mobile_embeds"] as? JSONArray)!.isEmpty {
                if let embedsB = data["mobile_embeds"] as? JSONArray, let embeds = embedsB[0] as? JSONDictionary, let height = embeds["height"] as? Int, let width = embeds["width"] as? Int {
                    print(embedsB)
                    let ratio = Double(height) / Double(width)
                    let width = Double(itemWidth)
                    imageHeight = Int(width * ratio)
                }
            }

            let size = CGSize(width: width - 18, height: CGFloat.greatestFiniteMagnitude)
            let layout = YYTextLayout(containerSize: size, text: content)!
            let infoHeight = layout.textBoundingSize.height
            estimatedHeights[id] = CGFloat(24 + infoHeight + CGFloat(imageHeight))
        }
        return CGSize(width: itemWidth, height: estimatedHeights[id]!)
    }

    var estimatedHeights: [String: CGFloat] = [:]

    func refresh() {
        do {
            try session?.getLiveThreadDetails(id, completion: { (result) in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let rawdetails):
                    self.getOldThreads()
                    let data = (rawdetails as! JSONDictionary)["data"] as! JSONDictionary
                    self.doInfo(data)
                    if let websocketURL = data["websocket_url"] {
                        self.setupWatcher(websocketUrl: websocketURL as! String)
                    }
                }
            })
        } catch {
            print(error)
        }
    }
    
    func doInfo(_ json: JSONDictionary) {
        self.baseData = json
        DispatchQueue.main.async {
            self.title = (json["title"] as? String) ?? ""
            self.startPulse((json["state"] as? String ?? "complete") == "complete")
        }
    }
    
    var baseData: JSONDictionary?
    @objc func showMenu(_ sender: AnyObject) {
        let alert = UIAlertController.init(title: (baseData!["title"] as? String) ?? "", message: "\n\n\(baseData!["viewer_count"] as! Int) watching\n\n\n\(baseData!["description"] as! String)", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    func getOldThreads() {
        do {
            try session?.getCurrentThreads(id, completion: { (result) in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let rawupdates):
                    for item in rawupdates {
                        self.content.append((item as! JSONDictionary)["data"] as! JSONDictionary)
                    }
                    self.doneLoading()
                }
            })
        } catch {
            
        }
    }
    
    var socket: WebSocket?
    func setupWatcher(websocketUrl: String) {
        socket = WebSocket(url: URL(string: websocketUrl)!)
        //websocketDidConnect
        socket!.onConnect = {
            print("websocket is connected")
        }
        //websocketDidDisconnect
        socket!.onDisconnect = { (error: Error?) in
            print("websocket is disconnected: \(error?.localizedDescription ?? "")")
        }
        //websocketDidReceiveMessage
        socket!.onText = { (text: String) in
            print("got some text: \(text)")
            do {
                let text = try JSONSerialization.jsonObject(with: text.data(using: .utf8)!, options: [])
                if (text as! JSONDictionary)["type"] as! String == "update" {
                    if let payload = (text as! JSONDictionary)["payload"] as? JSONDictionary, let data = payload["data"] as? JSONDictionary {
                        DispatchQueue.main.async {
                            self.content.insert(data, at: 0)
                            self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: false)
                            let contentHeight = self.tableView.contentSize.height
                            let offsetY = self.tableView.contentOffset.y
                            let bottomOffset = contentHeight - offsetY
                            if #available(iOS 11.0, *) {
                                CATransaction.begin()
                                CATransaction.setDisableActions(true)
                                self.tableView.performBatchUpdates({
                                    self.tableView.insertItems(at: [IndexPath(row: 0, section: 0)])
                                }, completion: { (_) in
                                    self.tableView.contentOffset = CGPoint(x: 0, y: self.tableView.contentSize.height - bottomOffset)
                                    CATransaction.commit()
                                })
                            } else {
                                self.tableView.insertItems(at: [IndexPath(row: 0, section: 0)])
                            }
                        }
                    }
                }
            } catch {
                
            }
        }
        //websocketDidReceiveData
        socket!.onData = { (data: Data) in
            print("got some data: \(data.count)")
        }
        //you could do onPong as well.
        socket!.connect()
    }

    func doneLoading() {
        DispatchQueue.main.async {
            self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: false)
            self.tableView.reloadData()
        }
    }
}
