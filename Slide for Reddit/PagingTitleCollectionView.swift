//
//  PagingTitleCollectionView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/12/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Anchorage
import UIKit

public protocol PagingTitleDelegate {
    func didSelect(_ subreddit: String)
}
public class PagingTitleCollectionView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    
    public var collectionView: UICollectionView!
    private var collectionViewLayout: UICollectionViewFlowLayout!
    private var delegate: PagingTitleDelegate
    
    private var dataSource: [String] = []
    public weak var parentScroll: UIScrollView?
    
    private var indexOfCellBeforeDragging = 0
    private var widthSet = false
    
    init(withSubreddits: [String], delegate: PagingTitleDelegate) {
        self.dataSource = withSubreddits
        self.delegate = delegate

        super.init(frame: CGRect.zero)
        configureViews()
        collectionViewLayout.minimumLineSpacing = 0
    }
    
    func configureViews() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.collectionViewLayout = UICollectionViewFlowLayout()
        self.collectionViewLayout.scrollDirection = .horizontal
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        self.addSubview(collectionView)
        collectionView.edgeAnchors == self.edgeAnchors
        collectionView.backgroundColor = .clear
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.bounces = false
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.showsVerticalScrollIndicator = false
        //self.collectionView.isPagingEnabled = true
        self.collectionView.register(SubredditTitleCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: "subreddit")
    }
    
    public override var intrinsicContentSize: CGSize {
        get {
            if widthSet {
                return CGSize(width: collectionViewLayout.itemSize.width + 140, height: 40)
            }
            return CGSize(width: UIView.layoutFittingExpandedSize.width, height: UIView.layoutFittingExpandedSize.height)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func calculateSectionInset() -> CGFloat {
        let deviceIsIpad = UIDevice.current.userInterfaceIdiom == .pad
        let deviceOrientationIsLandscape = UIDevice.current.orientation.isLandscape
        let cellBodyViewIsExpended = deviceIsIpad || deviceOrientationIsLandscape
        let cellBodyWidth: CGFloat = 236 + (cellBodyViewIsExpended ? 174 : 0)
        
        let buttonWidth: CGFloat = 50
        
        let inset = (collectionViewLayout.collectionView!.frame.width - cellBodyWidth + buttonWidth) / 4
        return inset
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if !widthSet {
            configureCollectionViewLayoutItemSize()
            collectionView.reloadData()
        } else {
            let diff = collectionViewLayout.collectionView!.frame.size.width - 140 - (self.collectionViewLayout.itemSize.width)
            if diff <= 0 && collectionViewLayout.sectionInset.left > 70 {
                collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: 70, bottom: 0, right: 70)
            } else if diff > 0 && collectionViewLayout.sectionInset.left == 70 {
                collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: 70 + diff, bottom: 0, right: 70)
            }
        }
        addGradientMask()
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate.didSelect(dataSource[indexPath.row])
    }
    
    private func addGradientMask() {
        let coverView = GradientMaskView(frame: self.collectionView.bounds)
         let coverLayer = coverView.layer as! CAGradientLayer
         coverLayer.colors = [ColorUtil.theme.foregroundColor.withAlphaComponent(0).cgColor, ColorUtil.theme.foregroundColor.cgColor, ColorUtil.theme.foregroundColor.cgColor, ColorUtil.theme.foregroundColor.withAlphaComponent(0).cgColor]
        coverLayer.locations = [0.0, 0.15, 0.85, 1.0]
         coverLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
         coverLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        collectionView.mask = coverView
    }

    public func configureCollectionViewLayoutItemSize() {
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: 70, bottom: 0, right: 70)
        
        collectionViewLayout.itemSize = CGSize(width: collectionViewLayout.collectionView!.frame.size.width - 140, height: collectionViewLayout.collectionView!.frame.size.height)
        widthSet = true
    }
        
    //From https://github.com/hershalle/CollectionViewWithPaging-Finish/blob/master/CollectionViewWithPaging/ViewController.swift
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
        
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "subreddit", for: indexPath) as! SubredditTitleCollectionViewCell
        
        cell.setSubreddit(subreddit: dataSource[indexPath.row])
        return cell
    }

    public var currentIndex = 0
    public var originalOffset = CGFloat(0)
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        /*indexOfCellBeforeDragging = indexOfMajorCell()
        currentIndex = indexOfMajorCell()
        if let parent = parentScroll {
            originalOffset = parent.contentOffset.x
        }*/
    }
        
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.collectionView.mask?.frame = self.collectionView.bounds
        print(scrollView.contentOffset.x)
        /* Disable for now
        print(scrollView.contentOffset.x)
        if let parent = parentScroll {
            let currentY = scrollView.contentOffset.x

            var currentBackgroundOffset = parent.contentOffset
                        
            //Translate percentage of current view translation to the parent scroll view, add in original offset
            currentBackgroundOffset.x = originalOffset + ((currentY - (CGFloat(currentIndex) * collectionViewLayout.itemSize.width)) / (scrollView.frame.size.width - 140 )) * parent.frame.size.width
            parent.contentOffset = currentBackgroundOffset
            parent.layoutIfNeeded()
        }*/
    }
    

    /*//From https://github.com/hershalle/CollectionViewWithPaging-Finish/blob/master/CollectionViewWithPaging/ViewController.swift
     private func indexOfMajorCell() -> Int {
         let itemWidth = collectionViewLayout.itemSize.width
         let proportionalOffset = collectionViewLayout.collectionView!.contentOffset.x / itemWidth
         let index = Int(round(proportionalOffset))
         let safeIndex = max(0, min(dataSource.count - 1, index))
         return safeIndex
     }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // Stop scrollView sliding:
        targetContentOffset.pointee = scrollView.contentOffset

        // calculate where scrollView should snap to:
        let indexOfMajorCell = self.indexOfMajorCell()

        // calculate conditions:
        let dataSourceCount = collectionView(collectionView!, numberOfItemsInSection: 0)
        let swipeVelocityThreshold: CGFloat = 0.5 // after some trail and error
        let hasEnoughVelocityToSlideToTheNextCell = indexOfCellBeforeDragging + 1 < dataSourceCount && velocity.x > swipeVelocityThreshold
        let hasEnoughVelocityToSlideToThePreviousCell = indexOfCellBeforeDragging - 1 >= 0 && velocity.x < -swipeVelocityThreshold
        let majorCellIsTheCellBeforeDragging = indexOfMajorCell == indexOfCellBeforeDragging
        let didUseSwipeToSkipCell = majorCellIsTheCellBeforeDragging && (hasEnoughVelocityToSlideToTheNextCell || hasEnoughVelocityToSlideToThePreviousCell)

        if didUseSwipeToSkipCell {

            let snapToIndex = indexOfCellBeforeDragging + (hasEnoughVelocityToSlideToTheNextCell ? 1 : -1)
            let toValue = collectionViewLayout.itemSize.width * CGFloat(snapToIndex)

            // Damping equal 1 => no oscillations => decay animation:
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: velocity.x, options: .allowUserInteraction, animations: {
                scrollView.contentOffset = CGPoint(x: toValue, y: 0)
                scrollView.layoutIfNeeded()
            }, completion: nil)

        } else {
            // This is a much better way to scroll to a cell:
            let indexPath = IndexPath(row: indexOfMajorCell, section: 0)
            collectionViewLayout.collectionView!.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }*/
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
        self.backgroundColor = ColorUtil.theme.backgroundColor
    }

    func configureLayout() {
        batch {
            sideView.leftAnchor == innerView.leftAnchor
            sideView.sizeAnchors == CGSize.square(size: 30)
            sideView.centerYAnchor == innerView.centerYAnchor

            icon.edgeAnchors == sideView.edgeAnchors

            title.leftAnchor == sideView.rightAnchor + 8
            title.centerYAnchor == innerView.centerYAnchor
            title.rightAnchor == innerView.rightAnchor
            
            innerView.centerAnchors == self.contentView.centerAnchors
        }
    }

    func setSubreddit(subreddit: String) {
        title.textColor = ColorUtil.theme.fontColor
        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
        self.subreddit = subreddit
        self.sideView.isHidden = false
        self.icon.isHidden = false
        title.text = subreddit
        title.adjustsFontSizeToFitWidth = true
        title.sizeToFit()
        
        sideView.backgroundColor = ColorUtil.getColorForSub(sub: subreddit)
        let selectedView = UIView()
        selectedView.backgroundColor = ColorUtil.theme.backgroundColor
        selectedBackgroundView = selectedView
        
        if let icon = Subscriptions.icon(for: subreddit) {
            self.icon.contentMode = .scaleAspectFill
            self.icon.image = UIImage()
            self.icon.sd_setImage(with: URL(string: icon.unescapeHTML), completed: nil)
        } else {
            self.icon.contentMode = .center
            if subreddit.contains("m/") {
                self.icon.image = SubredditCellView.defaultIconMulti
            } else if subreddit.lowercased() == "all" {
                self.icon.image = SubredditCellView.allIcon
                self.sideView.backgroundColor = GMColor.blue500Color()
            } else if subreddit.lowercased() == "frontpage" {
                self.icon.image = SubredditCellView.frontpageIcon
                self.sideView.backgroundColor = GMColor.green500Color()
            } else if subreddit.lowercased() == "popular" {
                self.icon.image = SubredditCellView.popularIcon
                self.sideView.backgroundColor = GMColor.purple500Color()
            } else {
                self.icon.image = SubredditCellView.defaultIcon
            }
        }
    }
}
class GradientMaskView: UIView {
    override class var layerClass: AnyClass {
        get {
            return CAGradientLayer.self
        }
    }
}
