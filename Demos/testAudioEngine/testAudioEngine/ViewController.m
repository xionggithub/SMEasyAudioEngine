//
//  ViewController.m
//  testAudioEngine
//
//  Created by xiaoxiong on 2019/11/28.
//  Copyright © 2019 xiaoxiong. All rights reserved.
//

#import "ViewController.h"

#import <SMEasyAudioEngine/SMEasyAudioRecorder.h>
#import <SMEasyAudioEngine/SMEasyAudioEngine.h>
#import <SMEasyAudioEngine/SMEasyAudioMixerNode.h>
#import <SMEasyAudioEngine/SMEasyAudioIONode.h>
#import <SMEasyAudioEngine/SMEasyAudioRecordNode.h>
#import <SMEasyAudioEngine/SMEasyAudioProcessingIONode.h>
#import <SMEasyAudioEngine/SMEasyAudioFloatToInt16OutPutNode.h>
#import <SMEasyAudioEngine/SMEasyAudioPlayerNode.h>
#import <SMEasyAudioEngine/SMEasyAudioConvertNode.h>
#import <SMEasyAudioEngine/SMEasyAudioSession.h>
#import <SMEasyAudioEngine/SMEasyAudioConvertNode.h>
#import <SMEasyAudioEngine/SMEasyAudioNewTimePitchNode.h>
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UISlider *slider;

@end

@implementation ViewController
{
    SMEasyAudioEngine *_audioEngine;
    SMEasyAudioRecordNode *_recordNode;
    SMEasyAudioRecordNode *_recordNodeOne;
    SMEasyAudioIONode *_IONode;
    SMEasyAudioMixerNode *_mixNode;
    SMEasyAudioPlayerNode *_playerNode;
    SMEasyAudioNewTimePitchNode *_pitchNode;
    SMEasyAudioConvertNode *_ffoTofeconvertNode;//44100-48000
    SMEasyAudioConvertNode *_feToffoconvertNode;//48000-44100
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSURL *audioURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"test3" ofType:@"m4a"]];
    AVURLAsset *asset = [AVURLAsset assetWithURL:audioURL];
    CMTimeShow(asset.duration);
    
    [self configConvert];
    
    self.slider.value = [_pitchNode getNewTimePitch];
    NSLog(@"getNewTimePitch %f",self.slider.value);
    self.slider.minimumValue = -2400;
    self.slider.maximumValue = 2400;
}
- (void)configConvert{
    SMEasyAudioEngine *engine = [[SMEasyAudioEngine alloc]init];
    _audioEngine = engine;
    
    NSURL *audioURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"test3" ofType:@"m4a"]];
    SMEasyAudioPlayerNode *playerNode = [[SMEasyAudioPlayerNode alloc]initWithFile:audioURL];
    _playerNode = playerNode;
    
    SMEasyAudioNewTimePitchNode *pitchNode = [[SMEasyAudioNewTimePitchNode alloc]init];
    _pitchNode = pitchNode;
    
    SMEasyAudioMixerNode *mixNode = [[SMEasyAudioMixerNode alloc] initWithMixerElementCount:2];
    _mixNode = mixNode;
    
    SMEasyAudioIONode *ioNode = [[SMEasyAudioIONode alloc]init];
    _IONode = ioNode;
    
    SMEasyAudioConvertNode *ffoTofeconvertNode = [[SMEasyAudioConvertNode alloc]init];
    _ffoTofeconvertNode = ffoTofeconvertNode;
    AudioStreamBasicDescription desc = SMEasyAudioNonInterleavedFloatStereoAudioDescription;
    desc.mSampleRate = 44100;
    ffoTofeconvertNode.inputStreamFormat = desc;
    
    SMEasyAudioConvertNode *feToffoconvertNode = [[SMEasyAudioConvertNode alloc]init];
    _feToffoconvertNode = feToffoconvertNode;
    feToffoconvertNode.outputStreamFormat = desc;
    
    
    NSURL *audioWriteURL = [NSURL fileURLWithPath:[self tmpAudioFilePath:@"1"]];
    SMEasyAudioRecordNode *recordNode = [[SMEasyAudioRecordNode alloc] init];
    [recordNode createNewRecordFileAtPath:audioWriteURL];
    _recordNode = recordNode;
    
    
    audioWriteURL = [NSURL fileURLWithPath:[self tmpAudioFilePath:@"2"]];
    SMEasyAudioRecordNode *recordNodeOne = [[SMEasyAudioRecordNode alloc] init];
    [recordNodeOne createNewRecordFileAtPath:audioWriteURL];

    _recordNodeOne = recordNodeOne;
    recordNodeOne.inputStreamFormat = desc;
    recordNodeOne.outputStreamFormat = desc;

    
    [engine attachNode:ioNode];
    [engine attachNode:playerNode];
    [engine attachNode:pitchNode];
    [engine attachNode:mixNode];
    [engine attachNode:feToffoconvertNode];
    [engine attachNode:ffoTofeconvertNode];
    [engine attachNode:recordNode];
    [engine attachNode:recordNodeOne];

    [engine connect:ioNode to:mixNode fromBus:1 toBus:0];
    [engine connect:playerNode to:pitchNode fromBus:0 toBus:0];
    [engine connect:pitchNode to:mixNode fromBus:0 toBus:1];
    [engine connect:mixNode to:recordNode fromBus:0 toBus:0 modle:SMEasyAudioNodeConnectModleRenderCallBack];
    [engine connect:recordNode to:feToffoconvertNode fromBus:0 toBus:0];
    [engine connect:feToffoconvertNode to:recordNodeOne fromBus:0 toBus:0 modle:SMEasyAudioNodeConnectModleRenderCallBack];
    [engine connect:recordNodeOne to:ffoTofeconvertNode fromBus:0 toBus:0];
    [engine connect:ffoTofeconvertNode to:ioNode fromBus:0 toBus:0];

    [engine prepare];
    
    [mixNode setInputVolume:0 value:0];

}
- (void)resetAudioCapture{
    UInt32 sampleRate = [SMEasyAudioConstants getSampleRate];
    [[SMEasyAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord];
    [[SMEasyAudioSession sharedInstance] setPreferredSampleRate:sampleRate];
    
}

- (IBAction)start:(id)sender {
    [self resetAudioCapture];
    NSError *error;
    [_audioEngine startAndReturnError:&error];
}
- (IBAction)stop:(id)sender {
    [_audioEngine stop];
    [_recordNode finish];
    [_recordNodeOne finish];
}
- (IBAction)sliderValueChanged:(id)sender {
    UISlider *slider = (UISlider *)sender;
    [_pitchNode setNewTimePitch:slider.value];
}


- (NSString *)tmpAudioFilePath:(NSString *)name{
    NSString *tmpPath = [NSString stringWithFormat:@"%@/tmp-%@.m4a",[self tmpAudioFileRootPath],name];
    [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
    return tmpPath;
}
- (NSString *)tmpAudioFileRootPath{
    NSString *docPath  = [self documentDirectory];
    NSString *tmpServerRootPath = [docPath stringByAppendingPathComponent:@"Audio"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:tmpServerRootPath]) {
        NSError *error = nil;
        BOOL create = [fm createDirectoryAtPath:tmpServerRootPath withIntermediateDirectories:NO attributes:nil error:&error];
        if (!create || error) {
            NSLog(@"创建Audio缓存根目录失败");
        }
    }
    return tmpServerRootPath;
}
- (NSString *)documentDirectory{
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    return path;
}
- (NSString *)cacheDirectory{
    NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    return path;
}

@end
