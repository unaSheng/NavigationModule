import UIKit

@IBDesignable
public class DualColorLinearGradientView: UIView {
    
    @IBInspectable
    public var startColor: UIColor = .clear {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    @IBInspectable
    public var endColor: UIColor = .clear {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    @IBInspectable
    public var startPoint: CGPoint = .zero {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    @IBInspectable
    public var endPoint: CGPoint = CGPoint(x: 1, y: 1) {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    override public class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    private var gradientLayer: CAGradientLayer {
        return self.layer as! CAGradientLayer
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        var endColor = self.endColor
        if endColor == UIColor.clear {
            endColor = self.startColor.withAlphaComponent(0)
        }
        var startColor = self.startColor
        if startColor == UIColor.clear {
            startColor = self.endColor.withAlphaComponent(0)
        }
        self.gradientLayer.colors = [startColor,endColor].compactMap({ $0.cgColor })
        self.gradientLayer.startPoint = self.startPoint
        self.gradientLayer.endPoint = self.endPoint
    }
}
