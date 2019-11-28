//
//  SMEasyAudioConstants.h
//  SMAudioEngine
//
//  Created by xiaoxiong on 2017/8/21.
//  Copyright © 2017年 熊先提. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreGraphics/CoreGraphics.h>

@interface SMEasyAudioConstants : NSObject

FOUNDATION_EXPORT const AudioStreamBasicDescription SMEasyAudioNonInterleavedFloatStereoAudioDescription;

FOUNDATION_EXPORT const AudioStreamBasicDescription SMEasyAudioIsPackedFloatStereoAudioDescription;

FOUNDATION_EXPORT const AudioStreamBasicDescription SMEasyAudioNonInterleavedFloatMonoAudioDescription;

FOUNDATION_EXPORT const AudioStreamBasicDescription  SMEasyAudioNonInterleaved16BitStereoAudioDescription;

FOUNDATION_EXPORT const AudioStreamBasicDescription  SMEasyAudioIsPacked16BitStereoAudioDescription;

//no inter leaved 单buffer 双声道 StarMaker audioDescription
FOUNDATION_EXPORT const AudioStreamBasicDescription  SMEasyAudioNonInterleavedFloatStereoAndMonoAudioDescription;

FOUNDATION_EXPORT const int       SMEasyAudioNodeMaximumFramesPerSlice;

FOUNDATION_EXPORT ExtAudioFileRef SMEasyAudioEngineM4aExtAudioFileCreate(NSURL * url, double sampleRate, int channelCount,NSError ** error, OSStatus lastStatus);


+ (double) getSampleRate;
@end
