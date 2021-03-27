//
//  PagingTitleCollectionView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/12/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Anchorage
import UIKit

public protocol PagingTitleDelegate: class {
    func didSelect(_ subreddit: String)
    func didSetWidth()
}
public class PagingTitleCollectionView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // Overwrite this when implementing
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
    
    func registerCells() {
        
    }

    // Shared vars
    public var collectionView: UICollectionView!
    private var collectionViewLayout: FadingCollectionViewLayout!
    private weak var delegate: PagingTitleDelegate?
    
    public var dataSource: [String] = []
    public weak var parentScroll: UIScrollView?
    
    private var indexOfCellBeforeDragging = 0
    private var widthSet = false
    
    init(withTitles: [String], delegate: PagingTitleDelegate) {
        self.dataSource = withTitles
        self.delegate = delegate

        super.init(frame: CGRect.zero)
        configureViews()
    }
    
    func configureViews() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.collectionViewLayout = FadingCollectionViewLayout(scrollDirection: .horizontal)

        if self is TabsPagingTitleCollectionView {
            (self.collectionViewLayout as? FadingCollectionViewLayout)?.shouldFade = false
        }
        
        self.collectionViewLayout.delegate = self

        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        registerCells()

        self.addSubview(collectionView)
        collectionView.edgeAnchors /==/ self.edgeAnchors
        collectionView.backgroundColor = .clear

        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.bounces = false
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.showsVerticalScrollIndicator = false
        self.collectionView.contentInsetAdjustmentBehavior = .never
        self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 300, bottom: 0, right: 0)

        if SettingValues.fullWidthHeaderCells && !(self is TabsPagingTitleCollectionView) {
            self.collectionView.isUserInteractionEnabled = false
        }
        
    }
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.layoutFittingExpandedSize.width, height: UIView.layoutFittingExpandedSize.height)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    public override func layoutSubviews() {
        let oldOffset = collectionView.contentOffset
        super.layoutSubviews()
        if !widthSet {
            widthSet = true
            collectionViewLayout.reset()
            collectionView.reloadData()
            delegate?.didSetWidth()
        } else {
            collectionView.contentOffset = oldOffset
        }
        addGradientMask()
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelect(dataSource[indexPath.row])
    }
    
    public func addGradientMask() {
        let coverView = GradientMaskView(frame: self.collectionView.bounds)
        let coverLayer = coverView.layer as! CAGradientLayer
        coverLayer.colors = [UIColor.foregroundColor.withAlphaComponent(0).cgColor, UIColor.foregroundColor.cgColor, UIColor.foregroundColor.cgColor, UIColor.foregroundColor.withAlphaComponent(0).cgColor]
        coverLayer.locations = [0.0, 0.15, 0.85, 1.0]
        coverLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        coverLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        collectionView.mask = coverView
    }
        
    // From https://github.com/hershalle/CollectionViewWithPaging-Finish/blob/master/CollectionViewWithPaging/ViewController.swift
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
            
    public var currentIndex = 0
    public var originalOffset = CGFloat(0)
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    }
            
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.collectionView.mask?.frame = self.collectionView.bounds
    }
}

public class SubredditPagingTitleCollectionView: PagingTitleCollectionView {
        
    init(withSubreddits: [String], delegate: PagingTitleDelegate) {
        super.init(withTitles: withSubreddits, delegate: delegate)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func registerCells() {
        self.collectionView.register(SubredditTitleCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: "subreddit")
    }
                    
    override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "subreddit", for: indexPath) as! SubredditTitleCollectionViewCell
        
        cell.setSubreddit(subreddit: dataSource[indexPath.row])
        return cell
    }
}

public class TabsPagingTitleCollectionView: PagingTitleCollectionView {
        
    init(withTabs: [String], delegate: PagingTitleDelegate) {
        super.init(withTitles: withTabs, delegate: delegate)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func addGradientMask() {
        return
    }

    override func registerCells() {
        self.collectionView.register(TabTitleCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: "tab")
    }
                    
    override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tab", for: indexPath) as! TabTitleCollectionViewCell
        
        cell.setTitle(titleText: dataSource[indexPath.row])
        return cell
    }
}

class SubredditTitleCollectionViewCell: UICollectionViewCell {
    var subreddit = ""

    var sideView: UIView = UIView()
    var icon = UIImageView()
    var title: UILabel = UILabel()
    var innerView = UIView()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        configureLayout()
    }
    
    func configureViews() {
        self.clipsToBounds = true

        self.title = UILabel().then {
            $0.numberOfLines = 0
            $0.font = UIFont.boldSystemFont(ofSize: 18)
        }

        self.sideView = UIView().then {
            $0.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
            $0.layer.cornerRadius = 15
            $0.clipsToBounds = true
        }

        self.icon = UIImageView().then {
            $0.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
            $0.layer.cornerRadius = 15
            $0.clipsToBounds = true
            $0.isHidden = true
        }
        self.contentView.addSubview(innerView)
        self.innerView.addSubviews(sideView, title, icon)
        self.backgroundColor = .clear
    }

    func configureLayout() {
        batch {
            if SettingValues.subredditIcons {
                sideView.leftAnchor /==/ innerView.leftAnchor + 10
                sideView.sizeAnchors /==/ CGSize.square(size: 30)
                sideView.centerYAnchor /==/ innerView.centerYAnchor

                icon.edgeAnchors /==/ sideView.edgeAnchors
                icon.sizeAnchors /==/ CGSize.square(size: 30)

                title.leftAnchor /==/ sideView.rightAnchor + 8
                title.centerYAnchor /==/ innerView.centerYAnchor
                title.rightAnchor /==/ innerView.rightAnchor - 10
            } else {
                title.leftAnchor /==/ innerView.leftAnchor + 4
                title.centerYAnchor /==/ innerView.centerYAnchor
                title.rightAnchor /==/ innerView.rightAnchor - 4
            }
            innerView.centerYAnchor /==/ self.contentView.centerYAnchor
            innerView.centerXAnchor /==/ self.contentView.centerXAnchor
        }
    }
    
    func setSubreddit(subreddit: String) {
        title.textColor = SettingValues.reduceColor ? UIColor.fontColor : .white
        self.contentView.backgroundColor = .clear
        self.subreddit = subreddit
        self.sideView.isHidden = false
        self.icon.isHidden = false
        
        if !SettingValues.subredditIcons {
            self.sideView.isHidden = true
            self.icon.isHidden = true
        } else {
            self.sideView.isHidden = false
            self.icon.isHidden = false
        }
        
        title.adjustsFontSizeToFitWidth = true
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = subreddit.contains("u_") ? subreddit.replacingOccurrences(of: "u_", with: "u/") : subreddit
        title.numberOfLines = 1
        title.sizeToFit()
        sideView.backgroundColor = ColorUtil.getColorForSub(sub: subreddit)
        let selectedView = UIView()
        selectedView.backgroundColor = .clear
        selectedBackgroundView = selectedView
        
        self.icon.contentMode = .center
         if subreddit.lowercased() == "all" {
            self.icon.image = SubredditCellView.allIcon
        } else if subreddit.lowercased() == "frontpage" {
            self.icon.image = SubredditCellView.frontpageIcon
        } else if subreddit.lowercased() == "popular" {
            self.icon.image = SubredditCellView.popularIcon
        } else if let icon = Subscriptions.icon(for: subreddit) {
            self.icon.contentMode = .scaleAspectFill
            self.icon.image = UIImage()
            self.icon.sd_setImage(with: URL(string: icon.unescapeHTML), completed: nil)
        } else if subreddit.contains("m/") {
            self.icon.image = SubredditCellView.defaultIconMulti
        } else {
            self.icon.image = SubredditCellView.defaultIcon
        }
    }
}

class TabTitleCollectionViewCell: UICollectionViewCell {
    var titleText = ""
    var title: UILabel = UILabel()
    var innerView = UIView()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        configureLayout()
    }
        
    func configureViews() {
        self.clipsToBounds = true

        self.title = UILabel().then {
            $0.numberOfLines = 0
            $0.font = UIFont.boldSystemFont(ofSize: 18)
        }

        self.contentView.addSubview(innerView)
        self.innerView.addSubviews(title)
        self.contentView.backgroundColor = .clear
        self.backgroundColor = .clear
    }

    func configureLayout() {
        batch {
            title.leftAnchor /==/ innerView.leftAnchor + 4
            title.centerYAnchor /==/ innerView.centerYAnchor
            title.rightAnchor /==/ innerView.rightAnchor - 4
            innerView.centerYAnchor /==/ self.contentView.centerYAnchor
            innerView.centerXAnchor /==/ self.contentView.centerXAnchor
        }
    }
    
    func setTitle(titleText: String) {
        title.textColor = SettingValues.reduceColor ? UIColor.fontColor : .white
        self.contentView.backgroundColor = .clear
        self.titleText = titleText
                
        title.adjustsFontSizeToFitWidth = true
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = titleText
        title.numberOfLines = 1
        title.sizeToFit()

        let selectedView = UIView()
        selectedView.backgroundColor = .clear
        selectedBackgroundView = selectedView
    }
}

extension PagingTitleCollectionView: WrappingHeaderFlowLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, indexPath: IndexPath) -> CGSize {
        if SettingValues.fullWidthHeaderCells && !(self is TabsPagingTitleCollectionView) {
            return CGSize(width: collectionView.frame.size.width, height: 40)
        }
        if SettingValues.subredditIcons && !(self is TabsPagingTitleCollectionView) {
            var width = CGFloat(30) // icon size
            width += 4 // icon leading padding
            
            if collectionView.frame.size.width > 400 {
                width += 24 // title padding
            } else {
                width += 12
            }
            width += dataSource[indexPath.row].size(with: UIFont.boldSystemFont(ofSize: 18)).width
            return CGSize(width: width, height: 40)
        } else {
            var width = CGFloat(0) // icon size
            width += 8 // title padding
            width += dataSource[indexPath.row].size(with: UIFont.boldSystemFont(ofSize: 18)).width
            return CGSize(width: width, height: 40)
        }
    }
}

class GradientMaskView: UIView {
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
}

// Based on https://stackoverflow.com/a/42705208/3697225
class FadingCollectionViewLayout: WrappingHeaderFlowLayout {

    private var fadeFactor: CGFloat = 0.6
    public var shouldFade = true

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init(scrollDirection: UICollectionView.ScrollDirection) {
        super.init()
        self.scrollDirection = scrollDirection
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    func scrollDirectionOver() -> UICollectionView.ScrollDirection {
        return UICollectionView.ScrollDirection.horizontal
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if let attributesSuper: [UICollectionViewLayoutAttributes] = super.layoutAttributesForElements(in: rect) {
            if let attributes = NSArray(array: attributesSuper, copyItems: true) as? [UICollectionViewLayoutAttributes] {
                var visibleRect = CGRect()
                visibleRect.origin = collectionView!.contentOffset
                visibleRect.size = collectionView!.bounds.size
                if collectionView!.frame.size.width > 400 {
                    self.fadeFactor = 0.4
                }
                if self.shouldFade {
                    for attrs in attributes {
                        if attrs.frame.intersects(rect) {
                            let distance = visibleRect.midX - attrs.center.x
                            let normalizedDistance = abs(distance) / (visibleRect.width * fadeFactor)
                            let fade = 1 - normalizedDistance
                            attrs.alpha = fade
                        }
                    }
                }
                return attributes
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if let attributes = super.layoutAttributesForItem(at: itemIndexPath) {
            if shouldFade {
                attributes.alpha = 0
            }
            return attributes
        }
        return nil
    }

    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if let attributes = super.layoutAttributesForItem(at: itemIndexPath) {
            if shouldFade {
                attributes.alpha = 0
            }
            return attributes
        }
        return nil
    }
}
