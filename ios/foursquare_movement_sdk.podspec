#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint foursquare_movement_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'foursquare_movement_sdk'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for Foursquare Movement SDK'
  s.description      = <<-DESC
A Flutter plugin wrapping the Foursquare Movement SDK for passive location detection and geofencing.
                       DESC
  s.homepage         = 'https://github.com/Atmosphere-App/foursquare_movement_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Atmosphere' => 'engineering@getatmosphere.app' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'MovementSdk', '~> 4.0', '>= 4.0.5'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'foursquare_movement_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
