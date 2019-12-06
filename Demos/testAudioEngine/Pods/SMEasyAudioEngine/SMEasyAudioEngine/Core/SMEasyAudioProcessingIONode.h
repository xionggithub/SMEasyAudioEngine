//
//  SMEasyAudioProcessingIONode.h
//  StarMaker
//
//  Created by 熊先提 on 2018/3/19.
//  Copyright © 2018年 uShow. All rights reserved.
//

#import "SMEasyAudioNode.h"

@interface SMEasyAudioProcessingIONode : SMEasyAudioNode
@property (nonatomic ,assign) BOOL enableInput;

- (void) setAudioUnitStreamFormat:(AudioStreamBasicDescription) inputElementFormat outputElementFormat:(AudioStreamBasicDescription)outputElementFormat;
@end
