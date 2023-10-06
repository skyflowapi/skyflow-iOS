
// Class for adding feature of copy textfield of UILabel on longpressgesture for reveal element

import UIKit
 
public extension UILabel {
 
    private struct AssociatedKeys {
        static var isCopyingEnabled: UInt8 = 0
        static var shouldUseLongPressGestureRecognizer: UInt8 = 1
        static var longPressGestureRecognizer: UInt8 = 2
        static var copyIconImageView: UIImageView?
        static var copyAfterReveal: Bool = false
        static var actualValue: String = ""
    }
    @objc var copyAfterReveal: Bool {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.copyAfterReveal, newValue, .OBJC_ASSOCIATION_ASSIGN)
                setupCopyIcon()
        }
        get {
            let value = objc_getAssociatedObject(self, &AssociatedKeys.copyAfterReveal)
            return (value as? Bool) ?? false
        }
    }
    @objc var actualValue: String {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.actualValue, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            let value = objc_getAssociatedObject(self, &AssociatedKeys.actualValue)
            return (value as? String) ?? ""
        }
    }
    /// Set this property to `true` in order to enable the copy feature. Defaults to `false`.
    @objc
    @IBInspectable var isCopyingEnabled: Bool {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.isCopyingEnabled, newValue, .OBJC_ASSOCIATION_ASSIGN)
            setupGestureRecognizers()
        }
        get {
            let value = objc_getAssociatedObject(self, &AssociatedKeys.isCopyingEnabled)
            return (value as? Bool) ?? false
        }
    }

    // Add a computed property to manage the copy icon image view
    @objc
    @IBInspectable var copyIconImageView: UIImageView? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.copyIconImageView) as? UIImageView
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.copyIconImageView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
 
    /// Used to enable/disable the internal long press gesture recognizer. Defaults to `true`.
    @IBInspectable var shouldUseLongPressGestureRecognizer: Bool {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.shouldUseLongPressGestureRecognizer, newValue, .OBJC_ASSOCIATION_ASSIGN)
            setupGestureRecognizers()
        }
        get {
            let value = objc_getAssociatedObject(self, &AssociatedKeys.shouldUseLongPressGestureRecognizer)
            return (value as? Bool) ?? true
        }
    }
 
    @objc
    var longPressGestureRecognizer: UILongPressGestureRecognizer? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.longPressGestureRecognizer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.longPressGestureRecognizer) as? UILongPressGestureRecognizer
        }
    }
    
 
    @objc
    override var canBecomeFirstResponder: Bool {
        return isCopyingEnabled
    }
 
    @objc
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return (action == #selector(self.copy(_:)) && isCopyingEnabled)
    }
 
    @objc
    override func copy(_ sender: Any?) {
        if isCopyingEnabled {
            let pasteboard = UIPasteboard.general
            pasteboard.string = text
        }
        if copyAfterReveal {
                let pasteboard = UIPasteboard.general
            pasteboard.string = actualValue
                let image = UIImage(named: "Success-Icon", in: Bundle.module, compatibleWith: nil)
                copyIconImageView?.image = image

                // Reset the copy icon after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.copyIconImageView?.image = UIImage(named: "Copy-Icon", in: Bundle.module, compatibleWith: nil)
                }
            }
    }
    fileprivate func setupCopyIcon() {
            if isCopyingEnabled {
                let iconSize: CGFloat = 24.0

                if copyIconImageView == nil {
                    let image = UIImage(named: "Copy-Icon", in: Bundle.module, compatibleWith: nil)
                    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: iconSize, height: iconSize))
                    imageView.image = image
                    imageView.contentMode = .center
                    imageView.translatesAutoresizingMaskIntoConstraints = false
                    imageView.contentMode = .scaleAspectFit
                    addSubview(imageView)

                    NSLayoutConstraint.activate([
                        imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 5),
                        imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
                        imageView.widthAnchor.constraint(equalToConstant: iconSize),
                        imageView.heightAnchor.constraint(equalToConstant: iconSize)
                    ])
                    copyIconImageView = imageView
                }

                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(copyIconTapped(_:)))
                copyIconImageView?.isUserInteractionEnabled = true
                copyIconImageView?.addGestureRecognizer(tapGesture)
            }
        }

        @objc internal func copyIconTapped(_ sender: UITapGestureRecognizer) {
            // Copy text when the copy icon is tapped
            copy(sender)
//            if #available(iOS 13.0, *) {
//                DispatchQueue.main.async {
//                    let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
//                    feedbackGenerator.prepare()
//                    feedbackGenerator.impactOccurred()
//                }
//            }
        }
 
    @objc internal func longPressGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer === longPressGestureRecognizer && gestureRecognizer.state == .began {
            becomeFirstResponder()
 
            let copyMenu = UIMenuController.shared
            copyMenu.arrowDirection = .default
            
            if #available(iOS 13.0, *) {
                copyMenu.showMenu(from: self, rect: bounds)
            } else {
                // Fallback on earlier versions
                copyMenu.setMenuVisible(true, animated: true)
            }
            copyMenu.setTargetRect(CGRect(x: -25,y: -5, width : 100, height : 100), in: self)
        }
    }
 
    fileprivate func setupGestureRecognizers() {
        // Remove gesture recognizer
        if let longPressGR = longPressGestureRecognizer {
            removeGestureRecognizer(longPressGR)
            longPressGestureRecognizer = nil
        }
 
        if shouldUseLongPressGestureRecognizer && isCopyingEnabled {
            isUserInteractionEnabled = true
            // Enable gesture recognizer
            let longPressGR = UILongPressGestureRecognizer(target: self,
                                                           action: #selector(longPressGestureRecognized(gestureRecognizer:)))
            longPressGestureRecognizer = longPressGR
            addGestureRecognizer(longPressGR)
            
        }
    }
}

