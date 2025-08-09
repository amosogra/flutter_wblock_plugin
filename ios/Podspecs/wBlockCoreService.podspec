Pod::Spec.new do |s|
  s.name         = 'wBlockCoreService'
  s.version      = '4.0.0'
  s.summary      = 'Swift package with wBlock functionality'
  s.description  = 'A Swift package with content blocking capabilities.'
  s.homepage     = 'https://github.com/amosogra/wBlockCoreService_Package'
  s.license      = { :type => 'MIT' }
  s.author       = { 'Amos Ogra' => 'floodcoding@gmail.com' }
  s.source       = { :git => 'https://github.com/amosogra/wBlockCoreService_Package.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '13.0'

  s.dependency 'ContentBlockerConverter', '2.0.48'
  s.dependency 'ZIPFoundation', '0.9.19'
  s.dependency 'FilterEngine', '2.0.48' 
  
  # Include local Swift Package source
  s.source_files = ['Classes/**/*', 'Sources/**/*.{swift,h}']

  
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'SUPPORTS_MACCATALYST' => 'YES',
    'SWIFT_VERSION' => '5.9'
  }

  s.swift_version = '5.9'
  s.module_name = 'wBlockCoreService'
  s.requires_arc = true
end
