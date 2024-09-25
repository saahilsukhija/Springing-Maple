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
    pod 'Firebase/Functions'
    pod 'Firebase/Firestore'
    pod 'SwiftyDropbox'
  # Regular Animations
    pod 'lottie-ios'
    pod 'YPImagePicker'
  # Google Maps
    #pod 'GoogleMaps'
    
  # Storage (Phone numbers, names, friends, etc.)
    pod 'Firebase/Storage'
    #pod 'FirebaseUI/Storage'

  # Bottom Sheet Map, Will remove once ios15 is global platform.
   # pod 'FloatingPanel', '2.5.4'
  pod 'FDTake'
  pod "BSImagePicker", "~> 3.1"	

  target 'Property ManagementTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'Property ManagementUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name == 'BoringSSL-GRPC'
      target.source_build_phase.files.each do |file|
        if file.settings && file.settings['COMPILER_FLAGS']
          flags = file.settings['COMPILER_FLAGS'].split
          flags.reject! { |flag| flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
          file.settings['COMPILER_FLAGS'] = flags.join(' ')
        end
      end
    end
  end
end
