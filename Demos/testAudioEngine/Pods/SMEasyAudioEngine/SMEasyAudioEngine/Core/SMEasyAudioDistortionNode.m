//
//  SMEasyAudioDistortionNode.m
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioDistortionNode.h"

@implementation SMEasyAudioDistortionNode

- (instancetype)init{
    self = [super init];
    if (self) {
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_Effect;
        description.componentSubType = kAudioUnitSubType_Distortion;
        self.acdescription = description;
    }
    return self;
}


#pragma mark - Getters

- (double)delay {
    return [self getNodeParameterWithInID:kDistortionParam_Delay];
}

- (double)decay {
    return [self getNodeParameterWithInID:kDistortionParam_Decay];
}

- (double)delayMix {
    return [self getNodeParameterWithInID:kDistortionParam_DelayMix];
}

- (double)decimation {
    return [self getNodeParameterWithInID:kDistortionParam_Decimation];
}

- (double)rounding {
    return [self getNodeParameterWithInID:kDistortionParam_Rounding];
}

- (double)decimationMix {
    return [self getNodeParameterWithInID:kDistortionParam_DecimationMix];
}

- (double)linearTerm {
    return [self getNodeParameterWithInID:kDistortionParam_LinearTerm];
}

- (double)squaredTerm {
    return [self getNodeParameterWithInID:kDistortionParam_SquaredTerm];
}

- (double)cubicTerm {
    return [self getNodeParameterWithInID:kDistortionParam_CubicTerm];
}

- (double)polynomialMix {
    return [self getNodeParameterWithInID:kDistortionParam_PolynomialMix];
}

- (double)ringModFreq1 {
    return [self getNodeParameterWithInID:kDistortionParam_RingModFreq1];
}

- (double)ringModFreq2 {
    return [self getNodeParameterWithInID:kDistortionParam_RingModFreq2];
}

- (double)ringModBalance {
    return [self getNodeParameterWithInID:kDistortionParam_RingModBalance];
}

- (double)ringModMix {
    return [self getNodeParameterWithInID:kDistortionParam_RingModMix];
}

- (double)softClipGain {
    return [self getNodeParameterWithInID:kDistortionParam_SoftClipGain];
}

- (double)finalMix {
    return [self getNodeParameterWithInID:kDistortionParam_FinalMix];
}


#pragma mark - Setters

- (void)setDelay:(double)delay {
    [self setNodeParameterWithInID:kDistortionParam_Delay inValue:(AudioUnitParameterValue)delay];
}

- (void)setDecay:(double)decay {
    [self setNodeParameterWithInID:kDistortionParam_Decay inValue:(AudioUnitParameterValue)decay];
}

- (void)setDelayMix:(double)delayMix {
    [self setNodeParameterWithInID:kDistortionParam_DelayMix inValue:(AudioUnitParameterValue)delayMix];
}

- (void)setDecimation:(double)decimation {
    [self setNodeParameterWithInID:kDistortionParam_Decimation inValue:(AudioUnitParameterValue)decimation];
}

- (void)setRounding:(double)rounding {
    [self setNodeParameterWithInID:kDistortionParam_Rounding inValue:(AudioUnitParameterValue)rounding];
}

- (void)setDecimationMix:(double)decimationMix {
    [self setNodeParameterWithInID:kDistortionParam_DecimationMix inValue:(AudioUnitParameterValue)decimationMix];
}

- (void)setLinearTerm:(double)linearTerm {
    [self setNodeParameterWithInID:kDistortionParam_LinearTerm inValue:(AudioUnitParameterValue)linearTerm];
}

- (void)setSquaredTerm:(double)squaredTerm {
    [self setNodeParameterWithInID:kDistortionParam_SquaredTerm inValue:(AudioUnitParameterValue)squaredTerm];
}

- (void)setCubicTerm:(double)cubicTerm {
    [self setNodeParameterWithInID:kDistortionParam_CubicTerm inValue:(AudioUnitParameterValue)cubicTerm];
}

- (void)setPolynomialMix:(double)polynomialMix {
    [self setNodeParameterWithInID:kDistortionParam_PolynomialMix inValue:(AudioUnitParameterValue)polynomialMix];
}

- (void)setRingModFreq1:(double)ringModFreq1 {
    [self setNodeParameterWithInID:kDistortionParam_RingModFreq1 inValue:(AudioUnitParameterValue)ringModFreq1];
}

- (void)setRingModFreq2:(double)ringModFreq2 {
    [self setNodeParameterWithInID:kDistortionParam_RingModFreq2 inValue:(AudioUnitParameterValue)ringModFreq2];
}

- (void)setRingModBalance:(double)ringModBalance {
    [self setNodeParameterWithInID:kDistortionParam_RingModBalance inValue:(AudioUnitParameterValue)ringModBalance];
}

- (void)setRingModMix:(double)ringModMix {
    [self setNodeParameterWithInID:kDistortionParam_RingModMix inValue:(AudioUnitParameterValue)ringModMix];
}

- (void)setSoftClipGain:(double)softClipGain {
    [self setNodeParameterWithInID:kDistortionParam_SoftClipGain inValue:(AudioUnitParameterValue)softClipGain];
}

- (void)setFinalMix:(double)finalMix {
    [self setNodeParameterWithInID:kDistortionParam_FinalMix inValue:(AudioUnitParameterValue)finalMix];
}
@end
