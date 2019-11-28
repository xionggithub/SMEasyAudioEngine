//
//  SMEasyAudioIONode.m
//  SMAudioEngine
//
//  Created by 熊先提 on 2017/8/20.
//  Copyright © 2017年 熊先提. All rights reserved.
//

#import "SMEasyAudioIONode.h"


@implementation SMEasyAudioIONode
- (instancetype)init{
    self = [super init];
    if (self) {
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_Output;
        description.componentSubType = kAudioUnitSubType_RemoteIO;
        self.acdescription = description;
        self.enableInput = YES;
    }
    return self;
}

- (void) setAudioUnitStreamFormat:(AudioStreamBasicDescription) inputElementFormat outputElementFormat:(AudioStreamBasicDescription)outputElementFormat
{
    OSStatus status = noErr;
    status = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, inputElement,
                                  &inputElementFormat, sizeof(inputElementFormat));
    CheckStatus(status, @"Could not set stream format on I/O unit output scope", YES);
    
    status = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, outputElement,
                         &outputElementFormat, sizeof(outputElementFormat));
    CheckStatus(status, @"Could not set stream format on I/O unit output scope", YES);
}

- (void)resetAudioUnit{
    [super resetAudioUnit];
//    AudioUnitUninitialize(self.audioUnit);
//    AudioUnitInitialize(self.audioUnit);
    AudioUnitReset(self.audioUnit, kAudioUnitScope_Input, inputElement);
    OSStatus status = noErr;
    AudioStreamBasicDescription inputElementOutputStreamFormat = [self outputStreamFormat];
    status = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, inputElement,
                                  &inputElementOutputStreamFormat, sizeof(inputElementOutputStreamFormat));
    CheckStatus(status, @"Could not set stream format on I/O unit output scope", YES);
    if (self.enableInput) {
        status = noErr;
        UInt32 enableIO = 1;
        status = AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, inputElement,
                                      &enableIO, sizeof(enableIO));
        CheckStatus(status, @"Could not enable I/O on I/O unit input scope", YES);
        
        UInt32 maximumFramesPerSlice = SMEasyAudioNodeMaximumFramesPerSlice;
        AudioUnitSetProperty (
                              self.audioUnit,
                              kAudioUnitProperty_MaximumFramesPerSlice,
                              kAudioUnitScope_Global,
                              0,
                              &maximumFramesPerSlice,
                              sizeof (maximumFramesPerSlice)
                              );
        
        AudioStreamBasicDescription outputElementInputStreamFormat = [self inputStreamFormat];
        AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, outputElement, &outputElementInputStreamFormat, sizeof(outputElementInputStreamFormat));
    }
}
- (void)prepareForRender{
    [super prepareForRender];
}

@end
