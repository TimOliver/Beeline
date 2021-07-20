Pod::Spec.new do |s|
  s.name     = 'Beeline'
  s.version  = '1.0.1'
  s.license  =  { :type => 'MIT', :file => 'LICENSE' }
  s.summary  = 'An extremely lean implementation on the classic iOS router pattern.'
  s.homepage = 'https://github.com/TimOliver/Beeline'
  s.author   = 'Tim Oliver'
  s.source   = { :git => 'https://github.com/TimOliver/Beeline.git', :tag => s.version }
  s.source_files = 'Beeline/**/*.swift'
  s.swift_version = '5.0'

  s.ios.deployment_target   = '9.0'
  s.tvos.deployment_target = '9.0'

end
