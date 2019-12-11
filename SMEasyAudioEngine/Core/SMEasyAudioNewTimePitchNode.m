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


- (void)resetAudioUnit{
    [super resetAudioUnit];
    
    AudioStreamBasicDescription outputElementInputStreamFormat = [self inputStreamFormat];
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, outputElement, &outputElementInputStreamFormat, sizeof(outputElementInputStreamFormat));
    
    
    AudioStreamBasicDescription outputElementOutputStreamFormat = [self outputStreamFormat];
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, outputElement, &outputElementOutputStreamFormat, sizeof(outputElementOutputStreamFormat));
}
- (void)prepareForRender{
    [super prepareForRender];
}
- (void)setNewTimePitch:(Float32)pitchShift{
    OSStatus status = AudioUnitSetParameter(self.audioUnit, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, pitchShift, 0);
    CheckStatus(status, [NSString stringWithFormat:@"set Parameter NewTimePitch  %ld  fail",pitchShift], YES);
}
- (Float32)getNewTimePitch{
    AudioUnitParameterValue pitch;
    OSStatus status = AudioUnitGetParameter(self.audioUnit, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, &pitch);
    CheckStatus(status, @"get Parameter NewTimePitch  fail", YES);
    return pitch;
}
@end
