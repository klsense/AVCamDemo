#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

//added from aroverlayexample
#define kPushAcceptView @"puchAcceptView"


@protocol AVCamDemoCaptureManagerDelegate
@optional
- (void) captureStillImageFailedWithError:(NSError *)error;
- (void) acquiringDeviceLockFailedWithError:(NSError *)error;
- (void) cannotWriteToAssetLibrary;
- (void) assetLibraryError:(NSError *)error forURL:(NSURL *)assetURL;
- (void) someOtherError:(NSError *)error;
- (void) recordingBegan;
- (void) recordingFinished;
- (void) deviceCountChanged;
@end

@interface AVCamDemoCaptureManager : NSObject {
@private
    AVCaptureSession *_session;
    AVCaptureDeviceInput *_videoInput;
    //    id <AVCamDemoCaptureManagerDelegate> _delegate;
    id <AVCamDemoCaptureManagerDelegate> __unsafe_unretained  delegate;
    
    
    AVCaptureDeviceInput *_audioInput;
    AVCaptureMovieFileOutput *_movieFileOutput;
    AVCaptureStillImageOutput *_stillImageOutput;
    AVCaptureVideoDataOutput *_videoDataOutput;
    AVCaptureAudioDataOutput *_audioDataOutput;
    id _deviceConnectedObserver;
    id _deviceDisconnectedObserver;
    UIBackgroundTaskIdentifier _backgroundRecordingID;
}

@property (nonatomic,readonly,retain) AVCaptureSession *session;
@property (nonatomic,readonly,retain) AVCaptureDeviceInput *videoInput;
@property (nonatomic,assign) AVCaptureFlashMode flashMode;
@property (nonatomic,assign) AVCaptureTorchMode torchMode;
@property (nonatomic,assign) AVCaptureFocusMode focusMode;
@property (nonatomic,assign) AVCaptureExposureMode exposureMode;
@property (nonatomic,assign) AVCaptureWhiteBalanceMode whiteBalanceMode;
@property (nonatomic,readonly,getter=isRecording) BOOL recording;
@property (nonatomic,assign) id <AVCamDemoCaptureManagerDelegate> delegate;

//added from avorverlayexample
@property (nonatomic, strong) UIImage *stillImage;


- (BOOL) setupSessionWithPreset:(NSString *)sessionPreset error:(NSError **)error;
- (NSUInteger) cameraCount;
- (NSUInteger) micCount;
- (void) startRecording;
- (void) stopRecording;
- (void) captureStillImage;
- (BOOL) cameraToggle;
- (BOOL) hasMultipleCameras;
- (BOOL) hasFlash;
- (BOOL) hasTorch;
- (BOOL) hasFocus;
- (BOOL) hasExposure;
- (BOOL) hasWhiteBalance;
- (void) focusAtPoint:(CGPoint)point;
- (void) exposureAtPoint:(CGPoint)point;
- (void) setConnectionWithMediaType:(NSString *)mediaType enabled:(BOOL)enabled;
+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;

@end
