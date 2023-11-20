@import ObjectiveC;
#import "UIViewController+LifecycleObserver.h"

static void class_swizzleSelector(Class class, SEL originalSelector, SEL newSelector)
{
    Method origMethod = class_getInstanceMethod(class, originalSelector);
    Method newMethod = class_getInstanceMethod(class, newSelector);
    if(class_addMethod(class, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(class, newSelector, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}

@interface UIViewController (LifecycleObserver_Private)

@property (nonatomic, strong, readonly) NSHashTable *mtrLifecycleObservers;

@end

@implementation UIViewController (LifecycleObserver)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            class_swizzleSelector(self, @selector(viewDidLoad), @selector(mtr_lco_viewDidLoad));
            class_swizzleSelector(self, @selector(viewWillLayoutSubviews), @selector(mtr_lco_viewWillLayoutSubviews));
            class_swizzleSelector(self, @selector(viewDidLayoutSubviews), @selector(mtr_lco_viewDidLayoutSubviews));
            class_swizzleSelector(self, @selector(viewWillAppear:), @selector(mtr_lco_viewWillAppear:));
            class_swizzleSelector(self, @selector(viewDidAppear:), @selector(mtr_lco_viewDidAppear:));
            class_swizzleSelector(self, @selector(viewWillDisappear:), @selector(mtr_lco_viewWillDisappear:));
            class_swizzleSelector(self, @selector(viewDidDisappear:), @selector(mtr_lco_viewDidDisappear:));
        }
    });
}

- (NSHashTable *)mtrLifecycleObservers {
    NSAssert(NSThread.mainThread, @"");
    NSHashTable *table = objc_getAssociatedObject(self, @selector(mtrLifecycleObservers));
    if (table == nil) {
        table = [NSHashTable weakObjectsHashTable];
        objc_setAssociatedObject(self, @selector(mtrLifecycleObservers), table, OBJC_ASSOCIATION_RETAIN);
    }
    return table;
}

+ (NSHashTable *)mtrViewLoadObservers {
    NSAssert(NSThread.mainThread, @"");
    static NSHashTable *table;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            table = [NSHashTable weakObjectsHashTable];
        }
    });
    return table;
}

+ (void)mtr_addViewLoadObserver:(id<MTRUIViewControllerViewLoadObserver>)observer {
    [self.mtrViewLoadObservers addObject:observer];
}

- (void)mtr_addLifecycleObserver:(id<MTRUIViewControllerLifecycleObserver>)observer {
    [self.mtrLifecycleObservers addObject:observer];
}

- (void)mtr_lco_viewDidLoad {
    [self mtr_lco_viewDidLoad];
    for (id<MTRUIViewControllerViewLoadObserver> observer in UIViewController.mtrViewLoadObservers.allObjects) {
        [observer viewDidLoad:self];
    }
    for (id<MTRUIViewControllerLifecycleObserver> observer in self.mtrLifecycleObservers.allObjects) {
        [observer viewDidLoad];
    }
}

- (void)mtr_lco_viewWillAppear:(BOOL)animated {
    [self mtr_lco_viewWillAppear:animated];
    for (id<MTRUIViewControllerLifecycleObserver> observer in self.mtrLifecycleObservers.allObjects) {
        [observer viewWillAppear:animated];
    }
}

- (void)mtr_lco_viewDidAppear:(BOOL)animated {
    [self mtr_lco_viewDidAppear:animated];
    for (id<MTRUIViewControllerLifecycleObserver> observer in self.mtrLifecycleObservers.allObjects) {
        [observer viewDidAppear:animated];
    }
}

- (void)mtr_lco_viewWillDisappear:(BOOL)animated {
    [self mtr_lco_viewWillDisappear:animated];
    for (id<MTRUIViewControllerLifecycleObserver> observer in self.mtrLifecycleObservers.allObjects) {
        [observer viewWillDisappear:animated];
    }
}

- (void)mtr_lco_viewDidDisappear:(BOOL)animated {
    [self mtr_lco_viewDidDisappear:animated];
    for (id<MTRUIViewControllerLifecycleObserver> observer in self.mtrLifecycleObservers.allObjects) {
        [observer viewDidDisappear:animated];
    }
}

- (void)mtr_lco_viewWillLayoutSubviews {
    [self mtr_lco_viewWillLayoutSubviews];
    for (id<MTRUIViewControllerLifecycleObserver> observer in self.mtrLifecycleObservers.allObjects) {
        [observer viewWillLayoutSubviews];
    }
}

- (void)mtr_lco_viewDidLayoutSubviews {
    [self mtr_lco_viewDidLayoutSubviews];
    for (id<MTRUIViewControllerLifecycleObserver> observer in self.mtrLifecycleObservers.allObjects) {
        [observer viewDidLayoutSubviews];
    }
}

@end
