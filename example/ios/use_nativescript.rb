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

  if(options[:includeTKLiveSync])
    # TKLiveSync is acquired by unzipping @nativescript/ios/framework/internal/XCFrameworks.zip.
    # However, unzipping this into our project root would clobber NativeScript.xcframework with a same-named xcframework
    # that lacks the TNSRuntime.h header. We could unzip into a temporary directory, but it's rather too much work given
    # that even once installed, we ultimately don't support TKLiveSync functionality anyway (for now).
    # In future, hopefully we'll have a neat package that gives everything needed without having to juggle so much.
    puts "#{loggingPrefix} ❌ Including TKLiveSync is not supported for now but may be supported in future."
    exit(1)
  end

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

  ## This is built from the @nativescript/ui-mobile-base GitHub project, but the package doesn't seem to be published anywhere.
  ## So instead, we vend it along with TNSWidgets.xcframework in react-native-nativescript-runtime/ios/XCFrameworks.zip, just like NativeScript Capacitor does.
  tnsWidgetsXcframeworkDestParentPath = scriptDirPath
  tnsWidgetsXcframeworkDestPath = File.join(scriptDirPath, "TNSWidgets.xcframework")
  
  nativeScriptIosInternalDirectorySourcePath = File.join(nativeScriptIosPath, "framework", "internal")
  nativeScriptIosInternalDirectoryDestPath = File.join(scriptDirPath, "internal")
  nativeScriptIosInternalDirectoryDestXcframeworksZipPath = File.join(nativeScriptIosInternalDirectoryDestPath, "XCFrameworks.zip")

  ## Although there is indeed a NativeScript.xcframework within @nativescript/ios/framework/internal/XCFrameworks.zip, it lacks the TNSRuntime.h header.
  ## So instead, we vend it along with TNSWidgets.xcframework in react-native-nativescript-runtime/ios/XCFrameworks.zip, just like NativeScript Capacitor does.
  nativeScriptIosFrameworksSourcePath = File.join(nativeScriptRuntimeNodeModulePath, "ios", "XCFrameworks.zip")
  nativeScriptIosFrameworksExtractedDestPath = scriptDirPath
  nativeScriptXcframeworkDestPath = File.join(scriptDirPath, "NativeScript.xcframework")
  nativeScriptUserBundleDirPath = File.expand_path(File.join(scriptDirPath, "..", "nativescript", "build"))
  nativeScriptUserBundleFilePath = File.expand_path(File.join(scriptDirPath, "..", "nativescript", "build", "nativescript-bundle.js"))

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

  if File.directory?(nativeScriptXcframeworkDestPath) && File.directory?(tnsWidgetsXcframeworkDestPath) && (includeTKLiveSync ? File.directory?(tKLiveSyncXcframeworkDestPath) : true) then
    puts "#{loggingPrefix} ✅ Found both NativeScript.xcframework and TNSWidgets.xcframework #{includeTKLiveSync ? "(and TKLiveSync.xcframework)" : ""} in \"#{nativeScriptIosFrameworksExtractedDestPath}\", so will skip unzipping of \"#{nativeScriptIosFrameworksSourcePath}\"."
  else
    puts "#{loggingPrefix} ℹ️  Missing NativeScript iOS xcframeworks, so will unzip them from \"#{nativeScriptIosFrameworksSourcePath}\" into \"#{nativeScriptIosFrameworksExtractedDestPath}\" ..."

    if !File.file?(nativeScriptIosFrameworksSourcePath) then
      puts "#{loggingPrefix} ❌ NativeScript.xcframework and TNSWidgets.xcframework #{includeTKLiveSync ? "(and TKLiveSync.xcframework)" : ""} were both missing at \"#{nativeScriptIosFrameworksExtractedDestPath}\", so need to unzip \"#{nativeScriptIosFrameworksSourcePath}\"; however, that zip file is missing. Please run `npm install --save @nativescript/ios` again and then try repeating `pod install`. Also, if not using the default options, ensure that the correct nativescriptIosPath option is passed into use_nativescript!() in your app's Podfile."
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
  end

  puts "#{loggingPrefix} ℹ️  Will now start preparing the Xcode project..."

  if File.directory?(nativeScriptIosRuntimeMetaDirectoryDestPath) then
    puts "#{loggingPrefix} ✅ Found the NativeScript iOS meta folder (named \"NativeScript\") at \"#{nativeScriptIosRuntimeMetaDirectoryDestPath}\", so will skip copying it."
  else
    puts "#{loggingPrefix} ℹ️  Missing the NativeScript iOS meta folder (named \"NativeScript\") at \"#{nativeScriptIosRuntimeMetaDirectoryDestPath}\", so will copy it from \"#{nativeScriptIosRuntimeMetaDirectorySourcePath}\"."
    FileUtils.cp_r(nativeScriptIosRuntimeMetaDirectorySourcePath, nativeScriptIosRuntimeMetaDirectoryDestParentPath)
    puts "#{loggingPrefix} ✅ Successfully copied the NativeScript iOS meta folder to \"#{nativeScriptIosRuntimeMetaDirectorySourcePath}\"."
  end

  projectTarget = project.targets.find { |target| target.name == options[:projectTargetName] }

  def ensure_nativescript_build_phase(
    projectTarget,
    loggingPrefix,
    phaseName,
    shellScript
  )
    existingPhaseIndex = projectTarget.build_phases.index { |phase| defined?(phase.name) && phase.name == phaseName }
    # Reminder: even 0 is truthy in Ruby; only false and nil are falsy.
    # The new_shell_script_build_phase helper shoves the build phase on the end of the array, so we'll have to shift them as appropriate subsequently.
    buildPhase = existingPhaseIndex ? projectTarget.build_phases[existingPhaseIndex] : projectTarget.new_shell_script_build_phase(phaseName)
    buildPhase.shell_script = shellScript
    return buildPhase
  end

  ensure_nativescript_build_phase(projectTarget, loggingPrefix, "NativeScript prebuild", "\"${SRCROOT}/internal/nativescript-pre-build\"")
  ensure_nativescript_build_phase(projectTarget, loggingPrefix, "NativeScript prelink", "\"${SRCROOT}/internal/nativescript-pre-link\"")
  # For some reason Capacitor doesn't include the postbuild phase.
  if(doPostbuild) then
    ensure_nativescript_build_phase(projectTarget, loggingPrefix, "NativeScript postbuild", "\"${SRCROOT}/internal/nativescript-post-build\"")
  else
    nativescriptPostbuildPhaseIndex = projectTarget.build_phases.index { |phase| defined?(phase.name) && phase.name == "NativeScript postbuild" }
    if(nativescriptPostbuildPhaseIndex)
      projectTarget.build_phases.delete_at(nativescriptPostbuildPhaseIndex)
    end
  end

  def place_nativescript_build_phase(
    projectTarget,
    loggingPrefix,
    nativescriptBuildPhaseName,
    atIndex
  )
    nativescriptBuildPhaseIndex = projectTarget.build_phases.index { |phase| defined?(phase.name) && phase.name == nativescriptBuildPhaseName }
    if(!nativescriptBuildPhaseIndex)
      puts "#{loggingPrefix} ❌ Unexpectedly unable to find index for specified NativeScript build phase. Please ensure that ensure_nativescript_build_phase() is called before this."
      exit(1)
    end

    if(nativescriptBuildPhaseIndex == atIndex)
      # It's already at the required position.
      return
    end

    if(nativescriptBuildPhaseIndex == atIndex)
      # It's already at the required position.
      return
    end

    # The delete_at() method is a notification-enabled ObjectList method, so is safe to use:
    # @see https://www.rubydoc.info/github/CocoaPods/Xcodeproj/Xcodeproj/Project/ObjectList
    nativescriptBuildPhase = projectTarget.build_phases.delete_at(nativescriptBuildPhaseIndex)

    # Inserts at the given index, shunting along anything that was originally at that index and beyond it.
    projectTarget.build_phases.insert(
      # We subtract 1 from the target index if it would've been shunted along by the deletion of nativeScriptBuildPhase just now.
      atIndex < nativescriptBuildPhaseIndex ? atIndex : (atIndex - 1),
      nativescriptBuildPhase
    )
  end

  # puts "Xcodeproj::Project::Object::PBXSourcesBuildPhase: #{Xcodeproj::Project::Object::PBXSourcesBuildPhase}"


  # "Compile Sources" phase (there are strictly 0-1 of these)
  compileSourcesPhaseIndex = projectTarget.build_phases.index { |phase| phase.instance_of? Xcodeproj::Project::Object::PBXSourcesBuildPhase }
  if(!compileSourcesPhaseIndex)
    # puts "#{loggingPrefix} ⚠️ Attempting to sort NativeScript prebuild phase, but there is no \"Compile Sources\" phase to place it before. Will instead place it as the first build step."
    # compileSourcesPhaseIndex = 0
    puts "#{loggingPrefix} ❌ Unable to compile NativeScript frameworks as there is no \"Compile Sources\" phase set up yet. Please add it into your Xcode project's build phases via the option \"New Compile Sources Phase\", then try repeating `pod install`."
    exit(1)
  end
  compileSourcesPhase = projectTarget.build_phases[compileSourcesPhaseIndex]
  place_nativescript_build_phase(projectTarget, loggingPrefix, "NativeScript prebuild", compileSourcesPhaseIndex)

  # "Link Binary With Libraries" phase (there are strictly 0-1 of these)
  linkingPhaseIndex = projectTarget.build_phases.index { |phase| phase.instance_of? Xcodeproj::Project::Object::PBXFrameworksBuildPhase }
  if(!linkingPhaseIndex)
    puts "#{loggingPrefix} ❌ Unable to link NativeScript frameworks or place NativeScript prelink phase, because there is no \"Link Binary with Libraries\" phase to place it before. Please add it into your Xcode project's build phases via the option \"New Link Binary With Libraries Phase\", then try repeating `pod install`."
    exit(1)
  end
  place_nativescript_build_phase(projectTarget, loggingPrefix, "NativeScript prelink", linkingPhaseIndex)

  # resultingLinkingPhaseIndex = projectTarget.build_phases.index { |phase| phase.instance_of? Xcodeproj::Project::Object::PBXFrameworksBuildPhase }
  # puts "#{loggingPrefix} ℹ️ prelink phase placed at #{linkingPhaseIndex} (where 'Link Binary with Libraries' was, hopefully shunting it to a new position of one higher: #{resultingLinkingPhaseIndex}"

  linkingPhase = projectTarget.build_phases.find { |phase| phase.instance_of? Xcodeproj::Project::Object::PBXFrameworksBuildPhase }
  if(!linkingPhase)
    puts "#{loggingPrefix} ❌ Expected to find \"Link Binary with Libraries\" build phase, but it was missing."
    exit(1)
  end

  # frameworks_group returns the group, creating it if necessary.

  extractedNativeScriptXcframeworkFileRef = project.frameworks_group.files.find { |ref| ref.path.end_with? "NativeScript.xcframework" }
  if(!extractedNativeScriptXcframeworkFileRef)
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
    if(!tKLiveSyncXcframeworkFileRef)
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
  if(!tnsWidgetsXcframeworkFileRef)
    tnsWidgetsXcframeworkFileRef = project.frameworks_group.new_file(tnsWidgetsXcframeworkDestPath);
    linkingPhase.add_file_reference(tnsWidgetsXcframeworkFileRef)
    puts "#{loggingPrefix} ✅ Added file reference to TNSWidgets.xcframework."
  else
    # I was thinking of attempt to update the path, but it seems to result in an uglier file path than the new_file() API gives you.
    # tnsWidgetsXcframeworkFileRef.path = tnsWidgetsXcframeworkDestPath
  end
  tnsWidgetsXcframeworkFileRef.build_files.each { |build_file| build_file.settings = { "ATTRIBUTES" => ["CodeSignOnCopy"] } }

  def ensure_nativescript_embed_phase(
    projectTarget,
    loggingPrefix,
    phaseName,
    extractedNativeScriptXcframeworkFileRef,
    tnsWidgetsXcframeworkFileRef
  )
    # existingPhaseIndex = projectTarget.build_phases.find { |phase| phase.instance_of? Xcodeproj::Project::Object::PBXCopyFilesBuildPhase }
    existingPhaseIndex = projectTarget.build_phases.index { |phase| defined?(phase.name) && phase.name == phaseName }
    # The new_shell_script_build_phase helper shoves the build phase on the end of the array, so we'll have to shift them as appropriate subsequently.
    embedPhase = existingPhaseIndex ? projectTarget.build_phases[existingPhaseIndex] : projectTarget.new_copy_files_build_phase(phaseName)
    
    embedPhase.dst_path = ""
    embedPhase.dst_subfolder_spec = Xcodeproj::Constants::COPY_FILES_BUILD_PHASE_DESTINATIONS[:frameworks]

    if !embedPhase.files.any? { |ref| ref&.file_ref&.path&.end_with? "NativeScript.xcframework" }
      embedPhase.add_file_reference(extractedNativeScriptXcframeworkFileRef)
    end

    if !embedPhase.files.any? { |ref| ref&.file_ref&.path&.end_with? "TNSWidgets.xcframework" }
      embedPhase.add_file_reference(tnsWidgetsXcframeworkFileRef)
    end

    puts "#{loggingPrefix} ✅ Added \"NativeScript Embed Frameworks\" build phase."
    return embedPhase
  end
  embedPhase = ensure_nativescript_embed_phase(projectTarget, loggingPrefix, "NativeScript Embed Frameworks", extractedNativeScriptXcframeworkFileRef, tnsWidgetsXcframeworkFileRef)

  nativeScriptUserGroup = project.groups.find { |ref|
    puts("project.group[i] #{ref}")
    puts("project.group[i].name - defined: #{defined?(ref.name)}; nil: #{ref.name.nil?}; #{ref.name}")
    puts("project.group[i].path - defined: #{defined?(ref.path)}; nil: #{ref.path.nil?}; #{ref.path}")
    break ref if (!ref.name.nil? && ref.name == "NativeScriptUser")
    break ref if (!ref.path.nil? && (ref.path.end_with? "nativescript/build"))
    next
  }
  if(!nativeScriptUserGroup)
    nativeScriptUserGroup = project.new_group("NativeScriptUser", nativeScriptUserBundleDirPath);
    puts "#{loggingPrefix} ✅ Added the \"NativeScriptUser\" group."
  else
    puts "#{loggingPrefix} ✅ Found existing \"NativeScriptUser\" group."
  end
  puts("nativeScriptUserGroup.children #{nativeScriptUserGroup.children}")
  puts("nativeScriptUserGroup.files #{nativeScriptUserGroup.files}")

  nativeScriptUserBundleFileRef = nativeScriptUserGroup.files.find { |ref| ref.path.end_with? "nativescript-bundle.js" }
  if(nativeScriptUserBundleFileRef.nil?)
    # nativeScriptUserBundleFileRef = nativeScriptUserGroup.new_file("nativescript-bundle.js")
    nativeScriptUserBundleFileRef = nativeScriptUserGroup.new_file(nativeScriptUserBundleFilePath)
    puts "#{loggingPrefix} ✅ Added file reference to the NativeScript user bundle."
  else
    puts "#{loggingPrefix} ✅ Found file reference to the NativeScript user bundle."
  end


  # PBXResourcesBuildPhase
  resourcesPhase = projectTarget.resources_build_phase
  if(resourcesPhase.nil?)
    puts "#{loggingPrefix} ❌ Unable to add NativeScript built code bundle as there is no \"Copy Bundle Resources\" set up yet. Please add it into your Xcode project's build phases via the option \"New Copy Bundle Resources Phase\", then try repeating `pod install`."
    exit(1)
  end
  resourcesPhaseIndex = projectTarget.build_phases.index { |phase| phase == resourcesPhase }
  place_nativescript_build_phase(projectTarget, loggingPrefix, "NativeScript Embed Frameworks", resourcesPhaseIndex + 1)
  if(doPostbuild) then
    # In fresh NativeScript projects, postbuild appears several phases after "Compile Sources": just after "Copy Bundle Resources".
    place_nativescript_build_phase(projectTarget, loggingPrefix, "NativeScript postbuild", resourcesPhaseIndex + 2)
  end

  # TODO: Before placing prelink, ensure that \"Link Bindary With Libraries" is moved to straight after Compile Sources?
  # I'm not really sure to what extend the exact ordering matters, but it would be consistent with new NativeScript projects.
  
  puts "#{loggingPrefix} resourcesPhase.files: #{resourcesPhase.files}"
  if(!resourcesPhase.files.any? { |ref| ref.file_ref.path.end_with? "nativescript-bundle.js" })
    # puts "#{loggingPrefix} resourcesPhase.files: #{resourcesPhase.files}"
    # projectTarget.add_resources(nativeScriptUserBundleFileRef)
    resourcesPhase.add_file_reference(nativeScriptUserBundleFileRef)
    puts "#{loggingPrefix} ✅ Added the NativeScript user bundle to the Copy Bundle Resources phase."
  else
    puts "#{loggingPrefix} ✅ NativeScript user bundle was found in the Copy Bundle Resources phase."
  end

  puts "#{loggingPrefix} project.groups: #{project.groups}"
  nativeScriptMetaGroup = project.groups.find { |ref|
    break ref if (!ref.name.nil? && ref.name == "NativeScript")
    break ref if (!ref.path.nil? && ref.path == "NativeScript")
    next
  }
  if(nativeScriptMetaGroup.nil?)
    nativeScriptMetaGroup = project.new_group("NativeScript", nativeScriptIosRuntimeMetaDirectoryDestPath);

    Dir.entries(nativeScriptIosRuntimeMetaDirectoryDestPath).select { |entry| !entry.start_with? "." }.each { |entry| nativeScriptMetaGroup.new_file(entry) }
    puts "#{loggingPrefix} ✅ Added file reference to NativeScript meta directory."
  else
    puts "#{loggingPrefix} ✅ Found existing NativeScript meta directory."
  end
  puts "#{loggingPrefix} nativeScriptMetaGroup: #{nativeScriptMetaGroup}"
  puts "#{loggingPrefix} nativeScriptMetaGroup.files: #{nativeScriptMetaGroup.files}"
  nativeScriptMetaGroup.files.each { |fileRef|
    # Based on: https://github.com/NativeScript/nativescript-dev-xcode/blob/a7f032722d0edab445598bc8602ef49d4640151e/lib/pbxProject.js#L618
    # Note that we don't recurse down the group. Hopefully it remains as a flat structure.
    file_type = fileRef.last_known_file_type
    if (file_type.start_with? "sourcecode.") && !(file_type.end_with? ".h") && file_type != Xcodeproj::Constants::FILE_TYPES_BY_EXTENSION["plist"] && file_type != Xcodeproj::Constants::FILE_TYPES_BY_EXTENSION["modulemap"] then
      # The true param avoids duplicates.
      # FIXME: Actually, it's bugged.
      compileSourcesPhase.add_file_reference(fileRef, true)
    end
  }

  # projectTarget.build_configurations.each { |config|
  #   puts "#{loggingPrefix} ℹ️  Inspecting BUILD_SETTINGS for projectTarget => #{projectTarget.name} & CONFIGURATION => #{config.name}"
    
  #   puts "#{loggingPrefix} ℹ️  Existing config.build_settings: #{config.build_settings}"

  #   # TODO: Allow this to be user-configurable, because there's only one Obj-C bridging header allowed.
  #   # puts "#{loggingPrefix} ℹ️  Existing SWIFT_OBJC_BRIDGING_HEADER: #{config.build_settings[:SWIFT_OBJC_BRIDGING_HEADER]}"
  #   # config.build_settings["SWIFT_OBJC_BRIDGING_HEADER"] = "\"$(SRCROOT)/NativeScript/App-Bridging-Header.h\""
  #   # puts "#{loggingPrefix} ✅ Updated SWIFT_OBJC_BRIDGING_HEADER: #{config.build_settings[:SWIFT_OBJC_BRIDGING_HEADER]}"
  
  #   puts "#{loggingPrefix} ℹ️  Updated config.build_settings: #{config.build_settings}"
  # }
  
  project.save()

  # TODO: run the build-nativescript.js script.
end
