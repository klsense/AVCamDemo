#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define kPushAcceptView @"puchAcceptView"


@protocol AVCamDemoCaptureManagerDelegate
@optional
- (void) captureStillImageFailedWithError:(NSError *)error;
- (void) acquiringDeviceLockFailedWithError:(NSError *)error;
- (void) deviceCountChanged;
@end

@interface AVCamDemoCaptureManager : NSObject {
@private
    AVCaptureSession *_session;
    AVCaptureDeviceInput *_videoInput;
    id <AVCamDemoCaptureManagerDelegate> __unsafe_unretained  delegate;
    AVCaptureStillImageOutput *_stillImageOutput;
    AVCaptureVideoDataOutput *_videoDataOutput;
    id _deviceConnectedObserver;
    id _deviceDisconnectedObserver;
    UIBackgroundTaskIdentifier _backgroundRecordingID;
}

@property (nonatomic,readonly,retain) AVCaptureSession *session;
@property (nonatomic,readonly,retain) AVCaptureDeviceInput *videoInput;
@property (nonatomic,assign) AVCaptureFocusMode focusMode;
@property (nonatomic,assign) AVCaptureExposureMode exposureMode;
@property (nonatomic,assign) id <AVCamDemoCaptureManagerDelegate> delegate;
@property (nonatomic,strong) UIImage *stillImage;


- (BOOL) setupSessionWithPreset:(NSString *)sessionPreset error:(NSError **)error;
- (NSUInteger) cameraCount;
- (NSUInteger) micCount;
- (void) captureStillImage;
- (BOOL) hasFocus;
- (BOOL) hasExposure;
- (void) focusAtPoint:(CGPoint)point;
- (void) exposureAtPoint:(CGPoint)point;
- (void) setConnectionWithMediaType:(NSString *)mediaType enabled:(BOOL)enabled;
+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;

@end
