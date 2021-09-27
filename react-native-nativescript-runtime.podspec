require "json"
# require "xcodeproj"
# path_to_project = "${SOURCE_ROOT}/${PROJECT_NAME}.xcodeproj"
# project = Xcodeproj::Project.open(path_to_project)
# loggingPrefix = "[react-native-nativescript-runtime]"
# puts "#{loggingPrefix} path_to_project: #{path_to_project}"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-nativescript-runtime"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "10.0" }
  s.source       = { :git => "https://github.com/shirakaba/react-native-nativescript-runtime.git", :tag => "#{s.version}" }

  s.source_files = ["ios/**/*.{h,m,mm}", "cpp/**/*.{h,cpp}"]

  # These will be packaged into the node module and, rather than the CocoaPod compiling them as sources, the
  # use_nativescript() command will do the rest.
  s.exclude_files = ["ios/NativeScript/*.{h,m,mm}", "ios/XCFrameworks.zip"]

  # As advised by: https://notificare.com/blog/2021/04/23/Publishing-XCFrameworks-via-CocoaPods/
  # However, if we do this, we get "[!] [Xcodeproj] Generated duplicate UUIDs:" 
  # s.vendored_frameworks = [
  #   "ios/NativeScript.xcframework",
  #   "ios/TNSWidgets.xcframework"
  # ]

  s.dependency "React-Core"

  # s.pod_target_xcconfig = {
  #   # 'HEADER_SEARCH_PATHS' => "$(inherited) \"$(SRCROOT)/NativeScript\""
  #   'HEADER_SEARCH_PATHS' => "\"$(SRCROOT)/NativeScript\""
  # }
end
