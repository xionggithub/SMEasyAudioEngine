//
//  AEAudioFileRecorderModule.m
//  TheAmazingAudioEngine
//
//  Created by Michael Tyson on 1/04/2016.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//

#import "AEAudioFileRecorderModule.h"
#import "AEUtilities.h"
#import "AETypes.h"
#import "AEAudioBufferListUtilities.h"
#import "AEWeakRetainingProxy.h"
#import "AEDSPUtilities.h"
#import "AEMainThreadEndpoint.h"
#import <AudioToolbox/AudioToolbox.h>
#import <pthread.h>
#import <stdatomic.h>

@interface AEAudioFileRecorderModule () {
    ExtAudioFileRef _audioFile;
    
    pthread_mutex_t _audioFileMutex;
    AEHostTicks    _startTime;
    AEHostTicks    _stopTime;
    volatile BOOL  _complete;
    volatile BOOL  _recording;
    UInt32         _recordedFrames;
}
@property (nonatomic, readwrite) int numberOfChannels;
@property (nonatomic, readwrite) BOOL recording;
@property (nonatomic, strong) AEMainThreadEndpoint * stopRecordingNotificationEndpoint;
@end

@implementation AEAudioFileRecorderModule

- (instancetype)initWithRenderer:(AERenderer *)renderer URL:(NSURL *)url
                            type:(AEAudioFileType)type error:(NSError **)error {
    return [self initWithRenderer:renderer URL:url type:type numberOfChannels:2 error:error];
}

- (instancetype)initWithRenderer:(AERenderer *)renderer URL:(NSURL *)url type:(AEAudioFileType)type
                numberOfChannels:(int)numberOfChannels error:(NSError **)error {
    
    if ( !(self = [super initWithRenderer:renderer]) ) return nil;
    
    // 创建文件
    if ( !(_audioFile = AEExtAudioFileCreate(url, type, self.renderer.sampleRate, numberOfChannels, error)) ) return nil;
    
    // Prime async recording
    // 第一次调用主要是初始化和_audioFile相关的buffer
    ExtAudioFileWriteAsync(_audioFile, 0, NULL);
    
    self.processFunction = AEAudioFileRecorderModuleProcess;
    self.numberOfChannels = numberOfChannels;
    
    // 初始化: mutex
    pthread_mutex_init(&_audioFileMutex, NULL);
    
    return self;
}

- (void)dealloc {
    if ( _audioFile ) {
        [self finishWriting];
    }
    pthread_mutex_destroy(&_audioFileMutex);
}

// 从某个时间点开始
// 开启recording状态
- (void)beginRecordingAtTime:(AEHostTicks)time {
    self.recording = YES;
    _complete = NO;
    _recordedFrames = 0;
    //
    _startTime = time ? time : AECurrentTimeInHostTicks();
}

// 立即开始Recording
- (void)beginRecording {
    [self beginRecordingAtTime:0];
}

// 暂停记录数据
// 下次再调用
- (void)pauseRecording {
    self.recording = NO;
}


- (void)stopRecordingAtTime:(AEHostTicks)time completionBlock:(AEAudioFileRecorderModuleCompletionBlock)block {
    if ( time ) {
        // Stop after a delay
        __weak typeof(self) weakSelf = self;
        self.stopRecordingNotificationEndpoint =
            [[AEMainThreadEndpoint alloc] initWithHandler:^(void * _Nullable data, size_t length) {
            
                weakSelf.stopRecordingNotificationEndpoint = nil;
                [weakSelf finishWriting];
                weakSelf.recording = NO;
                if ( block ) block();
                
            } bufferCapacity:32];
        
        atomic_thread_fence(memory_order_release);
        _stopTime = time;
    } else {
        
        // Stop immediately
        // 立马停下来
        pthread_mutex_lock(&_audioFileMutex);
        
        // 结束文件的Writing
        [self finishWriting];
        self.recording = NO;
        pthread_mutex_unlock(&_audioFileMutex);
        
        if ( block ) {
            block();
        }
    }
}

// 核心逻辑
static void AEAudioFileRecorderModuleProcess(__unsafe_unretained AEAudioFileRecorderModule * THIS,
                                        const AERenderContext * _Nonnull context) {
    
    // TODO: 补充一下C++中线程"同步"的知识....
    // 加锁
    // 1. 虽然加锁会降低效率,但是为了保证文件写的正确性还是要加锁的
    if ( pthread_mutex_trylock(&THIS->_audioFileMutex) != 0 ) {
        return;
    }
    
    // 2. 两个状态的控制: 开始recording和complete
    if ( !THIS->_recording || THIS->_complete ) {
        pthread_mutex_unlock(&THIS->_audioFileMutex);
        return;
    }
    
    AEHostTicks startTime = THIS->_startTime;
    AEHostTicks stopTime = THIS->_stopTime;
    
    // 处理结束的问题
    if ( stopTime && stopTime < context->timestamp->mHostTime ) {
        THIS->_complete = YES;
        AEMainThreadEndpointSend(THIS->_stopRecordingNotificationEndpoint, NULL, 0);
        pthread_mutex_unlock(&THIS->_audioFileMutex);
        return;
    }
    
    // 开始时间处理的问题
    // 没到时间, 就不往文件中写
    // context->timestamp 在offline处理中好理解;但是在iounit中不太确定是什么值
    // TODO:
    AEHostTicks hostTimeAtBufferEnd
        = context->timestamp->mHostTime + AEHostTicksFromSeconds((double)context->frames / context->sampleRate);
    
    // 时间的理解:
    //     context->timestamp->mHostTime 当前系统的时间
    if ( startTime && startTime > hostTimeAtBufferEnd ) {
        pthread_mutex_unlock(&THIS->_audioFileMutex);
        return;
    }
    
    
    THIS->_startTime = 0;
    
    // 取出栈顶数据
    const AudioBufferList * abl = AEBufferStackGet(context->stack, 0);
    if ( !abl ) {
        pthread_mutex_unlock(&THIS->_audioFileMutex);
        return;
    }
    
    // Prepare buffer with the right number of channels
    // 关键是只要自己感兴趣的几个Channel
    AEAudioBufferListCreateOnStackWithFormat(buffer, AEAudioDescriptionWithChannelsAndRate(THIS->_numberOfChannels, 0));
    for ( int i=0; i<buffer->mNumberBuffers; i++ ) {
        buffer->mBuffers[i] = abl->mBuffers[MIN(abl->mNumberBuffers-1, i)];
    }
    if ( buffer->mNumberBuffers == 1 && abl->mNumberBuffers > 1 ) {
        // Mix down to mono
        // 多声道的Mix --> mono
        for ( int i=1; i<abl->mNumberBuffers; i++ ) {
            AEDSPMixMono(abl->mBuffers[i].mData, buffer->mBuffers[0].mData, 1.0, 1.0, context->frames, buffer->mBuffers[0].mData);
        }
    }
    
    // Advance frames, if we have a start time mid-buffer
    UInt32 frames = context->frames;
    if ( startTime && startTime > context->timestamp->mHostTime ) {
        // Offset
        UInt32 advanceFrames = round(AESecondsFromHostTicks(startTime - context->timestamp->mHostTime) * context->sampleRate);
        for ( int i=0; i<buffer->mNumberBuffers; i++ ) {
            buffer->mBuffers[i].mData += AEAudioDescription.mBytesPerFrame * advanceFrames;
            buffer->mBuffers[i].mDataByteSize -= AEAudioDescription.mBytesPerFrame * advanceFrames;
        }
        frames -= advanceFrames;
    }
    
    // Truncate if we have a stop time mid-buffer
    if ( stopTime && stopTime < hostTimeAtBufferEnd ) {
        UInt32 truncateFrames = round(AESecondsFromHostTicks(hostTimeAtBufferEnd - stopTime) * context->sampleRate);
        for ( int i=0; i<buffer->mNumberBuffers; i++ ) {
            buffer->mBuffers[i].mDataByteSize -= AEAudioDescription.mBytesPerFrame * truncateFrames;
        }
        frames -= truncateFrames;
    }
    
    AECheckOSStatus(ExtAudioFileWriteAsync(THIS->_audioFile, frames, buffer), "ExtAudioFileWriteAsync");
    THIS->_recordedFrames += frames;
    
    if ( stopTime && stopTime < hostTimeAtBufferEnd ) {
        THIS->_complete = YES;
        AEMainThreadEndpointSend(THIS->_stopRecordingNotificationEndpoint, NULL, 0);
    }
    
    pthread_mutex_unlock(&THIS->_audioFileMutex);
}

- (void)finishWriting {
    AECheckOSStatus(ExtAudioFileDispose(_audioFile), "AudioFileClose");
    _audioFile = NULL;
}

@end
