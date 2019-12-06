//
//  SMEasyAudioPlayerNode.m
//  SMAudioEngine
//
//  Created by xiaoxiong on 2017/8/21.
//  Copyright © 2017年 熊先提. All rights reserved.
//

#import "SMEasyAudioPlayerNode.h"
#import <AVFoundation/AVFoundation.h>
//#import "SMRecordViewController.h"

@interface SMEasyAudioPlayerNode ()

@end

@implementation SMEasyAudioPlayerNode{
    AudioFileID _audioFile;
    NSURL *_filePath;
    
    double      _fileSampleRate;
    int         _channels;
    int         _usableChannels;
    UInt32      _lengthInFrames;
    double      _regionDuration;
    double      _regionStartTime;
    CMTime      _audioCMTimeDuration;
    AudioStreamBasicDescription _inputStreamDescription;
    BOOL        _playComplete;
    
    UInt32      _playedFrames;
    UInt32      _totalFramesToPlay;
    
    NSTimeInterval _timeOffset;
    NSTimeInterval _currentTime;
    BOOL        _isResettingNewTime;
}
- (instancetype)initWithFile:(NSURL *)filePath{
    self = [super init];
    if (self) {
        _filePath = filePath;
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_Generator;
        description.componentSubType = kAudioUnitSubType_AudioFilePlayer;
        self.acdescription = description;
        _currentTime = 0;
        _isResettingNewTime = NO;
        _timeOffset = 0;
        if (_filePath && ![self openAudioFile]) {
            NSLog(@"ExtAudioFileOpenURL %@ Failed", filePath);
//            [SMRecordViewController postSMRecordErrorNotifationWithErrorString:[NSString stringWithFormat:@"ExtAudioFileOpenURL %@ Failed",filePath]];
            return nil;
        }
    }
    return self;
}

- (void) playMusicFile:(NSURL *)filePath
{
    _filePath = filePath;
    [self resetPlayer];
    if(_filePath) {
        [self openAudioFile];
        [self setUpFilePlayer:0];
        [self resetAudioUnit];
    }
}

- (BOOL)openAudioFile{
    CFURLRef infilePath = (__bridge CFURLRef)(_filePath);
    AudioFileTypeID fileTypeID = kAudioFileM4AType;
    OSStatus status = AudioFileOpenURL(infilePath, kAudioFileReadPermission, fileTypeID, &_audioFile);
    if (!CheckStatus(status, @"Could not open file", YES)) {
        NSLog(@"%@",_filePath);
        return NO;
    }
    status = noErr;
    AudioStreamBasicDescription fileDescription;
    UInt32 size = sizeof(fileDescription);
    status = AudioFileGetProperty(_audioFile, kAudioFilePropertyDataFormat, &size, &fileDescription);
    if (!CheckStatus(status, @"AudioFileGetProperty(kAudioFilePropertyDataFormat)",YES)) {
        AudioFileClose(_audioFile);
        _audioFile = NULL;
        return NO;
    }
    _inputStreamDescription = fileDescription;
    AudioFilePacketTableInfo packetInfo;
    size = sizeof(packetInfo);
    status = AudioFileGetProperty(_audioFile, kAudioFilePropertyPacketTableInfo, &size, &packetInfo);
    if (status != noErr ) {
        size = 0;
    }
    
    status = noErr;
    UInt64 fileLengthInFrames;
    if ( size > 0 ) {
        fileLengthInFrames = packetInfo.mNumberValidFrames;
    } else {
        UInt64 packetCount;
        size = sizeof(packetCount);
        status = AudioFileGetProperty(_audioFile, kAudioFilePropertyAudioDataPacketCount, &size, &packetCount);
        if ( !CheckStatus(status, @"AudioFileGetProperty(kAudioFilePropertyAudioDataPacketCount)",YES) ) {
            AudioFileClose(_audioFile);
            _audioFile = NULL;
            return NO;
        }
        fileLengthInFrames = packetCount * fileDescription.mFramesPerPacket;
    }
    if ( fileLengthInFrames == 0 ) {
        AudioFileClose(_audioFile);
        _audioFile = NULL;
        return NO;
    }
    _fileSampleRate = fileDescription.mSampleRate;
    _channels = fileDescription.mChannelsPerFrame;
    _lengthInFrames = (UInt32)fileLengthInFrames;
    _regionStartTime = 0;
    _regionDuration = (double)_lengthInFrames / _fileSampleRate;
    
    AVURLAsset *audioAsset = [AVURLAsset assetWithURL:_filePath];
    if (audioAsset) {
        _audioCMTimeDuration = audioAsset.duration;
        CMTimeShow(audioAsset.duration);
    }
    return YES;
}

static OSStatus playMusicRenderNotify(void *                            inRefCon,
                                      AudioUnitRenderActionFlags *    ioActionFlags,
                                      const AudioTimeStamp *            inTimeStamp,
                                      UInt32                            inBusNumber,
                                      UInt32                            inNumberFrames,
                                      AudioBufferList *                ioData)
{
    // !!! this method is timing sensitive, better not add any wasting time code here, even nslog
    if (*ioActionFlags & kAudioUnitRenderAction_PostRender) {
        __unsafe_unretained SMEasyAudioPlayerNode *THIS = (__bridge SMEasyAudioPlayerNode*)inRefCon;
        [THIS musicPlayFrames:inNumberFrames];
    }
    return noErr;
}

- (void) musicPlayFrames:(UInt32)numberFrames
{
    _playedFrames += numberFrames;
    if (_playedFrames >= _totalFramesToPlay)
    {
        [self pauseMusic];
        //回调主线程通知完成
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(player:didStopPlayForFinish:)]) {
                [self.delegate player:self didStopPlayForFinish:YES];
            }
        });
    }
}

- (void)resetAudioUnit{
    [super resetAudioUnit];
    
    
    OSStatus status = noErr;

    AudioStreamBasicDescription outputElementOutputStreamFormat = [self outputStreamFormat];
    status = noErr;
    status = AudioUnitSetProperty(
                                  self.audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  outputElement,
                                  &outputElementOutputStreamFormat,
                                  sizeof (outputElementOutputStreamFormat)
                                  );
    CheckStatus(status, @"Could not Set OutputStreamFormat for Player Unit", YES);
    
//    status = AudioUnitSetProperty(
//                                  self.audioUnit,
//                                  kAudioUnitProperty_StreamFormat,
//                                  kAudioUnitScope_Input,
//                                  outputElement,
//                                  &_inputStreamDescription,
//                                  sizeof (_inputStreamDescription)
//                                  );
//    CheckStatus(status, @"Could not Set InputStreamFormat for Player Unit", YES);
}

- (void)prepareForRender{
    if(_filePath) {
        [super prepareForRender];
        [self setUpFilePlayer];
        [self resetAudioUnit];
    }
}

- (void) setUpFilePlayer;
{
    [self setUpFilePlayer:0];
}
- (void) setUpFilePlayer:(NSTimeInterval) startOffset;
{
    _playComplete = NO;
    OSStatus status = noErr;
    // tell the file player unit to load the file we want to play
    status = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ScheduledFileIDs,
                                  kAudioUnitScope_Global, 0, &_audioFile, sizeof(_audioFile));
    CheckStatus(status, @"Tell AudioFile Player Unit Load Which File... ", YES);
    
    
    
    AudioStreamBasicDescription fileASBD;
    // get the audio data format from the file
    UInt32 propSize = sizeof(fileASBD);
    status = AudioFileGetProperty(_audioFile, kAudioFilePropertyDataFormat,
                                  &propSize, &fileASBD);
    CheckStatus(status, @"get the audio data format from the file... ", YES);
    
    status =  noErr;
    UInt64 nPackets;
    UInt32 propsize = sizeof(nPackets);
    status = AudioFileGetProperty(_audioFile, kAudioFilePropertyAudioDataPacketCount,
                         &propsize, &nPackets);
    CheckStatus(status, @"get the audio AudioDataPacketCount from the file... ", YES);
    status =  noErr;

    // tell the file player AU to play the entire file
    ScheduledAudioFileRegion rgn;
    memset (&rgn.mTimeStamp, 0, sizeof(rgn.mTimeStamp));
    rgn.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    rgn.mTimeStamp.mSampleTime = 0;
    rgn.mCompletionProc = NULL;
    rgn.mCompletionProcUserData = NULL;
    rgn.mAudioFile = _audioFile;    //要播放的文件
    rgn.mLoopCount = 0;             //  0 不循环
    rgn.mStartFrame = (SInt64)(startOffset * _inputStreamDescription.mSampleRate);            //  播放起始位置
    rgn.mFramesToPlay = MAX(1, _lengthInFrames - (UInt32)rgn.mStartFrame);
    _totalFramesToPlay = rgn.mFramesToPlay * ([self outputStreamFormat].mSampleRate / _inputStreamDescription.mSampleRate) + startOffset * [self outputStreamFormat].mSampleRate;
    _playedFrames = startOffset * [self outputStreamFormat].mSampleRate;
    
    status = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ScheduledFileRegion,
                                  kAudioUnitScope_Global, 0,&rgn, sizeof(rgn));
    CheckStatus(status, @"could not Set Region to audioUnit", YES);
    status =  noErr;

    
    // prime the file player AU with default values
    UInt32 defaultVal = 0;
    status = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ScheduledFilePrime,
                                  kAudioUnitScope_Global, 0, &defaultVal, sizeof(defaultVal));
    CheckStatus(status, @"Prime Player Unit With Default Value... ", YES);
    status =  noErr;

    [self removePlayRenderNotify];
    status = AudioUnitAddRenderNotify(self.audioUnit, &playMusicRenderNotify, (__bridge void *)self);
    CheckStatus(status, @"set Player Unit's Rendr Callback... ", YES);
    
    // tell the file player AU when to start playing (-1 sample time means next render cycle)
    AudioTimeStamp startTime;
    memset (&startTime, 0, sizeof(startTime));
    startTime.mFlags = kAudioTimeStampSampleTimeValid;
    startTime.mSampleTime = -1;
    status = AudioUnitSetProperty(self.audioUnit,
                                  kAudioUnitProperty_ScheduleStartTimeStamp,
                                  kAudioUnitScope_Global,
                                  outputElement,
                                  &startTime,
                                  sizeof(startTime));
    CheckStatus(status, @"set Player Unit Start Time... ", YES);
    status =  noErr;

}

- (void) removePlayRenderNotify
{
    OSStatus status;
    status = AudioUnitRemoveRenderNotify(self.audioUnit, &playMusicRenderNotify, (__bridge void *)self);
    CheckStatus(status, @"get Player Unit's Callback... ", YES);
}

- (void) pauseMusic
{
    [self resetPlayer];
    [self removePlayRenderNotify];
}

- (void) resumeMusic
{
    if(_filePath) {
        [self openAudioFile];
        [self setUpFilePlayer:_playedFrames / [self outputStreamFormat].mSampleRate];
        [self resetAudioUnit];
    }
}

- (AudioTimeStamp)currentAudioTimeStamp{
    OSStatus status;
    AudioTimeStamp currentTime;
    memset (&currentTime, 0, sizeof(currentTime));
    UInt32 size = sizeof(currentTime);
    status = AudioUnitGetProperty(self.audioUnit,
                                  kAudioUnitProperty_CurrentPlayTime,
                                  kAudioUnitScope_Global,
                                  outputElement,
                                  &currentTime,
                                  &size);
    CheckStatus(status, @"get Player Unit current Time... ", YES);
    status =  noErr;
    return currentTime;
}
- (NSTimeInterval)currentAudioTime{
    if (_isResettingNewTime) {
        return _currentTime;
    }
    _currentTime = _playedFrames / [self outputStreamFormat].mSampleRate;
    return _currentTime;
}

- (NSTimeInterval)audioDuration{
    return CMTimeGetSeconds(_audioCMTimeDuration);
}

- (void)resetPlayer{
    AudioUnitReset(self.audioUnit, kAudioUnitScope_Global, outputElement);
}
@end
