# ios/Podspecs/SafariConverterLib.podspec
Pod::Spec.new do |s|
  s.name         = 'FilterEngine'
  s.version      = '2.0.48'
  s.summary      = 'Swift package target FilterEngine from SafariConverterLib'
  s.homepage     = 'https://github.com/AdguardTeam/SafariConverterLib'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'AdGuard' => 'support@adguard.com' }
  s.source       = { :git => 'https://github.com/AdguardTeam/SafariConverterLib.git', :commit => '9e431a2' }
  
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.swift_version = '5.0'
  
  s.source_files     = 'Sources/FilterEngine/**/*.swift'

  # declare by version (must match what’s in ContentBlockerConverter.podspec)
  s.dependency 'ContentBlockerConverter', '2.0.48'
  s.dependency 'PublicSuffixList', '~> 1.1.47'
end