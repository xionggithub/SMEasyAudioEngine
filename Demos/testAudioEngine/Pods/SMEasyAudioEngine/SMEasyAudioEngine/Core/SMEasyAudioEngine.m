//
//  SMEasyAudioEngine.m
//  SMAudioEngine
//
//  Created by 熊先提 on 2017/8/20.
//  Copyright © 2017年 熊先提. All rights reserved.
//

#import "SMEasyAudioEngine.h"
#import "SMEasyAudioNode.h"
#import <AudioToolbox/AudioToolbox.h>
#import "SMEasyAudioErrorCheck.h"

@interface SMEasyAudioEngine ()
@property(nonatomic, assign) AUGraph            auGraph;
@end
@implementation SMEasyAudioEngine
{
    NSMutableArray <SMEasyAudioNode *>*_nodes;
    BOOL    _isGraphOpen;
}
- (instancetype)init{
    self = [super init];
    if (self) {
        OSStatus status = NewAUGraph(&_auGraph);
        CheckStatus(status, @"Could not create a new AUGraph", YES);
        [self addAudioSessionInterruptedObserver];
        _nodes = [[NSMutableArray alloc]init];
        _isGraphOpen = NO;
    }
    return self;
}


- (NSError *)attachNode:(SMEasyAudioNode *)node{
    if (!node || ![node isKindOfClass:[SMEasyAudioNode class]]) {
        return nil;
    }
    NSError *error;
    OSStatus status = noErr;
    AudioComponentDescription description = node.acdescription;
    AUNode audioNode;
    status = AUGraphAddNode(_auGraph, &description, &audioNode);
    if (CheckStatus(status, @"Could not add node to AUGraph", YES)) {
        node.audioNode = audioNode;
        [_nodes addObject:node];
    }else{
        error = [SMEasyAudioErrorCheck errorForCode:SMEasyAudioEngineErrorTypeAttachNodeError status:status];
    }
    return error;
}

- (NSError *)detachNode:(SMEasyAudioNode *)node{
    NSError *error = nil;
    error = [self disconnect:node withBus:0];
    if (error) {
        return error;
    }
    AUNode audioNode = node.audioNode;
    OSStatus status = AUGraphRemoveNode(_auGraph, audioNode);
    if (CheckStatus(status, @"Could not detach node to AUGraph", YES)) {
        node.audioNode = 0;
    }else{
        error = [SMEasyAudioErrorCheck errorForCode:SMEasyAudioEngineErrorTypeDetachNodeError status:status];
    }
    return error;
}
- (NSError *)disconnect:(SMEasyAudioNode *)node withBus:(SMEasyAudioNodeBus)inputBus{
    OSStatus status = noErr;
    status = AUGraphDisconnectNodeInput(_auGraph, node.audioNode, inputBus);
    if (!CheckStatus(status, @"Could not disconnect I/O node input", YES)) {
        return [SMEasyAudioErrorCheck errorForCode:SMEasyAudioEngineErrorTypeNodeDisconnectError status:status];
    }
    return nil;
}

- (NSError *)connect:(SMEasyAudioNode *)node1 to:(SMEasyAudioNode *)node2 fromBus:(SMEasyAudioNodeBus)bus1 toBus:(SMEasyAudioNodeBus)bus2{
    return [self connect:node1 to:node2 fromBus:bus1 toBus:bus2 modle:SMEasyAudioNodeConnectModleNormal];
}

- (NSError *)connect:(SMEasyAudioNode *)node1 to:(SMEasyAudioNode *)node2 fromBus:(SMEasyAudioNodeBus)bus1 toBus:(SMEasyAudioNodeBus)bus2 modle:(SMEasyAudioNodeConnectModle)modle{
    NSError *error = nil;
    if (!_isGraphOpen) {
        error = [self openGraph];
        if (error) {
            return error;
        }
    }
    OSStatus status = noErr;
    switch (modle) {
        case SMEasyAudioNodeConnectModleRenderCallBack:
        {
            AURenderCallback renderCallback = node2.nodeBaseRendersCallBack;
            AURenderCallbackStruct renderProc;
            renderProc.inputProc = renderCallback;
            renderProc.inputProcRefCon = (__bridge void *)node2;
            status = AUGraphSetNodeInputCallback(_auGraph, node2.audioNode, bus2, &renderProc);
            CheckStatus(status, @"Could not set InputCallback For IONode", YES);
            node2.perAudioNode = node1;
            node2.perAudioNodeConnectBus = bus1;
        }
            break;
        case SMEasyAudioNodeConnectModleNormal:
        default:
        {
            status = noErr;
            status = AUGraphConnectNodeInput(_auGraph, node1.audioNode, bus1, node2.audioNode, bus2);
            CheckStatus(status, @"Could not connect node1 output to  node2 input", YES);
        }
            break;
    }
#ifdef DEBUG
    [self showDataDescriptionFor:node1 and:node2];
#else
#endif
    if (noErr != status) {
        error = [SMEasyAudioErrorCheck errorForCode:SMEasyAudioEngineErrorTypeNodeConnectError status:status];
    }
    return error;
}

- (void)showDataDescriptionFor:(SMEasyAudioNode *)node1 and:(SMEasyAudioNode *)node2{
    OSStatus status = noErr;
    AudioStreamBasicDescription outputElementOutputStreamFormatForNode1;
    UInt32 size = sizeof(outputElementOutputStreamFormatForNode1);
    if (kAudioUnitSubType_RemoteIO == node1.acdescription.componentSubType || kAudioUnitSubType_VoiceProcessingIO == node1.acdescription.componentSubType) {
        status = AudioUnitGetProperty(node1.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, inputElement, &outputElementOutputStreamFormatForNode1, &size);
        if (!CheckStatus(status, @"Could not get stream format on io unit output scope for inputElement node1", YES)) {
            bzero(&outputElementOutputStreamFormatForNode1, sizeof(outputElementOutputStreamFormatForNode1));
        }
    }else{
        status = AudioUnitGetProperty(node1.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, outputElement, &outputElementOutputStreamFormatForNode1, &size);
        if (!CheckStatus(status, @"Could not get stream format on  unit output scope for outputElement node1", YES)) {
            bzero(&outputElementOutputStreamFormatForNode1, sizeof(outputElementOutputStreamFormatForNode1));
        }
    }
    
    AudioStreamBasicDescription outputElementInputStreamFormatForNode2;
    size = sizeof(outputElementInputStreamFormatForNode2);
    status = AudioUnitGetProperty(node2.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, outputElement, &outputElementInputStreamFormatForNode2, &size);
    if (!CheckStatus(status, @"Could not set stream format on  unit input scope outputElement node2", YES)) {
        bzero(&outputElementInputStreamFormatForNode2, sizeof(outputElementInputStreamFormatForNode2));
    }
    
    printf("node %d ===============================>node %d \n",node1.audioNode,node2.audioNode);
    printf("output                                input  \n");
    printf("%s                                     %s  \n",[typeString(node1.acdescription.componentManufacturer) UTF8String],[typeString(node2.acdescription.componentManufacturer) UTF8String]);
    printf("%s                                     %s  \n",[typeString(node1.acdescription.componentType) UTF8String],[typeString(node2.acdescription.componentType) UTF8String]);
    printf("%s                                     %s  \n",[typeString(node1.acdescription.componentSubType) UTF8String],[typeString(node2.acdescription.componentSubType) UTF8String]);
    printf("%f            mSampleRate                %f  \n",outputElementOutputStreamFormatForNode1.mSampleRate,outputElementInputStreamFormatForNode2.mSampleRate);
    printf("%u            mFormatID                  %u  \n",(unsigned int)outputElementOutputStreamFormatForNode1.mFormatID,(unsigned int)outputElementInputStreamFormatForNode2.mFormatID);
    printf("%u            mFormatFlags               %u  \n",(unsigned int)outputElementOutputStreamFormatForNode1.mFormatFlags,(unsigned int)outputElementInputStreamFormatForNode2.mFormatFlags);
    printf("%u            mBytesPerPacket            %u  \n",(unsigned int)outputElementOutputStreamFormatForNode1.mBytesPerPacket,(unsigned int)outputElementInputStreamFormatForNode2.mBytesPerPacket);
    printf("%u            mFramesPerPacket           %u  \n",(unsigned int)outputElementOutputStreamFormatForNode1.mFramesPerPacket,(unsigned int)outputElementInputStreamFormatForNode2.mFramesPerPacket);
    printf("%u            mBytesPerFrame             %u  \n",(unsigned int)outputElementOutputStreamFormatForNode1.mBytesPerFrame,(unsigned int)outputElementInputStreamFormatForNode2.mBytesPerFrame);
    printf("%u            mChannelsPerFrame          %u  \n",(unsigned int)outputElementOutputStreamFormatForNode1.mChannelsPerFrame,(unsigned int)outputElementInputStreamFormatForNode2.mChannelsPerFrame);
    printf("%u            mBitsPerChannel            %u  \n",(unsigned int)outputElementOutputStreamFormatForNode1.mBitsPerChannel,(unsigned int)outputElementInputStreamFormatForNode2.mBitsPerChannel);
    printf("%u            mReserved                  %u  \n",(unsigned int)outputElementOutputStreamFormatForNode1.mReserved,(unsigned int)outputElementInputStreamFormatForNode2.mReserved);
    
}

- (NSError *)disconnectNode:(SMEasyAudioNode *)node bus:(SMEasyAudioNodeBus)bus{
    NSError *error;
    OSStatus status = noErr;
    status = AUGraphDisconnectNodeInput(_auGraph, node.audioNode, bus);
    if (!CheckStatus(status, @"Could not disconnect  node ", YES)) {
        error = [SMEasyAudioErrorCheck errorForCode:SMEasyAudioEngineErrorTypeNodeDisconnectError status:status];
    }
    return error;
}

- (NSError *)openGraph{
    if (!_isGraphOpen) {
        OSStatus status = AUGraphOpen(_auGraph);
        if (CheckStatus(status, @"open graph fail", YES)) {
            //配置audionode 的audioUnit
            [_nodes enumerateObjectsUsingBlock:^(SMEasyAudioNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                SMEasyAudioNode *node = obj;
                OSStatus status = noErr;
                AudioUnit audioUnit = NULL;
                AUNode audioNode = node.audioNode;
                status = AUGraphNodeInfo(self->_auGraph, audioNode, NULL, &audioUnit);
                node.audioUnit = audioUnit;
                CheckStatus(status, @"Could not retrieve node info for currunt node", YES);
                [node resetAudioUnit];
            }];
            _isGraphOpen = YES;
        }else{
            return [SMEasyAudioErrorCheck errorForCode:SMEasyAudioEngineErrorTypeOpenAUGraphFail status:status];
        }
    }
    return nil;
}

- (NSError*) prepare
{
    
    //初始化auGraph的配置
    CAShow(_auGraph);
    OSStatus status = AUGraphInitialize(_auGraph);
    CheckStatus(status, @"Could not initialize AUGraph", YES);
    if(status != noErr)
    {
        return [SMEasyAudioErrorCheck errorForCode:SMEasyAudioEngineErrorTypeInitializAUGraphFail status:status];
    }
    //做一些render之前的准备
    [_nodes enumerateObjectsUsingBlock:^(SMEasyAudioNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SMEasyAudioNode *node = obj;
        [node prepareForRender];
    }];
    return nil;
}

- (BOOL)startAndReturnError:(NSError *__autoreleasing  _Nullable *)outError{
    if (_auGraph == NULL) {
        return NO;
    }
    Boolean isRunning = false;
    OSStatus status = noErr;
    if (CheckStatus(AUGraphIsRunning(_auGraph, &isRunning), @"get is runing fail", YES)){
        status = noErr;
        if (!isRunning) {
            status = AUGraphStart(_auGraph);
            if (!CheckStatus(status, @"Could not start AUGraph", YES)) {
                if (outError != NULL) {
                    *outError = [SMEasyAudioErrorCheck errorForCode:SMEasyAudioEngineErrorTypeStartAUGraphFail status:status];
                }
                return NO;
            }
        }
    }else{
        return NO;
    }
    return YES;
}


- (NSError *)stop{
    NSError *error = nil;
    Boolean isRunning = false;
    OSStatus status = AUGraphIsRunning(_auGraph, &isRunning);
    if (isRunning)
    {
        status = AUGraphStop(_auGraph);
        if (!CheckStatus(status, @"Could not stop AUGraph", YES)) {
            error = [SMEasyAudioErrorCheck errorForCode:SMEasyAudioEngineErrorTypeStopAUGraphFail status:status];
        }
    }
    return error;
}

- (void)destroyAudioUnitGraph
{
    AUGraphStop(_auGraph);
    _isGraphOpen = NO;
    AUGraphClearConnections(_auGraph);
    AUGraphUninitialize(_auGraph);
    AUGraphClose(_auGraph);
    DisposeAUGraph(_auGraph);
    _auGraph = NULL;
}

- (void)dealloc{
    [self stop];
    [self destroyAudioUnitGraph];
    [self removeAudioSessionInterruptedObserver];
    [_nodes removeAllObjects];
    _nodes = nil;
}

#pragma mark add Interrupted notification
- (void)addAudioSessionInterruptedObserver
{
    [self removeAudioSessionInterruptedObserver];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNotificationAudioInterrupted:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:[AVAudioSession sharedInstance]];
}

- (void)removeAudioSessionInterruptedObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionInterruptionNotification
                                                  object:nil];
}

- (void)onNotificationAudioInterrupted:(NSNotification *)sender {
    AVAudioSessionInterruptionType interruptionType = [[[sender userInfo] objectForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    switch (interruptionType) {
        case AVAudioSessionInterruptionTypeBegan:
            [self stop];
            break;
        case AVAudioSessionInterruptionTypeEnded:
        {
            [self startAndReturnError:nil];
        }
            break;
        default:
            break;
    }
}

@end
