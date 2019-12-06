//
//  SMEasyAudioNode.m
//  SMAudioEngine
//
//  Created by 熊先提 on 2017/8/20.
//  Copyright © 2017年 熊先提. All rights reserved.
//

#import "SMEasyAudioNode.h"
#import <CoreAudio/CoreAudioTypes.h>

const AudioUnitElement inputElement = 1;
const AudioUnitElement outputElement = 0;

@implementation SMEasyAudioFormat

@end

@implementation SMEasyAudioNode
@synthesize inputStreamFormat = _inputStreamFormat;
@synthesize outputStreamFormat = _outputStreamFormat;

//format
//LLLLLL
//RRRRRR
//SMEasyAudioNonInterleavedFloatStereoAudioDescription

//format
//LRLRLRLRLRLR
//SMEasyAudioIsPackedFloatStereoAudioDescription

- (void)setInputStreamFormat:(AudioStreamBasicDescription)inputStreamFormat{
    _inputStreamFormat = inputStreamFormat;
}
- (void)setOutputStreamFormat:(AudioStreamBasicDescription)outputStreamFormat{
    _outputStreamFormat = outputStreamFormat;
}
- (AudioStreamBasicDescription)inputStreamFormat{
    if (_inputStreamFormat.mSampleRate > 0) {
        return _inputStreamFormat;
    }else{
        AudioStreamBasicDescription desc = SMEasyAudioNonInterleavedFloatStereoAudioDescription;
        desc.mSampleRate = [SMEasyAudioConstants getSampleRate];
        return desc;
    }
}
- (AudioStreamBasicDescription)outputStreamFormat{
    if (_outputStreamFormat.mSampleRate > 0) {
        return _outputStreamFormat;
    }else{
        AudioStreamBasicDescription desc = SMEasyAudioNonInterleavedFloatStereoAudioDescription;
        desc.mSampleRate = [SMEasyAudioConstants getSampleRate];
        return desc;
    }
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.nodeBaseRendersCallBack = &renderCallBack;
        self.nodeCustomProcessCallBack = NULL;
        bzero(&_inputStreamFormat, sizeof(_inputStreamFormat));
        bzero(&_outputStreamFormat, sizeof(_outputStreamFormat));
    }
    return self;
}
- (BOOL)running{
    if ( !_audioUnit ) return NO;
    UInt32 unitRunning;
    UInt32 size = sizeof(unitRunning);
    OSStatus status = AudioUnitGetProperty(_audioUnit,
                                           kAudioOutputUnitProperty_IsRunning,
                                           kAudioUnitScope_Global,
                                           0,
                                           &unitRunning,
                                           &size);
    if ( !CheckStatus(status,@"AudioUnitGetProperty(kAudioOutputUnitProperty_IsRunning)",YES)) {
        return NO;
    }
    return unitRunning;
}
- (SMEasyAudioFormat *)format{
    return [[SMEasyAudioFormat alloc]init];
}

- (void)resetAudioUnit{

}

- (void)prepareForRender{
    
}

static OSStatus renderCallBack(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
    OSStatus result = noErr;
    __unsafe_unretained SMEasyAudioNode *self = (__bridge SMEasyAudioNode *)inRefCon;
    if (!self.perAudioNode) {
        return -1;
    }
    
    if (self->_isNoRenderAudio == NO) {
            result = AudioUnitRender(self.perAudioNode.audioUnit, ioActionFlags, inTimeStamp, self.perAudioNodeConnectBus, inNumberFrames, ioData);
    } else {
            for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
                memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
            }
    }
    
    if(CheckStatus(result, @"audioUnitRender fail", YES)){
        if (self.nodeCustomProcessCallBack) {
            result = self.nodeCustomProcessCallBack(inRefCon, inTimeStamp, inNumberFrames, ioData);
        }
    }
    return result;
}

- (void)setIsNoRenderAudio:(BOOL)isNoRenderAudio {
    _isNoRenderAudio = isNoRenderAudio;
}
@end
