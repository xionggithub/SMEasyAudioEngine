//
//  SMEasyAudioRecorder.m
//  testAudioEngine
//
//  Created by xiaoxiong on 2019/11/28.
//  Copyright © 2019 xiaoxiong. All rights reserved.
//

#import "SMEasyAudioRecorder.h"
#import "SMEasyAudioEngine.h"
#import "SMEasyAudioIONode.h"
#import "SMEasyAudioRecordNode.h"
#import "SMEasyAudioSession.h"

@implementation SMEasyAudioRecorder
{
    SMEasyAudioEngine *_audioEngine;
    SMEasyAudioRecordNode *_recordNode;
    SMEasyAudioIONode *_IONode;
}
- (nullable instancetype)initWithURL:(NSURL *)url format:(AVAudioFormat *)format error:(NSError **)outError{
    if (self = [super init]) {
        SMEasyAudioEngine *engine = [[SMEasyAudioEngine alloc]init];
        _audioEngine = engine;
        
        
        SMEasyAudioIONode *ioNode = [[SMEasyAudioIONode alloc]init];
        _IONode = ioNode;
        
        SMEasyAudioRecordNode *recordNode = [[SMEasyAudioRecordNode alloc] initWithRecordFilePath:url];
        _recordNode = recordNode;

        
        [engine attachNode:ioNode];
        [engine attachNode:recordNode];

        [engine connect:ioNode to:recordNode fromBus:1 toBus:0 modle:SMEasyAudioNodeConnectModleRenderCallBack];
        [engine connect:recordNode to:ioNode fromBus:0 toBus:0];

        [engine prepare];
    }
    return self;
}
- (void)resetAudioCapture{
    UInt32 sampleRate = [SMEasyAudioConstants getSampleRate];
    [[SMEasyAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord];
    [[SMEasyAudioSession sharedInstance] setPreferredSampleRate:sampleRate];
}
- (BOOL)record{
    [self resetAudioCapture];
    NSError *error;
   return [_audioEngine startAndReturnError:&error];
}
- (void)pause{
    [_audioEngine stop];
}
- (void)stop{
    [_audioEngine stop];
    [_recordNode finish];
}
@end
