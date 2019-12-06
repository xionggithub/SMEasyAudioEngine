//
//  SMEasyAudioOutputNode.h
//  SMEasyAudioEngine
//
//  Created by xiaoxiong on 2017/8/26.
//  Copyright © 2017年 xiaoxiong. All rights reserved.
//

#import "SMEasyAudioNode.h"


@protocol SMEasyAudioOutputNodeDelegate <NSObject>

@optional
-(void)audioOutput:(AudioBufferList *)buffer frame:(int)frame audioTime:(AudioTimeStamp *)audioTime;

@end
@interface SMEasyAudioOutputNode : SMEasyAudioNode
@property (nonatomic, weak)id<SMEasyAudioOutputNodeDelegate>delegate;
@end
