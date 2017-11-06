Pod::Spec.new do |spec|
  spec.name         = "FWDebug"
  spec.version      = "1.3.1"
  spec.summary      = "ios debug library"
  spec.homepage     = "http://ocphp.com"
  spec.license      = "MIT"
  spec.author       = { "Wu Yong" => "admin@ocphp.com" }
  spec.source       = { :git => "https://github.com/lszzy/FWDebug.git", :tag => "#{spec.version}" }

  spec.platform            = :ios, "8.0"
  spec.requires_arc        = true
  spec.frameworks          = [ "Foundation", "UIKit" ]
  spec.library             = [ "xml2", "z", "sqlite3", "c++" ]
  spec.xcconfig            = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2", "GCC_ENABLE_CPP_EXCEPTIONS" => "YES" }
  spec.source_files        = 'FWDebug/**/*.{h,m,mm,c,cpp}'
  spec.public_header_files = 'FWDebug/*.h'
end
