Pod::Spec.new do |s|
  s.name         = "KYDrawerController-ObjC"
  s.version      = "1.1.4"
  s.summary      = "KYDrawerController is a side drawer navigation container view controller, rewritten Swift version in Objective-C"
  s.homepage     = "https://github.com/AustinChou/KYDrawerController-ObjC"
  s.license      = "MIT"
  s.author       = { "Austin Chou" => "austinchou0126@gmail.com" }
  s.social_media_url   = "https://twitter.com/austinchou0126"
  s.platform     = :ios
  s.source       = { :git => "https://github.com/AustinChou/KYDrawerController-ObjC.git", :tag => s.version.to_s }
  s.source_files = "KYDrawerController/Classes/*.{h,m}"
  s.public_header_files = "KYDrawerController/Classes/*.h"
  s.requires_arc = true
  s.ios.deployment_target = '8.0'
end
