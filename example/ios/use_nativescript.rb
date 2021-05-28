require "xcodeproj"
require "FileUtils"
require "open3"

# @param [Object] options
# @param [String] options.nativeScriptIosPath - The path to the "@nativescript/ios" node module, relative to your app's
#                 Podfile.
#                 Defaults to: "../node_modules/@nativescript/ios".
# @param [String] options.nativeScriptRuntimeNodeModulePath - The path to the "react-native-nativescript-runtime" node
#                 module, relative to your app's Podfile.
#                 Defaults to: "../node_modules/react-native-nativescript-runtime".
# @param [Boolean] options.includeTKLiveSync - Whether to include TKLiveSync.
#                 This script can copy over the files and whatnot, but we don't support NativeScript LiveSync yet in
#                 React Native, so there's not much point to set this to true just yet.
#                 Defaults to: false
# @param [Boolean] options.doPostbuild - Whether to integrate and run the NativeScript postbuild script.
#                 NativeScript Capacitor doesn't seem to run it, so we'll default to not doing it for now.
#                 Defaults to: false
# @param [String] options.path_to_project The path to your Xcode project. Required.
# @param [String] options.projectTargetName The name of your Xcode project's build target. Required.
def use_nativescript(options={})
  loggingPrefix = "[use_nativescript]"
  scriptDirPath = File.expand_path(File.dirname(__FILE__))
  includeTKLiveSync = options[:includeTKLiveSync] ||= false
  doPostbuild = options[:doPostbuild] ||= false

  if(options[:path_to_project].nil?)
    puts "#{loggingPrefix} ❌ Please provide a value for the param \"path_to_project\"."
    exit(1)
  end

  if(options[:projectTargetName].nil?)
    puts "#{loggingPrefix} ❌ Please provide a value for the param \"projectTargetName\"."
    exit(1)
  end

  project = Xcodeproj::Project.open(options[:path_to_project])

  # The path to the @nativescript/ios node module
  nativeScriptIosPath = File.expand_path(options[:nativeScriptIosPath] ||= "../node_modules/@nativescript/ios")
  nativeScriptRuntimeNodeModulePath = File.expand_path(options[:nativeScriptRuntimeNodeModulePath] ||= "../node_modules/react-native-nativescript-runtime")
  
  # This originally came from @nativescript/capacitor, and was simply copied into react-native-nativescript-runtime.
  nativeScriptIosRuntimeMetaDirectorySourcePath = File.join(nativeScriptRuntimeNodeModulePath, "ios", "NativeScript")
  nativeScriptIosRuntimeMetaDirectoryDestParentPath = scriptDirPath
  nativeScriptIosRuntimeMetaDirectoryDestPath = File.join(scriptDirPath, "NativeScript")

  # This is built from @nativescript/ui-mobile-base, but the package isn't published, so we vend it with
  # react-native-nativescript-runtime ourselves.
  tnsWidgetsSourcePath = File.join(nativeScriptRuntimeNodeModulePath, "ios", "TNSWidgets.xcframework")
  tnsWidgetsXcframeworkDestParentPath = scriptDirPath
  tnsWidgetsXcframeworkDestPath = File.join(scriptDirPath, "TNSWidgets.xcframework")
  
  nativeScriptIosInternalDirectorySourcePath = File.join(nativeScriptIosPath, "framework", "internal")
  nativeScriptIosInternalDirectoryDestPath = File.join(scriptDirPath, "internal")
  nativeScriptIosInternalDirectoryDestXcframeworksZipPath = File.join(nativeScriptIosInternalDirectoryDestPath, "XCFrameworks.zip")

  nativeScriptIosFrameworksSourcePath = File.join(nativeScriptIosPath, "framework", "internal", "XCFrameworks.zip")
  nativeScriptIosFrameworksExtractedDestPath = scriptDirPath
  nativeScriptXcframeworkDestPath = File.join(scriptDirPath, "NativeScript.xcframework")

  tKLiveSyncXcframeworkDestPath = File.join(scriptDirPath, "TKLiveSync.xcframework")

  if File.directory?(nativeScriptIosInternalDirectoryDestPath) then
    puts "#{loggingPrefix} ✅ Found the NativeScript iOS \"internal\" folder at \"#{nativeScriptIosInternalDirectoryDestPath}\", so will skip copying it."
  else
    puts "#{loggingPrefix} ℹ️  The NativeScript iOS \"internal\" folder was missing from \"#{nativeScriptIosInternalDirectoryDestPath}\", so will try copying it from \"#{nativeScriptIosInternalDirectorySourcePath}\"."

    if !File.directory?(nativeScriptIosInternalDirectorySourcePath) then
      puts "#{loggingPrefix} ❌ Unable to copy the NativeScript iOS \"internal\" folder, as it was missing from \"#{nativeScriptIosInternalDirectorySourcePath}\". Please run `npm install --save @nativescript/ios` again and then try repeating `pod install`. Also, if not using the default options, ensure that the correct nativeScriptIosPath option is passed into use_nativescript!() in your app's Podfile."
      exit(1)
    end

    # No idea how to catch any errors on this!
    # See: https://stackoverflow.com/questions/9052363/how-to-catch-errors-when-copying-files-in-ruby
    FileUtils.cp_r(nativeScriptIosInternalDirectorySourcePath, nativeScriptIosInternalDirectoryDestPath)
    
    puts "#{loggingPrefix} ✅ Successfully copied the NativeScript iOS \"internal\" folder to \"#{nativeScriptIosInternalDirectoryDestPath}\"."

    if File.file?(nativeScriptIosInternalDirectoryDestXcframeworksZipPath) then
      puts "#{loggingPrefix} ℹ️  Will remove the superfluous XCFrameworks.zip file from our copy of the NativeScript iOS \"internal\" folder to save space."

      FileUtils.rm(nativeScriptIosInternalDirectoryDestXcframeworksZipPath)

      puts "#{loggingPrefix} ✅ Successfully removed the superfluous XCFrameworks.zip file from our copy of the NativeScript iOS \"internal\" folder."
    else
      puts "#{loggingPrefix} ✅ No superfluous XCFrameworks.zip file to remove from our copy of the NativeScript iOS \"internal\" folder, so skipping that step."
    end
  end

  if File.directory?(nativeScriptXcframeworkDestPath) && (includeTKLiveSync ? File.directory?(tKLiveSyncXcframeworkDestPath) : true) then
    puts "#{loggingPrefix} ✅ Found both NativeScript.xcframework and TKLiveSync.xcframework in \"#{nativeScriptIosFrameworksExtractedDestPath}\", so will skip unzipping of \"#{nativeScriptIosFrameworksSourcePath}\"."
  else
    puts "#{loggingPrefix} ℹ️  Missing NativeScript iOS xcframeworks, so will unzip them from \"#{nativeScriptIosFrameworksSourcePath}\" into \"#{nativeScriptIosFrameworksExtractedDestPath}\" ..."

    if !File.file?(nativeScriptIosFrameworksSourcePath) then
      puts "#{loggingPrefix} ❌ NativeScript.xcframework and TKLiveSync.xcframework were both missing at \"#{nativeScriptIosFrameworksExtractedDestPath}\", so need to unzip \"#{nativeScriptIosFrameworksSourcePath}\"; however, that zip file is missing. Please run `npm install --save @nativescript/ios` again and then try repeating `pod install`. Also, if not using the default options, ensure that the correct nativescriptIosPath option is passed into use_nativescript!() in your app's Podfile."
      exit(1)
    end
  
    Open3.popen3("unzip", "-o", nativeScriptIosFrameworksSourcePath, "-d", nativeScriptIosFrameworksExtractedDestPath) { |stdin, stdout, stderr, wait_thr|
      return_value = wait_thr.value
  
      if wait_thr.value.success?
        puts "#{loggingPrefix} ✅ Unzipping NativeScript iOS frameworks was successful!"
      else
        puts "#{loggingPrefix} ❌ Unzipping NativeScript iOS frameworks failed!"
        puts stderr.read
        exit 1
      end
    }

    if(!includeTKLiveSync && File.directory?(tKLiveSyncXcframeworkDestPath)) then
      FileUtils.rm(tKLiveSyncXcframeworkDestPath)
      # We won't be supporting LiveSync for the initial proof of concept, so no need to clutter up their project with it.
      puts "#{loggingPrefix} ✅ Removed TKLiveSync.xcframework from unzipped contents."
    end
  end

  puts "#{loggingPrefix} ℹ️  Will now start preparing the Xcode project..."

  if File.directory?(nativeScriptIosRuntimeMetaDirectoryDestPath) then
    puts "#{loggingPrefix} ✅ Found the NativeScript iOS meta folder (named \"NativeScript\") at \"#{nativeScriptIosRuntimeMetaDirectoryDestPath}\", so will skip copying it."
  else
    puts "#{loggingPrefix} ℹ️  Missing the NativeScript iOS meta folder (named \"NativeScript\") at \"#{nativeScriptIosRuntimeMetaDirectoryDestPath}\", so will copy it from \"#{nativeScriptIosRuntimeMetaDirectorySourcePath}\"."
    FileUtils.cp_r(nativeScriptIosRuntimeMetaDirectorySourcePath, nativeScriptIosRuntimeMetaDirectoryDestParentPath)
    puts "#{loggingPrefix} ✅ Successfully copied the NativeScript iOS meta folder to \"#{nativeScriptIosRuntimeMetaDirectorySourcePath}\"."
  end

  if File.directory?(tnsWidgetsXcframeworkDestPath) then
    puts "#{loggingPrefix} ✅ Found TNSWidgets.xcframework at \"#{tnsWidgetsXcframeworkDestPath}\", so will skip copying it."
  else
    puts "#{loggingPrefix} ℹ️  Missing TNSWidgets.xcframework at \"#{tnsWidgetsXcframeworkDestPath}\", so will copy it from \"#{tnsWidgetsSourcePath}\"."
    FileUtils.cp_r(tnsWidgetsSourcePath, tnsWidgetsXcframeworkDestParentPath)
    puts "#{loggingPrefix} ✅ Successfully copied TNSWidgets.xcframework to \"#{tnsWidgetsSourcePath}\"."
  end

  projectTarget = project.targets.find { |target| target.name == options[:projectTargetName] }
  # puts "build_phases: #{projectTarget.build_phases}"
  # puts "shell_script_build_phases: #{projectTarget.shell_script_build_phases}"

  # Prebuild
  prebuildPhaseName = "NativeScript prebuild"
  prebuildPhase = projectTarget.shell_script_build_phases.find { |phase| phase.name == prebuildPhaseName }
  if(prebuildPhase.nil?)
    prebuildPhase = projectTarget.new_shell_script_build_phase(prebuildPhaseName)
  end
  prebuildPhase.shell_script = "\"${SRCROOT}/internal/nativescript-pre-build\""

  # Prelink
  prelinkPhaseName = "NativeScript prelink"
  prelinkPhase = projectTarget.shell_script_build_phases.find { |phase| phase.name == prelinkPhaseName }
  if(prelinkPhase.nil?)
    prelinkPhase = projectTarget.new_shell_script_build_phase(prelinkPhaseName)
  end
  prelinkPhase.shell_script = "\"${SRCROOT}/internal/nativescript-pre-link\""

  if(doPostbuild) then
    # Postbuild. For some reason Capacitor doesn't include this.
    postbuildPhaseName = "NativeScript postbuild"
    postbuildPhase = projectTarget.shell_script_build_phases.find { |phase| phase.name == postbuildPhaseName }
    if(postbuildPhase.nil?)
      postbuildPhase = projectTarget.new_shell_script_build_phase(postbuildPhaseName)
    end
    postbuildPhase.shell_script = "\"${SRCROOT}/internal/nativescript-post-build\""
  end

  # The new_shell_script_build_phase helper unfortunately shoves the build phase on the end of the array.
  # So we do this extra array-manipulation step to sort them into their rightful positions.

  # puts "Xcodeproj::Project::Object::PBXSourcesBuildPhase: #{Xcodeproj::Project::Object::PBXSourcesBuildPhase}"

  # "Compile Sources" phase (there are strictly 0-1 of these)
  compileSourcesPhaseIndex = projectTarget.build_phases.index { |phase| phase.instance_of? Xcodeproj::Project::Object::PBXSourcesBuildPhase }
  if(compileSourcesPhaseIndex.nil?)
    puts "#{loggingPrefix} ⚠️ Attempting to sort NativeScript prebuild phase, but there is no \"Compile Sources\" phase to place it before. Will instead place it as the first build step."
    compileSourcesPhaseIndex = 0
  end

  if(doPostbuild) then
    # Place the postbuild 
    postbuildPhaseIndex = projectTarget.build_phases.index { |phase| defined?(phase.name) && phase.name == postbuildPhaseName }
    projectTarget.build_phases.insert(
      projectTarget.build_phases.length == 0 ? 0 : (compileSourcesPhaseIndex + 1),
      projectTarget.build_phases.delete_at(postbuildPhaseIndex)
    )
  end

  prebuildPhaseIndex = projectTarget.build_phases.index { |phase| defined?(phase.name) && phase.name == prebuildPhaseName }
  projectTarget.build_phases.insert(
    compileSourcesPhaseIndex,
    projectTarget.build_phases.delete_at(prebuildPhaseIndex)
  )

  # "Link Binary With Libraries" phase (there are strictly 0-1 of these)
  linkingPhaseIndex = projectTarget.build_phases.index { |phase| phase.instance_of? Xcodeproj::Project::Object::PBXFrameworksBuildPhase }
  if(linkingPhaseIndex.nil?)
    puts "#{loggingPrefix} ⚠️ Attempting to sort NativeScript prelink phase but there is no \"Link Binary with Libraries\" phase to place it before. Will instead place it immediately after the postbuild step."
    postbuildPhaseIndex = projectTarget.build_phases.index { |phase| defined?(phase.name) && phase.name == postbuildPhaseName }
    linkingPhaseIndex = postbuildPhaseIndex
  end

  prelinkPhaseIndex = projectTarget.build_phases.index { |phase| defined?(phase.name) && phase.name == prelinkPhaseName }
  projectTarget.build_phases.insert(
    linkingPhaseIndex,
    projectTarget.build_phases.delete_at(prelinkPhaseIndex)
  )

  linkingPhase = projectTarget.build_phases.find { |phase| phase.instance_of? Xcodeproj::Project::Object::PBXFrameworksBuildPhase }
  if(linkingPhaseIndex.nil?)
    puts "#{loggingPrefix} ❌ Unable to link NativeScript frameworks as there is no linking phase set up yet. Please add it into your Xcode project's build phases via the option \"New Link Binary With Libraries phase\", then try repeating `pod install`."
    exit(1)
  end

  # frameworks_group returns the group, creating it if necessary.

  extractedNativeScriptXcframeworkFileRef = project.frameworks_group.files.find { |ref| ref.path.end_with? "NativeScript.xcframework" }
  if(extractedNativeScriptXcframeworkFileRef.nil?)
    extractedNativeScriptXcframeworkFileRef = project.frameworks_group.new_file(nativeScriptXcframeworkDestPath);
    linkingPhase.add_file_reference(extractedNativeScriptXcframeworkFileRef)
    puts "#{loggingPrefix} ✅ Added file reference to NativeScript.xcframework."
  else
    # I was thinking of attempt to update the path, but it seems to result in an uglier file path than the new_file() API gives you.
    # extractedNativeScriptXcframeworkFileRef.path = nativeScriptXcframeworkDestPath
  end
  extractedNativeScriptXcframeworkFileRef.build_files.each { |build_file| build_file.settings = { "ATTRIBUTES" => ["CodeSignOnCopy"] } }

  if(includeTKLiveSync) then
    tKLiveSyncXcframeworkFileRef = project.frameworks_group.files.find { |ref| ref.path.end_with? "TKLiveSync.xcframework" }
    if(tKLiveSyncXcframeworkFileRef.nil?)
      tKLiveSyncXcframeworkFileRef = project.frameworks_group.new_file(tKLiveSyncXcframeworkDestPath);
      linkingPhase.add_file_reference(tKLiveSyncXcframeworkFileRef)
      puts "#{loggingPrefix} ✅ Added file reference to TKLiveSync.xcframework."
    else
      # I was thinking of attempt to update the path, but it seems to result in an uglier file path than the new_file() API gives you.
      # tKLiveSyncXcframeworkFileRef.path = tKLiveSyncXcframeworkDestPath
    end
    tKLiveSyncXcframeworkFileRef.build_files.each { |build_file| build_file.settings = { "ATTRIBUTES" => ["CodeSignOnCopy"] } }
  end

  tnsWidgetsXcframeworkFileRef = project.frameworks_group.files.find { |ref| ref.path.end_with? "TNSWidgets.xcframework" }
  if(tnsWidgetsXcframeworkFileRef.nil?)
    tnsWidgetsXcframeworkFileRef = project.frameworks_group.new_file(tnsWidgetsXcframeworkDestPath);
    linkingPhase.add_file_reference(tnsWidgetsXcframeworkFileRef)
    puts "#{loggingPrefix} ✅ Added file reference to TNSWidgets.xcframework."
  else
    # I was thinking of attempt to update the path, but it seems to result in an uglier file path than the new_file() API gives you.
    # tnsWidgetsXcframeworkFileRef.path = tnsWidgetsXcframeworkDestPath
  end
  tnsWidgetsXcframeworkFileRef.build_files.each { |build_file| build_file.settings = { "ATTRIBUTES" => ["CodeSignOnCopy"] } }

  # embedPhase = projectTarget.build_phases.find { |phase| phase.instance_of? Xcodeproj::Project::Object::PBXCopyFilesBuildPhase }
  embedPhase = projectTarget.build_phases.find { |phase| defined?(phase.name) && phase.name == "NativeScript Embed Frameworks" }
  if(embedPhase.nil?)
    embedPhase = projectTarget.new_copy_files_build_phase("NativeScript Embed Frameworks")
    
    embedPhase.dst_path = ""
    embedPhase.dst_subfolder_spec = Xcodeproj::Constants::COPY_FILES_BUILD_PHASE_DESTINATIONS[:frameworks]

    if !embedPhase.files.any? { |ref| ref.file_ref.path.end_with? "NativeScript.xcframework" }
      embedPhase.add_file_reference(extractedNativeScriptXcframeworkFileRef)
    end

    if !embedPhase.files.any? { |ref| ref.file_ref.path.end_with? "TNSWidgets.xcframework" }
      embedPhase.add_file_reference(tnsWidgetsXcframeworkFileRef)
    end

    puts "#{loggingPrefix} ✅ Added \"NativeScript Embed Frameworks\" build phase."
  end

  nativeScriptMetaGroup = project.groups.find { |ref| defined?(ref.name) && ref.name == "NativeScriptMeta" }
  if(nativeScriptMetaGroup.nil?)
    nativeScriptMetaGroup = project.new_group("NativeScriptMeta", nativeScriptIosRuntimeMetaDirectoryDestPath);

    Dir.entries(nativeScriptIosRuntimeMetaDirectoryDestPath).select { |entry| !entry.start_with? "." }.each { |entry| nativeScriptMetaGroup.new_file(entry) }
    puts "#{loggingPrefix} ✅ Added file reference to NativeScript meta directory."
  else
    # I was thinking of attempt to update the path, but it seems to result in an uglier file path than the new_group() API gives you.
    # nativeScriptMetaGroup.path = nativeScriptIosRuntimeMetaDirectoryDestPath
  end

  projectTarget.build_configurations.each { |config|
    puts "#{loggingPrefix} ℹ️  Inspecting BUILD_SETTINGS for projectTarget => #{projectTarget.name} & CONFIGURATION => #{config.name}"
    
    puts "#{loggingPrefix} ℹ️  Existing config.build_settings: #{config.build_settings}"

    # Editing this Hash was quite problematic. Its keys seem to be mixture of symbols and strings or something; a lot of approaches weren't working.

    # config.build_settings = {
    #   **config.build_settings,
    #   :HEADER_SEARCH_PATHS => "$(inherited) \"$(SRCROOT)/NativeScript\""
    # }

    # new_build_settings = Hash.new().merge(config.build_settings)
    # new_build_settings["HEADER_SEARCH_PATHS"] = "$(inherited) \"$(SRCROOT)/NativeScript\""
    # puts "#{loggingPrefix} ℹ️  new_build_settings: #{new_build_settings}"
    # config.build_settings = new_build_settings

    puts "#{loggingPrefix} ℹ️  Existing HEADER_SEARCH_PATHS: #{config.build_settings[:HEADER_SEARCH_PATHS]}"
    config.build_settings["HEADER_SEARCH_PATHS"] = "$(inherited) \"$(SRCROOT)/NativeScript\""
    puts "#{loggingPrefix} ✅ Updated HEADER_SEARCH_PATHS: #{config.build_settings[:HEADER_SEARCH_PATHS]}"

    # TODO: Allow this to be user-configurable, because there's only one Obj-C bridging header allowed.
    puts "#{loggingPrefix} ℹ️  Existing SWIFT_OBJC_BRIDGING_HEADER: #{config.build_settings[:SWIFT_OBJC_BRIDGING_HEADER]}"
    config.build_settings["SWIFT_OBJC_BRIDGING_HEADER"] = "\"$(SRCROOT)/NativeScript/App-Bridging-Header.h\""
    puts "#{loggingPrefix} ✅ Updated SWIFT_OBJC_BRIDGING_HEADER: #{config.build_settings[:SWIFT_OBJC_BRIDGING_HEADER]}"

    ourLdFlags = "$(inherited) -framework Capacitor -framework Cordova -framework WebKit $(inherited) -ObjC -sectcreate __DATA __TNSMetadata \"$(CONFIGURATION_BUILD_DIR)/metadata-$(CURRENT_ARCH).bin\" -framework NativeScript \"-F$(SRCROOT)/internal\" -licucore -lz -lc++ -framework Foundation -framework UIKit -framework CoreGraphics -framework MobileCoreServices -framework Security"

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

    def array_includes_array(array_to_inspect, array_to_search_for)
      inspectLength = array_to_inspect.length
      searchLength = array_to_search_for.length
    
      if searchLength == 0 then
        return true
      end
    
      if searchLength > inspectLength then
        return false
      end
    
      buffer = []
    
      for i in 0..inspectLength
        buffer.push(array_to_inspect[i])
    
        bufferLastIndex = buffer.length - 1
        if(buffer[bufferLastIndex] != array_to_search_for[bufferLastIndex]) then
          buffer.clear
          next
        end
    
        if(buffer.length == searchLength) then
          return true
        end
      end
    
      return false
    end

    # If the Xcode build gives the error "Command Ld failed", then it's probably due to a poor update of OTHER_LDFLAGS here:
    existing_OTHER_LDFLAGS = config.build_settings["OTHER_LDFLAGS"] ||= []
    if(!array_includes_array(existing_OTHER_LDFLAGS, nativeScriptLdFlags)) then
      puts "#{loggingPrefix} ℹ️  Existing OTHER_LDFLAGS: #{existing_OTHER_LDFLAGS}"
      # Initial state:
      # "OTHER_LDFLAGS"=>["$(inherited)", "-ObjC", "-lc++"]
      puts "#{loggingPrefix} ℹ️  Planned OTHER_LDFLAGS subarray 1/3: #{existing_OTHER_LDFLAGS}"
      puts "#{loggingPrefix} ℹ️  Planned OTHER_LDFLAGS subarray 2/3: #{(existing_OTHER_LDFLAGS.include? "$(inherited)") ? [] : ["$(inherited)"]}"
      puts "#{loggingPrefix} ℹ️  Planned OTHER_LDFLAGS subarray 3/3: #{nativeScriptLdFlags}"

      config.build_settings["OTHER_LDFLAGS"] = [
        *existing_OTHER_LDFLAGS,
        *((existing_OTHER_LDFLAGS.include? "$(inherited)") ? [] : ["$(inherited)"]),
        *nativeScriptLdFlags
      ]
      puts "#{loggingPrefix} ✅ Updated OTHER_LDFLAGS: #{config.build_settings["OTHER_LDFLAGS"]}"
    end

    config.build_settings["LD"] = "$SRCROOT/internal/nsld.sh"
    config.build_settings["LDPLUSPLUS"] = "$SRCROOT/internal/nsld.sh"
    # By default, this is NO for debug and YES for release. This is one state change we won't be able to undo during uninstall.
    config.build_settings["ENABLE_BITCODE"] = "NO"
    # By default, this is YES. This is one state change we won't be able to undo during uninstall.
    config.build_settings["CLANG_ENABLE_MODULES"] = "NO"
  
    puts "#{loggingPrefix} ℹ️  Updated config.build_settings: #{config.build_settings}"
  }
  
  project.save()

  # TODO: run the build-nativescript.js script.
end
