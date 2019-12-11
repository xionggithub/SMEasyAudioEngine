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
    AudioStreamBasicDescription outputElementInputStreamFormat = [self inputStreamFormat];
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, outputElement, &outputElementInputStreamFormat, sizeof(outputElementInputStreamFormat));
    
    AudioStreamBasicDescription outputElementOutputStreamFormat = [self outputStreamFormat];
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, outputElement, &outputElementOutputStreamFormat, sizeof(outputElementOutputStreamFormat));
    
}

- (void)prepareForRender{
    
}

- (BOOL)setNodePropertyWithInID:(AudioUnitPropertyID)inID
                         inData:(void *)inData
                     inDataSize:(UInt32)inDataSize
{
    return [self setNodePropertyWithInID:inID inScope:kAudioUnitScope_Global inElement:outputElement inData:inData inDataSize:inDataSize];
}

- (BOOL)getNodePropertyWithInID:(AudioUnitPropertyID)inID
                        outData:(void *)outData
                    outDataSize:(UInt32 *)outDataSize
{
    return [self getNodePropertyWithInID:inID inScope:kAudioUnitScope_Global inElement:outputElement outData:outData outDataSize:outDataSize];
}

- (BOOL)setNodePropertyWithInID:(AudioUnitPropertyID)inID
                        inScope:(AudioUnitScope)inScope
                      inElement:(AudioUnitElement)inElement
                         inData:(void *)inData
                     inDataSize:(UInt32)inDataSize
{
    OSStatus status;
    status = AudioUnitSetProperty(self.audioUnit, inID, inScope, inElement, inData, inDataSize);
    CheckStatus(status, [NSString stringWithFormat:@"set Property  %d  fail",inID], YES);
    if (status != noErr) {
        return NO;
    }
    return YES;
}

- (BOOL)getNodePropertyWithInID:(AudioUnitPropertyID)inID
                        inScope:(AudioUnitScope)inScope
                      inElement:(AudioUnitElement)inElement
                        outData:(void *)outData
                    outDataSize:(UInt32 *)outDataSize
{
    AudioUnitParameterValue value;
    OSStatus status;
    status = AudioUnitGetProperty(self.audioUnit, inID, inScope, inElement, outData, outDataSize);
    CheckStatus(status, [NSString stringWithFormat:@"get Property  %d  fail",inID], YES);
    if (status != noErr) {
        return NO;
    }
    return YES;
}

- (BOOL)setNodeParameterWithInID:(AudioUnitParameterID)inID
                         inValue:(AudioUnitParameterValue)inValue
{
    return [self setNodeParameterWithInID:inID inScope:kAudioUnitScope_Global inElement:outputElement inValue:inValue inBufferOffsetInFrames:0];
}

- (AudioUnitParameterValue)getNodeParameterWithInID:(AudioUnitParameterID)inID
{
    return [self getNodeParameterWithInID:inID inScope:kAudioUnitScope_Global inElement:outputElement];
}

- (BOOL)setNodeParameterWithInID:(AudioUnitParameterID)inID
                         inScope:(AudioUnitScope)inScope
                       inElement:(AudioUnitElement)inElement
                         inValue:(AudioUnitParameterValue)inValue
          inBufferOffsetInFrames:(UInt32)inBufferOffsetInFrames
{
    OSStatus status;
    status = AudioUnitSetParameter(self.audioUnit, inID, inScope, inElement, inValue, inBufferOffsetInFrames);
    CheckStatus(status, [NSString stringWithFormat:@"set parameter  %d  fail",inID], YES);
    if (status != noErr) {
        return NO;
    }
    return YES;
}

- (AudioUnitParameterValue)getNodeParameterWithInID:(AudioUnitParameterID)inID
                         inScope:(AudioUnitScope)inScope
                       inElement:(AudioUnitElement)inElement
{
    AudioUnitParameterValue value;
    OSStatus status;
    status = AudioUnitGetParameter(self.audioUnit, inID, inScope, inElement, &value);
    CheckStatus(status, [NSString stringWithFormat:@"get parameter  %d  fail",inID], YES);
    return value;
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
