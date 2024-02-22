# Uncomment the next line to define a global platform for your project
platform :ios, '14.0'

target 'Property Management' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Google Sign In
    pod 'GoogleAPIClientForREST/Sheets'
    pod 'GoogleSignIn'
    pod 'Firebase'
    pod 'Firebase/Auth'
    pod 'Firebase/Analytics'
    pod 'FirebaseFunctions'
    pod 'FirebaseFirestore'
  # Regular Animations
    pod 'lottie-ios'
    
  # Google Maps
    #pod 'GoogleMaps'
    
  # Storage (Phone numbers, names, friends, etc.)
    pod 'Firebase/Storage'
    #pod 'FirebaseUI/Storage'

  # Bottom Sheet Map, Will remove once ios15 is global platform.
   # pod 'FloatingPanel', '2.5.4'
  pod 'FDTake'

  target 'Property ManagementTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'Property ManagementUITests' do
    # Pods for testing
  end

end

# Disable Warnings
post_install do |installer|
  installer.aggregate_targets.each do |target|
    target.xcconfigs.each do |variant, xcconfig|
      xcconfig_path = target.client_root + target.xcconfig_relative_path(variant)
      IO.write(xcconfig_path, IO.read(xcconfig_path).gsub("DT_TOOLCHAIN_DIR", "TOOLCHAIN_DIR"))
    end
  end
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = "YES"
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
      if config.base_configuration_reference.is_a? Xcodeproj::Project::Object::PBXFileReference
        xcconfig_path = config.base_configuration_reference.real_path
        IO.write(xcconfig_path, IO.read(xcconfig_path).gsub("DT_TOOLCHAIN_DIR", "TOOLCHAIN_DIR"))
      end
    end
  end
end

