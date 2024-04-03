//
//  ViewController.swift
//  NavigationModule
//
//  Created by 李文秀 on 04/03/2024.
//  Copyright (c) 2024 李文秀. All rights reserved.
//

import UIKit
import NavigationModule

class ViewController: UIViewController {
    
    @IBAction func jumpButtonTapped(_ sender: Any) {
        let userListVC = ListViewController()
        navigationController?.navigationBar.isHidden = true
        navigationController?.pushViewController(userListVC, animated: true)
    }
}

