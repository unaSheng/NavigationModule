//
//  ListViewController.swift
//  NavigationModule_Example
//
//  Created by li.wenxiu on 2024/4/3.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import NavigationModule

class ListViewController: UIViewController {
    
    @NavigationModule var navigationModule
    
    var barStyle: _NavigationModule.BackgroundStyle = .default
    var autoAdjustAlpha = false
    
    var barButtonItems: [UIBarButtonItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "用户"
        
        let backItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), primaryAction: UIAction.init(handler: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }))
        navigationItem.leftBarButtonItem = backItem
        
        let editItem = BadgeBarButtonItem(title: "编辑", primaryAction: UIAction.init(handler: { _ in
            debugPrint("edit")
        }))
        editItem.badge = .text("9")
        
        let shareItem = BadgeBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), primaryAction: UIAction.init(handler: { _ in
            debugPrint("share")
        }))
        shareItem.badge = .dot
        
        let moreItem = BadgeBarButtonItem(image: UIImage(systemName: "ellipsis"), primaryAction: UIAction.init(handler: { _ in
            debugPrint("more")
        }))
        navigationItem.rightBarButtonItems = [editItem, shareItem, moreItem]
        
        barButtonItems = [backItem, editItem, shareItem, moreItem]
        barButtonItems.forEach({ $0.tintColor = .black })
        
        navigationModule.rightBarButtonItemSpacing = 0
        navigationModule.backgroundStyle = barStyle
        if case .solid = barStyle, autoAdjustAlpha {
            self.title = nil
        } else if case .clear = barStyle {
            self.title = nil
            self.view.backgroundColor = .lightGray
        } else if case .transparent = barStyle {
            self.title = nil
        }
    }
    
}
