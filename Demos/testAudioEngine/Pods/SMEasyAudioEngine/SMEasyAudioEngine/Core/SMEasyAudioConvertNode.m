//
//  SMEasyAudioConvertNode.m
//  SMEasyAudioEngine
//
//  Created by xiaoxiong on 2017/8/29.
//  Copyright © 2017年 xiaoxiong. All rights reserved.
//

#import "SMEasyAudioConvertNode.h"

@implementation SMEasyAudioConvertNode

- (instancetype)init{
    self = [super init];
    if (self) {
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_FormatConverter;
        description.componentSubType = kAudioUnitSubType_AUConverter;
        self.acdescription = description;
        
    }
    return self;
}
@end
