Pod::Spec.new do |spec|
  spec.name         = "FWDebug"
  spec.version      = "1.0.0"
  spec.summary      = "ios debug library"
  spec.homepage     = "http://ocphp.com"
  spec.license      = "MIT"
  spec.author       = { "Wu Yong" => "admin@ocphp.com" }

  spec.platform     = :ios, "7.0"
  spec.source       = { :git => "https://github.com/lszzy/ios-debug.git", :tag => spec.version.to_s }
  spec.source_files = 'FWDebug/**/*.{h,m}'
  spec.requires_arc = true
end
