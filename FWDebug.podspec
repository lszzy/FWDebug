Pod::Spec.new do |s|
  s.name                = "FWDebug"
  s.version             = "1.10.0"
  s.summary             = "ios debug library"
  s.homepage            = "http://wuyong.site"
  s.license             = "MIT"
  s.author              = { "Wu Yong" => "admin@wuyong.site" }
  s.source              = { :git => "https://github.com/lszzy/FWDebug.git", :tag => "#{s.version}" }
  
  s.platform            = :ios, "9.0"
  s.source_files        = 'FWDebug/Classes/**/*.{h,m,mm,c,cpp}'
  s.public_header_files = 'FWDebug/Classes/Public/*.h'
  s.frameworks          = 'Foundation', 'UIKit'
  s.library             = 'c++'
  s.resource            = 'FWDebug/Assets/FWDebug.bundle'
  
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
  s_arc_files           = Pathname.glob("FWDebug/Classes/**/*.{h,m,mm,c,cpp}")
  s_arc_files           = s_arc_files.map {|file| file.to_path}
  s_arc_files           = s_arc_files.reject {|file| s_mrr_files.include?(file)}
  s.requires_arc        = s_arc_files
  
  s.dependency 'FLEX'
  s.dependency 'GCDWebServer'
  s.dependency 'GCDWebServer/WebUploader'
  s.dependency 'GCDWebServer/WebDAV'
  s.dependency 'KSCrash'
  s.dependency 'NWPusher'
end
