//
//  AACPlayer.m
//  AudioToolboxDecodeAAC
//
//  Created by 刘文晨 on 2024/7/8.
//

#import "AACPlayer.h"
#import <AudioToolbox/AudioToolbox.h>

const uint32_t CONST_BUFFER_COUNT = 1;
const uint32_t CONST_BUFFER_SIZE = 0x10000;

@implementation AACPlayer
{
    AudioFileID audioFileID; // An opaque data type that represents an audio file object
    AudioStreamBasicDescription audioStreamBasicDescrpition; // An audio data format specification for a stream of audio
    AudioStreamPacketDescription *audioStreamPacketDescrption; // Describe one packet in a buffer of audio data
    
    AudioQueueRef audioQueue; // Define an opaque data type that represents an audio queue
    AudioQueueBufferRef audioQueueBuffer[CONST_BUFFER_COUNT];
    
    SInt64 readedPacket;
    uint32_t packetNums;
}

- (instancetype)init
{
    if (self = [super init])
    {
        [self customAudioConfig];
    }
    return self;
}

- (void)customAudioConfig
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"music" withExtension:@"aac"];
        
    OSStatus status = noErr;
    
    status = AudioFileOpenURL((__bridge CFURLRef)url, kAudioFileReadPermission, 0, &audioFileID); // Open an existing audio file specified by a URL
    if (status != noErr)
    {
        NSLog(@"failed to open an audio file: %d", status);
        return;
    }
    
    uint32_t size = sizeof(audioStreamBasicDescrpition);
    // Get the value of an audio file property
    status = AudioFileGetProperty(audioFileID, kAudioFilePropertyDataFormat, &size, &audioStreamBasicDescrpition);
    if (status != noErr)
    {
        NSLog(@"failed to get the audio file property: %d", status);
        return;
    }
    
    // Create a new playback audio queue object
    status = AudioQueueNewOutput(&audioStreamBasicDescrpition, bufferReady, (__bridge void * _Nullable)(self), NULL, NULL, 0, &audioQueue);
    if (status != noErr)
    {
        NSLog(@"failed to create playback audio queue: %d", status);
        return;
    }
    
    if (audioStreamBasicDescrpition.mBytesPerPacket == 0 || audioStreamBasicDescrpition.mFramesPerPacket == 0)
    {
        uint32_t maxSize;
        size = sizeof(maxSize);
        AudioFileGetProperty(audioFileID, kAudioFilePropertyPacketSizeUpperBound, &size, &maxSize); // The theoretical maximum packet size in the file
        if (maxSize > CONST_BUFFER_SIZE)
        {
            maxSize = CONST_BUFFER_SIZE;
        }
        packetNums = CONST_BUFFER_SIZE / maxSize;
        audioStreamPacketDescrption = malloc(sizeof(AudioStreamPacketDescription) * packetNums);
    }
    else
    {
        packetNums = CONST_BUFFER_SIZE / audioStreamBasicDescrpition.mBytesPerPacket;
        audioStreamPacketDescrption = nil;
    }
    
    char cookies[100];
    memset(cookies, 0, sizeof(cookies));
    // Some file types require that a magic cookie be provided before packets can be written to an audio file
    AudioFileGetProperty(audioFileID, kAudioFilePropertyMagicCookieData, &size, cookies);
    if (size > 0)
    {
        AudioQueueSetProperty(audioQueue, kAudioQueueProperty_MagicCookie, cookies, size); // Sets an audio queue property value.
    }
    
    readedPacket = 0;
    for (int i = 0; i < CONST_BUFFER_COUNT; i++)
    {
        // Ask an audio queue object to allocate an audio queue buffer
        AudioQueueAllocateBuffer(audioQueue, CONST_BUFFER_SIZE, &audioQueueBuffer[i]);
        if ([self fillBuffer:audioQueueBuffer[i]])
        {
            // buffer full
            break;
        }
        NSLog(@"buffer %d full", i);
    }
}

void bufferReady(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef buffer)
{
    NSLog(@"refresh buffer");
    AACPlayer *player = (__bridge AACPlayer *)inUserData;
    if (player == nil)
    {
        NSLog(@"player nil");
        return;
    }
    if ([player fillBuffer:buffer])
    {
        NSLog(@"play end");
        dispatch_async(dispatch_get_main_queue(), ^{
            [player stop];
        });
    }
}

- (bool)fillBuffer:(AudioQueueBufferRef)buffer
{
    bool isEnd = NO;
    uint32_t bytes = 0, packets = (uint32_t)packetNums;
    // Read packets of audio data from an audio file
    OSStatus status = noErr;
    status = AudioFileReadPackets(audioFileID, NO, &bytes, audioStreamPacketDescrption, readedPacket, &packets, buffer->mAudioData);
    NSAssert(status == noErr, ([NSString stringWithFormat:@"failed to read packets: %d", status]));
    
    if (packets > 0)
    {
        buffer->mAudioDataByteSize = bytes;
        AudioQueueEnqueueBuffer(audioQueue, buffer, packets, audioStreamPacketDescrption);
        readedPacket += packets;
    }
    else
    {
        isEnd = YES;
    }
    
    return isEnd;
}

- (void)play
{
    // Set a playback audio queue parameter value
    AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1.0);
    // Begin playing or recording audio
    AudioQueueStart(audioQueue, NULL);
}

- (void)stop
{
    AudioQueueStop(audioQueue, NO);
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayToEnd:)])
    {
        __strong typeof(AACPlayer) *player = self;
        [self.delegate onPlayToEnd:player];
    }
}

- (double)getCurrentTime
{
    Float64 timeInterval = 0.0;
    if (audioQueue)
    {
        AudioQueueTimelineRef timeLine;
        AudioTimeStamp timeStamp;
        OSStatus status = AudioQueueCreateTimeline(audioQueue, &timeLine); // Create a timeline object for an audio queue
        if(status == noErr)
        {
            AudioQueueGetCurrentTime(audioQueue, timeLine, &timeStamp, NULL); // Get the current audio queue time
            timeInterval = timeStamp.mSampleTime / audioStreamBasicDescrpition.mSampleRate; // The number of sample frames per second of the data in the stream
        }
    }
    return timeInterval;
}

@end
