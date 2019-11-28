//
//  SMEasyAudioMixerNode.h
//  SMAudioEngine
//
//  Created by 熊先提 on 2017/8/20.
//  Copyright © 2017年 熊先提. All rights reserved.
//

#import "SMEasyAudioNode.h"

@interface SMEasyAudioMixerNode : SMEasyAudioNode
//if enable then you can read follow parameters AveragePower and PeakPower
@property (nonatomic, assign) BOOL enableMetering;
- (instancetype)initWithMixerElementCount:(UInt32)mixerElementCount;
- (void)setInputVolume:(AudioUnitElement)inputNum value:(AudioUnitParameterValue)value;
- (AudioUnitParameterValue)getInputVolume:(AudioUnitElement)inputNum;

//get input channel power
- (CGFloat)averagePowerForChannel:(UInt32)channel;
- (CGFloat)peakPowerForChannel:(UInt32)channel;
@end
