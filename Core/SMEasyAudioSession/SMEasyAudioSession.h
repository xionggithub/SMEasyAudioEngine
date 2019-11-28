//
//  SMEasyAudioSession.h
//  SMAudioEngine
//
//  Created by 熊先提 on 2017/8/20.
//  Copyright © 2017年 熊先提. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

extern const NSTimeInterval AUSAudioSessionLatency_Background;
extern const NSTimeInterval AUSAudioSessionLatency_Default;
extern const NSTimeInterval AUSAudioSessionLatency_LowLatency;

@interface SMEasyAudioSession : NSObject
+ (SMEasyAudioSession *)sharedInstance;

@property(nonatomic, strong) AVAudioSession *audioSession; // Underlying system audio session
@property(nonatomic, assign) Float64 preferredSampleRate;
@property(nonatomic, assign, readonly) Float64 currentSampleRate;
@property(nonatomic, assign) NSTimeInterval preferredLatency;
@property(nonatomic, assign) BOOL active;
@property(nonatomic, strong) NSString *category;

@property (readonly, nonatomic) BOOL isBuildinPhone; // 是否直接通过手机的speaker/receiver来播放
@property (readonly, nonatomic) BOOL hasHeadset;     // 当前Session是否使用“带麦”耳机, 和AudioSession的Category相关
@property (readonly, nonatomic) BOOL hasHeadphone;   // 当前Session是否使用“不带麦”耳机, 和AudioSession的Category相关
@property (readonly, nonatomic) BOOL hasHeadphoneOrSet; // 当前Session是否使用Headphone 或 Headset, 和AudioSession的Category相关

- (void)addRouteChangeListener;

@end
