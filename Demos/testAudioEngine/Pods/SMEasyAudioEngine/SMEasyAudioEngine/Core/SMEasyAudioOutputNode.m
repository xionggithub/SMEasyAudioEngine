//
//  SMEasyAudioOutputNode.m
//  SMEasyAudioEngine
//
//  Created by xiaoxiong on 2017/8/26.
//  Copyright © 2017年 xiaoxiong. All rights reserved.
//

#import "SMEasyAudioOutputNode.h"
#import "SMAudioBufferListUtilities.h"

@implementation SMEasyAudioOutputNode
{
    dispatch_queue_t _outputAudioQueue;
}
- (instancetype)init{
    self = [super init];
    if (self) {
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_FormatConverter;
        description.componentSubType = kAudioUnitSubType_AUConverter;
        self.acdescription = description;
        self.nodeCustomProcessCallBack = &outPutAudioCallback;
        _outputAudioQueue = dispatch_queue_create("SM_Audio_Output_Queue", DISPATCH_QUEUE_SERIAL);
        
    }
    return self;
}


- (void)dealloc{
    _outputAudioQueue = nil;
}
static OSStatus outPutAudioCallback(void *inRefCon, const AudioTimeStamp *inTimeStamp, const UInt32 inNumberFrames, AudioBufferList *ioData)
{
    OSStatus result = noErr;
    __unsafe_unretained SMEasyAudioOutputNode *self = (__bridge SMEasyAudioOutputNode *)inRefCon;
    
    //拷贝数据 此处待优化 需要利用循环buffer 防止存储空间碎片化
    __block AudioBufferList *abl = SMAudioBufferListCopy(ioData);
    __block AudioTimeStamp audioTime = {
        .mSampleTime = inTimeStamp->mSampleTime,
        .mHostTime   = inTimeStamp->mHostTime,
        .mRateScalar = inTimeStamp->mRateScalar,
        .mReserved = inTimeStamp->mReserved,
        .mWordClockTime = inTimeStamp->mWordClockTime,
        .mSMPTETime = inTimeStamp->mSMPTETime,
        .mFlags = inTimeStamp->mFlags
    };
    dispatch_async(self->_outputAudioQueue, ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioOutput:frame:audioTime:)]) {
            [self.delegate audioOutput:abl frame:inNumberFrames audioTime:&audioTime];
        }
    });
    return result;
}
@end
