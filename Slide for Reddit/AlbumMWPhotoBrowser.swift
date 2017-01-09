//
//  AlbumMWPhotoBrowser.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/2/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import MHVideoPhotoGallery

class AlbumMWPhotoBrowser: NSObject, MHGalleryDataSource {
    
    var browser: MHGalleryController?
    weak var blockGal: MHGalleryController?

    func getThumbnailUrl(hash: String) -> String {
    return "https://i.imgur.com/" + hash + "s.png";
    }

    func create(hash: String) -> MHGalleryController {
    browser = ThemedGalleryViewController.gallery(withPresentationStyle: .imageViewerNavigationBarShown)
        browser?.dataSource = self
        browser?.autoplayVideos = true
        blockGal = browser
        browser?.finishedCallback = { currentIndex, image, interactiveTransition, viewMode in
            //do stuff
            DispatchQueue.main.async(execute: { () -> Void in
                let imageView = UIImageView(image: nil)
                self.blockGal?.dismiss(animated: true, dismiss: imageView, completion: nil)
            })
            
        }
        getAlbum(hash: hash)
        return browser!
    }
    
    func numberOfItems(inGallery galleryController: MHGalleryController!) -> Int {
        return photos.count
    }
    
    func item(for index: Int) -> MHGalleryItem! {
        return photos[index]
    }
    
    
    var albumImages:[URL]=[]
    var photos: [MHGalleryItem] = []
    
    func getAlbum(hash: String){
        let urlString = "http://imgur.com/ajaxalbums/getimages/\(hash)/hit.json?all=true"
        print(urlString)
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with:url!) { (data, response, error) in
            if error != nil {
                print(error ?? "Error loading album...")
            } else {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                        return
                    }
                    
                    let album = AlbumJSONBase.init(dictionary: json)
                    for a in (album?.data?.images)!{
                        let urls = "https://imgur.com/" + a.hash! + ((a.animated != nil && a.animated == "true") ? ".mp4" : ".png")
                        let url = URL.init(string: urls)
                        if(ContentType.isGif(uri: url!)){
                            let photo = MHGalleryItem.init(url: urls, galleryType: .video)
                            if((a.description) != nil){
                                photo?.descriptionString = a.description
                            }
                            self.photos.append(photo!)
                        } else {
                            let photo = MHGalleryItem.init(url: urls, thumbnailURL: self.getThumbnailUrl(hash: a.hash!))
                            if((a.description) != nil){
                                photo?.descriptionString = a.description
                            }
                            self.photos.append(photo!)
                        }

                    }

                    DispatchQueue.main.async{

                    self.refresh()
                    }
                } catch let error as NSError {
                    print(error)
                }
            }
            
            }.resume()
    }
    
    func refresh(){
        print("reloading")
        browser?.reloadData()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
