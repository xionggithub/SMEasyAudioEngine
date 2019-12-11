//
//  SMEasyAudioVarispeedNode.m
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioVarispeedNode.h"

@implementation SMEasyAudioVarispeedNode
- (instancetype)init{
    self = [super init];
    if (self) {
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_FormatConverter;
        description.componentSubType = kAudioUnitSubType_Varispeed;
        self.acdescription = description;
    }
    return self;
}

#pragma mark - Getters

- (double)playbackRate {
    return [self getNodeParameterWithInID:kVarispeedParam_PlaybackRate];
}

- (double)playbackCents {
    return [self getNodeParameterWithInID:kVarispeedParam_PlaybackCents];
}


#pragma mark - Setters

- (void)setPlaybackRate:(double)playbackRate {
    [self setNodeParameterWithInID:kVarispeedParam_PlaybackRate inValue:(AudioUnitParameterValue)playbackRate];
}

- (void)setPlaybackCents:(double)playbackCents {
    [self setNodeParameterWithInID:kVarispeedParam_PlaybackCents inValue:(AudioUnitParameterValue)playbackCents];
}
@end
