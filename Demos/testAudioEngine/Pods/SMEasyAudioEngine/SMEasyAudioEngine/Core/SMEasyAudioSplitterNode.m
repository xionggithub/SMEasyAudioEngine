//
//  SMEasyAudioSplitterNode.m
//  testForAudioConvert
//
//  Created by xiaoxiong on 2017/8/31.
//  Copyright © 2017年 xiaoxiong. All rights reserved.
//

#import "SMEasyAudioSplitterNode.h"

@implementation SMEasyAudioSplitterNode
- (instancetype)init{
    self = [super init];
    if (self) {
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_FormatConverter;
        description.componentSubType = kAudioUnitSubType_Splitter;
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
@end
