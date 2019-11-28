
//
//  SMEasyAudioFloatToInt16Node.m
//  SMEasyAudioEngine
//
//  Created by xiaoxiong on 2017/8/28.
//  Copyright © 2017年 xiaoxiong. All rights reserved.
//

#import "SMEasyAudioFloatToInt16OutPutNode.h"
#import "SMAudioBufferListUtilities.h"
#import "SMCircleAudioBuffer.h"


const UInt32 SMCircleBufferMaxFramesPerSlice = 10*4096;
const UInt32 SMBufferStackMaxFramesPerSlice = 4096;

@implementation SMEasyAudioFloatToInt16OutPutNode
{
    dispatch_queue_t _outputAudioQueue;
    AudioConverterRef _converterNonInterFloat2PackedShort;
    AudioBufferList *_bufferShort;
    AudioBufferList *_outPutBuffer;
    SMCircleAudioBuffer *_circleBuffer;
    bool  _finishOutputBufferData;
    UInt32 _circleBufferOffset;
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
        
        // 创建: Converter
        OSStatus result = AudioConverterNew(&SMEasyAudioNonInterleavedFloatStereoAudioDescription,
                                            &SMEasyAudioIsPacked16BitStereoAudioDescription,
                                            &_converterNonInterFloat2PackedShort);
        CheckStatus(result, @"Warning: Couldn't build converterNoNonInterFloat2PackedShort", YES);
        
        
        _bufferShort = SMAudioBufferListCreateWithFormat(SMEasyAudioIsPacked16BitStereoAudioDescription, SMBufferStackMaxFramesPerSlice);
        
        _outPutBuffer = SMAudioBufferListCreateWithFormat(SMEasyAudioIsPacked16BitStereoAudioDescription, SMCircleBufferMaxFramesPerSlice);
        
        //创建一个2x4096帧长度的循环buffer
        _circleBuffer = (SMCircleAudioBuffer *)malloc(sizeof(SMCircleAudioBuffer));
        BOOL createCircleBuffer = SMCircleAudioBufferInit(_circleBuffer,SMCircleBufferMaxFramesPerSlice, SMEasyAudioIsPacked16BitStereoAudioDescription);
        
        _circleBuffer->audioDescription = SMEasyAudioIsPacked16BitStereoAudioDescription;
        if (!createCircleBuffer) {
            return nil;
        }
        SMCircleAudioBufferClear(_circleBuffer);
        _finishOutputBufferData = YES;
        
        UInt32 circleBufferAvalibleSpaceFrame = SMCircleAudioBufferGetAvailableSpace(self->_circleBuffer);
        _circleBufferOffset = circleBufferAvalibleSpaceFrame - SMCircleBufferMaxFramesPerSlice;
        
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

- (void)dealloc{
    SMAudioBufferListFree(_bufferShort);
    _bufferShort = NULL;
    SMAudioBufferListFree(_outPutBuffer);
    _outPutBuffer = NULL;
    if (_converterNonInterFloat2PackedShort) {
        AudioConverterDispose(_converterNonInterFloat2PackedShort);
        _converterNonInterFloat2PackedShort = NULL;
    }
    SMCircleAudioBufferCleanup(_circleBuffer);
    free(_circleBuffer);
    _circleBuffer = NULL;
    _outputAudioQueue = nil;
}
static OSStatus outPutAudioCallback(void *inRefCon, const AudioTimeStamp *inTimeStamp, const UInt32 inNumberFrames, AudioBufferList *ioData)
{
    OSStatus result = noErr;
    SMEasyAudioFloatToInt16OutPutNode *self = (__bridge SMEasyAudioFloatToInt16OutPutNode *)inRefCon;
    //清空临时buffer 用于将存放将float 转 short 的数据
    SMAudioBufferListSilenceWithFormat(self->_bufferShort, SMEasyAudioIsPacked16BitStereoAudioDescription, 0, SMBufferStackMaxFramesPerSlice);
    SMAudioBufferListSetLength(self->_bufferShort, SMBufferStackMaxFramesPerSlice);
    
    //数据转换 float ->  short
    OSStatus status = AudioConverterConvertComplexBuffer(self->_converterNonInterFloat2PackedShort,
                                                         inNumberFrames, ioData, self->_bufferShort);
    
    CheckStatus(status, @"Error: Couldn't convert NonInterleaved float  to IsPacked short error status", YES);
    
    //将转换后的short 数据放入循环buffer  bufferEnqueue
    UInt32 avalibleSpaceFrame = SMCircleAudioBufferGetAvailableSpace(self->_circleBuffer) - self->_circleBufferOffset;
    //判断循环buffer剩余空间是否能存储 inNumberFrames 帧数据，如果不能则丢掉数据
    if (avalibleSpaceFrame > inNumberFrames) {
        BOOL enqueueSucess = SMCircleAudioBufferEnqueue(self->_circleBuffer, self->_bufferShort, inTimeStamp, inNumberFrames);
        if (!enqueueSucess) {
            NSLog(@"入队buffer 失败");
        }
    }else{
        NSLog(@"buffer 长度不够，数据丢失 %d",(unsigned int)inNumberFrames);
    }
    
#ifdef DEBUG
    assert(avalibleSpaceFrame <= SMCircleBufferMaxFramesPerSlice);
#else
#endif    
    if (!self->_finishOutputBufferData) {
        return result;
    }
    
    //异步线程将数据回调给powerInfo
    dispatch_async(self->_outputAudioQueue, ^{
        if (NULL == self->_circleBuffer) {
            return;
        }
        self->_finishOutputBufferData = false;
        UInt32 avalibleNumFrame = 0;
        AudioTimeStamp audioTime;
        bzero(&audioTime, sizeof(audioTime));
        //检测当前buffer是否有数据可读取
        avalibleNumFrame  = SMCircleAudioBufferPeek(self->_circleBuffer, &audioTime);
#ifdef DEBUG
        assert(avalibleNumFrame <= SMCircleBufferMaxFramesPerSlice);
#else
#endif
        if (avalibleNumFrame > 0) {
            bzero(&audioTime, sizeof(audioTime));
            //buffer dequeue
            SMCircleAudioBufferDequeue(self->_circleBuffer, &avalibleNumFrame, self->_outPutBuffer, &audioTime);
            
            //重置outputBuffer长度 以便于外面访问
            SMAudioBufferListSetLengthWithFormat(self->_outPutBuffer,
                                                 SMEasyAudioIsPacked16BitStereoAudioDescription,
                                                 avalibleNumFrame);
            if (self.delegate && [self.delegate respondsToSelector:@selector(audioOutput:frame:audioTime:)]) {
                [self.delegate audioOutput:self->_outPutBuffer frame:avalibleNumFrame audioTime:&audioTime];
            }
            
            SMAudioBufferListSilenceWithFormat(self->_outPutBuffer,
                                               SMEasyAudioIsPacked16BitStereoAudioDescription,
                                               0,
                                               SMCircleBufferMaxFramesPerSlice);
            SMAudioBufferListSetLengthWithFormat(self->_outPutBuffer,
                                                 SMEasyAudioIsPacked16BitStereoAudioDescription,
                                                 SMCircleBufferMaxFramesPerSlice);
        }
        self->_finishOutputBufferData = true;
    });
    return result;
}
@end
