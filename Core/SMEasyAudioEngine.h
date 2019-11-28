//
//  SMEasyAudioEngine.h
//  SMAudioEngine
//
//  Created by 熊先提 on 2017/8/20.
//  Copyright © 2017年 熊先提. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVFAudio.h>
#import "SMEasyAudioType.h"
typedef NS_ENUM(NSInteger, SMEasyAudioNodeConnectModle) {
    SMEasyAudioNodeConnectModleNormal,        //普通连接模式
    SMEasyAudioNodeConnectModleRenderCallBack //添加render回调得连接
};

@class SMEasyAudioNode;
@interface SMEasyAudioEngine : NSObject



/**
 添加节点

 @param node 节点
 */
- (NSError *)attachNode:(SMEasyAudioNode *)node;

/**
 取消节点

 @param node 节点
 */
- (NSError *)detachNode:(SMEasyAudioNode *)node;

/**
 @param node1 节点1
 @param node2 节点2
 @param bus1 节点1的连接端
 @param bus2 节点2的连接段
 */
- (NSError *)connect:(SMEasyAudioNode *)node1 to:(SMEasyAudioNode *)node2 fromBus:(SMEasyAudioNodeBus)bus1 toBus:(SMEasyAudioNodeBus)bus2;
/**
 将两个节点连接
 
 @param node1 节点1
 @param node2 节点2
 @param bus1 节点1的连接端
 @param bus2 节点2的连接段
 @param modle 连接模式
 */
- (NSError *)connect:(SMEasyAudioNode *)node1 to:(SMEasyAudioNode *)node2 fromBus:(SMEasyAudioNodeBus)bus1 toBus:(SMEasyAudioNodeBus)bus2 modle:(SMEasyAudioNodeConnectModle)modle;


/**
 取消节点的连接

 @param node 节点
 @param bus 节点对应的输入还是输出
 */
- (NSError *)disconnectNode:(SMEasyAudioNode *)node bus:(SMEasyAudioNodeBus)bus;


/**
 所有连接就绪后再start之前进行一些准备
 */
- (NSError *) prepare;


/**
 启动

 @param outError 启动失败的报错
 @return 启动结果的返回
 */
- (BOOL)startAndReturnError:(NSError **)outError;


/**
 停止
 */
- (NSError *)stop;
@end
