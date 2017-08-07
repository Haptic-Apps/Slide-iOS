//
//  SWSegmentedControl.swift
//  Pods
//
//  Created by Sarun Wongpatcharapakorn on 1/27/16.
//
//

import UIKit

@IBDesignable
open class SWSegmentedControl: UIControl {
    
    open weak var delegate: SWSegmentedControlDelegate?
    
    private var selectionIndicatorView: UIView!
    private var buttons: [UIButton]?
    private var items: [String] = ["First", "Second"]
    
    
    // Wait for a day UIFont will be inspectable
    @IBInspectable open var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize) {
        didSet {
            self.configureView()
        }
    }
    
    @IBInspectable open var titleColor: UIColor? {
        didSet {
            self.configureView()
        }
    }
    
    @IBInspectable open var unselectedTitleColor: UIColor? = UIColor.lightGray {
        didSet {
            self.configureView()
        }
    }
    
    @IBInspectable open var indicatorColor: UIColor? {
        didSet {
            self.configureView()
        }
    }
    
    @IBInspectable open var selectedSegmentIndex: Int = 0 {
        didSet {
            self.configureIndicator()

            if let buttons = self.buttons {
                for button in buttons {
                    button.isSelected = false
                }
                
                let selectedButton = buttons[selectedSegmentIndex]
                selectedButton.isSelected = true
            }
        }
    }
    
    private var indicatorXConstraint: NSLayoutConstraint!
    
    @IBInspectable open var indicatorThickness: CGFloat = 3 {
        didSet {
            self.indicatorHeightConstraint.constant = self.indicatorThickness
        }
    }
    
    private var indicatorWidthConstraint: NSLayoutConstraint!
    
    @IBInspectable open var indicatorPadding: CGFloat = 0 {
        didSet {
            configureView()
        }
    }
    
    private var indicatorHeightConstraint: NSLayoutConstraint!
    
    var numberOfSegments: Int {
        return items.count
    }
    
    
    public init() {
        super.init(frame: CGRect.zero)
        self.commonInit()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }
    
    public init(items: [String]) {
        super.init(frame: CGRect.zero)
        self.items = items
        self.commonInit()
    }
    
    private func commonInit() {
        self.backgroundColor = UIColor.clear
        self.initButtons()
        self.initIndicator()
        
        self.selectedSegmentIndex = 0
    }
    
    open override func prepareForInterfaceBuilder() {

    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        // For autolayout
        self.configureIndicator()
    }
    
    private func initIndicator() {
        guard self.numberOfSegments > 0 else { return }
        
        let selectionIndicatorView = UIView()
        self.selectionIndicatorView = selectionIndicatorView
        
        selectionIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        selectionIndicatorView.backgroundColor = self.tintColor
        self.addSubview(selectionIndicatorView)
        
        let xConstraint = NSLayoutConstraint(item: selectionIndicatorView, attribute: .centerX, relatedBy: .equal, toItem: self.xToItem, attribute: .centerX, multiplier: 1, constant: 0)
        self.indicatorXConstraint = xConstraint
        self.addConstraint(xConstraint)
        
        let yConstraint = NSLayoutConstraint(item: selectionIndicatorView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        self.addConstraint(yConstraint)
        
        let wConstraint = NSLayoutConstraint(item: selectionIndicatorView, attribute: .width, relatedBy: .equal, toItem: self.wToItem, attribute: .width, multiplier: 1, constant: -(2 * indicatorPadding))
        indicatorWidthConstraint = wConstraint
        self.addConstraint(wConstraint)
        
        let hConstraint = NSLayoutConstraint(item: selectionIndicatorView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.indicatorThickness)
        self.indicatorHeightConstraint = hConstraint
        self.addConstraint(hConstraint)
    }
    
    private func initButtons() {
        guard self.numberOfSegments > 0 else { return }
        
        var views = [String: AnyObject]()
        var xVisualFormat = "H:|"
        let yVisualFormat = "V:|[button0]|"
        var previousButtonName: String? = nil
        
        var buttons = [UIButton]()
        defer {
            self.buttons = buttons
        }
        for index in 0..<self.numberOfSegments {
            let button = UIButton(type: .custom)
            self.configureButton(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle(self.titleForSegmentAtIndex(index), for: UIControlState())
            button.addTarget(self, action: #selector(SWSegmentedControl.didTapButton(_:)), for: .touchUpInside)
            
            buttons.append(button)
            self.addSubview(button)
            
            let buttonName = "button\(index)"
            views[buttonName] = button
            if let previousButtonName = previousButtonName {
                xVisualFormat.append("[\(buttonName)(==\(previousButtonName))]")
            } else {
                xVisualFormat.append("[\(buttonName)]")
            }
            
            previousButtonName = buttonName
        }
        
        xVisualFormat.append("|")
        
        let xConstraints = NSLayoutConstraint.constraints(withVisualFormat: xVisualFormat, options: [.alignAllTop, .alignAllBottom], metrics: nil, views: views)
        let yConstraints = NSLayoutConstraint.constraints(withVisualFormat: yVisualFormat, options: [], metrics: nil, views: views)
        
        NSLayoutConstraint.activate(xConstraints)
        NSLayoutConstraint.activate(yConstraints)
    }
    
    open func titleForSegmentAtIndex(_ segment: Int) -> String? {
        guard segment < self.items.count else {
            return nil
        }
        
        return self.items[segment]
    }
    
    open func setSelectedSegmentIndex(_ index: Int, animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.1, animations: {
                self.selectedSegmentIndex = index
                self.layoutIfNeeded()
            })
        } else {
            self.selectedSegmentIndex = index
        }
    }
    
    override open func tintColorDidChange() {
        super.tintColorDidChange()
        
        self.configureView()
    }
    
    // MARK: - Appearance
    private func configureView() {
        self.configureIndicator()
        self.configureButtons()
    }
    
    private func colorToUse(_ color: UIColor?) -> UIColor {
        return color ?? self.tintColor
    }
    
    private func configureIndicator() {
        self.indicatorXConstraint.constant =  CGFloat(self.selectedSegmentIndex) * self.itemWidth
        indicatorWidthConstraint.constant = -(2 * indicatorPadding)
        self.selectionIndicatorView.backgroundColor = self.colorToUse(self.indicatorColor)
    }
    
    private func configureButtons() {
        guard let buttons = self.buttons else {
            return
        }
        
        for button in buttons {
            self.configureButton(button)
        }
    }
    
    private func configureButton(_ button: UIButton) {
        button.titleLabel?.font = self.font
        button.setTitleColor(self.colorToUse(self.titleColor), for: .selected)
        button.setTitleColor(self.unselectedTitleColor, for: UIControlState())

    }
    
    // MARK: - Actions
    func didTapButton(_ button: UIButton) {
        guard let index = self.buttons?.index(of: button) else {
            return
        }
        
        if let shouldSelectItem = delegate?.segmentedControl?(self, canSelectItemAtIndex: index),
           shouldSelectItem == false {
            
            return
        }
        
        delegate?.segmentedControl?(self, willDeselectItemAtIndex: selectedSegmentIndex)
        delegate?.segmentedControl?(self, willSelectItemAtIndex: index)
        
        self.setSelectedSegmentIndex(index)
        self.sendActions(for: .valueChanged)
        
        delegate?.segmentedControl?(self, didDeselectItemAtIndex: selectedSegmentIndex)
        delegate?.segmentedControl?(self, didSelectItemAtIndex: index)
    }
    
    // MARK: - Layout Helpers
    private var xToItem: UIView {
        return self.buttons![self.selectedSegmentIndex]
    }
    
    private var wToItem: UIView {
        
        return self.buttons![self.selectedSegmentIndex]
    }
    
    private var itemWidth: CGFloat {
        return self.bounds.size.width / CGFloat(self.numberOfSegments)
    }
}
