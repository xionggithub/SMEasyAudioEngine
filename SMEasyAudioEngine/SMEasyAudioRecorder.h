//
//  SMEasyAudioRecorder.h
//  testAudioEngine
//
//  Created by xiaoxiong on 2019/11/28.
//  Copyright © 2019 xiaoxiong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface SMEasyAudioRecorder : NSObject
- (nullable instancetype)initWithURL:(NSURL *)url format:(AVAudioFormat *)format error:(NSError **)outError;
- (BOOL)record;
- (void)pause;
- (void)stop;
@end

NS_ASSUME_NONNULL_END
