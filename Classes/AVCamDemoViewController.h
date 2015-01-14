#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class AVCamDemoCaptureManager, AVCamDemoPreviewView, ExpandyButton;

@interface AVCamDemoViewController : UIViewController <UIImagePickerControllerDelegate,UINavigationControllerDelegate> {
@private
    AVCamDemoCaptureManager *_captureManager;
    AVCamDemoPreviewView *_videoPreviewView;
    AVCaptureVideoPreviewLayer *_captureVideoPreviewLayer;
    UIView *_adjustingInfoView;
    //no need for toolbar
    UIToolbar *_overlayToolbar;
    UIBarButtonItem *_hudButton;
    UIBarButtonItem *_cameraToggleButton;
    UIBarButtonItem *_recordButton;
    UIBarButtonItem *_stillImageButton;
    UIBarButtonItem *_gravityButton;
    ExpandyButton *_flash;
    ExpandyButton *_torch;
    ExpandyButton *_focus;
    ExpandyButton *_exposure;
    ExpandyButton *_whiteBalance;
    
    UIView *_adjustingFocus;
    UIView *_adjustingExposure;
    UIView *_adjustingWhiteBalance;
    
    BOOL _configHidden;
    CALayer *_focusBox;
    CALayer *_exposeBox;
}
@property (nonatomic, strong) UIBarButtonItem *cameraButton;
@property (nonatomic, strong) UIBarButtonItem *folderButton;
@property (nonatomic, strong) UIToolbar *toolBar;
@property (nonatomic, strong) UIButton *closeTransparentView;



@property (nonatomic,retain) AVCamDemoCaptureManager *captureManager;
@property (nonatomic,retain) IBOutlet AVCamDemoPreviewView *videoPreviewView;
@property (nonatomic,retain) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic,retain) IBOutlet UIView *adjustingInfoView;
@property (strong, nonatomic) IBOutlet UIToolbar *overlayToolbar;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *hudButton;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *cameraToggleButton;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *recordButton;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *stillImageButton;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *gravityButton;
@property (nonatomic,retain) ExpandyButton *flash;
@property (nonatomic,retain) ExpandyButton *torch;
@property (nonatomic,retain) ExpandyButton *focus;
@property (nonatomic,retain) ExpandyButton *exposure;
@property (nonatomic,retain) ExpandyButton *whiteBalance;

@property (nonatomic,retain) IBOutlet UIView *adjustingFocus;
@property (nonatomic,retain) IBOutlet UIView *adjustingExposure;
@property (nonatomic,retain) IBOutlet UIView *adjustingWhiteBalance;

- (IBAction)record:(id)sender;
- (IBAction)still:(id)sender;
- (IBAction)cameraToggle:(id)sender;
- (IBAction)hudViewToggle:(id)sender;

- (IBAction)flashChange:(id)sender;

- (IBAction)torchChange:(id)sender;

- (IBAction)focusChange:(id)sender;

- (IBAction)exposureChange:(id)sender;

- (IBAction)whiteBalanceChange:(id)sender;

- (IBAction)changeGravity;

//added by aroverlayexample
@property (nonatomic, assign) BOOL bFirstScan;


@end

