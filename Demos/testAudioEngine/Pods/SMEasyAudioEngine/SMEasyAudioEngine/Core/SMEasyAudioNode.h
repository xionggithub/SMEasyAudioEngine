//
//  SMEasyAudioNode.h
//  SMAudioEngine
//
//  Created by 熊先提 on 2017/8/20.
//  Copyright © 2017年 熊先提. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SMEasyAudioErrorCheck.h"
#import "SMEasyAudioType.h"
#import "SMEasyAudioConstants.h"

extern const AudioUnitElement inputElement;
extern const AudioUnitElement outputElement;


/**
 audio node 自定义的音频处理回调
 */
typedef OSStatus (*SMEasyAudioNodeCustomProcessCallback)(void                   * _Nullable     inRefCon,
                                                         const AudioTimeStamp   * _Nullable     inTimeStamp,
                                                         const UInt32                           inNumberFrames,
                                                         AudioBufferList  * __nullable    ioData);

@interface SMEasyAudioFormat : NSObject
@property(nonatomic, assign) AudioStreamBasicDescription    audioDescription;
@end

@interface SMEasyAudioNode : NSObject

@property(nonatomic , assign) NSInteger  tag;

@property(nonatomic, assign) AUNode                         audioNode;

@property(nonatomic, assign) AudioUnit _Nullable            audioUnit;

@property(nonatomic, assign) AudioComponentDescription      acdescription;

@property(nonatomic, assign) BOOL  isNoRenderAudio;

@property(nonatomic, assign, readonly) BOOL  running;
/**
 拉取数据的回调
 */
@property(nonatomic, assign)    AURenderCallback                     _Nullable     nodeBaseRendersCallBack;

/**
 处理拉取的数据的回调
 */
@property(nonatomic, assign)    SMEasyAudioNodeCustomProcessCallback _Nullable     nodeCustomProcessCallBack;


@property(nonatomic, weak)      SMEasyAudioNode  * _Nullable     perAudioNode;

@property(nonatomic, assign)    SMEasyAudioNodeBus    perAudioNodeConnectBus;

@property(nonatomic, assign,readonly)    AudioStreamBasicDescription    inputStreamFormat;

@property(nonatomic, assign,readonly)    AudioStreamBasicDescription    outputStreamFormat;

/**
 outputElement
 
 @param inputStreamFormat 数据格式
 */
- (void)setInputStreamFormat:(AudioStreamBasicDescription)inputStreamFormat;


/**
 IO node 是 inputElement 其他 node 是outputElement

 @param outputStreamFormat 数据格式
*/
- (void)setOutputStreamFormat:(AudioStreamBasicDescription)outputStreamFormat;


- (void)resetAudioUnit;

- (void)prepareForRender;
@end
