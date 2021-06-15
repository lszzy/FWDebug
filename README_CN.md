# FWDebug

[![Pod Version](https://img.shields.io/cocoapods/v/FWDebug.svg?style=flat)](http://cocoadocs.org/docsets/FWDebug/)
[![Pod Platform](https://img.shields.io/cocoapods/p/FWDebug.svg?style=flat)](http://cocoadocs.org/docsets/FWDebug/)
[![Pod License](https://img.shields.io/cocoapods/l/FWDebug.svg?style=flat)](https://github.com/lszzy/FWDebug/blob/master/LICENSE)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/lszzy/FWDebug)

# [English](README.md)

iOS调试库，支持iOS9+，无需添加任何代码，方便iOS开发和测试。

## 屏幕截图
![屏幕截图](FWDebug.gif)

## 使用教程
真机或模拟器中5秒内摇一摇两次即可出现调试菜单。功能如下：

* FLEX调试工具（摇一摇开启）
* 循环引用检测和分析（在对象查看页面点击搜索）
* Class和Protocol的头文件查看（在类查看页面点击"Runtime Headers"）
* FPS、内存、CPU占用率显示（摇一摇开启）
* 手机、App信息查看（"Device Info"入口）
* App崩溃日志的记录、查看（"Crash Log"入口）
* App文件管理器（"Browse Directory"入口）
* Documents文件http、webdav服务器（"Web Server"入口）
* 真机NSLog显示（"System Log"入口，"App Config"可配置过滤系统日志）
* 生成dylib动态库并注入其它App（"Dylib"目录，需手机越狱）
* App加密工具（"App Config"可配置开启）
* CLLocationManager虚拟定位（"Fake Location"入口）
* 模拟器虚拟远程推送发送和接收功能（"Fake Notification"入口）
* APNs远程推送发送功能（"Fake Notification"入口"APNS Client"配置）
* 启动时间、控制器加载和网络请求时间查看（"Time Profiler"入口或点击帧率图标快速查看当前控制器时间）
* WKWebView请求抓包功能（"App Config"打开开关后查看"Network History"即可）
* WKWebView自动注入vConsole功能（"App Config"打开开关后打开WKWebView即可）
* WebSite静态web服务器（"Web Server"入口，web文件放到Documents/website即可）

## 审核说明
针对大家关心的上架审核问题，特别说明一下：

**由于本调试库调用了私有Api，上架审核会不通过的，所以提交AppStore时请移除。**

只需在添加pod时设置`:configurations => ['Debug']`，只在Debug模式生效即可。

## 安装教程
推荐使用CocoaPods安装，自动管理依赖和环境配置。

### CocoaPods
本调试库支持Debug和Release环境，建议Debug模式开启。Podfile示例：

	platform :ios, '9.0'
	# use_frameworks!

	target 'Example' do
	  pod 'FWDebug', :configurations => ['Debug']
	end

## 更新日志
1.9.2版本：

	* 新增内建静态web服务器功能

1.9.1版本：

	* 重构项目架构，无修改方式引入三方库
	* 同步Vendor最新主干代码
	* 优化过滤系统NSLog日志功能

1.9.0版本：

	* 增加WKWebView请求抓包功能
	* WKWebView自动注入vConsole调试功能

1.8.5版本：

	* 更新FLEX为4.4.0版本

1.8.4版本：

	* 更新FLEX为4.2.2版本

1.8.3版本：

	* 新增5指两次点击切换调试器功能

1.8.2版本：

	* 兼容Xcode 12

1.8.1版本：

	* 优化时间查看功能，增加清除按钮

1.8.0版本：

	* 增加启动时间、控制器加载和网络请求时间查看功能
	* 增加长按调试按钮跳转URL功能
	* 优化内存判定方法

1.7.4版本：

	* 更新FLEX为4.1.1版本
	* 最低兼容iOS9
	* 兼容深色模式

1.7.3版本：

	* 同步Vendor最新主干代码

1.7.2版本：

	* 同步Vendor最新主干代码

1.7.1版本：

	* 同步Vendor最新主干代码
	* 增加过滤System Log的开关

1.7.0版本：

	* 同步FLEX 3等最新主干代码
	* 兼容Xcode 11

1.6.0版本：

	* 增加模拟器虚拟远程推送发送和接收功能
	* 增加APNs远程推送发送功能

1.5.3版本：

	* 同步Vendor最新主干代码

1.5.2版本：

	* 支持InjectionIII开发调试

1.5.1版本：

	* 同步Vendor最新主干代码
	* Example项目Swift 4兼容

1.5.0版本：

	* 增加CLLocationManager虚拟定位和移动功能

1.4.2版本：

	* 增加NSLog显示条数限制
	* Example项目Swift混编调试

1.4.1版本：

	* 优化循环引用检测功能

1.4.0版本：

	* 添加类和对象的循环引用检测功能
	* 添加当前ViewController的循环引用检测功能

1.3.1版本：

	* Example项目iPhoneX适配
	* 修复Documents文件http服务器

1.3.0版本：

	* 移除部分工具、保留核心功能
	* 重构、优化代码
	* 添加App加密工具

1.2.1版本：

	* 同步FLEX最新主干代码
	* 添加屏幕截图、更新说明

1.2.0版本：

	* 修复iOS10真机NSLog显示
	* 添加手机App列表查看
	* 添加JSPatch动态修改应用
	* 添加dylib项目和注入现有App工具

1.1.0版本：

	* 调整项目结构
	* 更新FLEX到2.4.0版本
	* 添加崩溃日志调试
	* 添加Documents文件http、webdav服务器
	* 添加头文件查看
	* 添加FPS显示
	* 添加App、设备信息

1.0.0版本：

	* 添加FLEX调试

## 第三方库
本调试库使用了第三方库，在此感谢所有第三方库的作者。列举如下：

* [FLEX](https://github.com/Flipboard/FLEX)
* [GCDWebServer](https://github.com/swisspol/GCDWebServer)
* [RuntimeBrowser](https://github.com/nst/RuntimeBrowser)
* [KSCrash](https://github.com/kstenerud/KSCrash)
* [FBRetainCycleDetector](https://github.com/facebook/FBRetainCycleDetector)
* [NWPusher](https://github.com/noodlewerk/NWPusher)

## 官方网站
[大勇的网站](http://www.wuyong.site)
