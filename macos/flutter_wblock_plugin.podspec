#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_wblock_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_wblock_plugin'
  s.version          = '0.2.0'
  s.summary          = 'A Flutter plugin for wBlock - The next-generation ad blocker for Safari on macOS.'
  s.description      = <<-DESC
A Flutter plugin that provides native integration with Safari Content Blocker API for ad blocking on macOS.
                       DESC
  s.homepage         = 'https://github.com/yourusername/flutter_wblock_plugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.resources = ['Classes/SafariWebExtension/Resources/**/*']
  
  # Explicitly exclude problematic resource directories
  s.exclude_files = [
    'Classes/SafariWebExtension/**/*',
    'Classes/**/Resources/**/*',
  ]
  
  # Don't try to include the Safari extension resources in the pod
  # These should be handled by your app target directly


  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'
  # Module configuration
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES',
    'SWIFT_VERSION' => '5.0'
  }
  s.swift_version = '5.0'
end
