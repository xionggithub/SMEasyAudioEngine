//
//  SMEasyAudioParametricEQNode.m
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioParametricEQNode.h"

@implementation SMEasyAudioParametricEQNode
- (instancetype)init{
    self = [super init];
    if (self) {
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_Effect;
        description.componentSubType = kAudioUnitSubType_ParametricEQ;
        self.acdescription = description;
    }
    return self;
}

#pragma mark - Getters

- (double)centerFrequency {
    return [self getNodeParameterWithInID:kParametricEQParam_CenterFreq];
}

- (double)qFactor {
    return [self getNodeParameterWithInID:kParametricEQParam_Q];
}

- (double)gain {
    return [self getNodeParameterWithInID:kParametricEQParam_Gain];
}


#pragma mark - Setters

- (void)setCenterFrequency:(double)centerFrequency {
    [self setNodeParameterWithInID:kParametricEQParam_CenterFreq inValue:(AudioUnitParameterValue)centerFrequency];
}

- (void)setQFactor:(double)qFactor {
    [self setNodeParameterWithInID:kParametricEQParam_Q inValue:(AudioUnitParameterValue)qFactor];
}

- (void)setGain:(double)gain {
    [self setNodeParameterWithInID:kParametricEQParam_Gain inValue:(AudioUnitParameterValue)gain];
}
@end
