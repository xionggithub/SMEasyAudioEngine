//
//  SMEasyAudioVoiceRecordNode.m
//  SMAudioEngine
//
//  Created by 熊先提 on 2017/8/20.
//  Copyright © 2017年 熊先提. All rights reserved.
//

#import "SMEasyAudioRecordNode.h"

@interface SMEasyAudioRecordNode ()

@end

@implementation SMEasyAudioRecordNode
{
    ExtAudioFileRef _finalAudioFile;
}
@synthesize filePath = _filePath;
- (NSURL *)filePath{
    return _filePath;
}
- (instancetype)initWithRecordFilePath:(NSURL *)path{
    self = [super init];
    if (self) {
        AudioComponentDescription description;
        bzero(&description, sizeof(description));
        description.componentManufacturer = kAudioUnitManufacturer_Apple;
        description.componentType = kAudioUnitType_FormatConverter;
        description.componentSubType = kAudioUnitSubType_AUConverter;
        self.acdescription = description;
        _filePath = path;
        self.nodeCustomProcessCallBack = &recordAudioCallback;
        self.asyncWrite = YES;
    }
    return self;
}



- (void)resetAudioUnit{
    [super resetAudioUnit];
    AudioStreamBasicDescription outputElementInputStreamFormat = [self inputStreamFormat];
    AudioStreamBasicDescription outputElementOutputStreamFormat = [self outputStreamFormat];

    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, outputElement, &outputElementInputStreamFormat, sizeof(outputElementInputStreamFormat));
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, outputElement, &outputElementOutputStreamFormat, sizeof(outputElementOutputStreamFormat));
    
    [self prepareFinalWriteFile];
}
- (void)prepareForRender{
    [super prepareForRender];
}

- (void)prepareFinalWriteFile{
    
    NSError *error;
    AudioStreamBasicDescription outputElementInputStreamFormat = [self inputStreamFormat];
    //create file
    _finalAudioFile = SMEasyAudioEngineM4aExtAudioFileCreate(_filePath, [SMEasyAudioConstants getSampleRate], outputElementInputStreamFormat.mChannelsPerFrame, &error, 0);
    NSLog(@"create record file %@",error);
    if (!_finalAudioFile) {
        return;
    }
    //    // This is a very important part and easiest way to set the ASBD for the File with correct format.
    AudioStreamBasicDescription clientFormat;
    UInt32 fSize = sizeof (clientFormat);
    memset(&clientFormat, 0, sizeof(clientFormat));
    // get the audio data format from the Output Unit
    CheckStatus(AudioUnitGetProperty(self.audioUnit,
                                     kAudioUnitProperty_StreamFormat,
                                     kAudioUnitScope_Output,
                                     0,
                                     &clientFormat,
                                     &fSize),@"AudioUnitGetProperty on failed", YES);
    
    // set the audio data format of mixer Unit
    CheckStatus(ExtAudioFileSetProperty(_finalAudioFile,
                                        kExtAudioFileProperty_ClientDataFormat,
                                        sizeof(clientFormat),
                                        &clientFormat),
                @"ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat failed", YES);
    
    
    // specify codec
    UInt32 codec = kAppleHardwareAudioCodecManufacturer;
    CheckStatus(ExtAudioFileSetProperty(_finalAudioFile,
                                        kExtAudioFileProperty_CodecManufacturer,
                                        sizeof(codec),
                                        &codec),@"ExtAudioFileSetProperty on extAudioFile Faild", YES);
    
    CheckStatus(ExtAudioFileWriteAsync(_finalAudioFile, 0, NULL),@"ExtAudioFileWriteAsync Failed", YES);
}
- (void)finish{
    ExtAudioFileDispose(_finalAudioFile);
    _finalAudioFile = NULL;
    NSLog(@"finish write");
    NSURL *path = _filePath;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSData *data = [NSData dataWithContentsOfURL:path];
        NSLog(@"file data size %lu",(unsigned long)data.length);
    });
}




static OSStatus recordAudioCallback(void *inRefCon, const AudioTimeStamp *inTimeStamp, const UInt32 inNumberFrames, AudioBufferList *ioData)
{
    OSStatus result = noErr;
    __unsafe_unretained SMEasyAudioRecordNode *self = (__bridge SMEasyAudioRecordNode *)inRefCon;
    if (self->_finalAudioFile) {
        if (self.asyncWrite) {
            result = ExtAudioFileWriteAsync(self->_finalAudioFile, inNumberFrames, ioData);
        }else{
            result = ExtAudioFileWrite(self->_finalAudioFile, inNumberFrames, ioData);
        }
    }
    return result;
}
@end