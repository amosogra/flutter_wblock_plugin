# ios/Podspecs/PublicSuffixList.podspec
Pod::Spec.new do |s|
  s.name         = 'PublicSuffixList'
  s.version      = '1.1.47'                             # match the version you need
  s.summary      = 'PublicSuffixList library from swift-psl'
  s.homepage     = 'https://github.com/ameshkov/swift-psl'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'ameshkov' => 'support@ameshkov.com' }
  s.source       = { :git => 'https://github.com/ameshkov/swift-psl.git', :tag => 'v1.1.47'}
  s.swift_version    = '5.6'
  s.platform         = :ios, '13.0'
  s.source_files     = 'Sources/PublicSuffixList/**/*.swift'

  # <-- Add this so the .bin resource files get packaged
  s.resources        = 'Sources/PublicSuffixList/Resources/*.bin'
end
