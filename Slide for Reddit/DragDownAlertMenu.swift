//
//  DragDownAlertMenu.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/9/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import Anchorage
import SDWebImage
import SwiftLinkPreview
import UIKit

class AlertMenuAction: NSObject {
    var title: String
    var icon: UIImage?
    var action: () -> Void
    var enabled = true
    var isInput = false
    
    init(title: String, icon: UIImage?, action: @escaping () -> Void, enabled: Bool = true) {
        self.title = title
        self.icon = icon
        self.action = action
        self.enabled = enabled
    }
}

class AlertMenuInputAction: AlertMenuAction {
    var inputField: UITextField
    var exitOnAction: Bool
    var textRequired: Bool

    init(title: String, icon: UIImage?, action: @escaping () -> Void, inputField: UITextField, enabled: Bool = true, inputIcon: UIImage, inputPlaceholder: String, inputValue: String?, accentColor: UIColor, exitOnAction: Bool, textRequired: Bool) {
        self.inputField = inputField
        self.exitOnAction = exitOnAction
        self.textRequired = textRequired
        super.init(title: title, icon: icon, action: action)
        inputField.setImageMode(image: inputIcon.getCopy(withSize: CGSize.square(size: 20)), accentColor: accentColor, placeholder: inputPlaceholder)
        inputField.addTarget(self, action: #selector(textChanged(_:)), for: UIControl.Event.editingChanged)
        inputField.addTarget(self, action: #selector(done(_:)), for: UIControl.Event.editingDidEndOnExit)
        inputField.text = inputValue
        self.isInput = true

        self.enabled = textRequired
    }
    
    @objc func textChanged(_ textField: UITextField) {
        self.enabled = !(textField.text?.isEmpty ?? true)
    }
    
    @objc func done(_ textField: UITextField) {
        if let text = textField.text {
            if !text.isEmpty && exitOnAction {
                action()
            }
        }
    }
}

extension UITextField {
    func setImageMode(image: UIImage, accentColor: UIColor, placeholder: String) {
        self.tintColor = accentColor
        self.layer.cornerRadius = 15
        self.clipsToBounds = true
        self.becomeFirstResponder()
        self.textColor = ColorUtil.theme.fontColor
        self.backgroundColor = ColorUtil.theme.foregroundColor
        self.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor.withAlphaComponent(0.3)])
        self.left(image: image, color: ColorUtil.theme.fontColor)
        //self.leftViewPadding = 12
        self.layer.borderWidth = 1
        self.layer.cornerRadius = 8
        self.layer.borderColor = ColorUtil.theme.fontColor.withAlphaComponent(0.3) .cgColor
        self.keyboardAppearance = .default
        self.keyboardType = .default
        self.returnKeyType = .done
    }
}

class InsetTextField: UITextField {
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 32, dy: 0)
    }
    
    override open func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var textRect = super.leftViewRect(forBounds: bounds)
        textRect.origin.x += 12
        return textRect
    }
    // text position
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 42, dy: 0)
    }
}

class BottomActionCell: UITableViewCell {
    var background = UIView()
    var title = UILabel()
    var icon = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layoutViews()
        themeViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setAction(action: AlertMenuAction, color: UIColor?) {
        title.text = action.title
        if color != nil {
            title.textColor = color!
            if action.icon != nil {
                icon.image = action.icon!.getCopy(withColor: color!)
            }
        } else if action.icon != nil {
            icon.image = action.icon
        }
        
        if !action.enabled {
            self.isUserInteractionEnabled = false
            self.background.alpha = 0.5
            self.title.alpha = 0.5
            self.icon.alpha = 0.5
        } else {
            self.isUserInteractionEnabled = true
            self.background.alpha = 1
            self.title.alpha = 1
            self.icon.alpha = 1
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                self.background.alpha = 0.4
            }, completion: nil)
        } else {
            UIView.animate(withDuration: 0.1, delay: 0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                self.background.alpha = 1
            }, completion: nil)
        }
    }

    func layoutViews() {
        self.contentView.addSubviews(background, title, icon)
        background.verticalAnchors == self.contentView.verticalAnchors + 4
        background.horizontalAnchors == self.contentView.horizontalAnchors + 8
        title.leftAnchor == background.leftAnchor + 16
        title.verticalAnchors == background.verticalAnchors
        title.centerYAnchor == background.centerYAnchor
        
        icon.leftAnchor == title.rightAnchor + 16
        icon.rightAnchor == background.rightAnchor - 16
        icon.centerYAnchor == background.centerYAnchor
        icon.heightAnchor == 44
        
        self.selectionStyle = .none
    }
    
    func themeViews() {
        self.background.backgroundColor = ColorUtil.theme.foregroundColor
        self.background.layer.cornerRadius = 10
        self.background.clipsToBounds = true
        
        self.title.textColor = ColorUtil.theme.fontColor
        self.title.font = UIFont.systemFont(ofSize: 16)
        
        self.icon.contentMode = .center
        
        self.contentView.backgroundColor = ColorUtil.theme.backgroundColor
    }
    
}

class DragDownAlertMenu: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    var descriptor: String
    var subtitle: String
    var icon: String?
    
    var actions: [AlertMenuAction] = []
    var textFields: [UITextField] = []
    
    var tableView = UITableView()
    var headerView = UIView()
    var themeColor: UIColor?
    var full = false
    var hasInput = false

    init(title: String, subtitle: String, icon: String?, themeColor: UIColor? = nil, full: Bool = false) {
        self.descriptor = title
        self.subtitle = subtitle
        self.icon = icon
        self.themeColor = themeColor
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = self
        self.full = full
    }
    
    var backgroundView = UIView().then {
        $0.backgroundColor = .clear
    }

    var interactionController: DragDownDismissInteraction?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(_ vc: UIViewController?) {
        if vc == nil {
            return
        }
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
        vc!.present(self, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        self.headerView = view
    }
    
    func stylize() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(BottomActionCell.classForCoder(), forCellReuseIdentifier: "action")
        self.tableView.separatorStyle = .none
    }
    
    func addAction(title: String, icon: UIImage?, enabled: Bool = true, action: @escaping () -> Void) {
        actions.append(AlertMenuAction(title: title, icon: icon, action: action, enabled: enabled))
    }
    
    func addTextInput(title: String, icon: UIImage?, enabled: Bool = true, action: @escaping () -> Void, inputPlaceholder: String, inputValue: String? = nil, inputIcon: UIImage, textRequired: Bool, exitOnAction: Bool) {
        let input = InsetTextField()
        
        actions.append(AlertMenuInputAction(title: title, icon: icon, action: {
            self.dismiss(animated: true) {
                action()
            }
        }, inputField: input, inputIcon: inputIcon, inputPlaceholder: inputPlaceholder, inputValue: inputValue, accentColor: themeColor ?? ColorUtil.theme.fontColor, exitOnAction: exitOnAction, textRequired: textRequired))
        
        textFields.append(input)
        hasInput = true
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = actions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "action") as! BottomActionCell
        cell.setAction(action: item, color: themeColor)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (subtitle.isEmpty ? 55 : 80) + (hasInput ? 58 : 0)
    }
    
    func getText() -> String? {
        if !textFields.isEmpty {
            return textFields[0].text
        }
        return nil
    }
    
    var isPresenting = false

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if #available(iOS 11.0, *) {
            return 30 + self.additionalSafeAreaInsets.bottom + 20
        } else {
            return 30 + 20
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    var height = CGFloat.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(backgroundView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(DragDownAlertMenu.handleTap(_:)))
        backgroundView.addGestureRecognizer(tapGesture)
        self.tableView = UITableView()
        self.view.addSubview(tableView)
        backgroundView.edgeAnchors == view.edgeAnchors

        self.tableView.centerXAnchor == self.view.centerXAnchor
        self.tableView.widthAnchor == min(self.view.frame.size.width, 450)
        self.tableView.bottomAnchor == self.view.bottomAnchor + 20
        self.tableView.bounces = false
        self.tableView.backgroundColor = ColorUtil.theme.backgroundColor
        self.tableView.layer.cornerRadius = 15
        self.tableView.layer.masksToBounds = true
        let maxHeight: CGFloat
        if full {
            maxHeight = UIScreen.main.bounds.height - 80
            height = min(maxHeight, CGFloat((subtitle.isEmpty ? 55 : 80) + (hasInput ? 58 : 0) + (60 * actions.count) + 60))
        } else {
            maxHeight = UIScreen.main.bounds.height * (2 / 3)
            height = min(maxHeight, CGFloat((subtitle.isEmpty ? 55 : 80) + (hasInput ? 58 : 0) + (60 * actions.count) + 60))
        }
        if height < maxHeight {
            tableView.isScrollEnabled = false
        }
        self.tableView.heightAnchor == height
        stylize()
        self.tableView.reloadData()
        interactionController = DragDownDismissInteraction(viewController: self)
        //self.tableView.roundCorners(UIRectCorner.allCorners, radius: 10)

        // Focus the title for accessibility users
        UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: descriptor)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            self.view.frame.origin.y -= keyboardHeight
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            self.view.frame.origin.y += keyboardHeight
        }
    }

    var lastY: CGFloat = 0.0

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentY = scrollView.contentOffset.y
        let currentBottomY = height + currentY
        if currentY > lastY {
            tableView.bounces = true
        } else {
            if currentBottomY < scrollView.contentSize.height + scrollView.contentInset.bottom {
                tableView.bounces = false
            }
        }
        lastY = scrollView.contentOffset.y
    }

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        //Remove old search constraints
        NSLayoutConstraint.deactivate(textFields.flatMap({ $0.constraints }))
        textFields.forEach({ $0.removeFromSuperview() })
        
        let label: UILabel = UILabel()
        label.numberOfLines = 2
        
        let toReturn = UIView()
        toReturn.backgroundColor = ColorUtil.theme.backgroundColor
        let attributedTitle = NSMutableAttributedString(string: self.descriptor, attributes: [NSAttributedString.Key.foregroundColor: themeColor ?? ColorUtil.theme.fontColor, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17)])
        if !subtitle.isEmpty {
            attributedTitle.append(NSAttributedString(string: "\n" + subtitle, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13), NSAttributedString.Key.foregroundColor: themeColor?.withAlphaComponent(0.6) ?? ColorUtil.theme.fontColor.withAlphaComponent(0.6)]))
        }
        label.attributedText = attributedTitle
        let close = UIImageView(image: UIImage(sfString: SFSymbol.xmark, overrideString: "close")?.navIcon().getCopy(withColor: themeColor ?? ColorUtil.theme.fontColor))
        close.contentMode = .center
        toReturn.addSubview(close)
        close.centerYAnchor == toReturn.centerYAnchor
        close.rightAnchor == toReturn.rightAnchor - 16
        close.heightAnchor == 30
        close.widthAnchor == 30
        close.addTapGestureRecognizer {
            self.dismiss(animated: true, completion: nil)
        }
        close.isAccessibilityElement = true
        close.accessibilityTraits = [.button]
        close.accessibilityLabel = "Close"
        
        if icon != nil {
            let image = UIImageView()
            image.layer.cornerRadius = 7
            image.clipsToBounds = true
            toReturn.addSubviews(image, label)
            image.leftAnchor == toReturn.leftAnchor + 12
            image.centerYAnchor == toReturn.centerYAnchor
            image.heightAnchor == 45
            image.widthAnchor == 45
            image.contentMode = .scaleAspectFill
            image.isAccessibilityElement = false
            if #available(iOS 11.0, *) {
                image.accessibilityIgnoresInvertColors = true
            }
            
            if let url = URL(string: icon!) {
                if ContentType.isImage(uri: url) {
                    image.loadImageWithPulsingAnimation(atUrl: url, withPlaceHolderImage: LinkCellImageCache.web)
                } else {
                    image.image = LinkCellImageCache.web
                    let slp = SwiftLinkPreview(session: URLSession.shared,
                                               workQueue: SwiftLinkPreview.defaultWorkQueue,
                                               responseQueue: DispatchQueue.main,
                                               cache: DisabledCache.instance)
                    slp.preview(icon!, onSuccess: { (response) in
                        image.loadImageWithPulsingAnimation(atUrl: URL(string: response.image ?? response.icon ?? ""), withPlaceHolderImage: LinkCellImageCache.web)
                    }, onError: { (_) in })
                }
            } else {
                image.image = LinkCellImageCache.web
            }
            label.leftAnchor == image.rightAnchor + 8
            label.rightAnchor == close.leftAnchor - 8
            label.verticalAnchors == toReturn.verticalAnchors
        } else {
            toReturn.addSubview(label)
            label.leftAnchor == toReturn.leftAnchor + 16
            label.rightAnchor == close.leftAnchor - 8
            label.verticalAnchors == toReturn.verticalAnchors
        }
        
        let bar = UIView().then {
            $0.backgroundColor = .clear // ColorUtil.theme.fontColor.withAlphaComponent(0.25)
        }
        toReturn.addSubview(bar)
        bar.horizontalAnchors == toReturn.horizontalAnchors
        bar.bottomAnchor == toReturn.bottomAnchor
        bar.heightAnchor == 1
        
        if textFields.isEmpty {
            return toReturn
        } else {
            let finalView = UIStackView().then {
                $0.axis = .vertical
                $0.backgroundColor = ColorUtil.theme.backgroundColor
            }
            finalView.addArrangedSubview(toReturn)
            toReturn.heightAnchor == (subtitle.isEmpty ? 55 : 80)
            toReturn.horizontalAnchors == finalView.horizontalAnchors
            for field in textFields {
                finalView.addArrangedSubview(field)
                field.horizontalAnchors == finalView.horizontalAnchors + 8
                field.heightAnchor == 50
            }
            let space = UIView()
            finalView.addArrangedSubview(space)
            space.heightAnchor == 8
            space.horizontalAnchors == finalView.horizontalAnchors
            return finalView
        }
    }
    
    var headers = [String]()
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selected = self.actions[indexPath.row]
        if selected.isInput {
            if let input = selected as? AlertMenuInputAction {
                if input.textRequired && getText() != nil && !getText()!.isEmpty {
                    selected.action()
                }
            }
        } else {
            dismiss(animated: true) {
                selected.action()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}

//Based off of https://stackoverflow.com/a/45525284/3697225
extension DragDownAlertMenu: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        let presentationController = DragDownPresentationController(presentedViewController: presented,
                                                                          presenting: presenting)
        return presentationController
    }
    
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let menu = presented as? DragDownAlertMenu else {
            return nil
        }
        return DragDownPresentationAnimator(isPresentation: true, interactionController: menu.interactionController)
    }
    
    func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            guard let menu = dismissed as? DragDownAlertMenu else {
                return nil
            }
            return DragDownPresentationAnimator(isPresentation: false, interactionController: menu.interactionController)
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let animator = animator as? DragDownPresentationAnimator,
            let interactionController = animator.interactionController,
            interactionController.interactionInProgress
            else {
                return nil
        }
        return interactionController
    }
}

// MARK: - Accessibility
extension DragDownAlertMenu {
    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true, completion: nil)
        return true
    }

    override var accessibilityViewIsModal: Bool {
        get {
            return true
        }
        set { } // swiftlint:disable:this unused_setter_value
    }
}

final class DragDownPresentationAnimator: NSObject {
    
    let isPresentation: Bool
    var presented = false
    var interactionController: DragDownDismissInteraction?
    
    init(isPresentation: Bool, interactionController: DragDownDismissInteraction?) {
        self.isPresentation = isPresentation
        self.interactionController = interactionController
        super.init()
    }
}
extension DragDownPresentationAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isPresentation || presented ? 0.3 : 0.25
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key = isPresentation ? UITransitionContextViewControllerKey.to
            : UITransitionContextViewControllerKey.from
        guard let controller = transitionContext.viewController(forKey: key)! as? DragDownAlertMenu else {
            fatalError("Presented view controller must be an instance of DragDownAlertMenu!")
        }
        
        controller.view.layoutSubviews()
        
        let presentedContentViewFrame = controller.tableView.frame
        var dismissedContentViewFrame = presentedContentViewFrame
        dismissedContentViewFrame.origin.y = transitionContext.containerView.frame.size.height
        let initialContentViewFrame = isPresentation ? dismissedContentViewFrame : presentedContentViewFrame
        let finalContentViewFrame = isPresentation ? presentedContentViewFrame : dismissedContentViewFrame
        controller.tableView.frame = initialContentViewFrame
        
        var curve = UIView.AnimationOptions.curveEaseInOut
        var spring = CGFloat(0.9)
        var initial = CGFloat(0.4)
        if let interactionController = interactionController,
            interactionController.interactionInProgress {
            curve = UIView.AnimationOptions.curveLinear
            spring = 0
            initial = 0
        }
        if !isPresentation || presented {
            spring = 0
        } else {
            presented = true
        }
        if spring == 0 {
            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                           delay: 0,
                           options: curve,
                           animations: {
                            controller.tableView.frame = finalContentViewFrame
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
            
        } else {
            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                           delay: 0,
                           usingSpringWithDamping: spring,
                           initialSpringVelocity: initial,
                           options: curve,
                           animations: {
                            controller.tableView.frame = finalContentViewFrame
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}

class DragDownPresentationController: UIPresentationController {
    
    fileprivate var backgroundView: UIView!
    
    // Mirror Manager params here
    
    override init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?) {
        
        super.init(presentedViewController: presentedViewController,
                   presenting: presentingViewController)
        
    }
    
    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
        backgroundView.frame = frameOfPresentedViewInContainerView
    }
    
    override func size(forChildContentContainer container: UIContentContainer,
                       withParentContainerSize parentSize: CGSize) -> CGSize {
        return CGSize(width: parentSize.width, height: parentSize.height)
    }
    
    override func presentationTransitionWillBegin() {
        let accountView = presentedViewController as! DragDownAlertMenu
        setupDimmingView()
        if let containerView = containerView {
            containerView.insertSubview(backgroundView, at: 0)
            //            accountView.view.removeFromSuperview() // TODO: Risky?
            containerView.addSubview(accountView.view)
        }
        if accountView.isEditing {
            accountView.textFields[0].becomeFirstResponder()
        }
    }
    
    override func dismissalTransitionWillBegin() {
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.backgroundView.alpha = 0
            }, completion: { _ in
                self.backgroundView.alpha = 0.7
            })
        } else {
        }
        containerView?.endEditing(true)
    }
    
}

// MARK: - Private
private extension DragDownPresentationController {
    func setupDimmingView() {
        backgroundView = UIView(frame: UIScreen.main.bounds).then {
            $0.backgroundColor = .black
            $0.alpha = 0.7
        }
    }
}
class DragDownDismissInteraction: UIPercentDrivenInteractiveTransition, UIGestureRecognizerDelegate {
    var interactionInProgress = false
    
    private var shouldCompleteTransition = false
    private weak var viewController: DragDownAlertMenu!
    private var storedHeight: CGFloat = 400
    
    init(viewController: DragDownAlertMenu) {
        super.init()
        self.viewController = viewController
        self.storedHeight = viewController.height
        prepareGestureRecognizer(in: viewController.view)
    }
    
    private func prepareGestureRecognizer(in view: UIView) {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.direction = UIPanGestureRecognizer.Direction.vertical
        gesture.delegate = self
        view.addGestureRecognizer(gesture)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return (viewController.tableView.contentOffset.y == 0 || viewController.headerView.bounds.contains(touch.location(in: viewController.headerView)) || !(viewController.tableView.bounds.contains(touch.location(in: viewController.tableView))))
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer is UIPanGestureRecognizer && (viewController.tableView.contentOffset.y == 0)
    }
    
    @objc func handleGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let vc = viewController
        
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!)
        let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view!)
        var progress = min(max(0, translation.y), storedHeight) / storedHeight
        progress = max(min(progress, 1), 0) // Clamp between 0 and 1

        switch gestureRecognizer.state {
        case .began:
            interactionInProgress = true
            viewController.dismiss(animated: true, completion: nil)
            storedHeight = vc!.height
        case .changed:
            shouldCompleteTransition = progress > 0.5 || velocity.y > 1000
            update(progress)
        case .cancelled:
            interactionInProgress = false
            cancel()
        case .ended:
            interactionInProgress = false
            shouldCompleteTransition ? finish() : cancel()
        default:
            break
        }
    }
    
}
