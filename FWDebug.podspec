Pod::Spec.new do |spec|
  spec.name                = "FWDebug"
  spec.version             = "1.4.2"
  spec.summary             = "ios debug library"
  spec.homepage            = "http://wuyong.site"
  spec.license             = "MIT"
  spec.author              = { "Wu Yong" => "admin@wuyong.site" }
  spec.platform            = :ios, "8.0"
  spec.source              = { :git => "https://github.com/lszzy/FWDebug.git", :tag => "#{spec.version}" }

  spec_mrr_files           = [
    'FWDebug/Vendor/FBRetainCycleDetector/Associations/FBAssociationManager.h',
    'FWDebug/Vendor/FBRetainCycleDetector/Associations/FBAssociationManager.mm',
    'FWDebug/Vendor/FBRetainCycleDetector/Layout/Blocks/FBBlockStrongLayout.h',
    'FWDebug/Vendor/FBRetainCycleDetector/Layout/Blocks/FBBlockStrongLayout.m',
    'FWDebug/Vendor/FBRetainCycleDetector/Layout/Blocks/FBBlockStrongRelationDetector.h',
    'FWDebug/Vendor/FBRetainCycleDetector/Layout/Blocks/FBBlockStrongRelationDetector.m',
    'FWDebug/Vendor/FBRetainCycleDetector/Layout/Classes/FBClassStrongLayoutHelpers.h',
    'FWDebug/Vendor/FBRetainCycleDetector/Layout/Classes/FBClassStrongLayoutHelpers.m',
  ]
  spec_arc_files           = Pathname.glob("FWDebug/**/*.{h,m,mm,c,cpp}")
  spec_arc_files           = spec_arc_files.map {|file| file.to_path}
  spec_arc_files           = spec_arc_files.reject {|file| spec_mrr_files.include?(file)}
  spec.requires_arc        = spec_arc_files

  spec.source_files        = 'FWDebug/**/*.{h,m,mm,c,cpp}'
  spec.public_header_files = 'FWDebug/*.h'
  spec.frameworks          = [ "Foundation", "UIKit" ]
  spec.library             = [ "xml2", "z", "sqlite3", "c++" ]
  spec.xcconfig            = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2", "GCC_ENABLE_CPP_EXCEPTIONS" => "YES" }
end
