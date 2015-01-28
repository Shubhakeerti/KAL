#
#  Be sure to run `pod spec lint KAL.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "KAL"
  s.version      = "0.0.1"
  s.summary      = "A short description of KAL."

  s.homepage     = "http://github/Shubhakeerti/KAL"
  s.license      = { :type => "New BDS License", :file => "LICENSE" }
  s.author             = { "Shubhakeerti" => "shubhakeerti.alagundagi@gmail.com" }
  s.platform     = :ios, "5.0"
  s.source       = { :git => "http://github/Shubhakeerti/KAL.git", :tag => "0.0.1" }
  s.source_files = "*.{h,m}"
  s.requires_arc = true
end
