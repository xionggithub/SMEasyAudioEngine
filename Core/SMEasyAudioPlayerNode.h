//
//  SMEasyAudioPlayerNode.h
//  SMAudioEngine
//
//  Created by xiaoxiong on 2017/8/21.
//  Copyright © 2017年 熊先提. All rights reserved.
//

#import "SMEasyAudioNode.h"

@class SMEasyAudioPlayerNode;
@protocol SMEasyAudioPlayerNodeDelegate <NSObject>
@optional

/**
 player node 停止播放的回调

 @param player 当前player
 @param finish 当前停止播放，是否是播放完成
 */
- (void)player:(SMEasyAudioPlayerNode *)player didStopPlayForFinish:(BOOL)finish;

@end
@interface SMEasyAudioPlayerNode : SMEasyAudioNode

@property (nonatomic, assign)id<SMEasyAudioPlayerNodeDelegate>delegate;

- (instancetype)initWithFile:(NSURL *)filePath;

- (NSTimeInterval)currentAudioTime;

- (void) musicPlayFrames:(UInt32)numberFrames;

- (NSTimeInterval)audioDuration;

- (void) playMusicFile:(NSURL *)filePath;

- (void) pauseMusic;

- (void) resumeMusic;
@end
