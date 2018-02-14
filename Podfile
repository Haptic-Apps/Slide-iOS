# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'Slide for Reddit' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  # Pods for Slide for Reddit

  pod 'reddift', :git =>  'https://github.com/ccrama/reddift'
  pod 'SDWebImage', '~>3.8'
  pod 'SideMenu'
pod 'MaterialComponents/AnimationTiming'
pod 'MaterialComponents/Buttons'
pod 'MaterialComponents/Dialogs'
pod 'MaterialComponents/Ink'
pod 'MaterialComponents/Palettes'
pod 'MaterialComponents/TextFields'
pod 'MaterialComponents/ProgressView'
pod "MKColorPicker"
  pod 'XLActionController'
pod 'MaterialComponents/ShadowElevations'
pod 'MaterialComponents/Snackbar’
pod 'MaterialComponents/ActivityIndicator'
pod 'MaterialComponents/Tabs'
  pod “SloppySwiper”, :git => ‘https://github.com/fastred/SloppySwiper'
  pod 'UZTextView', :git => 'https://github.com/ccrama/UZTextView'
  pod 'TTTAttributedLabel'
  pod "KCFloatingActionButton", "~> 2.1.0"
  pod 'ImagePickerSheetController', :git => 'https://github.com/lbrndnr/ImagePickerSheetController’, :branch => ‘swift3’
  pod 'Alamofire', '~> 4.3'
    pod 'SwiftyJSON'
pod 'ActionSheetPicker-3.0’, :git => ‘https://github.com/ccrama/ActionSheetPicker-3.0'
  pod ‘RealmSwift’

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
