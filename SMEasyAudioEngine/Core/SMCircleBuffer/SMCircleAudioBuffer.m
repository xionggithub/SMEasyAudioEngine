//
//  SMCircleAudioBuffer.m
//  TheAmazingAudioEngine
//
//  Created by Michael Tyson on 29/04/2016.
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

#import "SMCircleAudioBuffer.h"
#import "TPCircularBuffer+AudioBufferList.h"

BOOL SMCircleAudioBufferInit(SMCircleAudioBuffer * buffer, UInt32 capacityInFrames, AudioStreamBasicDescription audioDescription) {
    int channelCount = ((audioDescription.mFormatFlags & kAudioFormatFlagIsPacked)?1:audioDescription.mChannelsPerFrame);
    buffer->audioDescription = audioDescription;
    
    // Determine capacity in bytes
    size_t bytes = capacityInFrames * buffer->audioDescription.mBytesPerFrame * channelCount;
    
     // Increase capacity slightly to make room for metadata
    bytes += MIN(2048, bytes * 0.15);
    
    return TPCircularBufferInit(&buffer->buffer, (int32_t)bytes);
}

void SMCircleAudioBufferCleanup(SMCircleAudioBuffer *buffer) {
    TPCircularBufferCleanup(&buffer->buffer);
}

void SMCircleAudioBufferClear(SMCircleAudioBuffer *buffer) {
    TPCircularBufferClear(&buffer->buffer);
}

void SMCircleAudioBufferSetAtomic(SMCircleAudioBuffer *buffer, BOOL atomic) {
    TPCircularBufferSetAtomic(&buffer->buffer, atomic);
}


UInt32 SMCircleAudioBufferGetAvailableSpace(SMCircleAudioBuffer *buffer) {
    return TPCircularBufferGetAvailableSpace(&buffer->buffer, &buffer->audioDescription);
}

BOOL SMCircleAudioBufferEnqueue(SMCircleAudioBuffer *buffer,
                             const AudioBufferList *bufferList,
                             const AudioTimeStamp *timestamp,
                             UInt32 frames) {
    return TPCircularBufferCopyAudioBufferList(&buffer->buffer, bufferList, timestamp, frames, &buffer->audioDescription);
}

AudioBufferList * SMCircleAudioBufferPrepareEmptyAudioBufferList(SMCircleAudioBuffer *buffer,
                                                              UInt32 frameCount,
                                                              const AudioTimeStamp *timestamp) {
    return TPCircularBufferPrepareEmptyAudioBufferListWithAudioFormat(&buffer->buffer, &buffer->audioDescription, frameCount, timestamp);
}

void SMCircleAudioBufferProduceAudioBufferList(SMCircleAudioBuffer *buffer) {
    return TPCircularBufferProduceAudioBufferList(&buffer->buffer, NULL);
}

UInt32 SMCircleAudioBufferPeek(SMCircleAudioBuffer *buffer, AudioTimeStamp *outTimestamp) {
    return TPCircularBufferPeek(&buffer->buffer, outTimestamp, &buffer->audioDescription);
}

void SMCircleAudioBufferDequeue(SMCircleAudioBuffer *buffer,
                             UInt32 *ioLengthInFrames,
                             const AudioBufferList *outputBufferList,
                             AudioTimeStamp *outTimestamp) {
    return TPCircularBufferDequeueBufferListFrames(&buffer->buffer, ioLengthInFrames, outputBufferList, outTimestamp, &buffer->audioDescription);
}

AudioBufferList * SMCircleAudioBufferNextBufferList(SMCircleAudioBuffer *buffer,
                                                 AudioTimeStamp *outTimestamp,
                                                 const AudioBufferList * lastBufferList) {
    return lastBufferList ?
        TPCircularBufferNextBufferListAfter(&buffer->buffer, lastBufferList, outTimestamp)
        : TPCircularBufferNextBufferList(&buffer->buffer, outTimestamp);
}

void SMCircleAudioBufferConsumeNextBufferList(SMCircleAudioBuffer *buffer) {
    return TPCircularBufferConsumeNextBufferList(&buffer->buffer);
}

void SMCircleAudioBufferConsumeNextBufferListPartial(SMCircleAudioBuffer *buffer, UInt32 frames) {
    return TPCircularBufferConsumeNextBufferListPartial(&buffer->buffer, frames, &buffer->audioDescription);
}
