//
//  SwiftController.swift
//  Example
//
//  Created by wuyong on 2018/3/2.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

import UIKit
import OSLog
import FWDebug
import CoreLocation

@objcMembers class SwiftController: UIViewController, CLLocationManagerDelegate {
    // MARK: - Property
    var object: Any? {
        get {
            let key = unsafeBitCast(Selector(#function), to: UnsafeRawPointer.self)
            return objc_getAssociatedObject(self, key)
        }
        set {
            let key = unsafeBitCast(Selector(#function), to: UnsafeRawPointer.self)
            objc_setAssociatedObject(self, key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private class TestObject {
        var id: Int = 1
        var name: String = "name"
    }
    
    private var testObject = TestObject()
    
    var locationManager: CLLocationManager?
    var locationButton: UIButton?
    var imageView: UIImageView?

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
        
        let chooseFileButton = UIButton(type: .system)
        chooseFileButton.setTitle("Choose Image", for: .normal)
        chooseFileButton.addTarget(self, action: #selector(onChooseImage), for: .touchUpInside)
        chooseFileButton.frame = CGRect(x: self.view.frame.size.width / 2 - 100, y: 120, width: 200, height: 30)
        self.view.addSubview(chooseFileButton)
        
        let requestImageButton = UIButton(type: .system)
        requestImageButton.setTitle("Request Image", for: .normal)
        requestImageButton.addTarget(self, action: #selector(onRequestImage), for: .touchUpInside)
        requestImageButton.frame = CGRect(x: self.view.frame.size.width / 2 - 100, y: 170, width: 200, height: 30)
        self.view.addSubview(requestImageButton)
        
        let crashButton = UIButton(type: .system)
        crashButton.setTitle("Crash", for: .normal)
        crashButton.addTarget(self, action: #selector(onCrash), for: .touchUpInside)
        crashButton.frame = CGRect(x: self.view.frame.size.width / 2 - 100, y: 220, width: 200, height: 30)
        self.view.addSubview(crashButton)
        
        let nslogButton = UIButton(type: .system)
        nslogButton.setTitle("NSLog", for: .normal)
        nslogButton.addTarget(self, action: #selector(onNSLog), for: .touchUpInside)
        nslogButton.frame = CGRect(x: self.view.frame.size.width / 2 - 100, y: 270, width: 200, height: 30)
        self.view.addSubview(nslogButton)
        
        let oslogButton = UIButton(type: .system)
        oslogButton.setTitle("OSLog", for: .normal)
        oslogButton.addTarget(self, action: #selector(onOSLog), for: .touchUpInside)
        oslogButton.frame = CGRect(x: self.view.frame.size.width / 2 - 100, y: 320, width: 200, height: 30)
        self.view.addSubview(oslogButton)
        
        let imageView = UIImageView()
        self.imageView = imageView
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: self.view.frame.size.width / 2 - 50, y: 370, width: 100, height: 100)
        self.view.addSubview(imageView)
    }
    
    // MARK: - Public
    public static func registerCustomEntry() {
        FWDebugManager.sharedInstance().registerEntry("📱 Custom Entry") { vc in
            vc.dismiss(animated: true) {
                print("Custom Entry clicked")
            }
        }
        
        FWDebugManager.sharedInstance().registerObjectEntry("Custom Entry", title: "Custom") { object in
            return object is UIViewController
        } actionBlock: { vc, object in
            vc.dismiss(animated: true) {
                print("Custom Entry clicked")
            }
        }
        
        FWDebugManager.sharedInstance().registerInfoEntry("Custom Entry") {
            "Custom Value"
        }
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
            FWDebugManager.sharedInstance().systemLog("systemLog: Show FWDebug")
            FWDebugManager.sharedInstance().customLog("customLog: Show FWDebug")
        } else {
            FWDebugManager.sharedInstance().hide()
            FWDebugManager.sharedInstance().systemLog("systemLog: Hide FWDebug")
            FWDebugManager.sharedInstance().customLog("customLog: Hide FWDebug")
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
    
    func onChooseImage() {
        FWDebugManager.sharedInstance().chooseFile(Bundle.main.resourcePath ?? "") { filePath in
            return filePath.hasSuffix(".png")
        } completion: { [weak self] filePath in
            self?.imageView?.image = UIImage(contentsOfFile: filePath)
        }
    }
    
    func onRequestImage() {
        let urlRequest = URLRequest(url: URL(string: "http://kvm.wuyong.site/images/images/progressive.jpg")!)
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, _, _ in
            guard let data = data else { return }
            DispatchQueue.main.async { [weak self] in
                self?.imageView?.image = UIImage(data: data)
            }
        }
        dataTask.resume()
    }
    
    func onClose() {
        dismiss(animated: true)
    }
    
    func onCrash() {
        let object = NSObject()
        object.perform(#selector(onCrash))
    }
    
    func onNSLog() {
        NSLog("NSLog: onNSLog clicked")
    }
    
    func onOSLog() {
        os_log("OSLog: onOSLog clicked", log: .default, type: .error)
    }
}
