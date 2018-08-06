//
// Created by Carlos Crane on 5/24/18.
// Copyright (c) 2018 Haptic Apps. All rights reserved.
//

// Derived from https://stackoverflow.com/a/49843358/3697225
import Foundation
import Photos

class CustomAlbum: NSObject {
    static let albumName = "Slide for Reddit"
    static let shared = CustomAlbum()

    private var assetCollection: PHAssetCollection!

    private override init() {
        super.init()

        if let assetCollection = fetchAssetCollectionForAlbum() {
            self.assetCollection = assetCollection
            return
        }
    }

    private func checkAuthorizationWithHandler(completion: @escaping ((_ success: Bool) -> Void)) {
        if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization({ (_) in
                self.checkAuthorizationWithHandler(completion: completion)
            })
        } else if PHPhotoLibrary.authorizationStatus() == .authorized {
            self.createAlbumIfNeeded { (success) in
                if success {
                    completion(true)
                } else {
                    completion(false)
                }

            }

        } else {
            completion(false)
        }
    }

    private func createAlbumIfNeeded(completion: @escaping ((_ success: Bool) -> Void)) {
        if let assetCollection = fetchAssetCollectionForAlbum() {
            // Album already exists
            self.assetCollection = assetCollection
            completion(true)
        } else {
            PHPhotoLibrary.shared().performChanges({
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: CustomAlbum.albumName)   // create an asset collection with the album name
            }, completionHandler: { success, _ in
                if success {
                    self.assetCollection = self.fetchAssetCollectionForAlbum()
                    completion(true)
                } else {
                    // Unable to create album
                    completion(false)
                }
            })
        }
    }

    private func fetchAssetCollectionForAlbum() -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", CustomAlbum.albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        if let _: AnyObject = collection.firstObject {
            return collection.firstObject
        }
        return nil
    }

    func save(image: UIImage, parent: UIViewController?) {
        self.checkAuthorizationWithHandler { (success) in
            if success, self.assetCollection != nil {
                PHPhotoLibrary.shared().performChanges({
                    let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
                    if let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection) {
                        let enumeration: NSArray = [assetPlaceHolder!]
                        albumChangeRequest.addAssets(enumeration)
                    }

                }, completionHandler: { (success, _) in
                    DispatchQueue.main.async {
                        if success {
                            BannerUtil.makeBanner(text: "Image saved to gallery!", color: .black, seconds: 3, context: parent)
                        } else {
                            BannerUtil.makeBanner(text: "Error saving image!\nMake sure Slide has permission to access gallery", color: GMColor.red500Color(), seconds: 3, context: parent)
                        }
                    }
                })

            }
        }
    }

    func saveMovieToLibrary(movieURL: URL, parent: UIViewController?) {

        self.checkAuthorizationWithHandler { (success) in
            if success, self.assetCollection != nil {

                PHPhotoLibrary.shared().performChanges({

                    if let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: movieURL) {
                        let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
                        if let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection) {
                            let enumeration: NSArray = [assetPlaceHolder!]
                            albumChangeRequest.addAssets(enumeration)
                        }

                    }

                }, completionHandler: { (success, error) in
                    DispatchQueue.main.async {
                        if success {
                            BannerUtil.makeBanner(text: "Video saved to gallery!", color: .black, seconds: 3, context: parent)
                        } else {
                            print("Error writing to movie library: \(error!.localizedDescription)")
                            BannerUtil.makeBanner(text: "Error saving video!\nMake sure Slide has permission to access gallery", color: GMColor.red500Color(), seconds: 3, context: parent)
                        }
                    }
                })

            }
        }

    }
}
