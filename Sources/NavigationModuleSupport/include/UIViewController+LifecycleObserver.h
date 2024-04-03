@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@protocol MTRUIViewControllerViewLoadObserver <NSObject>

- (void)viewDidLoad:(UIViewController *)viewController;

@end

@protocol MTRUIViewControllerLifecycleObserver <NSObject>

- (void)viewDidLoad;
- (void)viewWillAppear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
- (void)viewWillDisappear:(BOOL)animated;
- (void)viewDidDisappear:(BOOL)animated;
- (void)viewWillLayoutSubviews;
- (void)viewDidLayoutSubviews;

@end

@interface UIViewController (LifecycleObserver)

- (void)mtr_addLifecycleObserver:(id<MTRUIViewControllerLifecycleObserver>)observer;
+ (void)mtr_addViewLoadObserver:(id<MTRUIViewControllerViewLoadObserver>)observer;

@end

NS_ASSUME_NONNULL_END
