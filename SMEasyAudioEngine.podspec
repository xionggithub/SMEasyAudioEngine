Pod::Spec.new do |s|
  s.name     = 'SMEasyAudioEngine'
  s.version  = '1.0'
  s.license  = 'BSD'
  s.summary  = 'An open source iOS framework for audio processing.'
  s.homepage = 'https://github.com/xionggithub/SMEasyAudioEngine'
  s.author   = { 'xionggithub' => '...' }
  s.source   = { :git => 'https://github.com/xionggithub/SMEasyAudioEngine.git', :tag => "#{s.version}" }
  
  s.source_files = 'SMEasyAudioEngine/**/*.{h,hpp,c,cpp,m,mm}'
  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.10'
  s.xcconfig = {     
    'USER_HEADER_SEARCH_PATHS' => '$(inherited) ${PODS_ROOT}/SMEasyAudioEngine/SMEasyAudioEngine'
  }
  s.ios.frameworks   = ['AudioToolbox', 'AVFoundation'] 
  s.osx.frameworks   = ['AudioToolbox', 'AVFoundation']
end
