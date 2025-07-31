# ios/Podspecs/ZIPFoundation.podspec
Pod::Spec.new do |s|
  s.name         = 'ZIPFoundation'
  s.version      = '0.9.19'
  s.summary      = 'Effortless ZIP Handling in Swift'
  s.description  = 'A library to create, read and modify ZIP archive files.'
  s.homepage     = 'https://github.com/weichsel/ZIPFoundation'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Thomas Zoechling' => 'thomas@zoechling.at' }
  s.source       = { :git => 'https://github.com/weichsel/ZIPFoundation.git', :tag => '0.9.19' }
  
  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.15'
  s.swift_version = '5.0'
  
  s.source_files = 'Sources/ZIPFoundation/*.swift'
  s.frameworks = 'Foundation'
  s.requires_arc = true
end