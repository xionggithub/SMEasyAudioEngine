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

/**
重置audiounit
*/
- (void)resetAudioUnit;

/**
渲染前的准备
*/
- (void)prepareForRender;

/**
设置node 的audiounit 的属性
 inScope   kAudioUnitScope_Global
 inElement outputElement  (0)
 
 @param inID inID
 @param inData inData
 @param inDataSize inDataSize
*/
- (BOOL)setNodePropertyWithInID:(AudioUnitPropertyID)inID
                         inData:(void * _Nonnull)inData
                     inDataSize:(UInt32)inDataSize;

/**
获取node 的audiounit 的属性
 inScope   kAudioUnitScope_Global
 inElement outputElement  (0)
 
 @param inID inID
 @param outData outData
 @param outDataSize  outDataSize
*/
- (BOOL)getNodePropertyWithInID:(AudioUnitPropertyID)inID
                        outData:(void * _Nonnull)outData
                    outDataSize:(UInt32 * _Nonnull)outDataSize;

/**
设置node 的audiounit 的属性
 
 @param inID inID
 @param inScope  inScope
 @param inElement inElement
 @param inData inData
 @param inDataSize outDataSize
*/
- (BOOL)setNodePropertyWithInID:(AudioUnitPropertyID)inID
                        inScope:(AudioUnitScope)inScope
                      inElement:(AudioUnitElement)inElement
                         inData:(void * _Nonnull)inData
                     inDataSize:(UInt32)inDataSize;

/**
获取node 的audiounit 的属性
 
 @param inID  inID
 @param inScope  inScope
 @param inElement inElement
 @param outData outData
 @param outDataSize outDataSize
*/
- (BOOL)getNodePropertyWithInID:(AudioUnitPropertyID)inID
                        inScope:(AudioUnitScope)inScope
                      inElement:(AudioUnitElement)inElement
                        outData:(void * _Nonnull)outData
                    outDataSize:(UInt32 * _Nonnull)outDataSize;


/**
 设置node 的audiounit 的参数
 inScope   kAudioUnitScope_Global
 inElement   outputElement  (0)
 inBufferOffsetInFrames   0
 
 @param inID inID
 @param inValue  inValue
*/

- (BOOL)setNodeParameterWithInID:(AudioUnitParameterID)inID
                         inValue:(AudioUnitParameterValue)inValue;

/**
获取node 的audiounit 的参数
 inScope   kAudioUnitScope_Global
 inElement   outputElement  (0)
 
 @param inID inID
*/
- (AudioUnitParameterValue)getNodeParameterWithInID:(AudioUnitParameterID)inID;

/**
 设置node 的audiounit 的参数
 
 @param inID inID
 @param inScope inScope
 @param inElement inElement
 @param inValue inValue
 @param inBufferOffsetInFrames inBufferOffsetInFrames
*/
- (BOOL)setNodeParameterWithInID:(AudioUnitParameterID)inID
                         inScope:(AudioUnitScope)inScope
                       inElement:(AudioUnitElement)inElement
                         inValue:(AudioUnitParameterValue)inValue
          inBufferOffsetInFrames:(UInt32)inBufferOffsetInFrames;

/**
获取node 的audiounit 的参数
 
 @param inID inID
 @param inScope inScope
 @param inElement inElement
*/
- (AudioUnitParameterValue)getNodeParameterWithInID:(AudioUnitParameterID)inID
                                            inScope:(AudioUnitScope)inScope
                                          inElement:(AudioUnitElement)inElement;
@end
