//
//  AEIOAudioUnit.m
//  TheAmazingAudioEngine
//
//  Created by Michael Tyson on 4/04/2016.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "AEIOAudioUnit.h"
#import "AETypes.h"
#import "AEUtilities.h"
#import "AEBufferStack.h"
#import "AETime.h"
#import "AEManagedValue.h"
#import "AEAudioBufferListUtilities.h"
#import "AEDSPUtilities.h"
#import <AVFoundation/AVFoundation.h>

NSString * const AEIOAudioUnitDidUpdateStreamFormatNotification = @"AEIOAudioUnitDidUpdateStreamFormatNotification";
NSString * const AEIOAudioUnitDidSetupNotification = @"AEIOAudioUnitDidSetupNotification";


@interface AEIOAudioUnit ()
@property (nonatomic, strong) AEManagedValue * renderBlockValue;
@property (nonatomic, readwrite) double currentSampleRate;
//@property (nonatomic, readwrite) int numberOfOutputChannels;
// @property (nonatomic, readwrite) int numberOfInputChannels;
@property (nonatomic) AudioTimeStamp inputTimestamp;
@property (nonatomic) BOOL needsInputGainScaling;
@property (nonatomic) float currentInputGain;
#if TARGET_OS_IPHONE
@property (nonatomic, strong) id sessionInterruptionObserverToken;
@property (nonatomic, strong) id mediaResetObserverToken;
@property (nonatomic, strong) id routeChangeObserverToken;
@property (nonatomic) NSTimeInterval outputLatency;
@property (nonatomic) NSTimeInterval inputLatency;
#endif
@property (nonatomic, assign) BOOL isUpdateStreamFormat;
@end

@implementation AEIOAudioUnit
@dynamic running, renderBlock, IOBufferDuration;

- (instancetype)init {
    if ( !(self = [super init]) ) return nil;
    self.isUpdateStreamFormat = NO;
#if TARGET_OS_IPHONE
    self.latencyCompensation = YES;
#endif
    
    // 默认允许输出
    _outputEnabled = YES;
    self.renderBlockValue = [AEManagedValue new];
    
    // 期待的输入数据为2个Channel
    _numberOfInputChannels = 2;
    _numberOfOutputChannels = 2;
    
    _currentInputGain = _inputGain = 1.0;
    
    AETimeInit();
    
    return self;
}

- (void)dealloc {
    [self teardown];
}

- (BOOL)running {
    // 是否正在跑呢？
    if ( !_audioUnit ) return NO;
    UInt32 unitRunning;
    UInt32 size = sizeof(unitRunning);
    if ( !AECheckOSStatus(AudioUnitGetProperty(_audioUnit, kAudioOutputUnitProperty_IsRunning, kAudioUnitScope_Global, 0,
                                               &unitRunning, &size),
                          "AudioUnitGetProperty(kAudioOutputUnitProperty_IsRunning)") ) {
        return NO;
    }
    
    return unitRunning;
}

- (BOOL)setup:(NSError * _Nullable __autoreleasing *)error {
    NSAssert(!_audioUnit, @"Already setup");
    
    NSAssert(self.outputEnabled || self.inputEnabled, @"Must have output or input enabled");
    
#if !TARGET_OS_IPHONE
    NSAssert(!(self.outputEnabled && self.inputEnabled), @"Can only have both input and output enabled on iOS");
#endif
    
    // Get an instance of the output audio unit
    AudioComponentDescription acd = {};
#if TARGET_OS_IPHONE
    // RemoteIO配置
    acd = AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple,
                                          kAudioUnitType_Output, kAudioUnitSubType_RemoteIO);
#else
    acd = AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple,
                                          kAudioUnitType_Output, kAudioUnitSubType_HALOutput);
#endif
    
    // 1. 创建AudioUnit
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &acd);
    OSStatus result = AudioComponentInstanceNew(inputComponent, &_audioUnit);
    if ( !AECheckOSStatus(result, "AudioComponentInstanceNew") ) {
        if ( error ) *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:result
                    userInfo:@{ NSLocalizedDescriptionKey: @"Unable to instantiate IO unit" }];
        return NO;
    }
    
    // 2. Set the maximum frames per slice to render
    result = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global,
                                  0, &AEBufferStackMaxFramesPerSlice, sizeof(AEBufferStackMaxFramesPerSlice));
    AECheckOSStatus(result, "AudioUnitSetProperty(kAudioUnitProperty_MaximumFramesPerSlice)");
    
    // 3. Enable/disable input
    //    允许数据输出
    UInt32 flag = self.inputEnabled ? 1 : 0;
    result = AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flag, sizeof(flag));
    if ( !AECheckOSStatus(result, "AudioUnitSetProperty(kAudioOutputUnitProperty_EnableIO)") ) {
        if ( error ) *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:result
                                              userInfo:@{ NSLocalizedDescriptionKey: @"Unable to enable/disable input" }];
        return NO;
    }
    
    // 4. Enable/disable output
    flag = self.outputEnabled ? 1 : 0;
    result = AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &flag, sizeof(flag));
    if ( !AECheckOSStatus(result, "AudioUnitSetProperty(kAudioOutputUnitProperty_EnableIO)") ) {
        if ( error ) *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:result
                                              userInfo:@{ NSLocalizedDescriptionKey: @"Unable to enable/disable output" }];
        return NO;
    }
    
    // Set the render callback
    // 5. 这个在每次Render前后都会被调用
    AURenderCallbackStruct rcbs = { .inputProc = AEIOAudioUnitRenderCallback, .inputProcRefCon = (__bridge void *)(self) };
    result = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, 0,
                                  &rcbs, sizeof(rcbs));
    if ( !AECheckOSStatus(result, "AudioUnitSetProperty(kAudioUnitProperty_SetRenderCallback)") ) {
        if ( error ) *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:result
                                              userInfo:@{ NSLocalizedDescriptionKey: @"Unable to configure output render" }];
        return NO;
    }

    // 6. 这个在需要Pull数据时被调用
    // Set the input callback
    AURenderCallbackStruct inRenderProc;
    inRenderProc.inputProc = &AEIOAudioUnitInputCallback;
    inRenderProc.inputProcRefCon = (__bridge void *)self;
    result = AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global,
                                  0, &inRenderProc, sizeof(inRenderProc));
    if ( !AECheckOSStatus(result, "AudioUnitSetProperty(kAudioOutputUnitProperty_SetInputCallback)") ) {
        if ( error ) *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:result
                                              userInfo:@{ NSLocalizedDescriptionKey: @"Unable to configure input process" }];
        return NO;
    }
    
    // Initialize
    result = AudioUnitInitialize(_audioUnit);
    if ( !AECheckOSStatus(result, "AudioUnitInitialize")) {
        if ( error ) *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:result
                                              userInfo:@{ NSLocalizedDescriptionKey: @"Unable to initialize IO unit" }];
        return NO;
    }
    
    // Update stream formats
    [self updateStreamFormat];
    
    // Register a callback to watch for stream format changes
    AudioUnitAddPropertyListener(_audioUnit, kAudioUnitProperty_StreamFormat,AEIOAudioUnitStreamFormatChanged,
                                                 (__bridge void*)self);
    
    
#if TARGET_OS_IPHONE
    __weak typeof(self) weakSelf = self;
    
    // Watch for session interruptions
    __block BOOL wasRunning;
    self.sessionInterruptionObserverToken =
    [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionInterruptionNotification object:nil queue:nil
                                                  usingBlock:^(NSNotification *notification) {
        NSInteger type = [notification.userInfo[AVAudioSessionInterruptionTypeKey] integerValue];
        if ( type == AVAudioSessionInterruptionTypeBegan ) {
            wasRunning = weakSelf.running;
            if ( wasRunning ) {
                [weakSelf stop];
            }
        } else {
            if ( wasRunning ) {
                [weakSelf start:NULL];
            }
        }
    }];
    
    // Watch for media reset notifications
    self.mediaResetObserverToken =
    [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionMediaServicesWereResetNotification object:nil
                                                       queue:nil usingBlock:^(NSNotification *notification) {
        [weakSelf reload];
    }];
    
    // Watch for audio route changes
    self.routeChangeObserverToken =
    [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionRouteChangeNotification object:nil
                                                       queue:nil usingBlock:^(NSNotification *notification)
    {
        weakSelf.outputLatency = [AVAudioSession sharedInstance].outputLatency;
        weakSelf.inputLatency = [AVAudioSession sharedInstance].inputLatency;
        weakSelf.inputGain = weakSelf.inputGain;
    }];
#endif
    
    // Notify
    [[NSNotificationCenter defaultCenter] postNotificationName:AEIOAudioUnitDidSetupNotification object:self];
    
    return YES;
}

- (void)teardown {
#if TARGET_OS_IPHONE
    //移除_audioUnit 的 StreamFormat 变化的监听
    AudioUnitRemovePropertyListenerWithUserData(_audioUnit, kAudioUnitProperty_StreamFormat, AEIOAudioUnitStreamFormatChanged, (__bridge void*)self);
    [[NSNotificationCenter defaultCenter] removeObserver:self.sessionInterruptionObserverToken];
    self.sessionInterruptionObserverToken = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self.mediaResetObserverToken];
    self.mediaResetObserverToken = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self.routeChangeObserverToken];
    self.routeChangeObserverToken = nil;
#endif
    AECheckOSStatus(AudioUnitUninitialize(_audioUnit), "AudioUnitUninitialize");
    AECheckOSStatus(AudioComponentInstanceDispose(_audioUnit), "AudioComponentInstanceDispose");
    _audioUnit = NULL;
}

- (BOOL)start:(NSError *__autoreleasing *)error {
    NSAssert(_audioUnit, @"You must call setup: on this instance before starting it");
    
#if TARGET_OS_IPHONE
    // Activate audio session
    NSError * e;
    if ( ![[AVAudioSession sharedInstance] setActive:YES error:&e] ) {
        NSLog(@"Couldn't activate audio session: %@", e);
        if ( error ) *error = e;
        return NO;
    }
    
    self.outputLatency = [AVAudioSession sharedInstance].outputLatency;
    self.inputLatency = [AVAudioSession sharedInstance].inputLatency;
    self.inputGain = self.inputGain;
#endif
    
    [self updateStreamFormat];
    
    // Start unit
    OSStatus result = AudioOutputUnitStart(_audioUnit);
    if ( !AECheckOSStatus(result, "AudioOutputUnitStart") ) {
        if ( error ) *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:result
                                              userInfo:@{ NSLocalizedDescriptionKey: @"Unable to start IO unit" }];
        return NO;
    }
    
    return YES;
}

- (void)stop {
    NSAssert(_audioUnit, @"You must call setup: on this instance before starting or stopping it");
    
    // Stop unit
    AECheckOSStatus(AudioOutputUnitStop(_audioUnit), "AudioOutputUnitStop");
}

AudioUnit _Nonnull AEIOAudioUnitGetAudioUnit(__unsafe_unretained AEIOAudioUnit * _Nonnull THIS) {
    return THIS->_audioUnit;
}

OSStatus AEIOAudioUnitRenderInput(__unsafe_unretained AEIOAudioUnit * _Nonnull THIS,
                                  const AudioBufferList * _Nonnull buffer, UInt32 frames) {
    
    // 直接Silence， 不会出错
    if ( !THIS->_inputEnabled || THIS->_numberOfInputChannels == 0 ) {
        AEAudioBufferListSilence(buffer, 0, frames);
        return 0;
    }
    
    AudioUnitRenderActionFlags flags = 0;
    AudioTimeStamp timestamp = THIS->_inputTimestamp;
    AEAudioBufferListCopyOnStack(mutableAbl, buffer, 0);
    
    OSStatus status = AudioUnitRender(THIS->_audioUnit, &flags, &timestamp, 1, frames, mutableAbl);
    AECheckOSStatus(status, "AudioUnitRender");
    
    if ( status == noErr && THIS->_needsInputGainScaling &&
            (fabs(THIS->_inputGain - 1.0) > 1.0e-5 || fabs(THIS->_inputGain - THIS->_currentInputGain) > 1.0e-5) ) {
        AEDSPApplyGainSmoothed(mutableAbl, THIS->_inputGain, &THIS->_currentInputGain, frames);
    }
    return status;
}

AudioTimeStamp AEIOAudioUnitGetInputTimestamp(__unsafe_unretained AEIOAudioUnit * _Nonnull THIS) {
    return THIS->_inputTimestamp;
}

double AEIOAudioUnitGetSampleRate(__unsafe_unretained AEIOAudioUnit * _Nonnull THIS) {
    return THIS->_currentSampleRate;
}

#if TARGET_OS_IPHONE

// 获取输入和输出Delay
AESeconds AEIOAudioUnitGetInputLatency(__unsafe_unretained AEIOAudioUnit * _Nonnull THIS) {
    return THIS->_inputLatency;
}

AESeconds AEIOAudioUnitGetOutputLatency(__unsafe_unretained AEIOAudioUnit * _Nonnull THIS) {
    return THIS->_outputLatency;
}

#endif

- (void)setSampleRate:(double)sampleRate {
    if ( fabs(_sampleRate - sampleRate) <= DBL_EPSILON ) return;
    
    // 采样率改变时会通知
    _sampleRate = sampleRate;
    
    // 采样率变化了
    if ( self.running ) {
        [self updateStreamFormat];
    } else {
        self.currentSampleRate = sampleRate;
        [[NSNotificationCenter defaultCenter] postNotificationName:AEIOAudioUnitDidUpdateStreamFormatNotification object:self];
    }
}

- (double)currentSampleRate {
    if ( _audioUnit ) return _currentSampleRate;
    
    if ( self.sampleRate != 0 ) return self.sampleRate;
    
    // If not setup yet, take the sample rate from the audio session
#if TARGET_OS_IPHONE
    NSError * error;
    if ( ![[AVAudioSession sharedInstance] setActive:YES error:&error] ) {
        NSLog(@"Couldn't activate audio session: %@", error);
        return 0.0;
    }
    return [[AVAudioSession sharedInstance] sampleRate];
#else
    return [self streamFormatForDefaultDeviceScope:
            self.outputEnabled ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput].mSampleRate;
#endif
}

- (void)setOutputEnabled:(BOOL)outputEnabled {
    if ( _outputEnabled == outputEnabled ) return;
    _outputEnabled = outputEnabled;
    if ( self.renderBlock && _audioUnit ) {
        BOOL wasRunning = self.running;
        AECheckOSStatus(AudioUnitUninitialize(_audioUnit), "AudioUnitUninitialize");
        UInt32 flag = _outputEnabled ? 1 : 0;
        OSStatus result =
            AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &flag, sizeof(flag));
        if ( AECheckOSStatus(result, "AudioUnitSetProperty(kAudioOutputUnitProperty_EnableIO)") ) {
            [self updateStreamFormat];
            if ( AECheckOSStatus(AudioUnitInitialize(_audioUnit), "AudioUnitInitialize") && wasRunning ) {
                [self start:NULL];
            }
        }
    }
}

- (int)numberOfOutputChannels {
    return _numberOfOutputChannels;
}

- (AEIOAudioUnitRenderBlock)renderBlock {
    return self.renderBlockValue.objectValue;
}

- (void)setRenderBlock:(AEIOAudioUnitRenderBlock)renderBlock {
    self.renderBlockValue.objectValue = [renderBlock copy];
}

- (void)setInputEnabled:(BOOL)inputEnabled {
    if ( _inputEnabled == inputEnabled ) return;
    _inputEnabled = inputEnabled;
    
    // inputEnabled之后,对应的AudioUnit如何处理呢?
    // 这是一件大事,不要指望能非常平滑的处理, 一般在启动时配置
    if ( _audioUnit ) {
        BOOL wasRunning = self.running;
        AECheckOSStatus(AudioUnitUninitialize(_audioUnit), "AudioUnitUninitialize");
        UInt32 flag = _inputEnabled ? 1 : 0;
        // EnableIO
        OSStatus result =
            AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flag, sizeof(flag));
        if ( AECheckOSStatus(result, "AudioUnitSetProperty(kAudioOutputUnitProperty_EnableIO)") ) {
            [self updateStreamFormat];
            if ( AECheckOSStatus(AudioUnitInitialize(_audioUnit), "AudioUnitInitialize") && wasRunning ) {
                [self start:NULL];
            }
        }
    }
}

- (void)setInputGain:(double)inputGain {
    _inputGain = inputGain;
    
#if TARGET_OS_IPHONE
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    
    // Try to set the hardware gain; zero seems to still be audible, though, so we'll bypass for that
    if ( audioSession.inputGainSettable && inputGain > 0 ) {
        // AVAudioSession's gain seems to be logarithmic,
        // so we'll do a little rough scaling on the input values (power ratio)
        // 如何理解?
        // inputGain >= 1, 则保持为1
        // inputGain <  1, 则?
        double gain = inputGain > 1.0-1.0e-5 ? 1.0 : 1.0 - (AEDSPRatioToDecibels(inputGain) / -30.0);
        
        // 注意: gain的意义
        NSError * error = nil;
        if ( ![audioSession setInputGain:gain error:&error] ) {
            NSLog(@"Couldn't set input gain: %@", error);
            [audioSession setInputGain:1.0 error:NULL];
            _needsInputGainScaling = YES;
        } else {
            _needsInputGainScaling = inputGain > 1.0+1.0e-5;
        }
    } else {
        _needsInputGainScaling = YES;
    }
    
    // _needsInputGainScaling 如果能交给系统的AudioSession来处理,就不用代码来处理了
#else
    _needsInputGainScaling = YES;
#endif
}

/*
- (void)setNumberOfInputChannels:(int)numberOfInputChannels {
    if ( _audioUnit && _inputEnabled && _numberOfInputChannels != numberOfInputChannels) {
        [self updateStreamFormat];
    }
}
*/

- (AESeconds)IOBufferDuration {
#if TARGET_OS_IPHONE
    // iPhone下就直接返回
    return [[AVAudioSession sharedInstance] IOBufferDuration];
#else
    // Get the default device
    AudioDeviceID deviceId =
        [self defaultDeviceForScope:self.outputEnabled ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput];
    if ( deviceId == kAudioDeviceUnknown ) return 0.0;
    
    // Get the buffer duration
    UInt32 duration;
    UInt32 size = sizeof(duration);
    AudioObjectPropertyAddress addr = {
        kAudioDevicePropertyBufferFrameSize,
        self.outputEnabled ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput, 0 };
    if ( !AECheckOSStatus(AudioObjectGetPropertyData(deviceId, &addr, 0, NULL, &size, &duration),
                          "AudioObjectSetPropertyData") ) return 0.0;
    
    return (double)duration / self.currentSampleRate;
#endif
}

- (void)setIOBufferDuration:(AESeconds)IOBufferDuration {
#if TARGET_OS_IPHONE
    NSError * error = nil;
    if ( ![[AVAudioSession sharedInstance] setPreferredIOBufferDuration:IOBufferDuration error:&error] ) {
        NSLog(@"Unable to set IO Buffer duration: %@", error.localizedDescription);
    }
#else
    // Get the default device
    AudioDeviceID deviceId =
    [self defaultDeviceForScope:self.outputEnabled ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput];
    if ( deviceId == kAudioDeviceUnknown ) return;
    
    // Set the buffer duration
    UInt32 duration = (double)IOBufferDuration * self.currentSampleRate;
    UInt32 size = sizeof(duration);
    AudioObjectPropertyAddress addr = {
        kAudioDevicePropertyBufferFrameSize,
        self.outputEnabled ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput, 0 };
    AECheckOSStatus(AudioObjectSetPropertyData(deviceId, &addr, 0, NULL, size, &duration),
                    "AudioObjectSetPropertyData");
#endif
}

#pragma mark -

static OSStatus AEIOAudioUnitRenderCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags,
                                            const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber,
                                            UInt32 inNumberFrames, AudioBufferList *ioData) {
    
    // Render
    __unsafe_unretained AEIOAudioUnit * THIS = (__bridge AEIOAudioUnit *)inRefCon;
    
    AudioTimeStamp timestamp = *inTimeStamp;
    
#if TARGET_OS_IPHONE
    // 如果有时间戳补偿, 则这个时间应该是用户最终看到的时间
    // TODO: 这个如何处理呢？
    if ( THIS->_latencyCompensation ) {
        timestamp.mHostTime += AEHostTicksFromSeconds(THIS->_outputLatency);
    }
#endif
    
    __unsafe_unretained AEIOAudioUnitRenderBlock renderBlock
        = (__bridge AEIOAudioUnitRenderBlock)AEManagedValueGetValue(THIS->_renderBlockValue);
    
    // 交给RenderBlock来处理
    if ( renderBlock ) {
        // 数据的读取交给: renderBlock来处理
        renderBlock(ioData, inNumberFrames, &timestamp);
    } else {
        // 否则没有声音
        *ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
    }
    
    return noErr;
}

static OSStatus AEIOAudioUnitInputCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags,
                                           const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber,
                                           UInt32 inNumberFrames, AudioBufferList *ioData) {
    // Grab timestamp
    __unsafe_unretained AEIOAudioUnit * THIS = (__bridge AEIOAudioUnit *)inRefCon;
    
    AudioTimeStamp timestamp = *inTimeStamp;
    
#if TARGET_OS_IPHONE
    if ( THIS->_latencyCompensation ) {
        timestamp.mHostTime -= AEHostTicksFromSeconds(THIS->_inputLatency);
    }
#endif
    
    THIS->_inputTimestamp = timestamp;
    return noErr;
}

static void AEIOAudioUnitStreamFormatChanged(void *inRefCon, AudioUnit inUnit, AudioUnitPropertyID inID,
                                             AudioUnitScope inScope, AudioUnitElement inElement) {
    __weak AEIOAudioUnit * weakSelf = (__bridge AEIOAudioUnit *)inRefCon;
    if (weakSelf.isUpdateStreamFormat) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong AEIOAudioUnit * strongSelf = weakSelf;
        if (strongSelf.running) {
            [strongSelf updateStreamFormat];
        }
    });
}

//                                  I/O Unit
//
//                     input scope             output scope
//                  |--------------|        |-----------------|
//                  |   |-------------------------------|     |         /|
//              |---|---|         element 0             | ----|------- | |
//              |   |   |-------------------------------|     |         \|
//      O       |   |              |        |                 |
//     /        |   |              |        |                 |
//    /         |   |   |-------------------------------|     |
//    |   ------|---|---|         element 1             | ----|---------
//  -----       |   |   |-------------------------------|     |        |
//              |   |                                         |        |
//              |   |-----------------------------------------|        |
//              |                 |---------|                          |
//              ----------------- |         |--------------------------|
//                                |  APP    |
//                                |---------|
//
//
- (void)updateStreamFormat {
    self.isUpdateStreamFormat = YES;
    BOOL stoppedUnit = NO;
    BOOL hasChanges = NO;
    BOOL iaaInput = NO;
    BOOL iaaOutput = NO;
    
#if TARGET_OS_IPHONE
    UInt32 iaaConnected = NO;
    UInt32 size = sizeof(iaaConnected);
    if ( AECheckOSStatus(AudioUnitGetProperty(_audioUnit, kAudioUnitProperty_IsInterAppConnected,
                                              kAudioUnitScope_Global, 0, &iaaConnected, &size),
                         "AudioUnitGetProperty(kAudioUnitProperty_IsInterAppConnected)") && iaaConnected ) {
        AudioComponentDescription componentDescription;
        size = sizeof(componentDescription);
        if ( AECheckOSStatus(AudioUnitGetProperty(_audioUnit, kAudioOutputUnitProperty_NodeComponentDescription,
                                                  kAudioUnitScope_Global, 0, &componentDescription, &size),
                             "AudioUnitGetProperty(kAudioOutputUnitProperty_NodeComponentDescription)") ) {
            iaaOutput = YES;
            iaaInput = componentDescription.componentType == kAudioUnitType_RemoteEffect
            || componentDescription.componentType == kAudioUnitType_RemoteMusicEffect;
        }
    }
#endif
    
    if ( self.outputEnabled ) {
        // Get the current output sample rate and number of output channels
        AudioStreamBasicDescription asbd;
        UInt32 size = sizeof(asbd);
        AECheckOSStatus(AudioUnitGetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0,
                                             &asbd, &size),
                        "AudioUnitGetProperty(kAudioUnitProperty_StreamFormat)");
        
        if ( iaaOutput ) {
            asbd.mChannelsPerFrame = 2;
        }
        
        double priorSampleRate = self.currentSampleRate;
        self.currentSampleRate = self.sampleRate == 0 ? asbd.mSampleRate : self.sampleRate;
        
        BOOL rateChanged = fabs(priorSampleRate - _currentSampleRate) > DBL_EPSILON;
        BOOL running = self.running;
        if ( rateChanged && running ) {
            AECheckOSStatus(AudioOutputUnitStop(_audioUnit), "AudioOutputUnitStop");
            stoppedUnit = YES;
            hasChanges = YES;
        }
        //捕捉非running下类似采样率等配置的变化
        if (rateChanged) {
            hasChanges = YES;
        }
        
        if ( _numberOfOutputChannels != (int)asbd.mChannelsPerFrame ) {
            hasChanges = YES;
            self.numberOfOutputChannels = asbd.mChannelsPerFrame;
        }
        //由于在插拔耳机的时候  output StreamFormat 改变导致output callback的iodata 销毁重新创建，但是音频处理线程中iodata正在使用所以出现崩溃
        self.numberOfOutputChannels = 2;

        // Update the stream format
        asbd = AEAudioDescription;
        asbd.mChannelsPerFrame = self.numberOfOutputChannels;
        asbd.mSampleRate = self.currentSampleRate;
        //设置input scope 0  如上图就是喇叭的输入数据格式，也就是AEIOAudioUnitRenderCallback 中的ioData 的格式
        AECheckOSStatus(AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0,
                                             &asbd, sizeof(asbd)),
                        "AudioUnitSetProperty(kAudioUnitProperty_StreamFormat)");
    }
    
    // _audioUnit Element0 本身就是一个转码器
    //
    //          InputStreamFormat ---> AudioUnit Element0 ---> OutputStreamFormat --> Speaker
    //  Mic --> InputStreamFormat ---> AudioUnit Element1 ---> OutputStreamFormat
    //  Mic和Speaker是不可靠的，也是无法控制的，不要太依赖于这两个模块；如果Element0/1两端格式不一致，则它自带Converter
    //
    
    if ( self.inputEnabled ) {
        // Get the current input number of input channels
        AudioStreamBasicDescription asbd;
        UInt32 size = sizeof(asbd);
        AECheckOSStatus(AudioUnitGetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input,
                                             1, &asbd, &size),
                        "AudioUnitGetProperty(kAudioUnitProperty_StreamFormat)");
        
        if ( iaaInput ) {
            asbd.mChannelsPerFrame = 2;
        }
        
        int channels = self.maximumInputChannels ? MIN(asbd.mChannelsPerFrame, self.maximumInputChannels) : asbd.mChannelsPerFrame;
        if ( _numberOfInputChannels != (int)channels ) {
            hasChanges = YES;
            self.numberOfInputChannels = channels;
        }
        
        if ( !self.outputEnabled ) {
            self.currentSampleRate = self.sampleRate == 0 ? asbd.mSampleRate : self.sampleRate;
        }
        
        if ( self.numberOfInputChannels > 0 ) {
            // Set the stream format
            asbd = AEAudioDescription;
            asbd.mChannelsPerFrame = self.numberOfInputChannels;
            asbd.mSampleRate = self.currentSampleRate;
            AECheckOSStatus(AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1,
                                                 &asbd, sizeof(asbd)),
                            "AudioUnitSetProperty(kAudioUnitProperty_StreamFormat)");
        } else {
            memset(&_inputTimestamp, 0, sizeof(_inputTimestamp));
        }
    }
    
    if ( hasChanges ) {
        [[NSNotificationCenter defaultCenter] postNotificationName:AEIOAudioUnitDidUpdateStreamFormatNotification object:self];
    }
    
    if ( stoppedUnit ) {
        AECheckOSStatus(AudioOutputUnitStart(_audioUnit), "AudioOutputUnitStart");
    }

    /*BOOL stoppedUnit = NO;
    BOOL hasChanges = NO;
    
    if ( self.outputEnabled ) {
        AudioStreamBasicDescription asbd;
        asbd = AEAudioDescription;
        self.numberOfOutputChannels = 2;
        self.currentSampleRate = 44100;
        asbd.mChannelsPerFrame = self.numberOfOutputChannels;
        asbd.mSampleRate = self.currentSampleRate;
        
        
        BOOL running = self.running;
        if (running ) {
            // 暂停
            AECheckOSStatus(AudioOutputUnitStop(_audioUnit), "AudioOutputUnitStop");
            stoppedUnit = YES;
            hasChanges = YES;
        }
        
        // 设置Element0的输入格式
        AECheckOSStatus(AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0,
                                             &asbd, sizeof(asbd)),
                        "AudioUnitSetProperty(kAudioUnitProperty_StreamFormat)");
    }
    
    // _audioUnit Element0 本身就是一个转码器
    //
    //          InputStreamFormat ---> AudioUnit Element0 ---> OutputStreamFormat --> Speaker
    //  Mic --> InputStreamFormat ---> AudioUnit Element1 ---> OutputStreamFormat
    //  Mic和Speaker是不可靠的，也是无法控制的，不要太依赖于这两个模块；如果Element0/1两端格式不一致，则它自带Converter
    //
    
    if ( self.inputEnabled ) {

        self.currentSampleRate = 44100;
        
        if ( self.numberOfInputChannels > 0 ) {
            AudioStreamBasicDescription asbd;
            // Set the stream format
            asbd = AEAudioDescription;
            
            //  这个如何在外部控制呢?
            asbd.mChannelsPerFrame = self.numberOfInputChannels;
            asbd.mSampleRate = self.currentSampleRate;
            AECheckOSStatus(AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1,
                                                 &asbd, sizeof(asbd)),
                            "AudioUnitSetProperty(kAudioUnitProperty_StreamFormat)");
        } else {
            memset(&_inputTimestamp, 0, sizeof(_inputTimestamp));
        }
    }
    
    if ( stoppedUnit ) {
        AECheckOSStatus(AudioOutputUnitStart(_audioUnit), "AudioOutputUnitStart");
    }*/
    self.isUpdateStreamFormat = NO;
}

- (void)reload {
    BOOL wasRunning = self.running;
    [self teardown];
    if ( ![self setup:NULL] ) return;
    if ( wasRunning ) {
        [self start:NULL];
    }
}

#if !TARGET_OS_IPHONE
- (AudioDeviceID)defaultDeviceForScope:(AudioObjectPropertyScope)scope {
    AudioDeviceID deviceId;
    UInt32 size = sizeof(deviceId);
    AudioObjectPropertyAddress addr = {
        scope == kAudioDevicePropertyScopeInput ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice,
        .mScope = kAudioObjectPropertyScopeGlobal,
        .mElement = 0
    };
    if ( !AECheckOSStatus(AudioObjectGetPropertyData(kAudioObjectSystemObject, &addr, 0, NULL, &size, &deviceId),
                          "AudioObjectGetPropertyData") ) {
        return kAudioDeviceUnknown;
    }
    
    return deviceId;
}

- (AudioStreamBasicDescription)streamFormatForDefaultDeviceScope:(AudioObjectPropertyScope)scope {
    // Get the default device
    AudioDeviceID deviceId = [self defaultDeviceForScope:scope];
    if ( deviceId == kAudioDeviceUnknown ) return (AudioStreamBasicDescription){};
    
    // Get stream format
    AudioStreamBasicDescription asbd;
    UInt32 size = sizeof(asbd);
    AudioObjectPropertyAddress addr = { kAudioDevicePropertyStreamFormat, scope, 0 };
    if ( !AECheckOSStatus(AudioObjectGetPropertyData(deviceId, &addr, 0, NULL, &size, &asbd),
                          "AudioObjectGetPropertyData") ) {
        return (AudioStreamBasicDescription){};
    }
    
    return asbd;
}
#endif

@end
