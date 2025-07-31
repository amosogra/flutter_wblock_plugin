# ios/Podspecs/SafariConverterLib.podspec
Pod::Spec.new do |s|
  s.name         = 'ContentBlockerConverter'
  s.version      = '2.0.48'
  s.summary      = 'Swift library that converts AdGuard rules to Safari content blocking rules'
  s.homepage     = 'https://github.com/AdguardTeam/SafariConverterLib'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'AdGuard' => 'support@adguard.com' }
  s.source       = { :git => 'https://github.com/AdguardTeam/SafariConverterLib.git', :commit => '9e431a2' }
  
  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.15'
  s.swift_version = '5.0'
  
  # only include the ContentBlockerConverter target sources
  s.source_files     = 'Sources/ContentBlockerConverter/**/*.swift'

  # its Swift‑PM dependency
  s.dependency 'Punycode', '3.0.0'
end