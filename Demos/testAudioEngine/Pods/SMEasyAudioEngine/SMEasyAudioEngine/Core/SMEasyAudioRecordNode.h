//
//  SMEasyAudioVoiceRecordNode.h
//  SMAudioEngine
//
//  Created by 熊先提 on 2017/8/20.
//  Copyright © 2017年 熊先提. All rights reserved.
//

#import "SMEasyAudioNode.h"

@interface SMEasyAudioRecordNode : SMEasyAudioNode
@property (nonatomic, copy, readonly) NSURL *filePath;
@property (nonatomic, assign) BOOL asyncWrite;
- (void)createNewRecordFileAtPath:(NSURL *)path;
- (void)finish;
@end
