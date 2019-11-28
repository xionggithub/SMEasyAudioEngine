Pod::Spec.new do |s|
  s.name     = 'SMEasyAudioEngine'
  s.version  = '1.0'
  s.license  = 'BSD'
  s.summary  = 'An open source iOS framework for audio processing.'
  s.homepage = 'https://github.com/xionggithub/SMEasyAudioEngine'
  s.author   = { 'xionggithub' => '...' }
  s.source   = { :git => 'https://github.com/xionggithub/SMEasyAudioEngine.git', :tag => "#{s.version}" }
  
  s.source_files = 'SMEasyAudioEngine/**/*.{h,m}'
  s.ios.deployment_target = '7.0'
  s.xcconfig = {     
    'USER_HEADER_SEARCH_PATHS' => '$(inherited) ${PODS_ROOT}/SMEasyAudioEngine/SMEasyAudioEngine'
  }

  s.subspec 'Core' do |c|
    c.source_files  = 'SMEasyAudioEngine/Core/*.{h,m,c,cpp,hpp}'
    c.private_header_files = 'SMEasyAudioEngine/Core/*.{h,hpp}'
    c.subspec 'SMCircleBuffer' do |smcb|
      smcb.source_files  = 'SMEasyAudioEngine/Core/SMCircleBuffer/*.{h,m,c,cpp,hpp}'
      smcb.private_header_files = 'SMEasyAudioEngine/Core/SMCircleBuffer/*.{h,hpp}'
    end
    c.subspec 'SMEasyAudioSession' do |smeas|
      smeas.source_files  = 'SMEasyAudioEngine/Core/SMEasyAudioSession/*.{h,m,c,cpp,hpp}'
      smeas.private_header_files = 'SMEasyAudioEngine/Core/SMEasyAudioSession/*.{h,hpp}'
    end
  end

  s.ios.exclude_files = 'framework/Source/Mac'
  s.ios.frameworks   = ['AudioToolbox', 'AVFoundation']
  
 
end
