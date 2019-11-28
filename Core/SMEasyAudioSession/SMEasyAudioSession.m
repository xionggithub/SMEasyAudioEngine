//
//  SMEasyAudioSession.m
//  SMAudioEngine
//
//  Created by 熊先提 on 2017/8/20.
//  Copyright © 2017年 熊先提. All rights reserved.
//

#import "SMEasyAudioSession.h"
#import "AVAudioSession+RouteUtils.h"
#import <UIKit/UIKit.h>
#define iOS10_Later ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0)

const NSTimeInterval AUSAudioSessionLatency_Background = 0.0929;
const NSTimeInterval AUSAudioSessionLatency_Default = 0.0232;
const NSTimeInterval AUSAudioSessionLatency_LowLatency = 0.0058;
@implementation SMEasyAudioSession
@synthesize category = _category;
+ (SMEasyAudioSession *)sharedInstance
{
    static SMEasyAudioSession *instance = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SMEasyAudioSession alloc] init];
    });
    return instance;
}

- (id)init
{
    if((self = [super init]))
    {
        _preferredSampleRate = _currentSampleRate = 48000;
        _audioSession = [AVAudioSession sharedInstance];
        [self addAudioSessionRouteChangeNotification];
        [self updateHeadphoneStatus:[self audioRoute]];
    }
    return self;
}

- (void)dealloc{
    [self removeAudioSessionRouteChangeNotification];
}
- (NSString *)category{
    _category = [[AVAudioSession sharedInstance] category];
    return _category;
}
- (void)setCategory:(NSString *)category
{
    _category = category;
    
    NSError *error = nil;
    if ([AVAudioSessionCategoryPlayback isEqualToString:category]) {
        [self.audioSession setCategory:category
                           withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                 error:&error];
    } else if ([AVAudioSessionCategoryPlayAndRecord isEqualToString: category]){
        if(iOS10_Later){
            [self.audioSession setCategory:category
                               withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker|AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowBluetoothA2DP
                                     error:&error];
        }else{
            [self.audioSession setCategory:category
                               withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker|AVAudioSessionCategoryOptionAllowBluetooth
                                     error:&error];
        }
    } else {
        [self.audioSession setCategory: category error:&error];
    }
}

- (void)setActive:(BOOL)active
{
    _active = active;
    
    NSError *error = nil;
    
    if(![self.audioSession setPreferredSampleRate:self.preferredSampleRate error:&error])
        NSLog(@"Error when setting sample rate on audio session: %@", error.localizedDescription);
    
    if(![self.audioSession setActive:_active error:&error])
        NSLog(@"Error when setting active state of audio session: %@", error.localizedDescription);
    
    _currentSampleRate = [self.audioSession sampleRate];
}

- (void)setPreferredLatency:(NSTimeInterval)preferredLatency
{
    _preferredLatency = preferredLatency;
    
    NSError *error = nil;
    if(![self.audioSession setPreferredIOBufferDuration:_preferredLatency error:&error])
        NSLog(@"Error when setting preferred I/O buffer duration");
}

- (void)addRouteChangeListener
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNotificationAudioRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
    [self adjustOnRouteChange];
}

#pragma mark - notification observer

- (void)onNotificationAudioRouteChange:(NSNotification *)sender {
    [self adjustOnRouteChange];
}

- (void)adjustOnRouteChange
{
    AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
    if (currentRoute) {
        if ([[AVAudioSession sharedInstance] usingWiredMicrophone]) {
        } else {
            if (![[AVAudioSession sharedInstance] usingBlueTooth]) {
                [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
            }
        }
    }
}


// 尽量少关注这些变化
// Session设置完毕之后, 再添加这些Notification
- (void)addAudioSessionRouteChangeNotification {
    // 防止重复添加(TODO), 是否合适呢?
    [self removeAudioSessionRouteChangeNotification];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioRouteChangedNotification:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
}

// Session使用完毕, 取消这些Notification
- (void)removeAudioSessionRouteChangeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionRouteChangeNotification
                                                  object: nil];
}

-(void)audioRouteChangedNotification:(NSNotification*)notification {
    AVAudioSessionRouteDescription *audioRoute = [self audioRoute];
    // SMLOG_INFO(@"Audio route changed: %@", audioRoute);
    
    
    __weak typeof(self)weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        [weakSelf updateHeadphoneStatus: audioRoute];
        
        // check if new audio route is handset or speaker
        AVAudioSessionPortDescription *outputDesc = audioRoute.outputs.firstObject;
        AVAudioSessionRouteChangeReason changeReason =
        [(NSNumber*)notification.userInfo[AVAudioSessionRouteChangeReasonKey] unsignedIntegerValue];
        // 如果拔下耳机
        if ( [outputDesc.portType isEqualToString:AVAudioSessionPortBuiltInReceiver]
            || [outputDesc.portType isEqualToString:AVAudioSessionPortBuiltInSpeaker] ) {
            // prevent a pause when resuming if the route is changing from built in receiver to speaker
            // 这两个有什么区别: build in receiver vs. speaker
            // 下面的话比较绕口
            // we would have already called switchedToDeviceSpeakers when it switched to built in receiver
            // this can happen when starting the app with headphones plugged in then unplugging during your
            // first performance on iOS 8
            // we can assume it was built in receiver if the change reason is
            // AVAudioSessionRouteChangeReasonCategoryChange
            if ( !(changeReason == AVAudioSessionRouteChangeReasonCategoryChange &&
                   [outputDesc.portType isEqualToString:AVAudioSessionPortBuiltInSpeaker]) ) {
            }
        }
        
        if (AVAudioSessionRouteChangeReasonNewDeviceAvailable == changeReason ||       // 插入耳机
            AVAudioSessionRouteChangeReasonOldDeviceUnavailable == changeReason) { // 拔出耳机
            
        }
    }];
}
- (void)updateHeadphoneStatus:(AVAudioSessionRouteDescription *)audioRoute {
    if (!audioRoute) {
        audioRoute = [AVAudioSession sharedInstance].currentRoute;
    }
    // 是否有外部输入输出
    NSString* inputPortType = audioRoute.inputs.firstObject.portType;
    NSString* outputPortType = audioRoute.outputs.firstObject.portType;
    
    BOOL hasExtInput = [AVAudioSessionPortHeadsetMic isEqualToString: inputPortType];
    BOOL hasExtOutput = [AVAudioSessionPortHeadphones isEqualToString: outputPortType];
    _hasHeadset = hasExtInput && hasExtOutput;
    _hasHeadphone = !hasExtInput && hasExtOutput;
    _isBuildinPhone = [AVAudioSessionPortBuiltInReceiver isEqualToString: outputPortType]
    || [AVAudioSessionPortBuiltInSpeaker isEqualToString: outputPortType];
}

-(AVAudioSessionRouteDescription*)audioRoute {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionRouteDescription *currentRoute = audioSession.currentRoute;
    return currentRoute;
}

@end
