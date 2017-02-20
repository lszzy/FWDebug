# FWDebug

[![Pod Version](http://img.shields.io/cocoapods/v/FWDebug.svg?style=flat)](http://cocoadocs.org/docsets/FWDebug/)
[![Pod Platform](http://img.shields.io/cocoapods/p/FWDebug.svg?style=flat)](http://cocoadocs.org/docsets/FWDebug/)
[![Pod License](http://img.shields.io/cocoapods/l/FWDebug.svg?style=flat)](https://github.com/lszzy/FWDebug/blob/master/LICENSE)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/lszzy/FWDebug)

iOS调试库，方便iOS开发和测试。

## 使用教程
真机或模拟器中5秒内摇一摇两次即可出现调试菜单。

## 安装教程
推荐使用CocoaPods安装，自动管理依赖和环境配置。如需手工导入请参考Example项目配置。

### CocoaPods
本调试库支持Debug和Release环境，一般Debug模式开启。Podfile添加内容，如下：

	pod 'FWDebug', :configurations => ['Debug']
	pod 'FLEX', :configurations => ['Debug']

### Carthage
本调试库支持Carthage，Cartfile添加内容，如下：

	github "Flipboard/FLEX"
	github "lszzy/FWDebug"

执行`carthage update`并拷贝`FWDebug.framework`和`FLEX.framework`到项目即可。

## 官方网站
[大勇的网站](http://www.ocphp.com)
