//
//  AlbumMWPhotoBrowser.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/2/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import ImageViewer
import SDWebImage

class AlbumMWPhotoBrowser: NSObject, GalleryItemsDataSource {
    func galleryConfiguration() -> GalleryConfiguration {
        
        return [
            
            GalleryConfigurationItem.closeButtonMode(.builtIn),
            
            GalleryConfigurationItem.pagingMode(.carousel),
            GalleryConfigurationItem.presentationStyle(.fade),
            GalleryConfigurationItem.hideDecorationViewsOnLaunch(true),
            
            GalleryConfigurationItem.swipeToDismissMode(.vertical),
            GalleryConfigurationItem.toggleDecorationViewsBySingleTap(true),
            
            GalleryConfigurationItem.overlayColor(UIColor(white: 0.035, alpha: 1)),
            GalleryConfigurationItem.overlayColorOpacity(1),
            GalleryConfigurationItem.overlayBlurOpacity(1),
            GalleryConfigurationItem.overlayBlurStyle(UIBlurEffectStyle.dark),
            
            GalleryConfigurationItem.maximumZoomScale(8),
            GalleryConfigurationItem.swipeToDismissThresholdVelocity(500),
            
            GalleryConfigurationItem.doubleTapToZoomDuration(0.15),
            
            GalleryConfigurationItem.blurPresentDuration(0.5),
            GalleryConfigurationItem.blurPresentDelay(0),
            GalleryConfigurationItem.colorPresentDuration(0.25),
            GalleryConfigurationItem.colorPresentDelay(0),
            
            GalleryConfigurationItem.blurDismissDuration(0.1),
            GalleryConfigurationItem.blurDismissDelay(0.4),
            GalleryConfigurationItem.colorDismissDuration(0.45),
            GalleryConfigurationItem.colorDismissDelay(0),
            
            GalleryConfigurationItem.itemFadeDuration(0.3),
            GalleryConfigurationItem.decorationViewsFadeDuration(0.15),
            GalleryConfigurationItem.rotationDuration(0.15),
            
            GalleryConfigurationItem.displacementDuration(0.55),
            GalleryConfigurationItem.reverseDisplacementDuration(0.25),
            GalleryConfigurationItem.displacementTransitionStyle(.springBounce(0.7)),
            GalleryConfigurationItem.displacementTimingCurve(.linear),
            
            GalleryConfigurationItem.statusBarHidden(true),
            GalleryConfigurationItem.displacementKeepOriginalInPlace(false),
            GalleryConfigurationItem.displacementInsetMargin(50),
            
            GalleryConfigurationItem.deleteButtonMode(.none),
            GalleryConfigurationItem.thumbnailsButtonMode(.builtIn)
        ]
    }
    

    func getThumbnailUrl(hash: String) -> String {
    return "https://i.imgur.com/" + hash + "s.png";
    }

    var browser: GalleryViewController?

    func create(hash: String) -> GalleryViewController {
        browser = GalleryViewController.init(startIndex: 0, itemsDataSource: self, itemsDelegate: nil, displacedViewsDataSource: nil, configuration: galleryConfiguration())
        getAlbum(hash: hash)
        return browser!
    }
    
    func itemCount() -> Int {
        return photos.count
    }
    
    func provideGalleryItem(_ index: Int) -> GalleryItem {
        if(photos.isEmpty){
            return GalleryItem.image(fetchImageBlock: { (completion) in
                
            })
        } else {
            return photos[index]
        }
    }
    
    
    var albumImages:[URL]=[]
    var photos: [GalleryItem] = []
    
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
                            let photo = GalleryItem.video(fetchPreviewImageBlock: { (completion) in
                                
                            }, videoURL: url!)
                            if((a.description) != nil){
                                //todo desc
                            }
                            self.photos.append(photo)
                        } else {
                            let photo = GalleryItem.image(fetchImageBlock: { (completion) in
                                SDWebImageDownloader.shared().downloadImage(with: url!, options: .allowInvalidSSLCertificates, progress: { (current, total) in
                                    
                                }, completed: { (image, _, error, _) in
                                    DispatchQueue.main.async {
                                        completion(image)
                                    }
                                })

                            })
                            if((a.description) != nil){
                                //todo desc
                            }
                            self.photos.append(photo)
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
        let vc = browser!.pagingDataSource.createItemController(0)
        browser!.setViewControllers([vc], direction: UIPageViewControllerNavigationDirection.reverse, animated: true, completion: nil)
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
