//
//  SwiftController.swift
//  Example
//
//  Created by wuyong on 2018/3/2.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

import UIKit
import FWDebug

@objc class SwiftController: UIViewController {
    // MARK: - Property
    private struct AssociatedKeys {
        static var object = "ak_object"
    }
    var object: Any? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.object)
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.object, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Swift"
        self.edgesForExtendedLayout = []
        self.view.backgroundColor = UIColor.white
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Debug", style: .plain, target: self, action: #selector(onDebug))
        
        let retainCycleButton = UIButton(type: .system)
        retainCycleButton.setTitle("Retain Cycle", for: .normal)
        retainCycleButton.addTarget(self, action: #selector(onRetainCycle), for: .touchUpInside)
        retainCycleButton.frame = CGRect(x: self.view.frame.size.width / 2 - 50, y: 20, width: 100, height: 30)
        self.view.addSubview(retainCycleButton)
        
        let crashButton = UIButton(type: .system)
        crashButton.setTitle("Crash", for: .normal)
        crashButton.addTarget(self, action: #selector(onCrash), for: .touchUpInside)
        crashButton.frame = CGRect(x: self.view.frame.size.width / 2 - 50, y: 70, width: 100, height: 30)
        self.view.addSubview(crashButton)
    }
    
    // MARK: - Action
    func onDebug() {
        if FWDebugManager.sharedInstance().isHidden {
            FWDebugManager.sharedInstance().show()
            NSLog("Show FWDebug")
        } else {
            FWDebugManager.sharedInstance().hide()
            NSLog("Hide FWDebug")
        }
    }
    
    func onRetainCycle() {
        let retainObject = SwiftController()
        retainObject.object = self
        self.object = retainObject
    }
    
    func onCrash() {
        let object = NSObject()
        object.perform(#selector(onCrash))
    }
}
