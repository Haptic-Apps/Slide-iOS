# Uncomment the next line to define a global platform for your project
platform :ios, '11'
inhibit_all_warnings!
target 'Slide for Reddit' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  # Pods for Slide for Reddit

  pod 'reddift', :git =>  'https://github.com/ccrama/reddift'
  pod 'MKColorPicker', :git => 'https://github.com/ccrama/MKColorPicker'
  pod 'LicensesViewController', '~> 0.7.0'
  pod 'OpalImagePicker'
  pod 'MaterialComponents/ActivityIndicator'
  pod 'MaterialComponents/ProgressView'
  pod 'SwiftEntryKit', :git => 'https://github.com/ccrama/SwiftEntryKit'
  pod 'SubtleVolume'
  pod 'SDCAlertView', :git => 'https://github.com/ccrama/SDCAlertView'
  pod 'MTColorDistance'
  pod 'SwiftLinkPreview', '~> 3.0.1'
  pod 'DTCoreText', :git => 'https://github.com/Cocoanetics/DTCoreText'
  pod 'RLBAlertsPickers', :git => 'https://github.com/ccrama/Alerts-Pickers'
  pod 'SwiftyJSON', :git => 'https://github.com/ccrama/SwiftyJSON.git', :branch => 'hotfix-xcode12'
  pod "YoutubePlayer-in-WKWebView", "~> 0.3.0"
  pod 'TGPControls'

  target 'Slide for RedditTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'Slide for RedditUITests' do
    inherit! :search_paths
    # Pods for testing
  end

  post_install do |installer|
    installer.pods_project.targets.each do |target|
        # Fix bundle targets' 'Signing Certificate' to 'Sign to Run Locally'
        if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
            target.build_configurations.each do |config|
                config.build_settings['CODE_SIGN_IDENTITY[sdk=macosx*]'] = '-'
            end
        end
    end

    installer.pods_project.targets.each do |target|
    	target.build_configurations.each do |config|
     	 config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11'
    	end
        if [
          'HTMLSpecialCharacters',
          'MiniKeychain',
          'RLBAlertsPickers',
          'SwiftLinkPreview'
        ].include? target.name
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '4.2'
            end
        end
    end
  end

end

pod 'SwiftLint'
