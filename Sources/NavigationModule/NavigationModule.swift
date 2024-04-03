import Foundation
import UIKit
import Combine

public typealias NavigationModule = Module<_NavigationModule>

public class BadgeBarButtonItem: UIBarButtonItem {
    public let badgeUpdated: PassthroughSubject<Badge?, Never> = .init()
    public var badge: Badge? = nil {
        didSet {
            self.badgeUpdated.send(badge)
        }
    }
}

public class PrimaryActionBarButtonItem: UIBarButtonItem {
    public init(title: String, action: @escaping () -> Void) {
        super.init()
        self.title = title
        self.primaryAction = UIAction(title: title, handler: { _ in
            action()
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class _NavigationModule: ViewControllerModule {
    
    public enum BackgroundStyle {
        case `default`
        case transparent
        case clear
        case solid(UIColor)
    }
    
    public var backgroundStyle: BackgroundStyle = .default {
        didSet { self.updateBackground() }
    }
    
    public var alpha: CGFloat = 1 {
        didSet { self.navigationView.alpha = alpha }
    }
    
    public var rightBarButtonItemSpacing: CGFloat = 0 {
        didSet { self.rightItemView.spacing = rightBarButtonItemSpacing }
    }
    
    public var leftBarButtonItemSpacing: CGFloat = 0 {
        didSet { self.leftItemView.spacing = leftBarButtonItemSpacing }
    }
    
    private var observers: Set<AnyCancellable> = []
    
    private let gradientView: DualColorLinearGradientView = DualColorLinearGradientView()
    private let navigationView: UIView
    private let navigationBarContentView: UIView
    private let titleLabel: UILabel
    private let backButton: UIButton
    private let leftItemView: UIStackView
    private let rightItemView: UIStackView
    private var leftItemChangeObservers: Set<AnyCancellable> = []
    private var rightItemChangeObservers: Set<AnyCancellable> = []
    private var backItemChangeObservers: Set<AnyCancellable> = []

    private weak var viewController: UIViewController?
    
    static let defaultNavigationBarHeight: CGFloat = 48
    
    public struct Options: ViewControllerModuleOptionsWithDefault {
        public init(navigationBarHeight: CGFloat = 48) {
            self.navigationBarHeight = navigationBarHeight
        }
        public init() {
            self.navigationBarHeight = 48
        }
        public var navigationBarHeight: CGFloat
    }
    
    let navigationBarHeight: CGFloat
    
    public required init(viewController: UIViewController, options: Options) {
        self.navigationBarHeight = options.navigationBarHeight
        self.viewController = viewController
        self.navigationView = UIView(frame: .zero)
        self.navigationBarContentView = UIView(frame: .zero)
        self.leftItemView = UIStackView()
        self.rightItemView = UIStackView()
        self.backButton = Self.makeView(for: UIBarButtonItem(image: UIImage(named: "nav_back")), observers: &backItemChangeObservers) as! UIButton
        self.titleLabel = UILabel(frame: .zero)
        
        gradientView.startPoint = CGPoint(x: 0, y: 0)
        gradientView.endPoint = CGPoint(x: 0, y: 1)
        gradientView.startColor = UIColor.black.withAlphaComponent(0.6)
        gradientView.endColor = UIColor.black.withAlphaComponent(0)
        gradientView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        gradientView.frame = navigationView.bounds
        gradientView.frame.size.height += 40
        navigationView.addSubview(gradientView)

        viewController.publisher(for: \.title).sink(receiveValue: { [weak self] title in
            self?.updateTitleView()
        }).store(in: &observers)
        viewController.navigationItem.publisher(for: \.titleView).sink(receiveValue: { [weak self] items in
            self?.updateTitleView()
        }).store(in: &observers)
        viewController.navigationItem.publisher(for: \.rightBarButtonItems).sink(receiveValue: { [weak self] items in
            self?.updateRightItems()
        }).store(in: &observers)
        viewController.navigationItem.publisher(for: \.rightBarButtonItem).sink(receiveValue: { [weak self] items in
            self?.updateRightItems()
        }).store(in: &observers)
        viewController.navigationItem.publisher(for: \.leftBarButtonItems).sink(receiveValue: { [weak self] items in
            self?.updateLeftItems()
        }).store(in: &observers)
        viewController.navigationItem.publisher(for: \.leftBarButtonItem).sink(receiveValue: { [weak self] item in
            self?.updateLeftItems()
        }).store(in: &observers)
        viewController.navigationItem.publisher(for: \.leftItemsSupplementBackButton).sink(receiveValue: { [weak self] item in
            self?.updateLeftItems()
        }).store(in: &observers)
        viewController.navigationItem.publisher(for: \.hidesBackButton).sink(receiveValue: { [weak self] items in
            self?.updateBackButton()
        }).store(in: &observers)
        
        navigationView.translatesAutoresizingMaskIntoConstraints = false
        navigationBarContentView.translatesAutoresizingMaskIntoConstraints = false
        leftItemView.translatesAutoresizingMaskIntoConstraints = false
        rightItemView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        leftItemView.axis = .horizontal
        rightItemView.axis = .horizontal
        leftItemView.alignment = .center
        rightItemView.alignment = .center
        leftItemView.spacing = 0
        rightItemView.spacing = 0
        
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        backButton.addAction(UIAction { [weak self] _ in
            self?.viewController?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)
        
        viewController.additionalSafeAreaInsets.top += self.navigationBarHeight
        self.updateBackground()
    }
    
    private func updateTitleView() {
        navigationBarContentView.subviews.forEach({ subView in
            if ![leftItemView, titleLabel, rightItemView].contains(subView) {
                subView.removeFromSuperview()
            }
        })
        if let titleView = viewController?.navigationItem.titleView {
            viewController?.navigationItem.titleView = nil
            if titleView.superview != navigationBarContentView {
                titleView.removeFromSuperview()
                titleView.translatesAutoresizingMaskIntoConstraints = false
                navigationBarContentView.addSubview(titleView)
                NSLayoutConstraint.activate([
                    titleView.centerYAnchor.constraint(equalTo: navigationBarContentView.centerYAnchor),
                    titleView.leadingAnchor.constraint(greaterThanOrEqualTo: leftItemView.trailingAnchor, constant: 8),
                    titleView.trailingAnchor.constraint(lessThanOrEqualTo: rightItemView.leadingAnchor, constant: -8)
                ])
                let titleCenterConstraint = titleView.centerXAnchor.constraint(equalTo: navigationBarContentView.centerXAnchor)
                titleCenterConstraint.priority = .fittingSizeLevel
                titleCenterConstraint.isActive = true
            }
            self.titleLabel.text = ""
            self.titleLabel.isHidden = true
        } else {
            self.titleLabel.text = self.viewController?.title
            self.titleLabel.isHidden = false
        }
    }
    
    private func updateBackground() {
        switch backgroundStyle {
        case .default:
            if self.viewController?.traitCollection.userInterfaceLevel == .elevated {
                navigationView.backgroundColor = .systemBackground
            } else {
                navigationView.backgroundColor = .systemBackground
            }
            gradientView.isHidden = true
            navigationView.overrideUserInterfaceStyle = .unspecified
        case .transparent:
            navigationView.backgroundColor = .clear
            gradientView.isHidden = false
            navigationView.overrideUserInterfaceStyle = .dark
        case .clear:
            navigationView.backgroundColor = .clear
            gradientView.isHidden = true
            navigationView.overrideUserInterfaceStyle = .unspecified
        case .solid(let color):
            navigationView.backgroundColor = color
            gradientView.isHidden = true
            navigationView.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    private func updateBackButton() {
        guard let viewController = self.viewController else { return }
        if viewController.navigationItem.hidesBackButton {
            backButton.isHidden = true
        } else {
            if let nav = viewController.navigationController {
                if nav.viewControllers.contains(viewController) {
                    backButton.isHidden = nav.viewControllers.first == viewController
                } else {
                    backButton.isHidden = true
                }
            } else {
                backButton.isHidden = true
            }
        }
    }
    
    private func updateRightItems() {
        guard let viewController = self.viewController else { return }
        self.rightItemChangeObservers = []
        let items = viewController.navigationItem.rightBarButtonItems ?? []
        self.rightItemView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        for item in items.reversed() {
            self.rightItemView.addArrangedSubview(Self.makeView(for: item, observers: &rightItemChangeObservers))
        }
    }
    
    private func updateLeftItems() {
        guard let viewController = self.viewController else { return }
        self.leftItemChangeObservers = []
        let items = viewController.navigationItem.leftBarButtonItems ?? []
        self.leftItemView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        if items.count == 0 || viewController.navigationItem.leftItemsSupplementBackButton {
            self.leftItemView.addArrangedSubview(backButton)
        }
        for item in items {
            self.leftItemView.addArrangedSubview(Self.makeView(for: item, observers: &leftItemChangeObservers))
        }
    }
    
    public static func makeView(for item: UIBarButtonItem, observers: inout Set<AnyCancellable>) -> UIView {
        if let customView = item.customView {
            if let badgeItem = item as? BadgeBarButtonItem, let badgeButton = customView as? BadgeSupport {
                badgeItem.badgeUpdated.sink(receiveValue: { badge in
                    badgeButton.badge = badge
                }).store(in: &observers)
                badgeButton.badge = badgeItem.badge
            }
            item.customView = nil
            return customView
        } else {
            if item.debugDescription.contains("systemItem=") {
                assertionFailure("system Item is not supported")
            }
            let button: UIButton
//            if item is PrimaryActionBarButtonItem {
//                button = PrimaryActionBarButton(type: .system)
//                button.contentEdgeInsets = UIEdgeInsets(top: 11, left: 8 + 15, bottom: 11, right: 8 + 15)
//            } else {
                button = BadgeButton(type: .system)
                button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
//            }
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            button.setTitle(item.title, for: .normal)
            button.setImage(item.image, for: .normal)
            button.tintColor = item.tintColor ?? .label
            
            item.publisher(for: \.title).sink(receiveValue: { title in
                button.setTitle(item.title, for: .normal)
            }).store(in: &observers)
            item.publisher(for: \.image).sink(receiveValue: { image in
                button.setImage(image, for: .normal)
            }).store(in: &observers)
            item.publisher(for: \.tintColor).sink(receiveValue: { color in
                button.tintColor = color ?? .label
            }).store(in: &observers)
            
            if let badgeItem = item as? BadgeBarButtonItem, let badgeButton = button as? BadgeSupport {
                badgeItem.badgeUpdated.sink(receiveValue: { badge in
                    badgeButton.badge = badge
                }).store(in: &observers)
                badgeButton.badge = badgeItem.badge
            }
            
            if let primaryAction = item.primaryAction {
                button.addAction(primaryAction, for: .touchUpInside)
            } else if let menu = item.menu {
                button.menu = menu
                button.showsMenuAsPrimaryAction = true
            } else if let t = item.target, let a = item.action {
                button.addTarget(t, action: a, for: .touchUpInside)
            }
            return button
        }
       
    }
    
    public func viewDidLoad() {
        guard let viewController = self.viewController else { return }
        viewController.view.addSubview(navigationView)
        
        navigationView.addSubview(navigationBarContentView)
        NSLayoutConstraint.activate([
            navigationBarContentView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            navigationBarContentView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            navigationBarContentView.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: -self.navigationBarHeight),
            navigationBarContentView.heightAnchor.constraint(equalToConstant: self.navigationBarHeight),
            navigationView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            navigationView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            navigationView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            navigationView.bottomAnchor.constraint(equalTo: navigationBarContentView.bottomAnchor)
        ])
        navigationBarContentView.addSubview(leftItemView)
        navigationBarContentView.addSubview(titleLabel)
        navigationBarContentView.addSubview(rightItemView)
        NSLayoutConstraint.activate([
            leftItemView.topAnchor.constraint(equalTo: navigationBarContentView.topAnchor),
            leftItemView.bottomAnchor.constraint(equalTo: navigationBarContentView.bottomAnchor),
            leftItemView.leadingAnchor.constraint(equalTo: navigationBarContentView.leadingAnchor, constant: 4),
            rightItemView.topAnchor.constraint(equalTo: navigationBarContentView.topAnchor),
            rightItemView.bottomAnchor.constraint(equalTo: navigationBarContentView.bottomAnchor),
            rightItemView.trailingAnchor.constraint(equalTo: navigationBarContentView.trailingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: navigationBarContentView.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: navigationBarContentView.bottomAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leftItemView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: rightItemView.leadingAnchor, constant: -8),
        ])
        let titleCenterConstraint = titleLabel.centerXAnchor.constraint(equalTo: navigationBarContentView.centerXAnchor)
        titleCenterConstraint.priority = .fittingSizeLevel
        titleCenterConstraint.isActive = true
    }
    
    public func viewDidLayoutSubviews() {
        guard let viewController = self.viewController else { return }
        self.updateBackground()
        self.updateBackButton()
        viewController.view.bringSubviewToFront(self.navigationView)
    }
    
    public func viewDidAppear(_ animated: Bool) {
        self.updateBackButton()
    }
}
