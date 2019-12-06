//
//  AEBufferStack.m
//  TheAmazingAudioEngine
//
//  Created by Michael Tyson on 23/03/2016.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "AEBufferStack.h"
#import "AETypes.h"
#import "AEDSPUtilities.h"
#import "AEUtilities.h"

const UInt32 AEBufferStackMaxFramesPerSlice = 4096;
static const int kDefaultPoolSize = 16;

typedef struct _AEBufferStackBufferLinkedList {
    void * buffer;
    struct _AEBufferStackBufferLinkedList * next;
} AEBufferStackPoolEntry;


// AEBufferStackPool
// 通过PoolEntry记录了free/used
// O(1)的内存申请和释放
typedef struct {
    void * bytes;
    AEBufferStackPoolEntry * free;
    AEBufferStackPoolEntry * used;
} AEBufferStackPool;

// 内存 + 时间
typedef struct {
    AudioTimeStamp timestamp;
    AudioBufferList audioBufferList;
} AEBufferStackBuffer;

struct AEBufferStack {
    int                poolSize;
    int                maxChannelsPerBuffer;
    UInt32             frameCount;
    AudioTimeStamp     timeStamp;
    int                stackCount;
    AEBufferStackPool  audioPool;      // 数据内存
    AEBufferStackPool  bufferListPool; // MetaInfo: AEBufferStackBuffer 内存
};

// BufferStack相关的操作
static void AEBufferStackPoolInit(AEBufferStackPool * pool, int entries, size_t bytesPerEntry);
static void AEBufferStackPoolCleanup(AEBufferStackPool * pool);
static void AEBufferStackPoolReset(AEBufferStackPool * pool);
static void * AEBufferStackPoolGetNextFreeBuffer(AEBufferStackPool * pool);
static BOOL AEBufferStackPoolFreeBuffer(AEBufferStackPool * pool, void * buffer);
static void * AEBufferStackPoolGetUsedBufferAtIndex(const AEBufferStackPool * pool, int index);
static void AEBufferStackSwapTopTwoUsedBuffers(AEBufferStackPool * pool);

AEBufferStack * AEBufferStackNew(int poolSize) {
    return AEBufferStackNewWithOptions(poolSize, 2, 0);
}

// 初始化: Stack
AEBufferStack * AEBufferStackNewWithOptions(int poolSize, int maxChannelsPerBuffer, int numberOfSingleChannelBuffers) {
    if ( !poolSize ) poolSize = kDefaultPoolSize; // 默认16
    if ( !numberOfSingleChannelBuffers ) numberOfSingleChannelBuffers = poolSize * maxChannelsPerBuffer;
    
    AEBufferStack * stack = (AEBufferStack*)calloc(1, sizeof(AEBufferStack));
    stack->poolSize = poolSize;
    stack->maxChannelsPerBuffer = maxChannelsPerBuffer;
    stack->frameCount = AEBufferStackMaxFramesPerSlice;
    
    // 按照Slice来分配内存
    // 4096 * 1024 --> 4M 其实还可以
    // stack->audioPool 的内存布局 和 bufferListPool 不一样
    // 每次最多处理多少帧: 4096 每帧多少byte
    // 多少个SingChannelData
    size_t bytesPerBufferChannel = AEBufferStackMaxFramesPerSlice * AEAudioDescription.mBytesPerFrame;
    AEBufferStackPoolInit(&stack->audioPool, numberOfSingleChannelBuffers, bytesPerBufferChannel);
    
    // 每个元素的大小:
    // AudioBufferList: <--> maxChannelsPerBuffer
    size_t bytesPerBufferListEntry = sizeof(AEBufferStackBuffer) + ((maxChannelsPerBuffer-1) * sizeof(AudioBuffer));
    // AEBufferStackBuffer 没有数据, 需要配置 audioPool使用
    AEBufferStackPoolInit(&stack->bufferListPool, poolSize, bytesPerBufferListEntry);
    
    return stack;
}

void AEBufferStackFree(AEBufferStack * stack) {
    AEBufferStackPoolCleanup(&stack->audioPool);
    AEBufferStackPoolCleanup(&stack->bufferListPool);
    free(stack);
}

void AEBufferStackSetFrameCount(AEBufferStack * stack, UInt32 frameCount) {
    assert(frameCount <= AEBufferStackMaxFramesPerSlice);
    stack->frameCount = frameCount;
}

UInt32 AEBufferStackGetFrameCount(const AEBufferStack * stack) {
    return stack->frameCount;
}

void AEBufferStackSetTimeStamp(AEBufferStack * stack, const AudioTimeStamp * timestamp) {
    stack->timeStamp = *timestamp;
}

const AudioTimeStamp * AEBufferStackGetTimeStamp(const AEBufferStack * stack) {
    return &stack->timeStamp;
}

int AEBufferStackGetPoolSize(const AEBufferStack * stack) {
    return stack->poolSize;
}

int AEBufferStackGetMaximumChannelsPerBuffer(const AEBufferStack * stack) {
    return stack->maxChannelsPerBuffer;
}

int AEBufferStackCount(const AEBufferStack * stack) {
    return stack->stackCount;
}

// 获取栈顶 index 的数据
// 不改写
const AudioBufferList * AEBufferStackGet(const AEBufferStack * stack, int index) {
    if ( index >= stack->stackCount ) return NULL;
    return &((const AEBufferStackBuffer*)AEBufferStackPoolGetUsedBufferAtIndex(&stack->bufferListPool, index))->audioBufferList;
}

// Push一个buffer, 数据不确定
const AudioBufferList * AEBufferStackPush(AEBufferStack * stack, int count) {
    return AEBufferStackPushWithChannels(stack, count, 2);
}

#ifdef DEBUG
static void AEBufferStackPushFailed() {}
#endif

// PUSH如何操作呢?
const AudioBufferList * AEBufferStackPushWithChannels(AEBufferStack * stack, int count, int channelCount) {
    assert(channelCount > 0);
    
    // 检查大小
    if ( stack->stackCount+count > stack->poolSize ) {
#ifdef DEBUG
        if ( AERateLimit() )
            printf("Couldn't push a buffer. Add a breakpoint on AEBufferStackPushFailed to debug.\n");
        AEBufferStackPushFailed();
#endif
        return NULL;
    }
    
    // 检查Channel大小
    if ( channelCount > stack->maxChannelsPerBuffer ) {
#ifdef DEBUG
        if ( AERateLimit() )
            printf("Tried to push a buffer with too many channels. Add a breakpoint on AEBufferStackPushFailed to debug.\n");
        AEBufferStackPushFailed();
#endif
        return NULL;
    }
    
    
    
    size_t sizePerBuffer = stack->frameCount * AEAudioDescription.mBytesPerFrame;
    AEBufferStackBuffer * first = NULL;
    for ( int j=0; j<count; j++ ) {
        // AEBufferStackBuffer
        AEBufferStackBuffer * buffer = (AEBufferStackBuffer *)AEBufferStackPoolGetNextFreeBuffer(&stack->bufferListPool);
        assert(buffer);
        if ( !first ) first = buffer;
        
        // 设置时间 & ChannelCount
        buffer->timestamp = stack->timeStamp;
        buffer->audioBufferList.mNumberBuffers = channelCount;
        for ( int i=0; i<channelCount; i++ ) {
            // 为每一个 mBuffers 分配Audio内存
            buffer->audioBufferList.mBuffers[i].mNumberChannels = 1;
            buffer->audioBufferList.mBuffers[i].mDataByteSize = (UInt32)sizePerBuffer;
            buffer->audioBufferList.mBuffers[i].mData = AEBufferStackPoolGetNextFreeBuffer(&stack->audioPool);
            assert(buffer->audioBufferList.mBuffers[i].mData);
        }
        stack->stackCount++;
    }
    
    return &first->audioBufferList;
}


const AudioBufferList * AEBufferStackPushExternal(AEBufferStack * stack, const AudioBufferList * buffer) {
    
    assert(buffer->mNumberBuffers > 0);
    // 如何获取外部Buffer呢?
    if ( stack->stackCount+1 > stack->poolSize ) {
#ifdef DEBUG
        if ( AERateLimit() )
            printf("Couldn't push a buffer. Add a breakpoint on AEBufferStackPushFailed to debug.\n");
        AEBufferStackPushFailed();
#endif
        return NULL;
    }
    
    // 不符合规格
    if ( buffer->mNumberBuffers > stack->maxChannelsPerBuffer ) {
#ifdef DEBUG
        if ( AERateLimit() )
            printf("Tried to push a buffer with too many channels. Add a breakpoint on AEBufferStackPushFailed to debug.\n");
        AEBufferStackPushFailed();
#endif
        return NULL;
    }
    
#ifdef DEBUG
    // 不符合规格: buffer太小了
    if ( buffer->mBuffers[0].mDataByteSize < stack->frameCount * AEAudioDescription.mBytesPerFrame ) {
        if ( AERateLimit() )
            printf("Warning: Pushed a buffer with %d frames < %d\n",
                   (int)(buffer->mBuffers[0].mDataByteSize / AEAudioDescription.mBytesPerFrame),
                   (int)stack->frameCount);
    }
#endif
    
    AEBufferStackBuffer * newBuffer
        = (AEBufferStackBuffer *)AEBufferStackPoolGetNextFreeBuffer(&stack->bufferListPool);
    assert(newBuffer);
    
    // 拷贝数据
    // 继承了 buffer 内部的数据
    newBuffer->timestamp = stack->timeStamp;
    memcpy(&newBuffer->audioBufferList, buffer, AEAudioBufferListGetStructSize(buffer));
    
    stack->stackCount++;
    
    return &newBuffer->audioBufferList;
}

const AudioBufferList * AEBufferStackDuplicate(AEBufferStack * stack) {
    if ( stack->stackCount == 0 ) return NULL;
    
    // 获取顶部的buffer
    const AEBufferStackBuffer * top
        = (const AEBufferStackBuffer*)AEBufferStackPoolGetUsedBufferAtIndex(&stack->bufferListPool, 0);
    if ( !top ) return NULL;
    
    // Push一个Buffer
    if ( !AEBufferStackPushWithChannels(stack, 1, top->audioBufferList.mNumberBuffers) ) return NULL;
    
    // 获取新的top
    AEBufferStackBuffer * duplicate
        = (AEBufferStackBuffer*)AEBufferStackPoolGetUsedBufferAtIndex(&stack->bufferListPool, 0);
    
    // 数据拷贝
    for ( int i=0; i<duplicate->audioBufferList.mNumberBuffers; i++ ) {
        memcpy(duplicate->audioBufferList.mBuffers[i].mData, top->audioBufferList.mBuffers[i].mData,
               duplicate->audioBufferList.mBuffers[i].mDataByteSize);
    }
    // 拷贝时间戳
    duplicate->timestamp = top->timestamp;
    
    return &duplicate->audioBufferList;
}

void AEBufferStackSwap(AEBufferStack * stack) {
    AEBufferStackSwapTopTwoUsedBuffers(&stack->bufferListPool);
}

void AEBufferStackPop(AEBufferStack * stack, int count) {
    count = MIN(count, stack->stackCount);
    if ( count == 0 ) {
        return;
    }
    for ( int i=0; i<count; i++ ) {
        AEBufferStackRemove(stack, 0);
    }
}

void AEBufferStackRemove(AEBufferStack * stack, int index) {
    AEBufferStackBuffer * buffer = (AEBufferStackBuffer *)AEBufferStackPoolGetUsedBufferAtIndex(&stack->bufferListPool, index);
    if ( !buffer ) {
        return;
    }
    for ( int j=buffer->audioBufferList.mNumberBuffers-1; j >= 0; j-- ) {
        // Free buffers in reverse order, so that they're in correct order if we push again
        AEBufferStackPoolFreeBuffer(&stack->audioPool, buffer->audioBufferList.mBuffers[j].mData);
    }
    AEBufferStackPoolFreeBuffer(&stack->bufferListPool, buffer);
    stack->stackCount--;
}

#pragma mark - Mix相关的操作
const AudioBufferList * AEBufferStackMix(AEBufferStack * stack, int count) {
    return AEBufferStackMixWithGain(stack, count, NULL);
}

// 如何Mixer两个Buffer呢?
const AudioBufferList * AEBufferStackMixWithGain(AEBufferStack * stack, int count, const float * gains) {
    // count == 1, 则直接返回
    if ( count != 0 && count < 2 ) return NULL;
    
    // 如果count == 0, 则处理所有的Stack
    for ( int i=1; count ? i<count : 1; i++ ) {
        const AudioBufferList * abl1 = AEBufferStackGet(stack, 0);
        const AudioBufferList * abl2 = AEBufferStackGet(stack, 1);
        
        // 返回栈顶的元素
        if ( !abl1 || !abl2 ) return AEBufferStackGet(stack, 0);
        
        // 计算Gain
        float abl1Gain = i == 1 && gains ? gains[0] : 1.0;
        float abl2Gain = gains ? gains[i] : 1.0;
        
        // 交换abls
        if ( abl2->mNumberBuffers < abl1->mNumberBuffers ) {
            // Swap abl1 and abl2, so that we're writing into the buffer with more channels
            AEBufferStackSwap(stack);
            abl1 = AEBufferStackGet(stack, 0);
            abl2 = AEBufferStackGet(stack, 1);
            float tmp = abl2Gain;
            abl2Gain = abl1Gain;
            abl1Gain = tmp;
        }
        
        // 释放栈顶的数据
        // 但是数据暂时还有效
        AEBufferStackPop(stack, 1);

        // 修改: abl1
        if ( i == 1 && abl1Gain != 1.0f ) {
            AEDSPApplyGain(abl1, abl1Gain, stack->frameCount);
        }
        
        // abl1
        // abl2 --> abl2 --> abl1正式退休
        AEDSPMix(abl1, abl2, 1, abl2Gain, YES, stack->frameCount, abl2);
    }
    
    // 返回Mix之后的数据
    return AEBufferStackGet(stack, 0);
}

// currentVolume 虽然是float类型的，但是还是以1为计数单位
void AEBufferStackApplyFaders(AEBufferStack * stack,
                              float targetVolume, float * currentVolume,
                              float targetBalance, float * currentBalance) {
    const AudioBufferList * abl = AEBufferStackGet(stack, 0);
    if ( !abl ) return;
    
    if ( fabsf(targetBalance) > FLT_EPSILON && abl->mNumberBuffers == 1 ) {
        // Make mono buffer stereo
        float * priorBuffer = abl->mBuffers[0].mData;
        AEBufferStackPop(stack, 1);
        abl = AEBufferStackPushWithChannels(stack, 1, 2);
        if ( !abl ) {
            // Restore prior buffer and bail
            AEBufferStackPushWithChannels(stack, 1, 1);
            return;
        }
        if ( abl->mBuffers[0].mData != priorBuffer ) {
            memcpy(abl->mBuffers[1].mData, priorBuffer, abl->mBuffers[1].mDataByteSize);
        }
        memcpy(abl->mBuffers[1].mData, priorBuffer, abl->mBuffers[1].mDataByteSize);
    }
    
    AEDSPApplyVolumeAndBalance(abl, targetVolume, currentVolume, targetBalance, currentBalance, stack->frameCount);
}

void AEBufferStackSilence(AEBufferStack * stack) {
    const AudioBufferList * abl = AEBufferStackGet(stack, 0);
    if ( !abl ) return;
    AEAudioBufferListSilence(abl, 0, stack->frameCount);
}

void AEBufferStackMixToBufferList(AEBufferStack * stack, int bufferCount, const AudioBufferList * output) {
    // Mix stack items
    for ( int i=0; bufferCount ? i<bufferCount : 1; i++ ) {
        const AudioBufferList * abl = AEBufferStackGet(stack, i);
        if ( !abl ) return;
        AEDSPMix(abl, output, 1, 1, YES, stack->frameCount, output);
    }
}

void AEBufferStackMixToBufferListChannels(AEBufferStack * stack, int bufferCount, AEChannelSet channels, const AudioBufferList * output) {
    
    // Setup output buffer
    AEAudioBufferListCopyOnStackWithChannelSubset(outputBuffer, output, channels);
    
    // Mix stack items
    for ( int i=0; bufferCount ? i<bufferCount : 1; i++ ) {
        const AudioBufferList * abl = AEBufferStackGet(stack, i);
        if ( !abl ) return;
        AEDSPMix(abl, outputBuffer, 1, 1, YES, stack->frameCount, outputBuffer);
    }
}

AudioTimeStamp * AEBufferStackGetTimeStampForBuffer(AEBufferStack * stack, int index) {
    if ( index >= stack->stackCount ) return NULL;
    return &((AEBufferStackBuffer*)AEBufferStackPoolGetUsedBufferAtIndex(&stack->bufferListPool, index))->timestamp;
}

void AEBufferStackReset(AEBufferStack * stack) {
    AEBufferStackPoolReset(&stack->audioPool);
    AEBufferStackPoolReset(&stack->bufferListPool);
    stack->stackCount = 0;
}

#pragma mark - Helpers

// 初始化
static void AEBufferStackPoolInit(AEBufferStackPool * pool, int entries, size_t bytesPerEntry) {
    pool->bytes = malloc(entries * bytesPerEntry);
    pool->used = NULL;
    
    // 创建: Free List
    AEBufferStackPoolEntry ** nextPtr = &pool->free;
    for ( int i=0; i<entries; i++ ){
        AEBufferStackPoolEntry * entry = (AEBufferStackPoolEntry*)calloc(1, sizeof(AEBufferStackPoolEntry));
        entry->buffer = pool->bytes + (i * bytesPerEntry);
        *nextPtr = entry;
        nextPtr = &entry->next;
    }
}

// 删除内存
static void AEBufferStackPoolCleanup(AEBufferStackPool * pool) {
    while ( pool->free ) {
        AEBufferStackPoolEntry * next = pool->free->next;
        free(pool->free);
        pool->free = next;
    }
    while ( pool->used ) {
        AEBufferStackPoolEntry * next = pool->used->next;
        free(pool->used);
        pool->used = next;
    }
    free(pool->bytes);
}

// 释放 used的buffer
static void AEBufferStackPoolReset(AEBufferStackPool * pool) {
    // Return all used buffers back to the free list
    AEBufferStackPoolEntry * entry = pool->used;
    while ( entry ) {
        // Point top entry at beginning of free list, and point free list to top entry (i.e. insert into free list)
        AEBufferStackPoolEntry * next = entry->next;
        entry->next = pool->free;
        pool->free = entry;
        
        entry = next;
    }
    
    pool->used = NULL;
}

// 获取下一个Free
// 如果没有返回NULL
// 如果有，同时更新: free/used
// 改写Pool结构
static void * AEBufferStackPoolGetNextFreeBuffer(AEBufferStackPool * pool) {
    // Get entry at top of free list
    AEBufferStackPoolEntry * entry = pool->free;
    if ( !entry ) return NULL;
    
    // Point free list at next entry (i.e. remove the top entry from the list)
    pool->free = entry->next;
    
    // Point top entry at beginning of used list, and point used list to top entry (i.e. insert into used list)
    entry->next = pool->used;
    pool->used = entry;
    
    return entry->buffer;
}

static BOOL AEBufferStackPoolFreeBuffer(AEBufferStackPool * pool, void * buffer) {
    
    AEBufferStackPoolEntry * entry = NULL;
    // 释放栈顶的元素(大概率事件)
    if ( pool->used && pool->used->buffer == buffer ) {
        // Found the corresponding entry at the top. Remove it from the used list.
        entry = pool->used;
        pool->used = entry->next;
        
    } else {
        // 遍历列表，应该也是很快的
        // Find it in the list, and note the preceding item
        AEBufferStackPoolEntry * preceding = pool->used;
        while ( preceding && preceding->next && preceding->next->buffer != buffer ) {
            preceding = preceding->next;
        }
        if ( preceding && preceding->next ) {
            // Found it. Remove it from the list
            entry = preceding->next;
            preceding->next = entry->next;
        }
    }
    
    // 如果是外部内存，则不自己释放
    if ( !entry ) {
        return NO;
    }
    
    // Point top entry at beginning of free list, and point free list to top entry (i.e. insert into free list)
    entry->next = pool->free;
    pool->free = entry;
    
    return YES;
}


// 获取used buffer @index
// 不改写
static void * AEBufferStackPoolGetUsedBufferAtIndex(const AEBufferStackPool * pool, int index) {
    AEBufferStackPoolEntry * entry = pool->used;
    for ( int i=0; i<index && entry; i++ ) {
        entry = entry->next;
    }
    return entry ? entry->buffer : NULL;
}

// 交换Top Two
static void AEBufferStackSwapTopTwoUsedBuffers(AEBufferStackPool * pool) {
    AEBufferStackPoolEntry * entry = pool->used;
    if ( !entry ) return;
    AEBufferStackPoolEntry * next = entry->next;
    if ( !next ) return;
    
    entry->next = next->next;
    next->next = entry;
    pool->used = next;
}
