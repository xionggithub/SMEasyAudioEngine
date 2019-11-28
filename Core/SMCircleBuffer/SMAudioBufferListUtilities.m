
#import "SMAudioBufferListUtilities.h"

AudioBufferList *SMAudioBufferListCreate(int frameCount) {
    return SMAudioBufferListCreateWithFormat(SMAudioDescription, frameCount);
}

AudioBufferList *SMAudioBufferListCreateWithFormat(AudioStreamBasicDescription audioFormat, int frameCount) {
    int numberOfBuffers = audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved ? audioFormat.mChannelsPerFrame : 1;
    int channelsPerBuffer = audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved ? 1 : audioFormat.mChannelsPerFrame;
    int bytesPerBuffer = audioFormat.mBytesPerFrame * frameCount;
    
    AudioBufferList *audio = malloc(sizeof(AudioBufferList) + (numberOfBuffers-1)*sizeof(AudioBuffer));
    if ( !audio ) {
        return NULL;
    }
    audio->mNumberBuffers = numberOfBuffers;
    for ( int i=0; i<numberOfBuffers; i++ ) {
        if ( bytesPerBuffer > 0 ) {
            audio->mBuffers[i].mData = calloc(bytesPerBuffer, 1);
            if ( !audio->mBuffers[i].mData ) {
                for ( int j=0; j<i; j++ ) free(audio->mBuffers[j].mData);
                free(audio);
                return NULL;
            }
        } else {
            audio->mBuffers[i].mData = NULL;
        }
        audio->mBuffers[i].mDataByteSize = bytesPerBuffer;
        audio->mBuffers[i].mNumberChannels = channelsPerBuffer;
    }
    return audio;
}

AudioBufferList *SMAudioBufferListCopy(const AudioBufferList *original) {
    AudioBufferList *audio = malloc(sizeof(AudioBufferList) + (original->mNumberBuffers-1)*sizeof(AudioBuffer));
    if ( !audio ) {
        return NULL;
    }
    audio->mNumberBuffers = original->mNumberBuffers;
    for ( int i=0; i<original->mNumberBuffers; i++ ) {
        audio->mBuffers[i].mData = malloc(original->mBuffers[i].mDataByteSize);
        if ( !audio->mBuffers[i].mData ) {
            for ( int j=0; j<i; j++ ) free(audio->mBuffers[j].mData);
            free(audio);
            return NULL;
        }
        audio->mBuffers[i].mDataByteSize = original->mBuffers[i].mDataByteSize;
        audio->mBuffers[i].mNumberChannels = original->mBuffers[i].mNumberChannels;
        memcpy(audio->mBuffers[i].mData, original->mBuffers[i].mData, original->mBuffers[i].mDataByteSize);
    }
    return audio;
}

void SMAudioBufferListFree(AudioBufferList *bufferList ) {
    for ( int i=0; i<bufferList->mNumberBuffers; i++ ) {
        if ( bufferList->mBuffers[i].mData ) free(bufferList->mBuffers[i].mData);
    }
    free(bufferList);
}

UInt32 SMAudioBufferListGetLength(const AudioBufferList *bufferList, int *oNumberOfChannels) {
    return SMAudioBufferListGetLengthWithFormat(bufferList, SMAudioDescription, oNumberOfChannels);
}

UInt32 SMAudioBufferListGetLengthWithFormat(const AudioBufferList *bufferList,
                                            AudioStreamBasicDescription audioFormat,
                                            int *oNumberOfChannels) {
    if ( oNumberOfChannels ) {
        *oNumberOfChannels = audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved
            ? bufferList->mNumberBuffers : bufferList->mBuffers[0].mNumberChannels;
    }
    return bufferList->mBuffers[0].mDataByteSize / audioFormat.mBytesPerFrame;
}

void SMAudioBufferListSetLength(AudioBufferList *bufferList, UInt32 frames) {
    return SMAudioBufferListSetLengthWithFormat(bufferList, SMAudioDescription, frames);
}

void SMAudioBufferListSetLengthWithFormat(AudioBufferList *bufferList,
                                          AudioStreamBasicDescription audioFormat,
                                          UInt32 frames) {
    for ( int i=0; i<bufferList->mNumberBuffers; i++ ) {
        bufferList->mBuffers[i].mDataByteSize = frames * audioFormat.mBytesPerFrame;
    }
}

void SMAudioBufferListOffset(AudioBufferList *bufferList, UInt32 frames) {
    return SMAudioBufferListOffsetWithFormat(bufferList, SMAudioDescription, frames);
}

void SMAudioBufferListOffsetWithFormat(AudioBufferList *bufferList,
                                       AudioStreamBasicDescription audioFormat,
                                       UInt32 frames) {
    for ( int i=0; i<bufferList->mNumberBuffers; i++ ) {
        bufferList->mBuffers[i].mData = (char*)bufferList->mBuffers[i].mData + frames * audioFormat.mBytesPerFrame;
        bufferList->mBuffers[i].mDataByteSize -= frames * audioFormat.mBytesPerFrame;
    }
}

void SMAudioBufferListAssign(AudioBufferList * target, const AudioBufferList * source, UInt32 offset, UInt32 length) {
    SMAudioBufferListAssignWithFormat(target, source, SMAudioDescription, offset, length);
}

void SMAudioBufferListAssignWithFormat(AudioBufferList * target, const AudioBufferList * source,
                                       AudioStreamBasicDescription audioFormat, UInt32 offset, UInt32 length) {
    target->mNumberBuffers = source->mNumberBuffers;
    for ( int i=0; i<source->mNumberBuffers; i++ ) {
        target->mBuffers[i].mNumberChannels = source->mBuffers[i].mNumberChannels;
        target->mBuffers[i].mData = source->mBuffers[i].mData + (offset * audioFormat.mBytesPerFrame);
        target->mBuffers[i].mDataByteSize = length * audioFormat.mBytesPerFrame;
    }
}

void SMAudioBufferListSilence(const AudioBufferList *bufferList, UInt32 offset, UInt32 length) {
    return SMAudioBufferListSilenceWithFormat(bufferList, SMAudioDescription, offset, length);
}

void SMAudioBufferListSilenceWithFormat(const AudioBufferList *bufferList,
                                        AudioStreamBasicDescription audioFormat,
                                        UInt32 offset,
                                        UInt32 length) {
    for ( int i=0; i<bufferList->mNumberBuffers; i++ ) {
        memset((char*)bufferList->mBuffers[i].mData + offset * audioFormat.mBytesPerFrame,
               0,
               length * audioFormat.mBytesPerFrame);
    }
}

void SMAudioBufferListCopyContents(const AudioBufferList * target,
                                   const AudioBufferList * source,
                                   UInt32 targetOffset,
                                   UInt32 sourceOffset,
                                   UInt32 length) {
    SMAudioBufferListCopyContentsWithFormat(target, source, SMAudioDescription, targetOffset, sourceOffset, length);
}

void SMAudioBufferListCopyContentsWithFormat(const AudioBufferList * target,
                                             const AudioBufferList * source,
                                             AudioStreamBasicDescription audioFormat,
                                             UInt32 targetOffset,
                                             UInt32 sourceOffset,
                                             UInt32 length) {
    for ( int i=0; i<MIN(target->mNumberBuffers, source->mNumberBuffers); i++ ) {
        memcpy(target->mBuffers[i].mData + (targetOffset * audioFormat.mBytesPerFrame),
               source->mBuffers[i].mData + (sourceOffset * audioFormat.mBytesPerFrame),
               length * audioFormat.mBytesPerFrame);
    }
}
