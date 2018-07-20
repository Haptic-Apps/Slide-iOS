import UIKit

class ColorPicker: UIView {

    var hueValueForPreview: CGFloat = 1.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var accent = false
    
    func setAccent(accent: Bool) {
        self.accent = true
    }
    
    var allColors: [CGColor] {
        return accent ? GMPalette.allAccentCGColor() : GMPalette.allCGColor()
    }
    
    private var lastTouchLocation: CGPoint?
    private var decelerateTimer: Timer?
    
    private var decelerationSpeed: CGFloat = 0.0 {
        didSet {
            if let timer = decelerateTimer {
                if timer.isValid {
                    timer.invalidate()
                }
            }
            decelerateTimer = Timer.scheduledTimer(timeInterval: 0.025, target: self, selector: #selector(decelerate), userInfo: nil, repeats: true)
        }
    }
    
    private lazy var panGesture: UIPanGestureRecognizer = {
        return UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    }()
   
    private(set) var value: CGFloat = 0.5 {
        didSet {
                if Int(self.value * CGFloat(allColors.count)) > allColors.count - 1 {
                    self.value -= 1
                }
                else if self.value < 0 {
                    self.value += 1
                }
                else {
                    setNeedsDisplay()
                }
           // delegate?.valueChanged(self.value, accent: accent)
        }
    }
    
    private func colors(for value: Int) -> [CGColor] {
        var result = [CGColor]()
        let i = value - 2
        var index = 0
        for val in i...(i + 4) {
            if(val < 0) {
                index = val + (allColors.count - 1)
            }
            else if(val > (allColors.count - 1)) {
                index = val - (allColors.count - 1)
            }
            else {
                index = val
            }
            result.append(allColors[index])
        }
        return result
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            lastTouchLocation = gesture.location(in: self)
        }
        else if gesture.state == .changed {
            if let location = lastTouchLocation {
                value += ((gesture.location(in: self).x - location.x) / frame.width) * 0.1
            }
            lastTouchLocation = gesture.location(in: self)
        }
        else if gesture.state == .ended || gesture.state == .cancelled {
            decelerationSpeed = gesture.velocity(in: self).x
        }
    }
    
    @objc private func decelerate() {
        decelerationSpeed *= 0.7255
        
        if abs(decelerationSpeed) <= 0.001 {
            if let decelerateTimer = decelerateTimer {
                decelerateTimer.invalidate()
            }
            return
        }
        
        value += ((decelerationSpeed * 0.025) / 100) * 0.2
    }
    
    private func commonInit() {
        addGestureRecognizer(panGesture)
        layer.cornerRadius = 5.0
        clipsToBounds = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors(for: Int(value * CGFloat(allColors.count))) as CFArray, locations: [0, 0.25, 0.50, 0.75, 1]) {
            ctx?.drawLinearGradient(gradient, start: CGPoint(x: rect.size.width, y: 0), end: CGPoint.zero, options: .drawsBeforeStartLocation)
        }
        
        let selectionPath = CGMutablePath()
        let verticalPadding = rect.height * 0.4
        let horizontalPosition = rect.midX
        
        selectionPath.move(to: CGPoint(x: horizontalPosition, y: verticalPadding * 0.5))
        selectionPath.addLine(to: CGPoint(x: horizontalPosition, y: rect.height - (verticalPadding * 0.5)))
        
        ctx?.addPath(selectionPath)
        
        ctx?.setLineWidth(1.0)
        ctx?.setStrokeColor(UIColor(white: 0, alpha: 0.5).cgColor)
        
        ctx?.strokePath()
    }
}
