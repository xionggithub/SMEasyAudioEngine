//
//  SMEasyAudioPeakLimiterNode.m
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioPeakLimiterNode.h"

@implementation SMEasyAudioPeakLimiterNode
- (instancetype)init{
    self = [super init];
    if (self) {
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_Effect;
        description.componentSubType = kAudioUnitSubType_PeakLimiter;
        self.acdescription = description;
    }
    return self;
}

#pragma mark - Getters

- (double)attackTime {
    return [self getNodeParameterWithInID:kLimiterParam_AttackTime];
}

- (double)decayTime {
    return [self getNodeParameterWithInID:kLimiterParam_DecayTime];
}

- (double)preGain {
    return [self getNodeParameterWithInID:kLimiterParam_PreGain];
}


#pragma mark - Setters

- (void)setAttackTime:(double)attackTime {
    [self setNodeParameterWithInID:kLimiterParam_AttackTime inValue:(AudioUnitParameterValue)attackTime];
}

- (void)setDecayTime:(double)decayTime {
    [self setNodeParameterWithInID:kLimiterParam_DecayTime inValue:(AudioUnitParameterValue)decayTime];
}

- (void)setPreGain:(double)preGain {
    [self setNodeParameterWithInID:kLimiterParam_PreGain inValue:(AudioUnitParameterValue)preGain];
}

@end
