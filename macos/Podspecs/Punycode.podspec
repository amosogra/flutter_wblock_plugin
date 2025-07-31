# ios/Podspecs/PunycodeSwift.podspec
Pod::Spec.new do |s|
  s.name         = 'Punycode'
  s.version      = '3.0.0'
  s.summary      = 'Swift implementation of Punycode'
  s.homepage     = 'https://github.com/gumob/PunycodeSwift'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'gumob' => 'dev@gumob.com' }
  s.source       = {:git  => 'https://github.com/gumob/PunycodeSwift.git', :tag  => '3.0.0'}
  s.osx.deployment_target      = "10.13"
  s.ios.deployment_target      = "12.0"
  s.swift_version= '5.6'
  s.source_files = 'Sources/**/*.{swift,h,m}'
end
