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

@end
