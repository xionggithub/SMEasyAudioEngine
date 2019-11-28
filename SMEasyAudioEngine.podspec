Pod::Spec.new do |s|
  s.name     = 'SMEasyAudioEngine'
  s.version  = '1.0'
  s.license  = 'BSD'
  s.summary  = 'An open source iOS framework for GPU-based image and video processing.'
  s.homepage = 'https://github.com/xionggithub/SMEasyAudioEngine'
  s.author   = { 'xionggithub' => '...' }
  s.source   = { :git => 'https://github.com/xionggithub/SMEasyAudioEngine.git', :tag => "#{s.version}" }
  
  s.source_files = './*.{h,m}'
  s.ios.deployment_target = '7.0'
  s.xcconfig = {     
    'USER_HEADER_SEARCH_PATHS' => '$(inherited) ${PODS_ROOT}/SMEasyAudioEngine'
  }
  # s.subspec 'Core' do |Core|
  #     Core.source_files  = './Core/*.{h,m,c,cpp,hpp}'
  #     Core.private_header_files = './Core/*.{h,hpp}'
  #     Core.subspec 'SMCircleBuffer' do |SMCircleBuffer|
  #       SMCircleBuffer.source_files  = './Core/SMCircleBuffer/*.{h,m,c,cpp,hpp}'
  #       SMCircleBuffer.private_header_files = './Core/SMCircleBuffer/*.{h,hpp}'
  #     end
  #     Core.subspec 'SMEasyAudioSession' do |SMEasyAudioSession|
  #       SMEasyAudioSession.source_files  = './Core/SMEasyAudioSession/*.{h,m,c,cpp,hpp}'
  #       SMEasyAudioSession.private_header_files = './Core/SMEasyAudioSession/*.{h,hpp}'
  #     end
  # end

  s.ios.exclude_files = 'framework/Source/Mac'
  s.ios.frameworks   = ['AudioToolbox', 'AVFoundation']
  
 
end
