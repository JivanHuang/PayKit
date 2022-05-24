//
//  ViewController.swift
//  SwiftPayKit
//
//  Created by Jivan on 2022/5/23.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let orderInfo = AlilPayOrderInfo(scheme: "", orderString: "")
        PayKit.shared.payOrder(orderInfo: orderInfo) { success, payCode, result in
            
        }
    }


}

