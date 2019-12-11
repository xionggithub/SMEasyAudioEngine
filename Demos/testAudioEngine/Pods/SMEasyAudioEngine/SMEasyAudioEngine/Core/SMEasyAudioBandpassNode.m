//
//  SMEasyAudioBandpassNode.m
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioBandpassNode.h"

@implementation SMEasyAudioBandpassNode

- (instancetype)init{
    self = [super init];
    if (self) {
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_Effect;
        description.componentSubType = kAudioUnitSubType_BandPassFilter;
        self.acdescription = description;
    }
    return self;
}


#pragma mark - Getters

- (double)centerFrequency {
    return [self getNodeParameterWithInID:kBandpassParam_CenterFrequency];
}

- (double)bandwidth {
    return [self getNodeParameterWithInID:kBandpassParam_Bandwidth];
}

#pragma mark - Setters

- (void)setCenterFrequency:(double)centerFrequency {
    [self setNodeParameterWithInID:kBandpassParam_CenterFrequency inValue:(AudioUnitParameterValue)centerFrequency];
}

- (void)setBandwidth:(double)bandwidth {
    [self setNodeParameterWithInID:kBandpassParam_Bandwidth inValue:(AudioUnitParameterValue)bandwidth];
}
@end
