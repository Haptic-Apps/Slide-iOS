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
import MaterialComponents.MaterialProgressView

class AlbumMWPhotoBrowser: NSObject, GalleryItemsDataSource {
    func galleryConfiguration() -> GalleryConfiguration {
        
        return [
            
            GalleryConfigurationItem.closeButtonMode(.none),
            
            GalleryConfigurationItem.pagingMode(.standard),
            GalleryConfigurationItem.presentationStyle(.fade),
            GalleryConfigurationItem.hideDecorationViewsOnLaunch(false),
            
            GalleryConfigurationItem.swipeToDismissMode(.always),
            GalleryConfigurationItem.toggleDecorationViewsBySingleTap(true),
            
            GalleryConfigurationItem.overlayColor(UIColor(white: 0.035, alpha: 1)),
            GalleryConfigurationItem.overlayColorOpacity(0.75),
            GalleryConfigurationItem.overlayBlurOpacity(0.75),
            GalleryConfigurationItem.overlayBlurStyle(UIBlurEffectStyle.dark),
            
            GalleryConfigurationItem.maximumZoomScale(8),
            GalleryConfigurationItem.swipeToDismissThresholdVelocity(500),
            
            GalleryConfigurationItem.doubleTapToZoomDuration(0.15),
            GalleryConfigurationItem.footerViewLayout(FooterLayout.pinRight(8, 0)),
            
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
            
            GalleryConfigurationItem.statusBarHidden(false),
            
            GalleryConfigurationItem.deleteButtonMode(.none),
            GalleryConfigurationItem.thumbnailsButtonMode(.builtIn)
        ]
    }
    
    
    func getThumbnailUrl(hash: String) -> String {
        return "https://i.imgur.com/" + hash + "s.png";
    }
    
    var browser: GalleryViewController?
    
     var size: UILabel?
    var progressView: MDCProgressView?

    var captions:[String] = [""]
    
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
