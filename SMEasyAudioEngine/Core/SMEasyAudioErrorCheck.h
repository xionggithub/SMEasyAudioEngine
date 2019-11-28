//
//  SMEasyAudioErrorCheck.h
//  SMAudioEngine
//
//  Created by 熊先提 on 2017/8/20.
//  Copyright © 2017年 熊先提. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>

typedef NS_ENUM(NSInteger,SMEasyAudioEngineErrorType) {
    SMEasyAudioEngineErrorTypeNone                          = 0,
    SMEasyAudioEngineErrorTypeAttachNodeError               = -10000001,//SMEasyAudioEngine 的AUGraph 绑定AUNode 错误
    SMEasyAudioEngineErrorTypeDetachNodeError               = -10000002,//SMEasyAudioEngine 的AUGraph 解绑AUNode 错误
    SMEasyAudioEngineErrorTypeNodeConnectError              = -10000003,//SMEasyAudioEngine 的AUGraph 连接AUNode 错误
    SMEasyAudioEngineErrorTypeNodeDisconnectError           = -10000004,//SMEasyAudioEngine 的AUGraph AUNode断开连接 错误
    SMEasyAudioEngineErrorTypeInitializAUGraphFail          = -10000005,//SMEasyAudioEngine 初始化AUGraph失败
    SMEasyAudioEngineErrorTypeOpenAUGraphFail               = -10000006,//SMEasyAudioEngine 打开AUGraph失败
    SMEasyAudioEngineErrorTypeStartAUGraphFail              = -10000007,//SMEasyAudioEngine 启动AUGraph失败
    SMEasyAudioEngineErrorTypeStopAUGraphFail               = -10000008,//SMEasyAudioEngine 停止并关闭AUGraph失败

};

@interface SMEasyAudioErrorCheck : NSObject
extern NSString *const SMEasyAudioErrorCheckNotificationKey;
extern bool CheckStatus(OSStatus status, NSString *message, BOOL fatal);
extern void CAAudioTimeStampShow(AudioTimeStamp time);
extern NSString* typeString(OSType type);
+ (NSError *)errorForCode:(SMEasyAudioEngineErrorType)errorCode status:(OSStatus)status;
@end
