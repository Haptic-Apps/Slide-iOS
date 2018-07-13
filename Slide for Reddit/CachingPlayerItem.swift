/*


 The MIT License

 Copyright (c) 2016 Nikita Belousov, neekeetab@gmail.com

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 */

import Foundation
import AVFoundation

fileprivate extension URL {

    func withScheme(_ scheme: String) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = scheme
        return components?.url
    }

}

@objc protocol CachingPlayerItemDelegate {

    /// Is called when the media file is fully downloaded.
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data)
    
    @objc optional func didReachEnd(_ playerItem: CachingPlayerItem)

    /// Is called every time a new portion of data is received.
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int)

    /// Is called after initial prebuffering is finished, means
    /// we are ready to play.
    @objc optional func playerItemReadyToPlay(_ playerItem: CachingPlayerItem)

    /// Is called when the data being downloaded did not arrive in time to
    /// continue playback.
    @objc optional func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem)

    /// Is called on downloading error.
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error)

}

open class CachingPlayerItem: AVPlayerItem {

    class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {

        var playingFromData = false
        var mimeType: String? // is required when playing from Data
        var session: URLSession?
        var mediaData: Data?
        var response: URLResponse?
        var pendingRequests = Set<AVAssetResourceLoadingRequest>()
        weak var owner: CachingPlayerItem?

        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {

            if playingFromData {

                // Nothing to load.

            } else if session == nil {

                // If we're playing from a url, we need to download the file.
                // We start loading the file on first request only.
//                guard let interceptedUrl = loadingRequest.request.url,
//                    let initialScheme = owner?.initialScheme,
//                    let initialUrl = interceptedUrl.withScheme(initialScheme) else {
//                        fatalError("internal inconsistency")
//                }

                guard let interceptedUrl = loadingRequest.request.url,
                    let initialScheme = owner?.initialScheme else {
                        fatalError("internal inconsistency")
                }

                // Fix the URL if we changed it to work with a reddit URL
                var transformedUrl = interceptedUrl.absoluteString
                if transformedUrl.contains("redditmedia") {
                    transformedUrl = transformedUrl.replacingOccurrences(of: ".mp4", with: "")
                }
                if transformedUrl.contains("v.redd.it") {
                    transformedUrl = transformedUrl.replacingOccurrences(of: ".mp4", with: "")
                }
                guard let finalURL = URL(string: transformedUrl),
                    let initialUrl = finalURL.withScheme(initialScheme) else {
                        fatalError("internal inconsistency")
                }

                startDataRequest(with: initialUrl)

            }

            pendingRequests.insert(loadingRequest)
            processPendingRequests()
            return true

        }

        func startDataRequest(with url: URL) {
            let configuration = URLSessionConfiguration.default
            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
            session?.dataTask(with: url).resume()
        }

        
        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
            pendingRequests.remove(loadingRequest)
        }

        // MARK: URLSession delegate

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            mediaData?.append(data)
            processPendingRequests()
            owner?.delegate?.playerItem?(owner!, didDownloadBytesSoFar: mediaData!.count, outOf: Int(dataTask.countOfBytesExpectedToReceive))
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
            completionHandler(Foundation.URLSession.ResponseDisposition.allow)
            mediaData = Data()
            self.response = response
            processPendingRequests()
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let errorUnwrapped = error {
                owner?.delegate?.playerItem?(owner!, downloadingFailedWith: errorUnwrapped)
                return
            }
            processPendingRequests()
            owner?.delegate?.playerItem?(owner!, didFinishDownloadingData: mediaData!)
        }

        // MARK: -

        func processPendingRequests() {

            // get all fullfilled requests
            let requestsFulfilled = Set<AVAssetResourceLoadingRequest>(pendingRequests.flatMap {
                self.fillInContentInformationRequest($0.contentInformationRequest)
                if self.haveEnoughDataToFulfillRequest($0.dataRequest!) {
                    $0.finishLoading()
                    return $0
                }
                return nil
            })

            // remove fulfilled requests from pending requests
            _ = requestsFulfilled.map { self.pendingRequests.remove($0) }

        }

        func fillInContentInformationRequest(_ contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {

            // if we play from Data we make no url requests, therefore we have no responses, so we need to fill in contentInformationRequest manually
            if playingFromData {
                contentInformationRequest?.contentType = self.mimeType
                contentInformationRequest?.contentLength = Int64(mediaData!.count)
                contentInformationRequest?.isByteRangeAccessSupported = true
                return
            }

            guard let responseUnwrapped = response else {
                // have no response from the server yet
                return
            }

            contentInformationRequest?.contentType = responseUnwrapped.mimeType
            contentInformationRequest?.contentLength = responseUnwrapped.expectedContentLength
            contentInformationRequest?.isByteRangeAccessSupported = true

        }

        func haveEnoughDataToFulfillRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {

            let requestedOffset = Int(dataRequest.requestedOffset)
            let requestedLength = dataRequest.requestedLength
            let currentOffset = Int(dataRequest.currentOffset)

            guard let songDataUnwrapped = mediaData,
                songDataUnwrapped.count > currentOffset else {
                    // Don't have any data at all for this request.
                    return false
            }

            let bytesToRespond = min(songDataUnwrapped.count - currentOffset, requestedLength)
            let dataToRespond = songDataUnwrapped.subdata(in: Range(uncheckedBounds: (currentOffset, currentOffset + bytesToRespond)))
            dataRequest.respond(with: dataToRespond)

            return songDataUnwrapped.count >= requestedLength + requestedOffset

        }

        deinit {
            session?.invalidateAndCancel()
        }

    }

    fileprivate let resourceLoaderDelegate = ResourceLoaderDelegate()
    fileprivate let url: URL
    fileprivate let initialScheme: String?

    weak var delegate: CachingPlayerItemDelegate?

    open func download() {
        if resourceLoaderDelegate.session == nil {
            resourceLoaderDelegate.startDataRequest(with: url)
        }
    }

    private let cachingPlayerItemScheme = "cachingPlayerItemScheme"

    /// Is used for playing remote files.
    init(url: URL) {

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let scheme = components.scheme,
            let urlWithCustomScheme = url.withScheme(cachingPlayerItemScheme) else {
                fatalError("Urls without a scheme are not supported")
        }

        self.url = url
        self.initialScheme = scheme

        let asset = AVURLAsset(url: urlWithCustomScheme) // Jon's note: Did `url` instead of `urlWithCustomScheme` and now HLS streaming works from v.redd.it
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)

        resourceLoaderDelegate.owner = self

        addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(playbackStalledHandler), name:NSNotification.Name.AVPlayerItemPlaybackStalled, object: self)

        NotificationCenter.default.addObserver(self, selector: #selector(didEndHandler), name: .AVPlayerItemDidPlayToEndTime, object: self)

    }
    
    /// Is used for playing remote files.
    init(localUrl: URL) {
        
        self.url = localUrl
        self.initialScheme = nil
        
        super.init(asset: AVAsset.init(url: localUrl), automaticallyLoadedAssetKeys: nil)
        
        addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(playbackStalledHandler), name:NSNotification.Name.AVPlayerItemPlaybackStalled, object: self)

        NotificationCenter.default.addObserver(self, selector: #selector(didEndHandler), name: .AVPlayerItemDidPlayToEndTime, object: self)
        
    }


    /// Is used for playing from Data.
    init(data: Data, mimeType: String, fileExtension: String) {

        guard let fakeUrl = URL(string: cachingPlayerItemScheme + "://whatever/file.\(fileExtension)") else {
            fatalError("internal inconsistency")
        }

        self.url = fakeUrl
        self.initialScheme = nil

        resourceLoaderDelegate.mediaData = data
        resourceLoaderDelegate.playingFromData = true
        resourceLoaderDelegate.mimeType = mimeType

        let asset = AVURLAsset(url: fakeUrl)
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        resourceLoaderDelegate.owner = self

        addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(playbackStalledHandler), name:NSNotification.Name.AVPlayerItemPlaybackStalled, object: self)

        NotificationCenter.default.addObserver(self, selector: #selector(didEndHandler), name: .AVPlayerItemDidPlayToEndTime, object: self)

    }

    // MARK: KVO
    
    

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        delegate?.playerItemReadyToPlay?(self)
    }

    // MARK: Notification hanlers

    @objc func playbackStalledHandler() {
        delegate?.playerItemPlaybackStalled?(self)
    }
    
    @objc func didEndHandler() {
        delegate?.didReachEnd?(self)
    }


    // MARK: -

    override init(asset: AVAsset, automaticallyLoadedAssetKeys: [String]?) {
        fatalError("not implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        removeObserver(self, forKeyPath: "status")
        resourceLoaderDelegate.session?.invalidateAndCancel()
    }

}
