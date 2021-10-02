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

  s.frameworks = ['Foundation']

  s.source_files = ["ios/**/*.{h,m,mm}", "cpp/**/*.{h,cpp,mm}"]

  # These will be packaged into the node module and, rather than the CocoaPod compiling them as sources, the
  # use_nativescript() command will do the rest.
  s.exclude_files = ["ios/NativeScript/*.{h,m,mm}", "ios/XCFrameworks.zip"]

  # As advised by: https://notificare.com/blog/2021/04/23/Publishing-XCFrameworks-via-CocoaPods/
  # However, if we do this, we get "[!] [Xcodeproj] Generated duplicate UUIDs:" 
  # s.vendored_frameworks = [
  #   "ios/NativeScript.xcframework",
  #   "ios/TNSWidgets.xcframework"
  # ]

  # @see https://github.com/mrousavy/react-native-vision-camera/blob/main/VisionCamera.podspec
  s.pod_target_xcconfig = {
    "DEFINES_MODULE" => "YES",
    "USE_HEADERMAP" => "YES",
    "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)/ReactCommon\" \"$(PODS_TARGET_SRCROOT)\" \"$(PODS_ROOT)/Headers/Private/React-Core\""
  }

  nativeScriptLdFlags = [
    ## These were linked in the NativeScript Capacitor example, but I think even the WebKit bit was purely added with Capacitor apps in mind.
    # "$(inherited)",
    # "-framework",
    # "Capacitor",
    # "-framework",
    # "Cordova",
    # "-framework",
    # "WebKit",
    # "$(inherited)",

    ## These are the NativeScript-specific flags.
    ## Fortunately, Ld is quite happy to accept the same flag multiple times.
    ## So even if React Native declares "-ObjC", "-lc++" (and more), it's no problem to re-specify it.
    ## This is good, because we identify whether NativeScript has set up in the Build Settings based on this set of flags being in this order.
    "-ObjC",
    "-sectcreate",
    "__DATA",
    "__TNSMetadata",
    "\"$(CONFIGURATION_BUILD_DIR)/metadata-$(CURRENT_ARCH).bin\"",
    "-framework",
    "NativeScript",
    ## TODO: make this path customisable based on where we installed nativeScriptIosInternalDirectoryDestPath to.
    ## We're a bit limited on options because we can't resolve Xcode variables like SRCROOT from the pod.
    ## I think ideally we'd derive it directly from node_modules (nativeScriptIosInternalDirectorySourcePath) to skip the copy step.
    ## But then maybe we'd be bundling more than necessary (the copy step deletes superfluous files from internal). I'm not sure!
    "-F\"$(SRCROOT)/internal\"",
    "-licucore",
    "-lz",
    "-lc++",
    "-framework",
    "Foundation",
    "-framework",
    "UIKit",
    "-framework",
    "CoreGraphics",
    "-framework",
    "MobileCoreServices",
    "-framework",
    "Security",
  ]

  s.user_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => ["$(inherited)", "\"$(SRCROOT)/NativeScript\""],
    'OTHER_LDFLAGS' => nativeScriptLdFlags,
    'LD' => "$SRCROOT/internal/nsld.sh",
    'LDPLUSPLUS' => "$SRCROOT/internal/nsld.sh",
    # By default, this is NO for debug and YES for release. This is one state change we won't be able to undo during uninstall.
    'ENABLE_BITCODE' => "NO",
    # By default, this is YES. This is one state change we won't be able to undo during uninstall.
    'CLANG_ENABLE_MODULES' => "NO"
  }

  s.requires_arc = true

  s.dependency "React-callinvoker"
  s.dependency "React"
  s.dependency "React-Core"

  # s.pod_target_xcconfig = {
  #   # 'HEADER_SEARCH_PATHS' => "$(inherited) \"$(SRCROOT)/NativeScript\""
  #   'HEADER_SEARCH_PATHS' => "\"$(SRCROOT)/NativeScript\""
  # }
end
