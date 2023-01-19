//
//  SwiftController.swift
//  Example
//
//  Created by wuyong on 2018/3/2.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

import UIKit
import FWDebug
import CoreLocation

@objcMembers class SwiftController: UIViewController, CLLocationManagerDelegate {
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
    
    private class TestObject {
        var id: Int = 1
        var name: String = "name"
    }
    
    private var testObject = TestObject()
    
    var locationManager: CLLocationManager?
    var locationButton: UIButton?

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
        retainCycleButton.frame = CGRect(x: self.view.frame.size.width / 2 - 100, y: 20, width: 200, height: 30)
        self.view.addSubview(retainCycleButton)
        
        let fakeLocationButton = UIButton(type: .system)
        self.locationButton = fakeLocationButton
        fakeLocationButton.setTitle("Fake Location", for: .normal)
        fakeLocationButton.addTarget(self, action: #selector(onFakeLocation), for: .touchUpInside)
        fakeLocationButton.frame = CGRect(x: self.view.frame.size.width / 2 - 100, y: 70, width: 200, height: 30)
        self.view.addSubview(fakeLocationButton)
        
        let crashButton = UIButton(type: .system)
        crashButton.setTitle("Crash", for: .normal)
        crashButton.addTarget(self, action: #selector(onCrash), for: .touchUpInside)
        crashButton.frame = CGRect(x: self.view.frame.size.width / 2 - 100, y: 120, width: 200, height: 30)
        self.view.addSubview(crashButton)
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //if let location = locations.last {
        if let location = manager.location {
            self.locationButton?.setTitle("\(location.coordinate.latitude),\(location.coordinate.longitude)", for: .normal)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.locationButton?.setTitle("Failed", for: .normal)
    }
    
    // MARK: - Action
    func onDebug() {
        if FWDebugManager.sharedInstance().isHidden {
            FWDebugManager.sharedInstance().show()
            FWDebugManager.sharedInstance().systemLog("Show FWDebug")
            FWDebugManager.sharedInstance().customLog("Show FWDebug")
        } else {
            FWDebugManager.sharedInstance().hide()
            FWDebugManager.sharedInstance().systemLog("Hide FWDebug")
            FWDebugManager.sharedInstance().customLog("Hide FWDebug")
        }
    }
    
    func onRetainCycle() {
        let retainObject = SwiftController()
        retainObject.object = self
        self.object = retainObject
    }
    
    func onFakeLocation() {
        if self.locationManager == nil {
            self.locationManager = CLLocationManager()
            self.locationManager?.delegate = self
            self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager?.distanceFilter = kCLDistanceFilterNone
            self.locationManager?.requestWhenInUseAuthorization()
            self.locationManager?.startUpdatingLocation()
            self.locationButton?.setTitle("Updating", for: .normal)
        } else {
            self.locationManager?.stopUpdatingLocation()
            self.locationManager?.delegate = nil
            self.locationManager = nil
            self.locationButton?.setTitle("Fake Location", for: .normal)
        }
    }
    
    func onCrash() {
        let object = NSObject()
        object.perform(#selector(onCrash))
    }
}
