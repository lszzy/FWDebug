# FWDebug

[![Pod Version](https://img.shields.io/cocoapods/v/FWDebug.svg?style=flat)](http://cocoadocs.org/docsets/FWDebug/)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Flszzy%2FFWDebug%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/lszzy/FWDebug)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Flszzy%2FFWDebug%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/lszzy/FWDebug)
[![Pod License](https://img.shields.io/cocoapods/l/FWDebug.svg?style=flat)](https://github.com/lszzy/FWDebug/blob/master/LICENSE)

# [中文](README_CN.md)

iOS debugging library, support for iOS11 +, without adding any code to facilitate iOS development and testing.

## Screenshot

### Mobile
![Mobile](FWDebug.gif)

### Browser
![Browser](FWDebug_Server.gif)

## Tutorial
Real machine or simulator shaking within 5 seconds twice to appear debug menu. Functions are as follows:

* FLEX debugging tool (shaking to open)
* PC Web debugging server, you can view mobile phone network requests, NSLog, open URL, Generate QR code, real-time screenshots, etc. ("Web Server" entrance)
* Check Swift object capabilities ("App Config" is enabled by default)
* Measure view distance (switch toolbar to "ruler" mode)
* Circular reference detection and analysis (click to search on the object view page)
* View the header files of Class and Protocol (click "Runtime Headers" on the class view page)
* FPS, memory, CPU occupancy rate display (shaking to open)
* Mobile phone, App information view, simulation function ("Device Info" entrance)
* App crash log recording and viewing ("Crash Log" entrance)
* App crash log is reported to mailbox and server (code configuration crashReporter)
* Recording and viewing of file logs ("Custom Log" entrance)
* App file manager ("Browse Directory" entrance)
* Documents file http, webdav server ("Web Server" entrance)
* Real machine NSLog display ("System Log" entrance, "App Config" can be configured to filter system logs)
* Generate dylib dynamic library and inject other App ("Dylib" directory, mobile phone jailbreak required)
* App encryption tool ("App Config" can be configured to open)
* CLLocationManager virtual location ("Fake Location" entrance)
* Simulator virtual remote push sending and receiving function ("Fake Notification" entrance)
* APNs remote push sending function ("Fake Notification" entrance "APNS Client" configuration)
* View the startup time, controller loading and network request time ("Time Profiler" entry or click the frame rate icon to quickly view the current controller time)
* WKWebView request packet capture function (just check "Network History" after turning on the "App Config" switch)
* WKWebView automatically injects the vConsole function (just turn on WKWebView after turning on the "App Config" switch)
* WebSite static web server ("Web Server" entrance, the web file can be placed in Documents/website)
* WKWebView cleanup cache ("App Config" entry)

## Review
For everyone concerned about the issue of shelf audit, in particular, explain:

**Since this debug library calls the private APIs, the on-board review will not pass, so please remove it when submitting to AppStore.**

The CocoaPods project only needs to set `:configurations => ['Debug']` when adding a pod, which will only take effect in Debug mode.

The Swift Package Manager project can remove FWDebug from the Target when packaging the AppStore.

## Installation tutorial
It is recommended to use CocoaPods or Swift Package Manager to install and automatically manage dependencies and environment configuration.

### CocoaPods
This debugging library supports Debug and Release environments. It is recommended that Debug mode be turned on. Podfile example:

    platform:ios, '11.0'
    use_frameworks!

    target 'Example' do
    pod 'FWDebug', :configurations => ['Debug']
    end

### Swift Package Manager
This debugging library supports Swift Package Manager. Please note that when packaging AppStore, please remove FWDebug from the Target. Package example:

     https://github.com/lszzy/FWDebug.git
    
     import FWDebug
## [Changelog](https://github.com/lszzy/FWDebug/blob/master/CHANGELOG.md)

## Vendor
This debug library uses a third-party library, thanks to all third-party library authors. Listed below:
	
* [FLEX](https://github.com/Flipboard/FLEX)
* [GCDWebServer](https://github.com/swisspol/GCDWebServer)
* [RuntimeBrowser](https://github.com/nst/RuntimeBrowser)
* [KSCrash](https://github.com/kstenerud/KSCrash)
* [FBRetainCycleDetector](https://github.com/facebook/FBRetainCycleDetector)
* [NWPusher](https://github.com/noodlewerk/NWPusher)
* [swift-atomics](https://github.com/apple/swift-atomics)
* [Echo](https://github.com/Azoy/Echo)
* [Reflex](https://github.com/FLEXTool/Reflex)

## Support
[wuyong.site](http://www.wuyong.site)
