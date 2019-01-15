//
//  AsyncAlertImagePickerViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/24/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import RLBAlertsPickers
import SDWebImage
import UIKit

extension UIAlertController {
    
    /// Add Image Picker
    ///
    /// - Parameters:
    ///   - flow: scroll direction
    ///   - pagging: pagging
    ///   - images: for content to select
    ///   - selection: type and action for selection of image/images
    
    func addAsyncImagePicker(flow: UICollectionView.ScrollDirection, paging: Bool, images: [URL], selection: AsyncImagePickerViewController.SelectionType? = nil) {
        let vc = AsyncImagePickerViewController(flow: flow, paging: paging, images: images, selection: selection)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            vc.preferredContentSize.height = vc.preferredSize.height * 0.9
            vc.preferredContentSize.width = vc.preferredSize.width * 0.9
        } else {
            vc.preferredContentSize.height = vc.preferredSize.height
        }
        
        setValue(vc, forKey: "contentViewController")
    }
}

final class AsyncImagePickerViewController: UIViewController {
    
    public typealias SingleSelection = (Int?) -> Swift.Void
    public typealias MultipleSelection = ([Int]) -> Swift.Void
    
    public enum SelectionType {
        case single(action: SingleSelection?)
        case multiple(action: MultipleSelection?)
    }
    
    // MARK: UI Metrics
    
    struct UI {
        static let itemHeight: CGFloat = UIScreen.main.bounds.width
    }
    
    var preferredSize: CGSize {
        return UIScreen.main.bounds.size
    }
    
    var columns: CGFloat {
         return UIDevice.current.userInterfaceIdiom == .pad ? 3 : 2
    }
    
    var itemSize: CGSize {
        return CGSize(width: view.bounds.width / columns, height: view.bounds.width / columns)
    }
    
    // MARK: Properties
    
    lazy var collectionView: UICollectionView = { [unowned self] in
        $0.dataSource = self
        $0.delegate = self
        $0.register(ItemWithImage.self, forCellWithReuseIdentifier: ItemWithImage.identifier)
        $0.showsVerticalScrollIndicator = false
        $0.showsHorizontalScrollIndicator = false
        $0.decelerationRate = UIScrollView.DecelerationRate.fast
        $0.bounces = false
        $0.backgroundColor = .clear
        $0.maskToBounds = false
        $0.clipsToBounds = false
        return $0
        }(UICollectionView(frame: .zero, collectionViewLayout: {
            $0.minimumInteritemSpacing = 0
            $0.minimumLineSpacing = 0
            $0.scrollDirection = .vertical
            $0.sectionInset = .zero
            return $0
        }(UICollectionViewFlowLayout())))
    
    fileprivate var selection: SelectionType?
    fileprivate var images: [URL] = []
    fileprivate var selectedImages: [Int] = []
    
    // MARK: Initialize
    
    required init(flow: UICollectionView.ScrollDirection, paging: Bool, images: [URL], selection: SelectionType?) {
        super.init(nibName: nil, bundle: nil)
        self.images = images
        self.selection = selection
        
        collectionView.isPagingEnabled = paging
        
        switch selection {
        case .single?: collectionView.allowsSelection = true
        case .multiple?: collectionView.allowsMultipleSelection = true
        case .none: break }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
    }
    
    override func loadView() {
        view = collectionView
    }
}

// MARK: - CollectionViewDelegate
extension AsyncImagePickerViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let image = indexPath.row
        switch selection {
            
        case .single(let action)?:
            action?(image)
            
        case .multiple(let action)?:
            action?(selectedImages)
            
        case .none: break }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        switch selection {
        case .multiple(let action)?:
            action?(selectedImages)
        default: break }
    }
}

// MARK: - CollectionViewDataSource
extension AsyncImagePickerViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let item = collectionView.dequeueReusableCell(withReuseIdentifier: ItemWithImage.identifier, for: indexPath) as? ItemWithImage else { return UICollectionViewCell() }
        item.imageView.sd_setImage(with: images[indexPath.row])
        return item
    }
}

// MARK: - CollectionViewDelegateFlowLayout
extension AsyncImagePickerViewController: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        Log("view size = \(view.bounds), collectionView = \(collectionView.size), itemSize = \(itemSize)")
        return itemSize
    }
}
class ItemWithImage: UICollectionViewCell {
    
    static let identifier = "IWI"
    
    lazy var imageView: UIImageView = {
        $0.backgroundColor = .clear
        $0.contentMode = .scaleAspectFill
        $0.maskToBounds = true
        return $0
    }(UIImageView())
    
    lazy var unselectedCircle: UIView = {
        $0.backgroundColor = .clear
        $0.borderWidth = 2
        $0.borderColor = .white
        $0.maskToBounds = false
        $0.isHidden = true
        return $0
    }(UIView())
    
    lazy var selectedCircle: UIView = {
        $0.backgroundColor = .clear
        $0.borderWidth = 2
        $0.isHidden = true
        $0.borderColor = .white
        $0.maskToBounds = false
        return $0
    }(UIView())
    
    lazy var selectedPoint: UIView = {
        $0.backgroundColor = UIColor.blue
        return $0
    }(UIView())
    
    fileprivate let inset: CGFloat = 8
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    fileprivate func setup() {
        backgroundColor = .clear
        
        let unselected: UIView = UIView()
        unselected.addSubview(imageView)
        unselected.addSubview(unselectedCircle)
        backgroundView = unselected
        
        let selected: UIView = UIView()
        selected.addSubview(selectedCircle)
        selected.addSubview(selectedPoint)
        selectedBackgroundView = selected
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }
    
    func layout() {
        imageView.frame = contentView.frame
        updateAppearance(forCircle: unselectedCircle)
        updateAppearance(forCircle: selectedCircle)
        updateAppearance(forPoint: selectedPoint)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        contentView.size = size
        layout()
        return size
    }
    
    func updateAppearance(forCircle view: UIView) {
        view.frame.size = CGSize(width: 28, height: 28)
        view.frame.origin.x = imageView.bounds.width - unselectedCircle.bounds.width - inset
        view.frame.origin.y = inset
        view.circleCorner = true
        view.shadowColor = UIColor.black.withAlphaComponent(0.4)
        view.shadowOffset = .zero
        view.shadowRadius = 4
        view.shadowOpacity = 0.2
        view.shadowPath = UIBezierPath(roundedRect: unselectedCircle.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: unselectedCircle.bounds.width / 2, height: unselectedCircle.bounds.width / 2)).cgPath
        view.shadowShouldRasterize = true
        view.shadowRasterizationScale = UIScreen.main.scale
    }
    
    func updateAppearance(forPoint view: UIView) {
        view.frame.size = CGSize(width: unselectedCircle.width - unselectedCircle.borderWidth * 2, height: unselectedCircle.height - unselectedCircle.borderWidth * 2)
        view.center = selectedCircle.center
        view.circleCorner = true
    }
}
