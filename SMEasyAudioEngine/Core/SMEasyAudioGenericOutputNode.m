//
//  SMEasyAudioPullNode.m
//  AudioRenderTest
//
//  Created by xiaoxiong on 2019/11/27.
//  Copyright © 2019 xiaoxiong. All rights reserved.
//

#import "SMEasyAudioGenericOutputNode.h"
#import "SMAudioBufferListUtilities.h"
#import "SMCircleAudioBuffer.h"

@implementation SMEasyAudioGenericOutputNode
- (instancetype)init{
    self = [super init];
    if (self) {
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_Output;
        description.componentSubType = kAudioUnitSubType_GenericOutput;
        self.acdescription = description;
    }
    return self;
}

//转换成RLRLRLRL方式输出

- (void)resetAudioUnit{
    [super resetAudioUnit];
    AudioStreamBasicDescription outputElementInputStreamFormat = [self inputStreamFormat];
    AudioStreamBasicDescription outputElementOutputStreamFormat = [self outputStreamFormat];
    
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, outputElement, &outputElementInputStreamFormat, sizeof(outputElementInputStreamFormat));
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, outputElement, &outputElementOutputStreamFormat, sizeof(outputElementOutputStreamFormat));
    
}
- (void)prepareForRender{
    [super prepareForRender];
}

- (BOOL)startOfflineRender
{
    NSLog(@"离线渲染线程 ==>%@",[NSThread currentThread]);
    AudioStreamBasicDescription outputASDB;
    UInt32  outputASDBSize = sizeof(outputASDB);
    AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &outputASDB,&outputASDBSize);
    if (outputASDB.mBitsPerChannel == 0) {
        return NO;
    }
    if (self.totalFrames <=0) {
        return NO;
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSUInteger totalFrames = self.totalFrames;
        NSUInteger minFrameToRead = 1024;
        AudioUnitRenderActionFlags flags = 0;
        AudioTimeStamp inTimeStamp;
        memset(&inTimeStamp, 0, sizeof(inTimeStamp));
        inTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
        inTimeStamp.mSampleTime = 0;
        AudioStreamBasicDescription audioFormat = [self outputStreamFormat];
        AudioBufferList *bufferlist = SMAudioBufferListCreateWithFormat(audioFormat, (int)minFrameToRead);
        NSError *error = nil;
        while (totalFrames) {
            
            UInt32 frameToRead = (UInt32)MIN(totalFrames, minFrameToRead);
            
            OSStatus status = AudioUnitRender(self.audioUnit,&flags,&inTimeStamp,0,frameToRead,bufferlist);
            if (status != noErr) {
                NSLog(@"出错了 即将结束");
                error = [NSError errorWithDomain:@"111" code:-1 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"渲染出错  错误码 %d",(int)status]}];
                break;
            }
            
            inTimeStamp.mSampleTime += frameToRead;
            
            totalFrames -= frameToRead;
            if (self.offlineRenderProgressBlock) {
                CGFloat progress = (self.totalFrames - totalFrames)/(self.totalFrames*1.0f);
                self.offlineRenderProgressBlock(progress);
            }
        }
        // 释放内存
        SMAudioBufferListFree(bufferlist);
        bufferlist = nil;
        NSLog(@"渲染线程结束");
        if (self.offlineRenderCompleteBlock) {
            self.offlineRenderCompleteBlock(error);
        }
    });
    return YES;
}

@end
