//
//  SMEasyAudioRecorder.m
//  testAudioEngine
//
//  Created by xiaoxiong on 2019/11/28.
//  Copyright © 2019 xiaoxiong. All rights reserved.
//

#import "SMEasyAudioRecorder.h"
#import "SMEasyAudioEngine.h"
#import "SMEasyAudioIONode.h"
#import "SMEasyAudioRecordNode.h"
#import "SMEasyAudioSession.h"
#import "SMEasyAudioMixerNode.h"
#import "AVAudioSession+RouteUtils.h"

@implementation SMEasyAudioRecorder
{
    SMEasyAudioEngine *_audioEngine;
    SMEasyAudioRecordNode *_recordNode;
    SMEasyAudioIONode *_IONode;
    SMEasyAudioMixerNode *_mixerNode;
}
- (nullable instancetype)initWithURL:(NSURL *)url format:(AVAudioFormat *)format error:(NSError **)outError{
    if (self = [super init]) {
        SMEasyAudioEngine *engine = [[SMEasyAudioEngine alloc]init];
        _audioEngine = engine;
        
        
        SMEasyAudioIONode *ioNode = [[SMEasyAudioIONode alloc]init];
        _IONode = ioNode;
        
        SMEasyAudioRecordNode *recordNode = [[SMEasyAudioRecordNode alloc] initWithRecordFilePath:url];
        _recordNode = recordNode;

        SMEasyAudioMixerNode *mixer = [[SMEasyAudioMixerNode alloc]initWithMixerElementCount:1];
        _mixerNode = mixer;
        
        [engine attachNode:ioNode];
        [engine attachNode:recordNode];
        [engine attachNode:mixer];

        [engine connect:ioNode to:recordNode fromBus:1 toBus:0 modle:SMEasyAudioNodeConnectModleRenderCallBack];
        [engine connect:recordNode to:mixer fromBus:0 toBus:0];
        [engine connect:mixer to:ioNode fromBus:0 toBus:0];

        [engine prepare];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(onNotificationAudioRouteChange:)
            name:AVAudioSessionRouteChangeNotification
          object:nil];
    }
    return self;
}
- (void)resetAudioCapture{
    UInt32 sampleRate = [SMEasyAudioConstants getSampleRate];
    [[SMEasyAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord];
    [[SMEasyAudioSession sharedInstance] setPreferredSampleRate:sampleRate];
}
- (BOOL)record{
    [self resetAudioCapture];
    NSError *error;
   return [_audioEngine startAndReturnError:&error];
}
- (void)pause{
    [_audioEngine stop];
}
- (void)stop{
    [_audioEngine stop];
    [_recordNode finish];
}
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onNotificationAudioRouteChange:(NSNotification *)sender {
    AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];

    if (currentRoute) {
        AVAudioSessionRouteChangeReason changeReason = [[sender.userInfo objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
        
        switch (changeReason) { // 暂时只处理 1和2
            case AVAudioSessionRouteChangeReasonUnknown:
                if (sender) {
                    break;
                }
            case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            case AVAudioSessionRouteChangeReasonOldDeviceUnavailable: {
                if ([[AVAudioSession sharedInstance] usingWiredMicrophone] || [[AVAudioSession sharedInstance] usingBlueTooth]) {
                    //使用耳机
                    if (_mixerNode) {
                        //人声+伴奏 mixer：打开
                        [_mixerNode setInputVolume:0 value:1];
                    }
                }
                //使用外放
                else {
                    //人声+伴奏 mixer：关闭
                    [_mixerNode setInputVolume:0 value:0];
                }
                
                break;
            }
            case AVAudioSessionRouteChangeReasonCategoryChange:
            case AVAudioSessionRouteChangeReasonOverride:
            case AVAudioSessionRouteChangeReasonWakeFromSleep:
            case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            case AVAudioSessionRouteChangeReasonRouteConfigurationChange:
                
                break;
                
            default:
                break;
        }
        
        
    }
}
@end
