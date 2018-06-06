//
//  ViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 01/04/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import SDWebImage
import MaterialComponents.MaterialSnackbar
import XLActionController
import Starscream

class LiveThreadViewController: MediaViewController, UICollectionViewDelegate, WrappingFlowLayoutDelegate, UICollectionViewDataSource {

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

        tableView.backgroundColor = ColorUtil.backgroundColor
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
    }

    func collectionView(_ collectionView: UICollectionView, width: CGFloat, indexPath: IndexPath) -> CGSize {
        let data = content[indexPath.row]
        var itemWidth = width - 10
        let id = data["id"] as! String
        if (estimatedHeights[id] == nil) {
            let titleString = NSMutableAttributedString.init(string: data["author"] as! String, attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 14, submission: true)])
            
            var content: CellContent?
            if (!(data["body_html"] as? String ?? "").isEmpty()) {
                var html = (data["body_html"] as! String).gtm_stringByUnescapingFromHTML()!
                html = html.trimmed()
                do {
                    html = WrapSpoilers.addSpoilers(html)
                    html = WrapSpoilers.addTables(html)
                    let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
                    let font = FontGenerator.fontOfSize(size: 16, submission: false)
                    let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: .white)
                    content = CellContent.init(string: LinkParser.parse(attr2, .white), width: (width - 16))
                } catch {
                }
            }
            var imageHeight = 0
            if(data["mobile_embeds"] != nil && !(data["mobile_embeds"] as? JSONArray)!.isEmpty){
                if let embedsB = data["mobile_embeds"] as? JSONArray, let embeds = embedsB[0] as? JSONDictionary, let height = embeds["height"] as? Int, let width = embeds["width"] as? Int, let url = embeds["original_url"] as? String {
                    let ratio = Double(height) / Double(width)
                    let width = Double(itemWidth);
                    imageHeight = Int(width * ratio)
                }
            }

            let framesetterT = CTFramesetterCreateWithAttributedString(titleString)
            let textSizeT = CTFramesetterSuggestFrameSizeWithConstraints(framesetterT, CFRange(), nil, CGSize.init(width: itemWidth - 16, height: CGFloat.greatestFiniteMagnitude), nil)
            if (content != nil) {
                let framesetterB = CTFramesetterCreateWithAttributedString(content!.attributedString)
                let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: itemWidth - 16, height: CGFloat.greatestFiniteMagnitude), nil)
                
                estimatedHeights[id] = CGFloat(34 + textSizeT.height + textSizeB.height + CGFloat(imageHeight))
            } else {
                estimatedHeights[id] = CGFloat(34 + textSizeT.height +  CGFloat(imageHeight))
            }
        }
        return CGSize(width: itemWidth, height: estimatedHeights[id]!)
    }

    var estimatedHeights: [String: CGFloat] = [:]

    func refresh() {
        do {
            try session?.getLiveThreadDetails(id, completion: { (result) in
                switch(result){
                case .failure(let error):
                    print(error)
                    break
                case .success(let rawdetails):
                    self.getOldThreads()
                    self.doInfo(((rawdetails as! JSONDictionary)["data"] as! JSONDictionary))
                    if(!(((rawdetails as! JSONDictionary)["data"] as! JSONDictionary)["websocket_url"] is NSNull)){
                        self.setupWatcher(websocketUrl: ((rawdetails as! JSONDictionary)["data"] as! JSONDictionary)["websocket_url"] as! String)
                    }
                }
            })
        } catch {
            print(error)
        }
    }
    
    func doInfo(_ json: JSONDictionary){
        self.baseData = json
        self.title = json["title"] as! String
        let more = UIButton.init(type: .custom)
        more.setImage(UIImage.init(named: "info")?.navIcon(), for: UIControlState.normal)
        more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
        more.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        var moreB = UIBarButtonItem.init(customView: more)
        navigationItem.rightBarButtonItem = moreB
    }
    
    var baseData: JSONDictionary?
    func showMenu(_ sender: AnyObject){
        let alert = UIAlertController.init(title: baseData!["title"] as! String, message: "\n\n\(baseData!["viewer_count"] as! Int) watching\n\n\n\(baseData!["description"] as! String)" , preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    func getOldThreads(){
        do {
            try session?.getCurrentThreads(id, completion: { (result) in
                switch(result){
                case .failure(let error):
                    print(error)
                    break
                case .success(let rawupdates):
                    for item in rawupdates{
                        self.content.append((item as! JSONDictionary)["data"] as! JSONDictionary)
                    }
                    self.doneLoading()
                }
            })
        } catch {
            
        }
    }
    
    var socket: WebSocket?
    func setupWatcher(websocketUrl: String){
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
                if((text as! JSONDictionary)["type"] as! String == "update"){
                    if let payload = (text as! JSONDictionary)["payload"] as? JSONDictionary, let data = payload["data"] as? JSONDictionary{
                        DispatchQueue.main.async {
                            self.content.insert(data, at: 0)
                            self.tableView.reloadData()
                            self.flowLayout.reset()
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
            self.tableView.reloadData()
            self.flowLayout.reset()
        }
    }
}
