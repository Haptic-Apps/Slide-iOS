# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'
inhibit_all_warnings!
target 'Slide for Reddit' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  # Pods for Slide for Reddit

  pod 'reddift', :git =>  'https://github.com/ccrama/reddift'
  pod 'SDWebImage'
  pod 'MKColorPicker', :git => 'https://github.com/ccrama/MKColorPicker'
  pod 'BadgeSwift', '~> 8.0'
  pod 'LicensesViewController', '~> 0.7.0'
  pod 'BiometricAuthentication'
  pod 'OpalImagePicker'
  pod 'MaterialComponents/ActivityIndicator'
  pod 'MaterialComponents/Tabs'
  pod 'MaterialComponents/ProgressView'
  pod 'SwiftEntryKit', :git => 'https://github.com/ccrama/SwiftEntryKit'
  pod 'SubtleVolume'
  pod 'SDCAlertView', :git => 'https://github.com/ccrama/SDCAlertView'
  pod 'Embassy', '~> 4.1.0'
  pod 'MTColorDistance'
  pod 'SwiftLinkPreview', '~> 3.0.1'
  pod 'DTCoreText', :git => 'https://github.com/Cocoanetics/DTCoreText'
  pod 'SwiftSpreadsheet'
  pod 'Starscream', '~> 3.1.1'
  pod 'RLBAlertsPickers', :git => 'https://github.com/ccrama/Alerts-Pickers'
  pod 'YYText'
  pod 'Alamofire', '~> 4.3'
  pod 'SwiftyJSON'
  pod 'RealmSwift'
  pod 'Anchorage', '~>4.3'
  pod 'Then'
  pod 'SwiftLint'
  pod "youtube-ios-player-helper"
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