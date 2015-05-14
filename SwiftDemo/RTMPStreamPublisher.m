//
//  RTMPStreamPublisher.m
//  SwiftDemo
//
//  Created by Truong Vo on 14/5/15.
//  Copyright (c) 2015 Truong Vo. All rights reserved.
//

#import "RTMPStreamPublisher.h"

#import "DEBUG.h"
#import "MemoryTicker.h"
#import "BroadcastStreamClient.h"
#import "MediaStreamPlayer.h"
#import "MPMediaEncoder.h"

@interface RTMPStreamPublisher () <MPIMediaStreamEvent> {
    NSString *hostText;
    NSString *streamText;
    
    MemoryTicker *memoryTicker;
    RTMPClient *socket;
    BroadcastStreamClient *upstream;
    
    MPVideoResolution resolution;
    AVCaptureVideoOrientation orientation;
}

- (void)sizeMemory:(NSNumber *)memory;
- (void)setDisconnect;

@end

@implementation RTMPStreamPublisher

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //[DebLog setIsActive:YES];
    
    hostText = @"rtmp://stream.ssh101.com/live";
    streamText = @"truongvo";
    
    memoryTicker = [[MemoryTicker alloc] initWithResponder:self andMethod:@selector(sizeMemory:)];
    memoryTicker.asNumber = YES;
    
    socket = nil;
    upstream = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Private Methods

// MEMORY

- (void)sizeMemory:(NSNumber *)memory {
#if 0
    memoryLabel.text = [NSString stringWithFormat:@"%d", [memory intValue]];
#else
    memoryLabel.text = [NSString stringWithFormat:@"%g", [upstream getMeanFPS]];
#endif
}

// ALERT

- (void)showAlert:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Receive"
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
    });
}

// ACTIONS

- (void)doConnect {
    resolution = RESOLUTION_LOW;
    //resolution = RESOLUTION_CIF;
    //resolution = RESOLUTION_MEDIUM;
    //resolution = RESOLUTION_VGA;
    
#if 1 // use inside RTMPClient instance
    
    upstream = [[BroadcastStreamClient alloc] init:hostText resolution:resolution];
    //upstream = [[BroadcastStreamClient alloc] initOnlyAudio:hostText];
    //upstream = [[BroadcastStreamClient alloc] initOnlyVideo:hostText resolution:resolution];
    
#else // use outside RTMPClient instance
    
    if (!socket) {
        socket = [[RTMPClient alloc] init:hostText];
        if (!socket) {
            [self showAlert:@"Connection has not be created"];
            return;
        }
        
        [socket spawnSocketThread];
    }
    
    upstream = [[BroadcastStreamClient alloc] initWithClient:socket resolution:resolution];
    
#endif
    
    upstream.delegate = self;
    
    //upstream.videoCodecId = MP_VIDEO_CODEC_FLV1;
    upstream.videoCodecId = MP_VIDEO_CODEC_H264;
    
    //upstream.audioCodecId = MP_AUDIO_CODEC_NELLYMOSER;
    upstream.audioCodecId = MP_AUDIO_CODEC_AAC;
    //upstream.audioCodecId = MP_AUDIO_CODEC_SPEEX;
    
    //[upstream setVideoBitrate:72000];
    
    orientation = AVCaptureVideoOrientationPortrait;
    //orientation = AVCaptureVideoOrientationPortraitUpsideDown;
    //orientation = AVCaptureVideoOrientationLandscapeRight;
    //orientation = AVCaptureVideoOrientationLandscapeLeft;
    [upstream setVideoOrientation:orientation];
    
    [upstream stream:streamText publishType:PUBLISH_LIVE];
    //[upstream stream:streamText orientation:orientation publishType:PUBLISH_RECORD];
    //[upstream stream:streamText orientation:orientation publishType:PUBLISH_APPEND];
    
    btnConnect.title = @"Disconnect";
}

- (void)doDisconnect {
    [upstream disconnect];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setDisconnect {
    [socket disconnect];
    socket = nil;
    
    [upstream teardownPreviewLayer];
    upstream = nil;
    
    btnConnect.title = @"Connect";
    btnToggle.enabled = NO;
    btnPublish.title = @"Start";
    btnPublish.enabled = NO;
    
    previewView.hidden = YES;
}

- (void)sendMetadata {
    NSString *camera = upstream.isUsingFrontFacingCamera ? @"FRONT" : @"BACK";
    NSDate *date = [NSDate date];
    NSDictionary *meta = [NSDictionary dictionaryWithObjectsAndKeys:camera, @"camera", [date description], @"date", nil];
    [upstream sendMetadata:meta event:@"changedCamera:"];
}

#pragma mark - IBActions

- (IBAction)connectControl:(id)sender {
    NSLog(@"connectControl: host = %@", hostText);
    
    (!upstream) ? [self doConnect] : [self doDisconnect];
}

- (IBAction)publishControl:(id)sender {
    NSLog(@"publishControl: stream = %@", streamText);
    
    (upstream.state != STREAM_PLAYING) ? [upstream start] : [upstream pause];
}

- (IBAction)camerasToggle:(id)sender {
    NSLog(@"camerasToggle:");
    
    if (upstream.state != STREAM_PLAYING)
        return;
    
    [upstream switchCameras];
    
    [self sendMetadata];
}

#pragma mark - MPIMediaStreamEvent

- (void)stateChanged:(id)sender state:(MPMediaStreamState)state description:(NSString *)description {
    NSLog(@" $$$$$$ <MPIMediaStreamEvent> stateChangedEvent: %d = %@ [%@]", (int)state, description, [NSThread isMainThread]?@"M":@"T");
    
    switch (state) {
        case CONN_DISCONNECTED: {
            [self setDisconnect];
            break;
        }
        case CONN_CONNECTED: {
            if (![description isEqualToString:MP_RTMP_CLIENT_IS_CONNECTED])
                break;
            [upstream start];
            break;
        }
        case STREAM_CREATED: {
            break;
        }
        case STREAM_PAUSED: {
            btnPublish.title = @"Start";
            btnToggle.enabled = NO;
            break;
        }
        case STREAM_PLAYING: {
            [upstream setPreviewLayer:previewView];
            
            previewView.hidden = NO;
            
            btnPublish.title = @"Pause";
            btnPublish.enabled = YES;
            btnToggle.enabled = YES;
            
            break;
        }
        default:
            break;
    }
}

- (void)connectFailed:(id)sender code:(int)code description:(NSString *)description {
    NSLog(@" $$$$$$ <MPIMediaStreamEvent> connectFailedEvent: %d = %@, [%@]", code, description, [NSThread isMainThread]?@"M":@"T");
    
    if (!upstream)
        return;
    
    [self setDisconnect];
    
    [self showAlert:(code == -1) ?
     @"Unable to connect to the server. Make sure the hostname/IP address and port number are valid" :
     [NSString stringWithFormat:@"connectFailedEvent: %@", description]];
}

#if 0
// Send metadata for each video frame
- (void)pixelBufferShouldBePublished:(CVPixelBufferRef)pixelBuffer timestamp:(int)timestamp {
    NSLog(@" $$$$$$ <MPIMediaStreamEvent> pixelBufferShouldBePublished: %d [%@]", timestamp, [NSThread isMainThread]?@"M":@"T");
    
    //[upstream sendMetadata:@{@"videoTimestamp":[NSNumber numberWithInt:timestamp]} event:@"videoFrameOptions:"];
    
    CVPixelBufferRef frameBuffer = pixelBuffer;
    
    // Get the base address of the pixel buffer.
    uint8_t *baseAddress = CVPixelBufferGetBaseAddress(frameBuffer);
    // Get the data size for contiguous planes of the pixel buffer.
    size_t bufferSize = CVPixelBufferGetDataSize(frameBuffer);
    // Get the pixel buffer width and height.
    size_t width = CVPixelBufferGetWidth(frameBuffer);
    size_t height = CVPixelBufferGetHeight(frameBuffer);
    
    [upstream sendMetadata:@{@"videoTimestamp":[NSNumber numberWithInt:timestamp], @"bufferSize":[NSNumber numberWithInt:bufferSize], @"width":[NSNumber numberWithInt:width], @"height":[NSNumber numberWithInt:height]} event:@"videoFrameOptions:"];
}
#endif

@end
