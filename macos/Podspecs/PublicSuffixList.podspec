# macos/Podspecs/PublicSuffixList.podspec
Pod::Spec.new do |s|
  s.name         = 'PublicSuffixList'
  s.version      = '2.0.0'                             # match the version you need
  s.summary      = 'PublicSuffixList library from swift-psl'
  s.homepage     = 'https://github.com/amosogra/swift-psl'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'ameshkov' => 'support@ameshkov.com' }
  s.source       = { :git => 'https://github.com/amosogra/swift-psl.git', :tag => 'v2.0.0'}
  s.swift_version    = '5.6'
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.source_files     = 'Sources/PublicSuffixList/**/*.swift'

  # # <-- Add this so the .bin resource files get packaged
  # s.resources        = 'Sources/PublicSuffixList/Resources/*.bin'

  # Add this line to create a resource bundle
  s.resource_bundles = {
    'PublicSuffixList' => ['Sources/PublicSuffixList/Resources/*']
  }
  
  # Or if you want to include resources directly:
  # s.resources = ['Sources/PublicSuffixList/Resources/*']
end
