//
//  SMEasyAudioHighShelfNode.m
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioHighShelfNode.h"

@implementation SMEasyAudioHighShelfNode

- (instancetype)init{
    self = [super init];
    if (self) {
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_Effect;
        description.componentSubType = kAudioUnitSubType_HighShelfFilter;
        self.acdescription = description;
    }
    return self;
}

#pragma mark - Getters

- (double)cutoffFrequency {
    return [self getNodeParameterWithInID:kAULowShelfParam_CutoffFrequency];
}

- (double)gain {
    return [self getNodeParameterWithInID:kAULowShelfParam_Gain];
}


#pragma mark - Setters

- (void)setCutoffFrequency:(double)cutoffFrequency {
    [self setNodeParameterWithInID:kAULowShelfParam_CutoffFrequency inValue:(AudioUnitParameterValue)cutoffFrequency];
}

- (void)setGain:(double)gain {
    [self setNodeParameterWithInID:kAULowShelfParam_Gain inValue:(AudioUnitParameterValue)gain];
}
@end
