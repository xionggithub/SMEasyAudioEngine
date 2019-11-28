//
//  SMEasyAudioConstants.m
//  SMAudioEngine
//
//  Created by xiaoxiong on 2017/8/21.
//  Copyright © 2017年 熊先提. All rights reserved.
//

#import "SMEasyAudioConstants.h"
#import "SMEasyAudioErrorCheck.h"
#import <AudioToolbox/AudioToolbox.h>
#import <sys/xattr.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>

@implementation SMEasyAudioConstants
//双声道 双buffer采集
//LLLLLLL
//RRRRRRR

const AudioStreamBasicDescription SMEasyAudioNonInterleavedFloatStereoAudioDescription = {
    .mFormatID          = kAudioFormatLinearPCM,
    .mFormatFlags       = kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved,
    .mChannelsPerFrame  = 2,
    .mBytesPerPacket    = sizeof(float),
    .mFramesPerPacket   = 1,
    .mBytesPerFrame     = sizeof(float),
    .mBitsPerChannel    = 8 * sizeof(float),
    .mSampleRate        = 48000,
};
//双声道 单buffer采集
//LRLRLRLRLRLRLRLRL
const AudioStreamBasicDescription SMEasyAudioIsPackedFloatStereoAudioDescription = {
    .mFormatID          = kAudioFormatLinearPCM,
    .mFormatFlags       = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked,
    .mChannelsPerFrame  = 2,
    .mBytesPerPacket    = sizeof(float)*2,
    .mFramesPerPacket   = 1,
    .mBytesPerFrame     = sizeof(float)*2,
    .mBitsPerChannel    = 8 * sizeof(float),
    .mSampleRate        = 48000,
};

//单声道单buffer
const AudioStreamBasicDescription SMEasyAudioNonInterleavedFloatMonoAudioDescription = {
    .mFormatID          = kAudioFormatLinearPCM,
    .mFormatFlags       = kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved,
    .mChannelsPerFrame  = 1,
    .mBytesPerPacket    = sizeof(float),
    .mFramesPerPacket   = 1,
    .mBytesPerFrame     = sizeof(float),
    .mBitsPerChannel    = 8 * sizeof(float),
    .mSampleRate        = 48000,
};


const AudioStreamBasicDescription  SMEasyAudioNonInterleaved16BitStereoAudioDescription = {
    .mFormatID          = kAudioFormatLinearPCM,
    .mFormatFlags       = kAudioFormatFlagIsSignedInteger  |
    kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsNonInterleaved,
    .mChannelsPerFrame  = 2,
    .mBytesPerPacket    = sizeof(SInt16),
    .mFramesPerPacket   = 1,
    .mBytesPerFrame     = sizeof(SInt16),
    .mBitsPerChannel    = 8 * sizeof(SInt16),
    .mSampleRate        = 48000,
};

const AudioStreamBasicDescription  SMEasyAudioIsPacked16BitStereoAudioDescription = {
    .mFormatID          = kAudioFormatLinearPCM,
    .mFormatFlags       = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked |
    kAudioFormatFlagsNativeEndian,
    .mChannelsPerFrame  = 2,
    .mBytesPerPacket    = sizeof(SInt16)*2,
    .mFramesPerPacket   = 1,
    .mBytesPerFrame     = sizeof(SInt16)*2,
    .mBitsPerChannel    = 8 * sizeof(SInt16),
    .mSampleRate        = 48000,
};

const AudioStreamBasicDescription  SMEasyAudioNonInterleavedFloatStereoAndMonoAudioDescription = {
    .mFormatID          = kAudioFormatLinearPCM,
    .mFormatFlags       = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved,
    .mChannelsPerFrame  = 2,
    .mBytesPerPacket    = sizeof(float),
    .mFramesPerPacket   = 1,
    .mBytesPerFrame     = sizeof(float),
    .mBitsPerChannel    = 8 * sizeof(float),
    .mSampleRate        = 48000,
};

const int   SMEasyAudioNodeMaximumFramesPerSlice = 4096;

static int creat_file_loop = 0;


+ (double) getSampleRate
{
    NSString *deviceModel = [self deviceModel];
    NSInteger model = [self deviceGeneration];
    
    // iPhone 6S及以上的手机，使用48000
    if (([deviceModel rangeOfString:@"iPhone"].location != NSNotFound) && (model >= 8)) {
        return 48000.0;
    }
    return 44100.0;
}

+ (NSString*)deviceModel
{
    // Check for device type
    size_t s;
    sysctlbyname("hw.machine", NULL, &s, NULL, 0);
    char *model = malloc(s);
    sysctlbyname("hw.machine", model, &s, NULL, 0);
    NSString *deviceModel = [NSString stringWithCString:model encoding:NSUTF8StringEncoding];
    free(model);
    return deviceModel;
}
+ (NSInteger)deviceGeneration{
    NSString *deviceModel = [self deviceModel];
    NSInteger generation = 0;

    @try {
        NSArray *array = [deviceModel componentsSeparatedByString:@","];
        NSString *iphoneModel = [array firstObject];
        // 将设备类型信息给清理掉
        iphoneModel = [iphoneModel stringByReplacingOccurrencesOfString:@"iPhone" withString:@""];
        iphoneModel = [iphoneModel stringByReplacingOccurrencesOfString:@"iPad" withString:@""];
        iphoneModel = [iphoneModel stringByReplacingOccurrencesOfString:@"iPod" withString:@""];
        
        // 得到设备代数
        generation = [iphoneModel integerValue];
    } @catch (NSException *exception) {
        
    }
    
    return generation;
}

ExtAudioFileRef SMEasyAudioEngineM4aExtAudioFileCreate(NSURL * url, double sampleRate, int channelCount,
                                           NSError ** error, OSStatus lastStatus) {
    
    if (lastStatus == noErr) {
        creat_file_loop = 0;
    }
    AudioStreamBasicDescription asbd = {
        .mChannelsPerFrame = channelCount,
        .mSampleRate = sampleRate,
    };
    AudioFileTypeID fileTypeID;
    
    // AAC encoding in M4A container
    // Get the output audio description for encoding AAC
    asbd.mFormatID = kAudioFormatMPEG4AAC;
    UInt32 size = sizeof(asbd);
    OSStatus status = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &asbd);
    if ( !CheckStatus(status,@"AudioFormatGetProperty(kAudioFormatProperty_FormatInfo",YES) ) {
        int fourCC = CFSwapInt32HostToBig(status);
        if ( error ) *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                                  code:status
                                              userInfo:@{ NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Couldn't prepare the output format (error %d/%4.4s)", (int)status, (char*)&fourCC]}];
        return NULL;
    }
    fileTypeID = kAudioFileM4AType;
    
    // Open the file
    ExtAudioFileRef audioFile;
    status = noErr;
    CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                            (CFStringRef)url.path,
                                                            kCFURLPOSIXPathStyle,
                                                            false);
    status = ExtAudioFileCreateWithURL(destinationURL, fileTypeID, &asbd, NULL, kAudioFileFlags_EraseFile,
                                       &audioFile);
    CFRelease(destinationURL);
    if ( !CheckStatus(status, @"ExtAudioFileCreateWithURL",YES) ) {
        if ( error )
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:status
                                     userInfo:@{ NSLocalizedDescriptionKey:@"Couldn't open the output file"}];
        return NULL;
    }
    
    
    if (lastStatus == kAudioConverterErr_HardwareInUse) {
        UInt32 codec = kAppleSoftwareAudioCodecManufacturer;
        status = ExtAudioFileSetProperty(audioFile, kExtAudioFileProperty_CodecManufacturer, sizeof(codec), &codec);
        if ( !CheckStatus(status, @"ExtAudioFileSetProperty",YES) ) {
            ExtAudioFileDispose(audioFile);
            if ( error )
                *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                             code:status
                                         userInfo:@{ NSLocalizedDescriptionKey:@"kExtAudioFileProperty_CodecManufacturer fail"}];
        }
    }
    // Set the client format
    asbd = SMEasyAudioNonInterleavedFloatStereoAudioDescription;
    asbd.mChannelsPerFrame = channelCount;
    asbd.mSampleRate = sampleRate;
    status = ExtAudioFileSetProperty(audioFile,
                                     kExtAudioFileProperty_ClientDataFormat,
                                     sizeof(asbd),
                                     &asbd);
    if ( !CheckStatus(status, @"ExtAudioFileSetProperty",YES) ) {
        ExtAudioFileDispose(audioFile);
        if ( error )
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:status
                                     userInfo:@{ NSLocalizedDescriptionKey:@"Couldn't configure the file writer"}];
        creat_file_loop ++;
        if (creat_file_loop > 2) {
            return NULL;
        }
        *error = nil;
        return SMEasyAudioEngineM4aExtAudioFileCreate(url, sampleRate, channelCount, error, status);
    }
    
    return audioFile;
}
@end
