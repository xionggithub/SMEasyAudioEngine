//
//  SMEasyAudioLowPassNode.m
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioLowPassNode.h"

@implementation SMEasyAudioLowPassNode

- (instancetype)init{
    self = [super init];
    if (self) {
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_Effect;
        description.componentSubType = kAudioUnitSubType_LowPassFilter;
        self.acdescription = description;
    }
    return self;
}

#pragma mark - Getters

- (double)cutoffFrequency {
    return [self getNodeParameterWithInID:kLowPassParam_CutoffFrequency];
}

- (double)resonance {
    return [self getNodeParameterWithInID:kLowPassParam_Resonance];
}


#pragma mark - Setters

- (void)setCutoffFrequency:(double)cutoffFrequency {
    [self setNodeParameterWithInID:kLowPassParam_CutoffFrequency inValue:(AudioUnitParameterValue)cutoffFrequency];
}

- (void)setResonance:(double)resonance {
    [self setNodeParameterWithInID:kLowPassParam_Resonance inValue:(AudioUnitParameterValue)resonance];
}

@end
