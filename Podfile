# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'
inhibit_all_warnings!
target 'Slide for Reddit' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  # Pods for Slide for Reddit

  pod 'reddift', :git =>  'https://github.com/ccrama/reddift'
  pod 'SDWebImage', '~>3.8'
  pod 'SideMenu'
  pod 'MaterialComponents/AnimationTiming'
  pod 'MaterialComponents/Buttons'
  pod 'MaterialComponents/Ink'
  pod 'MaterialComponents/Palettes'
  pod 'MaterialComponents/TextFields'
  pod 'MaterialComponents/BottomSheet'
  pod 'MaterialComponents/ProgressView'
  pod 'MKColorPicker'
  pod 'PullUpController'
  pod 'BadgeSwift', '~> 5.0'
  pod 'LicensesViewController', '~> 0.6.5'
  pod 'BiometricAuthentication'
  pod 'Embassy', '~> 4.0'
  pod 'MTColorDistance'
  pod 'DTCoreText', :git => 'https://github.com/Cocoanetics/DTCoreText'
  pod 'XLActionController', :git => 'https://github.com/ccrama/XLActionController'
  pod 'MaterialComponents/ShadowElevations'
  pod 'MaterialComponents/ActivityIndicator'
  pod 'SwiftSpreadsheet'
  pod 'Starscream', '~> 3.0.2'
  pod 'MaterialComponents/Tabs'
  pod 'RLBAlertsPickers', :git => 'https://github.com/ccrama/Alerts-Pickers'
  pod 'SloppySwiper', :git => 'https://github.com/fastred/sloppySwiper'
  pod 'TTTAttributedLabel'
  pod 'ActionSheetPicker-3.0', :git => 'https://github.com/ccrama/ActionSheetPicker-3.0'
  pod 'Alamofire', '~> 4.3'
  pod 'SwiftyJSON'
  pod 'RealmSwift'
  pod 'Anchorage'
  pod 'Then'
  pod 'SwiftLint'

  target 'Slide for RedditTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'Slide for RedditUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end
