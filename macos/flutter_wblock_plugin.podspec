#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_wblock_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_wblock_plugin'
  s.version          = '1.0.0'
  s.summary          = 'A Flutter plugin for wBlock content blocking functionality.'
  s.description      = <<-DESC
A Flutter plugin that provides content blocking functionality for Safari with support for up to 750,000 rules on macOS and 500,000 on iOS.
                       DESC
  s.homepage         = 'https://github.com/amosogra/flutter_wblock_plugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Amos Ogra' => 'floodcoding@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '13.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.9'

  # Add dependency to wBlockCoreService package
  s.dependency 'wBlockCoreService', '1.0.0'
end
