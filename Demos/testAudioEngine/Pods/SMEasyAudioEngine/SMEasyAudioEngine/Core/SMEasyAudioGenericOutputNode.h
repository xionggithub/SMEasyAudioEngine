//
//  SMEasyAudioPullNode.h
//  AudioRenderTest
//
//  Created by xiaoxiong on 2019/11/27.
//  Copyright © 2019 xiaoxiong. All rights reserved.
//

#import "SMEasyAudioNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMEasyAudioGenericOutputNode : SMEasyAudioNode
@property(nonatomic , assign) NSUInteger  totalFrames;
@property (copy, nonatomic) void (^offlineRenderProgressBlock)(CGFloat progress);
@property (copy, nonatomic) void (^offlineRenderCompleteBlock)(NSError *error);

- (BOOL)startOfflineRender;
@end

NS_ASSUME_NONNULL_END
