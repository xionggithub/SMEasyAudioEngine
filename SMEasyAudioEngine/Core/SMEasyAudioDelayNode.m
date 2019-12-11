//
//  SMEasyAudioDelayNode.m
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioDelayNode.h"

@implementation SMEasyAudioDelayNode

- (instancetype)init{
    self = [super init];
    if (self) {
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_Effect;
        description.componentSubType = kAudioUnitSubType_Delay;
        self.acdescription = description;
    }
    return self;
}

#pragma mark - Getters

- (double)wetDryMix {
    return [self getNodeParameterWithInID:kDelayParam_WetDryMix];
}

- (double)delayTime {
    return [self getNodeParameterWithInID:kDelayParam_DelayTime];
}

- (double)feedback {
    return [self getNodeParameterWithInID:kDelayParam_Feedback];
}

- (double)lopassCutoff {
    return [self getNodeParameterWithInID:kDelayParam_LopassCutoff];
}


#pragma mark - Setters

- (void)setWetDryMix:(double)wetDryMix {
    [self setNodeParameterWithInID:kDelayParam_WetDryMix inValue:(AudioUnitParameterValue)wetDryMix];
}

- (void)setDelayTime:(double)delayTime {
    [self setNodeParameterWithInID:kDelayParam_DelayTime inValue:(AudioUnitParameterValue)delayTime];
}

- (void)setFeedback:(double)feedback {
    [self setNodeParameterWithInID:kDelayParam_Feedback inValue:(AudioUnitParameterValue)feedback];
}

- (void)setLopassCutoff:(double)lopassCutoff {
    [self setNodeParameterWithInID:kDelayParam_LopassCutoff inValue:(AudioUnitParameterValue)lopassCutoff];
}

@end
