//
//  SMEasyAudioReverbNode.m
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioReverbNode.h"

@implementation SMEasyAudioReverbNode



- (instancetype)init{
    self = [super init];
    if (self) {
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_Effect;
        description.componentSubType = kAudioUnitSubType_Reverb2;
        self.acdescription = description;
    }
    return self;
}


- (double)dryWetMix {
    return [self getNodeParameterWithInID:kReverb2Param_DryWetMix];
}

- (double)gain {
    return [self getNodeParameterWithInID:kReverb2Param_Gain];
}

- (double)minDelayTime {
    return [self getNodeParameterWithInID:kReverb2Param_MinDelayTime];
}

- (double)maxDelayTime {
    return [self getNodeParameterWithInID:kReverb2Param_MaxDelayTime];
}

- (double)decayTimeAt0Hz {
    return [self getNodeParameterWithInID:kReverb2Param_DecayTimeAt0Hz];
}

- (double)decayTimeAtNyquist {
    return [self getNodeParameterWithInID:kReverb2Param_DecayTimeAtNyquist];
}

- (double)randomizeReflections {
    return [self getNodeParameterWithInID:kReverb2Param_RandomizeReflections];
}

#pragma mark - Setters

- (void)setDryWetMix:(double)dryWetMix {
    [self setNodeParameterWithInID:kReverb2Param_DryWetMix inValue:(AudioUnitParameterValue)dryWetMix];
}

- (void)setGain:(double)gain {
    [self setNodeParameterWithInID:kReverb2Param_Gain inValue:(AudioUnitParameterValue)gain];
}

- (void)setMinDelayTime:(double)minDelayTime {
    [self setNodeParameterWithInID:kReverb2Param_MinDelayTime inValue:(AudioUnitParameterValue)minDelayTime];
}

- (void)setMaxDelayTime:(double)maxDelayTime {
    [self setNodeParameterWithInID:kReverb2Param_MaxDelayTime inValue:(AudioUnitParameterValue)maxDelayTime];
}

- (void)setDecayTimeAt0Hz:(double)decayTimeAt0Hz {
    [self setNodeParameterWithInID:kReverb2Param_DecayTimeAt0Hz inValue:(AudioUnitParameterValue)decayTimeAt0Hz];
}

- (void)setDecayTimeAtNyquist:(double)decayTimeAtNyquist {
    [self setNodeParameterWithInID:kReverb2Param_DecayTimeAtNyquist inValue:(AudioUnitParameterValue)decayTimeAtNyquist];
}

- (void)setRandomizeReflections:(double)randomizeReflections {
    [self setNodeParameterWithInID:kReverb2Param_RandomizeReflections inValue:(AudioUnitParameterValue)randomizeReflections];
}
@end
