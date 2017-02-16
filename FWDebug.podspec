Pod::Spec.new do |s|
  s.name         = "FWDebug"
  s.version      = "1.0.0"
  s.summary      = "ocphp ios-debug"
  s.homepage     = "http://ocphp.com"
  s.license      = "MIT"
  s.author       = { "Wu Yong" => "admin@ocphp.com" }
  s.source       = { :git => "https://github.com/lszzy/ios-debug.git", :tag => s.version.to_s }

  s.requires_arc = true
  s.platform     = :ios, "7.0"
  s.source_files = 'FWDebug/**/*.{h,m}'

  s.dependency 'FLEX'
end
