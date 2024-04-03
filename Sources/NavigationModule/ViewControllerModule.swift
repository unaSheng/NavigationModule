import Foundation
import UIKit
#if SWIFT_PACKAGE
@_exported import NavigationModuleSupport
#endif

public protocol ViewControllerModuleOptionsWithDefault {
    init()
}

public protocol ViewControllerModule {
    associatedtype Options
    
    init(viewController: UIViewController, options: Options)
    
    func viewDidLoad()
    func viewWillAppear(_ animated: Bool)
    func viewDidAppear(_ animated: Bool)
    func viewWillDisappear(_ animated: Bool)
    func viewDidDisappear(_ animated: Bool)
    func viewWillLayoutSubviews()
    func viewDidLayoutSubviews()
}

extension ViewControllerModule {
    public func viewDidLoad() {}
    public func viewWillAppear(_ animated: Bool) {}
    public func viewDidAppear(_ animated: Bool) {}
    public func viewWillDisappear(_ animated: Bool) {}
    public func viewDidDisappear(_ animated: Bool) {}
    public func viewWillLayoutSubviews() {}
    public func viewDidLayoutSubviews() {}
}

public enum ViewControllerModuleInitializer {
    public static func initialize() {
        UIViewController.mtr_add(ViewControllerModuleLoader.shared)
    }
}

protocol ViewControllerModulePropertyWrapper {
    func _makeModule(for viewController: UIViewController)
}

@propertyWrapper
public struct Module<Value: ViewControllerModule>: ViewControllerModulePropertyWrapper {
    private class Core {
        var module: Value!
        var observer: ViewControllerLifecycleObserver!
    }
    
    private var core: Core = Core()
    private let options: Value.Options
    
    public init(options: Value.Options) {
        self.options = options
    }
    
    public init() where Value.Options: ViewControllerModuleOptionsWithDefault {
        self.options = Value.Options()
    }
    
    func _makeModule(for viewController: UIViewController) {
        let module = Value.init(viewController: viewController, options: options)
        let observer = ViewControllerLifecycleObserver(module: module)
        self.core.module = module
        self.core.observer = observer
        viewController.mtr_add(observer)
    }
    
    public static subscript<T: UIViewController>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, Self>
    ) -> Value {
        get {
            return instance[keyPath: storageKeyPath].core.module
        }
        set {
            fatalError()
        }
    }
    
    @available(*, unavailable, message: "This property wrapper can only be applied to UIViewControllers")
    public var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }
}


private class ViewControllerModuleLoader: NSObject, MTRUIViewControllerViewLoadObserver {
    static let shared: ViewControllerModuleLoader = ViewControllerModuleLoader()
    func viewDidLoad(_ viewController: UIViewController) {
        for child in Mirror(reflecting: viewController).children {
            if let module = child.value as? ViewControllerModulePropertyWrapper {
                module._makeModule(for: viewController)
            }
        }
    }
}

private class ViewControllerLifecycleObserver: NSObject, MTRUIViewControllerLifecycleObserver {
    
    private let module: any ViewControllerModule
    
    init(module: any ViewControllerModule) {
        self.module = module
    }
    
    func viewDidLoad() {
        module.viewDidLoad()
    }
    
    func viewWillAppear(_ animated: Bool) {
        module.viewWillAppear(animated)
    }
    
    func viewDidAppear(_ animated: Bool) {
        module.viewDidAppear(animated)
    }
    
    func viewWillDisappear(_ animated: Bool) {
        module.viewWillDisappear(animated)
    }
    
    func viewDidDisappear(_ animated: Bool) {
        module.viewDidDisappear(animated)
    }
    
    func viewWillLayoutSubviews() {
        module.viewWillLayoutSubviews()
    }
    
    func viewDidLayoutSubviews() {
        module.viewDidLayoutSubviews()
    }
}
