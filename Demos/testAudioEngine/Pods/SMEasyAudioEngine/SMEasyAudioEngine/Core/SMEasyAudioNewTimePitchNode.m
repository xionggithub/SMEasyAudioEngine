//
//  SMEasyAudioNewTimePitchNode.m
//  testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//  Copyright © 2019 xiaoxiong. All rights reserved.
//

#import "SMEasyAudioNewTimePitchNode.h"

@implementation SMEasyAudioNewTimePitchNode
- (instancetype)init{
    self = [super init];
    if (self) {
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_FormatConverter;
        description.componentSubType = kAudioUnitSubType_NewTimePitch;
        self.acdescription = description;
    }
    return self;
}


#pragma mark - Getters

- (double)rate {
    return [self getNodeParameterWithInID:kNewTimePitchParam_Rate];
}

- (double)pitch {
    return [self getNodeParameterWithInID:kNewTimePitchParam_Pitch];
}

- (double)overlap {
    return [self getNodeParameterWithInID:kNewTimePitchParam_Overlap];
}

- (BOOL)enablePeakLocking {
    return [self getNodeParameterWithInID:kNewTimePitchParam_EnablePeakLocking];
}


#pragma mark - Setters

- (void)setRate:(double)rate {
    [self setNodeParameterWithInID:kNewTimePitchParam_Rate inValue:(AudioUnitParameterValue)rate];
}

- (void)setPitch:(double)pitch {
    [self setNodeParameterWithInID:kNewTimePitchParam_Pitch inValue:(AudioUnitParameterValue)pitch];
}

- (void)setOverlap:(double)overlap {
    [self setNodeParameterWithInID:kNewTimePitchParam_Overlap inValue:(AudioUnitParameterValue)overlap];
}

- (void)setEnablePeakLocking:(BOOL)enablePeakLocking {
    [self setNodeParameterWithInID:kNewTimePitchParam_EnablePeakLocking inValue:(AudioUnitParameterValue)enablePeakLocking];
}
@end
