Pod::Spec.new do |s|
  s.name                = "FWDebug"
  s.version             = "6.0.2"
  s.summary             = "ios debug library"
  s.homepage            = "http://wuyong.site"
  s.license             = "MIT"
  s.author              = { "Wu Yong" => "admin@wuyong.site" }
  s.source              = { :git => "https://github.com/lszzy/FWDebug.git", :tag => "#{s.version}" }
  
  s_mrr_files           = [
    'FWDebug/Classes/Vendor/FBRetainCycleDetector/Associations/FBAssociationManager.h',
    'FWDebug/Classes/Vendor/FBRetainCycleDetector/Associations/FBAssociationManager.mm',
    'FWDebug/Classes/Vendor/FBRetainCycleDetector/Layout/Blocks/FBBlockStrongLayout.h',
    'FWDebug/Classes/Vendor/FBRetainCycleDetector/Layout/Blocks/FBBlockStrongLayout.m',
    'FWDebug/Classes/Vendor/FBRetainCycleDetector/Layout/Blocks/FBBlockStrongRelationDetector.h',
    'FWDebug/Classes/Vendor/FBRetainCycleDetector/Layout/Blocks/FBBlockStrongRelationDetector.m',
    'FWDebug/Classes/Vendor/FBRetainCycleDetector/Layout/Classes/FBClassStrongLayoutHelpers.h',
    'FWDebug/Classes/Vendor/FBRetainCycleDetector/Layout/Classes/FBClassStrongLayoutHelpers.m',
  ]
  s_arc_files           = Pathname.glob("FWDebug/Classes/**/*.{h,m,mm,c,cpp,def,swift}")
  s_arc_files           = s_arc_files.map {|file| file.to_path}
  s_arc_files           = s_arc_files.reject {|file| s_mrr_files.include?(file)}
  s.requires_arc        = s_arc_files
  
  s.platform            = :ios, "11.0"
  s.swift_version       = '5'
  s.source_files        = 'FWDebug/Classes/**/*.{h,m,mm,c,cpp,def,swift}'
  s.public_header_files = [
    'FWDebug/Classes/Public/*.h',
    'FWDebug/Classes/Vendor/swift-atomics/_AtomicsShims/_AtomicsShims.h',
    'FWDebug/Classes/Vendor/Echo/CEcho/*.h',
    'FWDebug/Classes/Vendor/FLEX/Core/FLEXTableViewSection.h',
    'FWDebug/Classes/Vendor/FLEX/Utility/Runtime/Objc/*.h',
    'FWDebug/Classes/Vendor/FLEX/Utility/Runtime/Objc/Reflection/*.h',
    'FWDebug/Classes/Vendor/FLEX/Utility/Categories/NSArray+FLEX.h',
    'FWDebug/Classes/Vendor/FLEX/Utility/Categories/FLEXRuntime+UIKitHelpers.h',
  ]
  s.resource            = 'FWDebug/Assets/GCDWebUploader.bundle'
  s.frameworks          = [ "Foundation", "UIKit" ]
  s.library             = [ "xml2", "z", "sqlite3", "c++" ]
  s.compiler_flags      = [ "-Wno-unsupported-availability-guard", "-Wno-deprecated-declarations" ]
  s.xcconfig            = {
    "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2",
    "GCC_ENABLE_CPP_EXCEPTIONS" => "YES",
    "CLANG_CXX_LANGUAGE_STANDARD" => "gnu++11",
  }
end
