import UIKit
import Foundation

public enum Badge {
    case dot
    case text(String?)
}

protocol BadgeSupport: AnyObject {
    var badge: Badge? { get set }
}

public class BadgeButton: UIButton, BadgeSupport {
    private var badgeView: BadgeView!
    
    public var badge: Badge? {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        if badgeView == nil {
            self.badgeView = BadgeView()
            self.badgeView.isUserInteractionEnabled = false
            self.addSubview(self.badgeView)
        }
        self.badgeView.badge = self.badge
        self.badgeView.frame.size = self.badgeView.intrinsicContentSize
        if let text = self.currentTitle, text.count > 0 {
            self.badgeView.center = CGPoint(x: self.titleLabel!.frame.maxX, y: self.titleLabel!.frame.minY)
        } else if let _ = self.currentImage {
            self.badgeView.frame = CGRect(x: self.imageView!.frame.maxX - self.badgeView.bounds.width, y: self.imageView!.frame.minY, width: self.badgeView.bounds.width, height: self.badgeView.bounds.height)
        } else {
            self.badgeView.frame = CGRect(x: self.bounds.width - self.badgeView.bounds.width, y: 0, width: self.badgeView.bounds.width, height: self.badgeView.bounds.height)
        }
    }
}

public class BadgeView: UILabel {
    
    public var badge: Badge? {
        didSet {
            if let badge = badge {
                switch badge {
                case .dot:
                    isHidden = false
                    text = nil
                case .text(let text):
                    self.text = text
                    self.isHidden = text == nil || text == "0"
                }
            } else {
                isHidden = true
            }
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height/2.0
        layer.masksToBounds = true
        
        if let badge, case .dot = badge {
            layer.borderColor = UIColor.clear.cgColor
            layer.borderWidth = 0
        } else {
            layer.borderColor = UIColor.systemRed.cgColor
            layer.borderWidth = 2
        }
    }
    
    private func setup() {
        font = .systemFont(ofSize: 10, weight: .semibold)
        backgroundColor = .systemRed
        textAlignment = .center
        
        layer.borderColor = UIColor.systemRed.cgColor
        textColor = .white
        backgroundColor = .systemRed
        layer.borderWidth = 2
    }
    
    public override func drawText(in rect: CGRect) {
        if let badge = badge, case .dot = badge {
            super.drawText(in: rect)
        } else {
            let insets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 3)
            super.drawText(in: rect.inset(by: insets))
        }
    }
    
    public override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        if let badge = badge {
            switch badge {
            case .dot:
                return CGSize(width: 8, height: 8)
            default:
                return CGSize(width: max(size.width + 6, 18), height: 18)
            }
        }
        return CGSize(width: max(size.width + 6, 18), height: 18)
    }
    
}
