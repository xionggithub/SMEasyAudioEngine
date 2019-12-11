//
//  SMEasyAudioDynamicsProcessorNode.m
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioDynamicsProcessorNode.h"

@implementation SMEasyAudioDynamicsProcessorNode

- (instancetype)init{
    self = [super init];
    if (self) {
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_Effect;
        description.componentSubType = kAudioUnitSubType_DynamicsProcessor;
        self.acdescription = description;
    }
    return self;
}

#pragma mark - Getters

- (double)threshold {
    return [self getNodeParameterWithInID:kDynamicsProcessorParam_Threshold];
}

- (double)headRoom {
    return [self getNodeParameterWithInID:kDynamicsProcessorParam_HeadRoom];
}

- (double)expansionRatio {
    return [self getNodeParameterWithInID:kDynamicsProcessorParam_ExpansionRatio];
}

- (double)expansionThreshold {
    return [self getNodeParameterWithInID:kDynamicsProcessorParam_ExpansionThreshold];
}

- (double)attackTime {
    return [self getNodeParameterWithInID:kDynamicsProcessorParam_AttackTime];
}

- (double)releaseTime {
    return [self getNodeParameterWithInID:kDynamicsProcessorParam_ReleaseTime];
}

- (double)masterGain {
    return [self getNodeParameterWithInID:kDynamicsProcessorParam_MasterGain];
}

- (double)compressionAmount {
    return [self getNodeParameterWithInID:kDynamicsProcessorParam_CompressionAmount];
}

- (double)inputAmplitude {
    return [self getNodeParameterWithInID:kDynamicsProcessorParam_InputAmplitude];
}

- (double)outputAmplitude {
    return [self getNodeParameterWithInID:kDynamicsProcessorParam_OutputAmplitude];
}


#pragma mark - Setters

- (void)setThreshold:(double)threshold {
    [self setNodeParameterWithInID:kDynamicsProcessorParam_Threshold inValue:(AudioUnitParameterValue)threshold];
}

- (void)setHeadRoom:(double)headRoom {
    [self setNodeParameterWithInID:kDynamicsProcessorParam_HeadRoom inValue:(AudioUnitParameterValue)headRoom];
}

- (void)setExpansionRatio:(double)expansionRatio {
    [self setNodeParameterWithInID:kDynamicsProcessorParam_ExpansionRatio inValue:(AudioUnitParameterValue)expansionRatio];
}

- (void)setExpansionThreshold:(double)expansionThreshold {
    [self setNodeParameterWithInID:kDynamicsProcessorParam_ExpansionThreshold inValue:(AudioUnitParameterValue)expansionThreshold];
}

- (void)setAttackTime:(double)attackTime {
    [self setNodeParameterWithInID:kDynamicsProcessorParam_AttackTime inValue:(AudioUnitParameterValue)attackTime];
}

- (void)setReleaseTime:(double)releaseTime {
    [self setNodeParameterWithInID:kDynamicsProcessorParam_ReleaseTime inValue:(AudioUnitParameterValue)releaseTime];
}

- (void)setMasterGain:(double)masterGain {
    [self setNodeParameterWithInID:kDynamicsProcessorParam_MasterGain inValue:(AudioUnitParameterValue)masterGain];
}

@end
