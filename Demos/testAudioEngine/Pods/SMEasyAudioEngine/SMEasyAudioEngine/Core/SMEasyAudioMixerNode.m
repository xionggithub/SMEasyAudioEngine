//
//  SMEasyAudioMixerNode.m
//  SMAudioEngine
//
//  Created by 熊先提 on 2017/8/20.
//  Copyright © 2017年 熊先提. All rights reserved.
//

#import "SMEasyAudioMixerNode.h"

@interface SMEasyAudioMixerNode ()
@property (nonatomic, assign)UInt32 mixerElementCount;
@end
@implementation SMEasyAudioMixerNode
@synthesize enableMetering = _enableMetering;
- (instancetype)initWithMixerElementCount:(UInt32)mixerElementCount{
    self = [super init];
    if (self) {
        NSAssert(mixerElementCount > 0, @"mixerElementCount must more than one");
        self.mixerElementCount = mixerElementCount;
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_Mixer;
        description.componentSubType = kAudioUnitSubType_MultiChannelMixer;
        self.acdescription = description;
    }
    return self;
}


- (void)resetAudioUnit{
    [super resetAudioUnit];
    UInt32 mixerElementCount1 = 0;
    UInt32 size = sizeof(mixerElementCount1);
    OSStatus status1 = AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0,
                                            &mixerElementCount1, &size);
    NSLog(@"%d %d",mixerElementCount1,status1);
    Float64           outSampleRate = [SMEasyAudioConstants getSampleRate];
    
    OSStatus status = noErr;
    UInt32 mixerElementCount = self.mixerElementCount;
    status = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0,
                                  &mixerElementCount, sizeof(mixerElementCount));
    CheckStatus(status, @"Could not set element count on mixer unit input scope", YES);
    status = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_SampleRate, kAudioUnitScope_Output, 0,
                                  &outSampleRate, sizeof(outSampleRate));
    CheckStatus(status, @"Could not set sample rate on mixer unit output scope", YES);
    
    AudioStreamBasicDescription outputElementInputStreamFormat = [self inputStreamFormat];
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, outputElement, &outputElementInputStreamFormat, sizeof(outputElementInputStreamFormat));
    
    AudioStreamBasicDescription outputElementOutputStreamFormat = [self outputStreamFormat];
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, outputElement, &outputElementOutputStreamFormat, sizeof(outputElementOutputStreamFormat));
    
    //如果需要获取p能量谱 先开启metering mode
    if (self.enableMetering) {
        UInt32 meteringMode = 1;
        [self setMeteringMode:meteringMode];
    }
}
- (void)prepareForRender{
    [super prepareForRender];
}


- (void)setInputVolume:(AudioUnitElement)inputNum value:(AudioUnitParameterValue)value
{
    [self setNodeParameterWithInID:kMultiChannelMixerParam_Volume inScope:kAudioUnitScope_Input inElement:inputNum inValue:value inBufferOffsetInFrames:0];
}
- (AudioUnitParameterValue)getInputVolume:(AudioUnitElement)inputNum
{
   return [self getNodeParameterWithInID:kMultiChannelMixerParam_Volume inScope:kAudioUnitScope_Input inElement:inputNum];
}

- (void)setEnableMetering:(BOOL)enableMetering{
    _enableMetering = enableMetering;
    if (self.audioUnit) {
        UInt32 meteringMode = _enableMetering?1:0;
        [self setMeteringMode:meteringMode];
    }
}
- (BOOL)enableMetering{
    return  _enableMetering;
}

- (void)setMeteringMode:(UInt32)meteringMode{
    OSStatus status = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_MeteringMode, kAudioUnitScope_Input, 0, &meteringMode, sizeof(meteringMode));
    CheckStatus(status, [NSString stringWithFormat:@"set meteringMode  %d  fail",meteringMode], YES);
}

- (BOOL)enableMeteringMode{
    UInt32 meteringMode = 0;
    UInt32 size = sizeof(meteringMode);
    OSStatus status  = AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_MeteringMode, kAudioUnitScope_Input, 0, &meteringMode, &size);
    if (status == noErr) {
        if (meteringMode == 1) {
            return YES;
        }else{
            return NO;
        }
    }else{
        return NO;
    }
}

- (CGFloat)averagePowerForChannel:(UInt32)channel{
    if (![self enableMeteringMode]) {
        NSLog(@"error! you should enable metering before call %s.",__func__);
        return 0;
    }
    AudioUnitParameterValue averagePowerValue = [self getNodeParameterWithInID:kMultiChannelMixerParam_PreAveragePower inScope:kAudioUnitScope_Input inElement:channel];
    return (CGFloat)averagePowerValue;
}
- (CGFloat)peakPowerForChannel:(UInt32)channel{
    if (![self enableMeteringMode]) {
        NSLog(@"error! you should enable metering before call %s.",__func__);
        return 0;
    }
    AudioUnitParameterValue peakPowerValue = [self getNodeParameterWithInID:kMultiChannelMixerParam_PrePeakHoldLevel inScope:kAudioUnitScope_Input inElement:channel];
    return (CGFloat)peakPowerValue;
}

- (void)setNodeParameterWithInID:(AudioUnitParameterID)inID
                         inScope:(AudioUnitScope)inScope
                       inElement:(AudioUnitElement)inElement
                         inValue:(AudioUnitParameterValue)inValue
          inBufferOffsetInFrames:(UInt32)inBufferOffsetInFrames
{
    OSStatus status;
    status = AudioUnitSetParameter(self.audioUnit, inID, inScope, inElement, inValue, inBufferOffsetInFrames);
    CheckStatus(status, [NSString stringWithFormat:@"set parameter  %d  fail",inID], YES);
}

- (AudioUnitParameterValue)getNodeParameterWithInID:(AudioUnitParameterID)inID
                         inScope:(AudioUnitScope)inScope
                       inElement:(AudioUnitElement)inElement
{
    AudioUnitParameterValue value;
    OSStatus status;
    status = AudioUnitGetParameter(self.audioUnit, inID, inScope, inElement, &value);
    CheckStatus(status, [NSString stringWithFormat:@"get parameter  %d  fail",inID], YES);
    return value;
}
@end
