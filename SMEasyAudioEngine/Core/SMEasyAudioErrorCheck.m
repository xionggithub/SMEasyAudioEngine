//
//  SMEasyAudioErrorCheck.m
//  SMAudioEngine
//
//  Created by 熊先提 on 2017/8/20.
//  Copyright © 2017年 熊先提. All rights reserved.
//

#import "SMEasyAudioErrorCheck.h"
#import <AudioToolbox/AudioToolbox.h>

NSString *const SMEasyAudioErrorCheckNotificationKey = @"kSMEasyAudioErrorCheckNotificationKey";

@implementation SMEasyAudioErrorCheck

NSString *SMAudioUnitErrorMessage(OSStatus status);
NSString* typeString(OSType type){
    char fourCC[16];
    *(UInt32 *)fourCC = CFSwapInt32HostToBig(type);
    fourCC[4] = '\0';
    
    NSString *typeString = nil;
    if(isprint(fourCC[0]) && isprint(fourCC[1]) && isprint(fourCC[2]) && isprint(fourCC[3]))
        typeString = [NSString stringWithFormat:@"%s", fourCC];
    else
        typeString = [NSString stringWithFormat:@"%d", (unsigned int)type];
    return typeString;
}
bool CheckStatus(OSStatus status, NSString *message, BOOL fatal)
{
    if(status != noErr)
    {
        char fourCC[16];
        *(UInt32 *)fourCC = CFSwapInt32HostToBig(status);
        fourCC[4] = '\0';
        
        NSString *debugMessage = nil;
        if(isprint(fourCC[0]) && isprint(fourCC[1]) && isprint(fourCC[2]) && isprint(fourCC[3]))
            debugMessage = [NSString stringWithFormat:@"%@: %s  %d", message, fourCC, (int)status];
        else
            debugMessage = [NSString stringWithFormat:@"%@: %d", message, (int)status];
        
        NSString *errorMessage = SMAudioUnitErrorMessage(status);
        NSLog(@"%@ %@",debugMessage,errorMessage);
        
        if (fatal) {
#ifdef DEBUG
            assert(fatal);
#else
#endif
            [[NSNotificationCenter defaultCenter] postNotificationName:SMEasyAudioErrorCheckNotificationKey object:message];
        }
        return false;
    }else{
        return true;
    }
}
//显示的可能不对
NSString *SMAudioUnitErrorMessage(OSStatus status){
    NSString *errorMessage = nil;
    switch (status) {
        case kAudioUnitErr_InvalidProperty:
            errorMessage = @"kAudioUnitErr_InvalidProperty";
            break;
        case kAudioUnitErr_InvalidParameter:
            errorMessage = @"kAudioUnitErr_InvalidParameter";
            break;
        case kAudioUnitErr_InvalidElement:
            errorMessage = @"kAudioUnitErr_InvalidElement";
            break;
        case kAudioUnitErr_NoConnection:
            errorMessage = @"kAudioUnitErr_NoConnection";
            break;
        case kAudioUnitErr_FailedInitialization:
            errorMessage = @"kAudioUnitErr_FailedInitialization";
            break;
        case kAudioUnitErr_TooManyFramesToProcess:
            errorMessage = @"kAudioUnitErr_TooManyFramesToProcess";
            break;
        case kAudioUnitErr_InvalidFile:
            errorMessage = @"kAudioUnitErr_InvalidFile";
            break;
        case kAudioUnitErr_UnknownFileType:
            errorMessage = @"kAudioUnitErr_UnknownFileType";
            break;
        case kAudioUnitErr_FileNotSpecified:
            errorMessage = @"kAudioUnitErr_FileNotSpecified";
            break;
        case kAudioUnitErr_FormatNotSupported:
            errorMessage = @"kAudioUnitErr_FormatNotSupported";
            break;
        case kAudioUnitErr_Uninitialized:
            errorMessage = @"kAudioUnitErr_Uninitialized";
            break;
        case kAudioUnitErr_InvalidScope:
            errorMessage = @"kAudioUnitErr_InvalidScope";
            break;
        case kAudioUnitErr_PropertyNotWritable:
            errorMessage = @"kAudioUnitErr_PropertyNotWritable";
            break;
        case kAudioUnitErr_CannotDoInCurrentContext:
            errorMessage = @"kAudioUnitErr_CannotDoInCurrentContext";
            break;
        case kAudioUnitErr_InvalidPropertyValue:
            errorMessage = @"kAudioUnitErr_InvalidPropertyValue";
            break;
        case kAudioUnitErr_PropertyNotInUse:
            errorMessage = @"kAudioUnitErr_PropertyNotInUse";
            break;
        case kAudioUnitErr_Initialized:
            errorMessage = @"kAudioUnitErr_Initialized";
            break;
        case kAudioUnitErr_InvalidOfflineRender:
            errorMessage = @"kAudioUnitErr_InvalidOfflineRender";
            break;
        case kAudioUnitErr_Unauthorized:
            errorMessage = @"kAudioUnitErr_Unauthorized";
            break;
        case kAudioComponentErr_InstanceInvalidated:
            errorMessage = @"kAudioComponentErr_InstanceInvalidated";
            break;
        case kAudioUnitErr_RenderTimeout:
            errorMessage = @"kAudioUnitErr_RenderTimeout";
            break;
        default:
        {
            char fourCC[16];
            *(UInt32 *)fourCC = CFSwapInt32HostToBig(status);
            fourCC[4] = '\0';
            
            if(isprint(fourCC[0]) && isprint(fourCC[1]) && isprint(fourCC[2]) && isprint(fourCC[3])){
                errorMessage = [NSString stringWithFormat:@"%s", fourCC];
            }else{
                errorMessage = @"kAudioUnitErr_Other";
            }
        }
            break;
    }
    return errorMessage;
}
void  CAAudioTimeStampShow(AudioTimeStamp time){
    printf("show AudioTimeStamp :\n");
    printf("    mSampleTime     :%f\n",time.mSampleTime);
    printf("    mHostTime       :%llu\n",time.mHostTime);
    printf("    mRateScalar     :%f\n",time.mRateScalar);
    printf("    mWordClockTime  :%llu\n",time.mWordClockTime);
    printf("    mSMPTETime:\n");
    printf("        mSubframes          :%d\n",time.mSMPTETime.mSubframes);
    printf("        mSubframeDivisor    :%d\n",time.mSMPTETime.mSubframeDivisor);
    printf("        mCounter            :%d\n",time.mSMPTETime.mCounter);
    printf("        mType               :%d\n",time.mSMPTETime.mType);
    printf("        mFlags              :%d\n",time.mSMPTETime.mFlags);
    printf("        mHours              :%d\n",time.mSMPTETime.mHours);
    printf("        mMinutes            :%d\n",time.mSMPTETime.mMinutes);
    printf("        mSeconds            :%d\n",time.mSMPTETime.mSeconds);
    printf("        mFrames             :%d\n",time.mSMPTETime.mFrames);
    printf("    mFlags          :%d\n",time.mFlags);
    printf("    mReserved       :%d\n",time.mReserved);

}



+ (NSError *)errorForCode:(SMEasyAudioEngineErrorType)errorCode status:(OSStatus)status{
    NSError *ktvError = nil;
    NSString *description = SMAudioUnitErrorMessage(status);
    ktvError = [NSError errorWithDomain:@"SMEasyAudioEngineErroDomain" code:errorCode userInfo:@{NSLocalizedDescriptionKey:description}];
    return ktvError;
}
@end
