#import "AVCamDemoViewController.h"
#import "AVCamDemoCaptureManager.h"
#import "ExpandyButton.h"
#import "AVCamDemoPreviewView.h"
#import "MDCSwipeToChoose.h"
#import "PartialTransparentView.h"

// KVO contexts
static void *AVCamDemoFocusModeObserverContext = &AVCamDemoFocusModeObserverContext;
static void *AVCamDemoTorchModeObserverContext = &AVCamDemoTorchModeObserverContext;
static void *AVCamDemoFlashModeObserverContext = &AVCamDemoFlashModeObserverContext;
static void *AVCamDemoAdjustingObserverContext = &AVCamDemoAdjustingObserverContext;

// HUD Appearance
const CGFloat hudCornerRadius = 8.f;
const CGFloat hudLayerWhite = 1.f;
const CGFloat hudLayerAlpha = .5f;
const CGFloat hudBorderWhite = .0f;
const CGFloat hudBorderAlpha = 1.f;
const CGFloat hudBorderWidth = 1.f;

@interface AVCamDemoViewController ()
@property (nonatomic,assign,getter=isConfigHidden) BOOL configHidden;
@property (nonatomic,retain) CALayer *focusBox;
@property (nonatomic,retain) CALayer *exposeBox;

//added from aroverlayexample
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;

@end

@interface AVCamDemoViewController (InternalMethods)
+ (CGRect)cleanApertureFromPorts:(NSArray *)ports;
+ (CGSize)sizeForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize;
+ (void)addAdjustingAnimationToLayer:(CALayer *)layer removeAnimation:(BOOL)remove;
- (CGPoint)translatePoint:(CGPoint)point fromGravity:(NSString *)gravity1 toGravity:(NSString *)gravity2;
- (void)drawFocusBoxAtPointOfInterest:(CGPoint)point;
- (void)drawExposeBoxAtPointOfInterest:(CGPoint)point;
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates;
@end


@interface AVCamDemoViewController (AVCamDemoCaptureManagerDelegate) <AVCamDemoCaptureManagerDelegate>
@end

@interface AVCamDemoViewController (AVCamDemoPreviewViewDelegate) <AVCamDemoPreviewViewDelegate>
@end

@implementation AVCamDemoViewController

@synthesize captureManager = _captureManager;
@synthesize videoPreviewView = _videoPreviewView;
@synthesize captureVideoPreviewLayer = _captureVideoPreviewLayer;
@synthesize adjustingInfoView = _adjustingInfoView;
@synthesize hudButton = _hudButton;
@synthesize cameraToggleButton = _cameraToggleButton;
@synthesize recordButton = _recordButton;
@synthesize stillImageButton = _stillImageButton;
@synthesize gravityButton = _gravityButton;
@synthesize flash = _flash;
@synthesize torch = _torch;
@synthesize focus = _focus;
@synthesize exposure = _exposure;
@synthesize whiteBalance = _whiteBalance;
@synthesize adjustingFocus = _adjustingFocus;
@synthesize adjustingExposure = _adjustingExposure;
@synthesize adjustingWhiteBalance = _adjustingWhiteBalance;
@synthesize configHidden = _configHidden;
@synthesize focusBox = _focusBox;
@synthesize exposeBox = _exposeBox;
@synthesize cameraButton;
@synthesize folderButton;
@synthesize closeTransparentView;

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:(NSCoder *)decoder];
    if (self != nil) {
        [self addObserver:self forKeyPath:@"captureManager.videoInput.device.flashMode" options:NSKeyValueObservingOptionNew context:AVCamDemoFlashModeObserverContext];
        [self addObserver:self forKeyPath:@"captureManager.videoInput.device.torchMode" options:NSKeyValueObservingOptionNew context:AVCamDemoTorchModeObserverContext];
        [self addObserver:self forKeyPath:@"captureManager.videoInput.device.focusMode" options:NSKeyValueObservingOptionNew context:AVCamDemoFocusModeObserverContext];
        [self addObserver:self forKeyPath:@"captureManager.videoInput.device.adjustingFocus" options:NSKeyValueObservingOptionNew context:AVCamDemoAdjustingObserverContext];
        [self addObserver:self forKeyPath:@"captureManager.videoInput.device.adjustingExposure" options:NSKeyValueObservingOptionNew context:AVCamDemoAdjustingObserverContext];
        [self addObserver:self forKeyPath:@"captureManager.videoInput.device.adjustingWhiteBalance" options:NSKeyValueObservingOptionNew context:AVCamDemoAdjustingObserverContext];
    }
    return self;
}

- (void) dealloc
{
    [self setCaptureManager:nil];
    //    [super dealloc];
}

//handles landscape and portrait mode for scan button and toolbar
-(void)willAnimateRotationToInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation
                                        duration:(NSTimeInterval)duration {
    
    [CATransaction begin];
    if (toInterfaceOrientation==UIInterfaceOrientationLandscapeLeft){
        //        self.captureVideoPreviewLayer.orientation = UIInterfaceOrientationLandscapeLeft;
        [[self.captureVideoPreviewLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        
        self.captureVideoPreviewLayer.frame = [[[self view] layer]bounds];  //self.view.layer.bounds.size.height
//        [cameraButton setFrame:CGRectMake(240, 230, 70, 70)];
//        [folderButton setFrame:CGRectMake(150, 230, 70, 70)];
        
        
        
    } else if (toInterfaceOrientation==UIInterfaceOrientationPortrait){
        [[self.captureVideoPreviewLayer connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
        
        self.captureVideoPreviewLayer.frame = [[[self view] layer]bounds];//CGRectMake(0, 0, 320, 568);
        NSLog(@"portrait");
//        [cameraButton setFrame:CGRectMake(130, 400, 70, 70)];//CGRectMake(130, 400, 60, 30)];
//        [folderButton setFrame:CGRectMake(40, 400, 70, 70)];//CGRectMake(130, 400, 60, 30)];
//        
        
        
        
    } else if (toInterfaceOrientation==UIInterfaceOrientationLandscapeRight){
        //        self.captureVideoPreviewLayer.orientation = UIInterfaceOrientationLandscapeRight;
        [[self.captureVideoPreviewLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        
        self.captureVideoPreviewLayer.frame = [[[self view] layer]bounds];
//        [cameraButton setFrame:CGRectMake(240, 230, 70, 70)];//CGRectMake(100, 250, 120, 30)];
//        [folderButton setFrame:CGRectMake(150, 230, 70, 70)];
        
        
        
    }
    [CATransaction commit];
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

-(void)viewDidLayoutSubviews {
    UIView *view = [self videoPreviewView];
    CALayer *viewLayer = [view layer];
    [viewLayer setMasksToBounds:YES];
    
    CGRect bounds = [view bounds];
    
    [self.captureVideoPreviewLayer setFrame:bounds];
}

- (void)viewDidLoad
{
    NSError *error;
    
    CALayer *adjustingInfolayer = [[self adjustingInfoView] layer];
    [adjustingInfolayer setCornerRadius:hudCornerRadius];
    [adjustingInfolayer setBorderColor:[[UIColor colorWithWhite:hudBorderWhite alpha:hudBorderAlpha] CGColor]];
    [adjustingInfolayer setBorderWidth:hudBorderWidth];
    [adjustingInfolayer setBackgroundColor:[[UIColor colorWithWhite:hudLayerWhite alpha:hudLayerAlpha] CGColor]];
    [adjustingInfolayer setPosition:CGPointMake([adjustingInfolayer position].x, [adjustingInfolayer position].y + 12.f)];
    
    AVCamDemoCaptureManager *captureManager = [[AVCamDemoCaptureManager alloc] init];
    if ([captureManager setupSessionWithPreset:AVCaptureSessionPresetHigh error:&error]) {
        [self setCaptureManager:captureManager];
        
        AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[captureManager session]];
        UIView *view = [self videoPreviewView];
        CALayer *viewLayer = [view layer];
        [viewLayer setMasksToBounds:YES];
        
        CGRect bounds = [view bounds];
        
        [captureVideoPreviewLayer setFrame:bounds];
        
        
        //        if ([captureVideoPreviewLayer isOrientationSupported]) {
        //            [captureVideoPreviewLayer setOrientation:AVCaptureVideoOrientationPortrait];
        //        }
        
        if ([captureVideoPreviewLayer.connection isVideoOrientationSupported]) {
            [captureVideoPreviewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
        
        [captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        [self setCaptureVideoPreviewLayer:captureVideoPreviewLayer];
        
        NSDictionary *unanimatedActions = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"bounds",[NSNull null], @"frame",[NSNull null], @"position", nil];
        CALayer *focusBox = [[CALayer alloc] init];
        [focusBox setActions:unanimatedActions];
        [focusBox setBorderWidth:3.f];
        [focusBox setBorderColor:[[UIColor colorWithRed:0.f green:0.f blue:1.f alpha:.8f] CGColor]];
        [focusBox setOpacity:0.f];
        [viewLayer addSublayer:focusBox];
        [self setFocusBox:focusBox];
        //        [focusBox release];
        
        //        CALayer *exposeBox = [[CALayer alloc] init];
        //        [exposeBox setActions:unanimatedActions];
        //        [exposeBox setBorderWidth:3.f];
        //        [exposeBox setBorderColor:[[UIColor colorWithRed:1.f green:0.f blue:0.f alpha:.8f] CGColor]];
        //        [exposeBox setOpacity:0.f];
        //        [viewLayer addSublayer:exposeBox];
        //        [self setExposeBox:exposeBox];
        //        [exposeBox release];
        //        [unanimatedActions release];
        
        CGPoint screenCenter = CGPointMake(bounds.size.width / 2.f, bounds.size.height / 2.f);
        
        [self drawFocusBoxAtPointOfInterest:screenCenter];
        [self drawExposeBoxAtPointOfInterest:screenCenter];
        
        if ([[captureManager session] isRunning]) {
            [self setConfigHidden:YES];
            NSInteger count = 0;
            if ([captureManager hasFlash]) {
                ExpandyButton *flash =  [[ExpandyButton alloc] initWithPoint:CGPointMake(8.f, 8.f)
                                                                       title:@"Flash"
                                                                 buttonNames:[NSArray arrayWithObjects:@"Off",@"On",@"Auto",nil]
                                                                selectedItem:[captureManager flashMode]];
                [flash setHidden:YES];
                [flash addTarget:self action:@selector(flashChange:) forControlEvents:UIControlEventValueChanged];
                [view addSubview:flash];
                [self setFlash:flash];
                //                [flash release];
                count++;
            }
            
            if ([captureManager hasTorch]) {
                ExpandyButton *torch =  [[ExpandyButton alloc] initWithPoint:CGPointMake(8.f, 8.f + (40.f * count))
                                                                       title:@"Torch"
                                                                 buttonNames:[NSArray arrayWithObjects:@"Off",@"On",@"Auto",nil]
                                                                selectedItem:[captureManager torchMode]];
                [torch setHidden:YES];
                [torch addTarget:self action:@selector(torchChange:) forControlEvents:UIControlEventValueChanged];
                [view addSubview:torch];
                [self setTorch:torch];
                //                [torch release];
                count++;
            }
            
            if ([captureManager hasFocus]) {
                ExpandyButton *focus =  [[ExpandyButton alloc] initWithPoint:CGPointMake(8.f, 8.f + (40.f * count))
                                                                       title:@"AFoc"
                                                                 buttonNames:[NSArray arrayWithObjects:@"Lock",@"Auto",@"Cont",nil]
                                                                selectedItem:[captureManager focusMode]];
                [focus setHidden:YES];
                [focus addTarget:self action:@selector(focusChange:) forControlEvents:UIControlEventValueChanged];
                [view addSubview:focus];
                [self setFocus:focus];
                //                [focus release];
                count++;
            }
            
            if ([captureManager hasExposure]) {
                ExpandyButton *exposure =  [[ExpandyButton alloc] initWithPoint:CGPointMake(8.f, 8.f + (40.f * count))
                                                                          title:@"AExp"
                                                                    buttonNames:[NSArray arrayWithObjects:@"Lock",@"Cont",nil]
                                                                   selectedItem:([captureManager exposureMode] == 2 ? 1 : [captureManager exposureMode])];
                [exposure setHidden:YES];
                [exposure addTarget:self action:@selector(exposureChange:) forControlEvents:UIControlEventValueChanged];
                [view addSubview:exposure];
                [self setExposure:exposure];
                //                [exposure release];
                count++;
            }
            
            if ([captureManager hasWhiteBalance]) {
                ExpandyButton *whiteBalance =  [[ExpandyButton alloc] initWithPoint:CGPointMake(8.f, 8.f + (40.f * count))
                                                                              title:@"AWB"
                                                                        buttonNames:[NSArray arrayWithObjects:@"Lock",@"Cont",nil]
                                                                       selectedItem:([captureManager whiteBalanceMode] == 2 ? 1 : [captureManager whiteBalanceMode])];
                [whiteBalance setHidden:YES];
                [whiteBalance addTarget:self action:@selector(whiteBalanceChange:) forControlEvents:UIControlEventValueChanged];
                [view addSubview:whiteBalance];
                [self setWhiteBalance:whiteBalance];
                //                [whiteBalance release];
            }
            
            [captureManager setDelegate:self];
            
            NSUInteger cameraCount = [captureManager cameraCount];
            if (cameraCount < 1) {
                [[self hudButton] setEnabled:NO];
                [[self cameraToggleButton] setEnabled:NO];
                [[self stillImageButton] setEnabled:NO];
                [[self gravityButton] setEnabled:NO];
            } else if (cameraCount < 2) {
                [[self cameraToggleButton] setEnabled:NO];
            }
            
            if (cameraCount < 1 && [captureManager micCount] < 1) {
                [[self recordButton] setEnabled:NO];
            }
            
            [viewLayer insertSublayer:captureVideoPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
            
            //            [captureVideoPreviewLayer release];
            
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                                message:@"Failed to start session."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Okay"
                                                      otherButtonTitles:nil];
            [alertView show];
            //            [alertView release];
        }
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Input Device Init Failed"
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Okay"
                                                  otherButtonTitles:nil];
        [alertView show];
        //        [alertView release];
    }
    
    //    [captureManager release];
    
    //added from avorverlayexample
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushAcceptView) name:kPushAcceptView object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tapToFocusExpose:) name:kFocus object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushAcceptView) name:kExpose object:nil];
    
    self.bFirstScan = TRUE;
    
    
    self.toolBar = [[UIToolbar alloc] init];
    self.toolBar.tag = 68;
    self.toolBar.frame = CGRectMake(0, self.view.frame.size.height-44, self.view.frame.size.width, 44);
    self.toolBar.backgroundColor = [UIColor blackColor];
    UIBarButtonItem *flexiableItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];

    self.cameraButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"camera.png"] style:UIBarButtonItemStyleDone target:self action:@selector(still:)];
    self.cameraButton.tag = 69;
    self.folderButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"folderbutton.png"] style:UIBarButtonItemStyleDone target:self action:@selector(showLibrary:)];
    self.folderButton.tag = 71;
    NSMutableArray *items = [[NSMutableArray alloc] initWithObjects:folderButton, flexiableItem, cameraButton, flexiableItem, nil];
    [self.toolBar setItems:items];
    [[self view] addSubview:self.toolBar];
    
//    cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    cameraButton.tag = 69;
//    [cameraButton setImage:[UIImage imageNamed:@"camera.png"] forState:UIControlStateNormal];
//    [cameraButton setFrame:CGRectMake(130, 400, 70, 70)];
//    [cameraButton addTarget:self action:@selector(still:) forControlEvents:UIControlEventTouchUpInside];
//    [[self view] addSubview:cameraButton];
//    
//    folderButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    folderButton.tag = 71;
//    [folderButton setImage:[UIImage imageNamed:@"folderbutton.png"] forState:UIControlStateNormal];
//    [folderButton setFrame:CGRectMake(40, 400, 70, 70)];
//    [folderButton addTarget:self action:@selector(showLibrary:) forControlEvents:UIControlEventTouchUpInside];
//    [[self view] addSubview:folderButton];
    
    closeTransparentView = [[UIButton alloc] initWithFrame:CGRectMake(280, 40, 25, 25)];
    UIImage *closeButton = [UIImage imageNamed:@"decline.png"];
    [closeTransparentView setBackgroundImage:closeButton forState:UIControlStateNormal];
    closeTransparentView.tag = 123;
    [closeTransparentView addTarget:self action:@selector(dismissPartialTransparentView) forControlEvents:UIControlEventTouchUpInside];
    
    [super viewDidLoad];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)img editingInfo:(NSDictionary *)editInfo
{
    UIImageOrientation orient = img.imageOrientation;
    NSLog(@"Image orientation: %d", orient);

    if (orient == UIImageOrientationUp) {
        CGFloat rads = M_PI * 90 / 180;
        float newSide = MAX([img size].width, [img size].height);
        CGSize size =  CGSizeMake(newSide, newSide);
        UIGraphicsBeginImageContext(size);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(ctx, newSide/2, newSide/2);
        CGContextRotateCTM(ctx, -rads);
        CGContextDrawImage(UIGraphicsGetCurrentContext(),CGRectMake(-[img size].width/2,-[img size].height/2,size.width, size.height),img.CGImage);
        UIImage *i = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        
        
        NSArray *transparentRects = [[NSArray alloc] initWithObjects:[NSValue valueWithCGRect:CGRectMake(25, 50, 270, 418)], nil];
        PartialTransparentView *transparentView = [[PartialTransparentView alloc] initWithFrame:[[[self view] layer]bounds] backgroundImage: i andTransparentRects:transparentRects];  //CGRectMake(0,0,320,568)
        transparentView.tag = 2002;
        [self.view addSubview:transparentView];
        //add close button for transparent view
        [self.view addSubview:closeTransparentView];
        self.bFirstScan = FALSE;
        
        //remove scan button to place above after
        [self bringCameraButtonToFront];
        [self bringFolderButtonToFront];
        
        [picker dismissViewControllerAnimated:YES completion:nil]; //dismisses the camera controller
        
    }
    else {
    NSArray *transparentRects = [[NSArray alloc] initWithObjects:[NSValue valueWithCGRect:CGRectMake(25, 50, 270, 418)], nil];
    PartialTransparentView *transparentView = [[PartialTransparentView alloc] initWithFrame:[[[self view] layer]bounds] backgroundImage: img andTransparentRects:transparentRects];  //CGRectMake(0,0,320,568)
    transparentView.tag = 2002;
    [self.view addSubview:transparentView];
    //add close button for transparent view
    [self.view addSubview:closeTransparentView];
    self.bFirstScan = FALSE;
    
    //remove scan button to place above after
    [self bringCameraButtonToFront];
    [self bringFolderButtonToFront];
    
    [picker dismissViewControllerAnimated:YES completion:nil]; //dismisses the camera controller
    }

    
}

- (void) imagePickerControllerDidCancel: (UIImagePickerController *) picker {
    //    [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil]; //dismisses the camera controller
    [picker dismissViewControllerAnimated:YES completion:nil]; //dismisses the camera controller
    UIView *viewToRemove = [self.view viewWithTag:101];
    [viewToRemove removeFromSuperview];
    
}

- (void) showLibrary: (id) sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum; //UIImagePickerControllerSourceTypeSavedPhotosAlbum  UIImagePickerControllerSourceTypePhotoLibrary
    //imagePicker.delegate = self;
    [imagePicker setDelegate:self];
    imagePicker.view.tag = 101;
    imagePicker.allowsEditing = NO;
    
    //[self.view addSubview:imagePicker.view];
    [self presentViewController:imagePicker animated:YES completion: nil];
    
}

-(void)tapToFocusExpose:(NSNotification *) notification {
    if ([notification.name isEqualToString:kFocus]) {
        NSDictionary* userInfo = notification.userInfo;
        CGPoint tapPoint = [[userInfo valueForKey:@"point"] CGPointValue];
        //        NSLog(@"%@",NSStringFromCGPoint(*tapPoint));
        [self tapToFocus:tapPoint];
        [self tapToExpose:tapPoint];
        
    }
    
}

-(void)pushAcceptView {
    //    self.pAcceptImage = [[AcceptImage alloc] initWithNibName:@"AcceptImage" bundle:nil];
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        self.pAcceptImage.previewImage.image = [self.captureManager stillImage];
    //    });
    //    self.pAcceptImage.view.tag = 102;
    //
    //    [[self view] addSubview:pAcceptImage.view];
    // You can customize MDCSwipeToChooseView using MDCSwipeToChooseViewOptions.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"firstLaunch"]) {
        NSLog(@"YES!!!!! THIS IS THE FIRST TIME USED FUCK YES!!!!!");
    }
    MDCSwipeToChooseViewOptions *options = [MDCSwipeToChooseViewOptions new];
    options.delegate = self;
    options.likedText = @"Keep";
    options.likedColor = [UIColor blueColor];
    options.nopeText = @"Delete";
    options.onPan = ^(MDCPanState *state){
        if (state.thresholdRatio == 1.f && state.direction == MDCSwipeDirectionLeft) {
            NSLog(@"Let go now to delete the photo!");
        }
    };
    
    MDCSwipeToChooseView *view = [[MDCSwipeToChooseView alloc] initWithFrame:self.view.bounds
                                                                     options:options];
    dispatch_async(dispatch_get_main_queue(), ^{
        view.imageView.image = [self.captureManager stillImage];
    });
    [self.view addSubview:view];
}


//added from aroverlayexample
// This is called when a user didn't fully swipe left or right.
- (void)viewDidCancelSwipe:(UIView *)view {
    NSLog(@"Couldn't decide, huh?");
}

#pragma mark - MDCSwipeToChooseDelegate Callbacks
// This is called then a user swipes the view fully left or right.
- (void)view:(UIView *)view wasChosenWithDirection:(MDCSwipeDirection)direction {
    if (direction == MDCSwipeDirectionLeft) {
        NSLog(@"Photo deleted!");
    } else {
        NSLog(@"Photo saved!");
        [self saveImageToPhotoAlbum];
    }
}

//added from aroverlayexample
- (void)saveImageToPhotoAlbum
{
    //Attempt to add opaque overlay layer to camera after image has been taken and saved. use captureManager
    //stillImage pointer to get UIImage
    //    if (self.pAcceptImage.isAccepted) {
    if (self.bFirstScan) {
        
        [[self.view viewWithTag:102] removeFromSuperview];
        
        UIImageView *image0 =[[UIImageView alloc] initWithFrame:[[[self view] layer]bounds]];
        
        image0.tag = 100;
        image0.image=[self.captureManager stillImage];
        UIImage* flippedImage = [UIImage imageWithCGImage:image0.image.CGImage
                                                    scale:image0.image.scale
                                              orientation:UIImageOrientationRight]; //UIImageOrientationLeftMirrored  UIImageOrientationRight
        image0.image = flippedImage;
        image0.alpha = .3;
        //            [self.view addSubview:image0];
        UIImageWriteToSavedPhotosAlbum([[self captureManager] stillImage], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        self.bFirstScan = FALSE;
        //            NSLog(@"First Scan: True");
        
        
        //create transparent border based on orientation
        UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
        NSArray *transparentRects;
        if (deviceOrientation == UIDeviceOrientationLandscapeRight || deviceOrientation == UIDeviceOrientationLandscapeLeft) {
//            transparentRects = [[NSArray alloc] initWithObjects:[NSValue valueWithCGRect:CGRectMake(25, 25, 520, 230)], nil];
            transparentRects = [[NSArray alloc] initWithObjects:[NSValue valueWithCGRect:CGRectMake(25, 50, 270, 418)], nil];

        }
        if (UIInterfaceOrientationIsPortrait(deviceOrientation)){
            transparentRects = [[NSArray alloc] initWithObjects:[NSValue valueWithCGRect:CGRectMake(25, 50, 270, 418)], nil];
            
        }
        //        NSArray *transparentRects = [[NSArray alloc] initWithObjects:[NSValue valueWithCGRect:CGRectMake(25, 50, 270, 418)], nil];
        
        //            PartialTransparentView *transparentView = [[PartialTransparentView alloc] initWithFrame:CGRectMake(0,0,320,500) backgroundImage: [UIImage imageWithCGImage:[self.captureManager stillImage].CGImage scale:[self.captureManager stillImage].scale orientation:UIImageOrientationRight] andTransparentRects:transparentRects];
        
        PartialTransparentView *transparentView = [[PartialTransparentView alloc] initWithFrame:[[[self view] layer]bounds] backgroundImage: [self.captureManager stillImage] andTransparentRects:transparentRects];  //CGRectMake(0,0,320,568)
        transparentView.tag = 2001;
        //             PartialTransparentView *transparentView = [[PartialTransparentView alloc] initWithFrame:CGRectMake(0,0,320,568) backgroundColor:[UIColor colorWithWhite:0.1 alpha:0.75] andTransparentRects:transparentRects];
        [transparentView setNeedsDisplay];
        [transparentView setContentMode:UIViewContentModeRedraw];
        [self.view addSubview:transparentView];
        [self.view addSubview:closeTransparentView];
        //        [self.view addSubview:closeTransparentView];
        //        [self bringOverlayButtonToFront];
        [self bringCameraButtonToFront];
        [self bringFolderButtonToFront];
        
    } else {
        [[self.view viewWithTag:102] removeFromSuperview];
        UIView *viewToRemove = [self.view viewWithTag:2001];
        [viewToRemove removeFromSuperview];
        UIImageWriteToSavedPhotosAlbum([[self captureManager] stillImage], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        [self dismissPartialTransparentView];
        NSLog(@"First Scan: False");
    }
    //    }
    //    else [[self.view viewWithTag:102] removeFromSuperview];
}

-(void)bringCameraButtonToFront {
    for (UIView *subview in self.view.subviews) {
        NSLog(@"subviews=%@ tag=%i",subview, subview.tag);
        //69 was the subview replaced by 68 because it (toolbar) was implemented
        if (subview.tag == 68) {
            [subview removeFromSuperview];
        }
    }
    [self.view addSubview:self.toolBar];
}

-(void)bringFolderButtonToFront {
    for (UIView *subview in self.view.subviews) {
        NSLog(@"subviews=%@ tag=%i",subview, subview.tag);
        //71 was the subview replaced by 68 because it (toolbar) was implemented
        if (subview.tag == 68) {
            [subview removeFromSuperview];
        }
    }
    [self.view addSubview:self.toolBar];
}
//omitted toolbar
//-(void)bringToolbarToFront {
//    for (UIView *subview in self.view.subviews) {
//        NSLog(@"subviews=%@ tag=%i",subview, subview.tag);
//        if (subview.tag == 69) {
//            [subview removeFromSuperview];
//        }
//    }
//    [self.view addSubview:self.overlayToolbar];
//}

-(void)dismissPartialTransparentView
{
    for (UIView *subview in self.view.subviews) {
        NSLog(@"subviews in dismissPartialTransparentView=%@",subview);
        if (subview.tag == 2002) {
            [subview removeFromSuperview];
        }
        if (subview.tag == 2001) {
            [subview removeFromSuperview];
        }
    }
    [self.closeTransparentView removeFromSuperview];
    self.bFirstScan = TRUE;
}

//added from aroverlayexample
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error != NULL) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Image couldn't be saved" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
    }
    else {
        //        [[self scanningLabel] setHidden:YES];
        NSLog(@"avcamedmoviewcontroller didfinishsavingwitherror finished saving");
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [self removeObserver:self forKeyPath:@"captureManager.videoInput.device.flashMode"];
    [self removeObserver:self forKeyPath:@"captureManager.videoInput.device.torchMode"];
    [self removeObserver:self forKeyPath:@"captureManager.videoInput.device.focusMode"];
    [self removeObserver:self forKeyPath:@"captureManager.videoInput.device.adjustingFocus"];
    [self removeObserver:self forKeyPath:@"captureManager.videoInput.device.adjustingExposure"];
    [self removeObserver:self forKeyPath:@"captureManager.videoInput.device.adjustingWhiteBalance"];
    
    [self setVideoPreviewView:nil];
    [self setCaptureVideoPreviewLayer:nil];
    [self setAdjustingInfoView:nil];
    [self setHudButton:nil];
    [self setCameraToggleButton:nil];
    [self setRecordButton:nil];
    [self setGravityButton:nil];
    [self setFlash:nil];
    [self setTorch:nil];
    [self setFocus:nil];
    [self setExposure:nil];
    [self setWhiteBalance:nil];
    [self setAdjustingFocus:nil];
    [self setAdjustingExposure:nil];
    [self setAdjustingWhiteBalance:nil];
    [self setFocusBox:nil];
    [self setExposeBox:nil];
}


#pragma mark Capture Buttons
- (IBAction)record:(id)sender
{
    if (![[self captureManager] isRecording]) {
        [[self recordButton] setEnabled:NO];
        [[self captureManager] startRecording];
    } else {
        [[self recordButton] setEnabled:NO];
        [[self captureManager] stopRecording];
    }
}

- (IBAction)still:(id)sender
{
    [[self captureManager] captureStillImage];
    
    UIView *flashView = [[UIView alloc] initWithFrame:[[self videoPreviewView] frame]];
    [flashView setBackgroundColor:[UIColor whiteColor]];
    [flashView setAlpha:0.f];
    [[[self view] window] addSubview:flashView];
    
    [UIView animateWithDuration:.4f
                     animations:^{
                         [flashView setAlpha:1.f];
                         [flashView setAlpha:0.f];
                     }
                     completion:^(BOOL finished){
                         [flashView removeFromSuperview];
                         //                         [flashView release];
                     }
     ];
}

#pragma mark Camera Toggle
- (IBAction)cameraToggle:(id)sender
{
    [[self captureManager] cameraToggle];
    [[self focusBox] removeAllAnimations];
    [[self exposeBox] removeAllAnimations];
    [self resetFocusAndExpose];
    
    // Update displaying of expandy buttons (don't display buttons for unsupported features)
    BOOL isConfigHidden = [self isConfigHidden];
    int count = 0;
    AVCamDemoCaptureManager *captureManager = [self captureManager];
    ExpandyButton *expandyButton = [self flash];
    if ([captureManager hasFlash]) {
        CGRect frame = [expandyButton frame];
        [expandyButton setFrame:CGRectMake(8.f, 8.f + (40.f * count), frame.size.width, frame.size.height)];
        count++;
        if (!isConfigHidden) [expandyButton setHidden:NO];
    } else {
        [expandyButton setHidden:YES];
    }
    
    expandyButton = [self torch];
    if ([captureManager hasTorch]) {
        CGRect frame = [expandyButton frame];
        [expandyButton setFrame:CGRectMake(8.f, 8.f + (40.f * count), frame.size.width, frame.size.height)];
        count++;
        if (!isConfigHidden) [expandyButton setHidden:NO];
    } else {
        [expandyButton setHidden:YES];
    }
    
    expandyButton = [self focus];
    if ([captureManager hasFocus]) {
        CGRect frame = [expandyButton frame];
        [expandyButton setFrame:CGRectMake(8.f, 8.f + (40.f * count), frame.size.width, frame.size.height)];
        count++;
        if (!isConfigHidden) [expandyButton setHidden:NO];
    } else {
        [expandyButton setHidden:YES];
    }
    
    expandyButton = [self exposure];
    if ([captureManager hasExposure]) {
        CGRect frame = [expandyButton frame];
        [expandyButton setFrame:CGRectMake(8.f, 8.f + (40.f * count), frame.size.width, frame.size.height)];
        count++;
        if (!isConfigHidden) [expandyButton setHidden:NO];
    } else {
        [expandyButton setHidden:YES];
    }
    
    expandyButton = [self whiteBalance];
    if ([captureManager hasWhiteBalance]) {
        CGRect frame = [expandyButton frame];
        [expandyButton setFrame:CGRectMake(8.f, 8.f + (40.f * count), frame.size.width, frame.size.height)];
        if (!isConfigHidden) [expandyButton setHidden:NO];
    } else {
        [expandyButton setHidden:YES];
    }
}

#pragma mark Config View
- (IBAction)hudViewToggle:(id)sender
{
    if ([self isConfigHidden]) {
        [self setConfigHidden:NO];
        AVCamDemoCaptureManager *captureManager = [self captureManager];
        if ([captureManager hasFlash]) {
            [[self flash] setHidden:NO];
        }
        if ([captureManager hasTorch]) {
            [[self torch] setHidden:NO];
        }
        if ([captureManager hasFocus]) {
            [[self focus] setHidden:NO];
        }
        if ([captureManager hasExposure]) {
            [[self exposure] setHidden:NO];
        }
        if ([captureManager hasWhiteBalance]) {
            [[self whiteBalance] setHidden:NO];
        }
        [[self adjustingInfoView] setHidden:NO];
    } else {
        [self setConfigHidden:YES];
        [[self flash] setHidden:YES];
        [[self torch] setHidden:YES];
        [[self focus] setHidden:YES];
        [[self exposure] setHidden:YES];
        [[self whiteBalance] setHidden:YES];
        [[self adjustingInfoView] setHidden:YES];
    }
}

- (IBAction)flashChange:(id)sender
{
    switch ([(ExpandyButton *)sender selectedItem]) {
        case 0:
            [[self captureManager] setFlashMode:AVCaptureFlashModeOff];
            break;
        case 1:
            [[self captureManager] setFlashMode:AVCaptureFlashModeOn];
            break;
        case 2:
            [[self captureManager] setFlashMode:AVCaptureFlashModeAuto];
            break;
    }
}

- (IBAction)torchChange:(id)sender
{
    switch ([(ExpandyButton *)sender selectedItem]) {
        case 0:
            [[self captureManager] setTorchMode:AVCaptureTorchModeOff];
            break;
        case 1:
            [[self captureManager] setTorchMode:AVCaptureTorchModeOn];
            break;
        case 2:
            [[self captureManager] setTorchMode:AVCaptureTorchModeAuto];
            break;
    }
}

- (IBAction)focusChange:(id)sender
{
    switch ([(ExpandyButton *)sender selectedItem]) {
        case 0:
            [[self captureManager] setFocusMode:AVCaptureFocusModeLocked];
            break;
        case 1:
            [[self captureManager] setFocusMode:AVCaptureFocusModeAutoFocus];
            break;
        case 2:
            [[self captureManager] setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            break;
    }
}

- (IBAction)exposureChange:(id)sender
{
    switch ([(ExpandyButton *)sender selectedItem]) {
        case 0:
            [[self captureManager] setExposureMode:AVCaptureExposureModeLocked];
            break;
        case 1:
            [[self captureManager] setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            break;
    }
}

- (IBAction)whiteBalanceChange:(id)sender
{
    switch ([(ExpandyButton *)sender selectedItem]) {
        case 0:
            [[self captureManager] setWhiteBalanceMode:AVCaptureWhiteBalanceModeLocked];
            break;
        case 1:
            [[self captureManager] setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
            break;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([[change objectForKey:NSKeyValueChangeNewKey] isEqual:[NSNull null]]) {
        return;
    }
    if (AVCamDemoFocusModeObserverContext == context) {
        if ([[change objectForKey:NSKeyValueChangeNewKey] integerValue] != [[self focus] selectedItem]) {
            [[self focus] setSelectedItem:[[change objectForKey:NSKeyValueChangeNewKey] integerValue]];
        }
    } else if (AVCamDemoFlashModeObserverContext == context) {
        if ([[change objectForKey:NSKeyValueChangeNewKey] integerValue] != [[self flash] selectedItem]) {
            [[self flash] setSelectedItem:[[change objectForKey:NSKeyValueChangeNewKey] integerValue]];
        }
    } else if (AVCamDemoTorchModeObserverContext == context) {
        if ([[change objectForKey:NSKeyValueChangeNewKey] integerValue] != [[self torch] selectedItem]) {
            [[self torch] setSelectedItem:[[change objectForKey:NSKeyValueChangeNewKey] integerValue]];
        }
    } else if (AVCamDemoAdjustingObserverContext == context) {
        UIView *view = nil;
        if ([keyPath isEqualToString:@"captureManager.videoInput.device.adjustingFocus"]) {
            view = [self adjustingFocus];
            [AVCamDemoViewController addAdjustingAnimationToLayer:[self focusBox] removeAnimation:NO];
        } else if ([keyPath isEqualToString:@"captureManager.videoInput.device.adjustingExposure"]) {
            view = [self adjustingExposure];
            [AVCamDemoViewController addAdjustingAnimationToLayer:[self exposeBox] removeAnimation:NO];
        } else if ([keyPath isEqualToString:@"captureManager.videoInput.device.adjustingWhiteBalance"]) {
            view = [self adjustingWhiteBalance];
        }
        
        if (view != nil) {
            CALayer *layer = [view layer];
            [layer setBorderWidth:1.f];
            [layer setBorderColor:[[UIColor colorWithWhite:0.f alpha:.7f] CGColor]];
            [layer setCornerRadius:8.f];
            
            if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue] == YES) {
                [layer setBackgroundColor:[[UIColor colorWithRed:1.f green:0.f blue:0.f alpha:.7f] CGColor]];
            } else {
                [layer setBackgroundColor:[[UIColor colorWithWhite:1.f alpha:.2f] CGColor]];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (IBAction)changeGravity
{
    AVCaptureVideoPreviewLayer *videoPreviewLayer = [self captureVideoPreviewLayer];
    if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
        [[self focusBox] setPosition:[self translatePoint:[[self focusBox] position] fromGravity:AVLayerVideoGravityResize toGravity:AVLayerVideoGravityResizeAspect]];
        [[self exposeBox] setPosition:[self translatePoint:[[self exposeBox] position] fromGravity:AVLayerVideoGravityResize toGravity:AVLayerVideoGravityResizeAspect]];
        [videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    } else if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
        [[self focusBox] setPosition:[self translatePoint:[[self focusBox] position] fromGravity:AVLayerVideoGravityResizeAspect toGravity:AVLayerVideoGravityResizeAspectFill]];
        [[self exposeBox] setPosition:[self translatePoint:[[self exposeBox] position] fromGravity:AVLayerVideoGravityResizeAspect toGravity:AVLayerVideoGravityResizeAspectFill]];
        [videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    } else if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill] ) {
        [[self focusBox] setPosition:[self translatePoint:[[self focusBox] position] fromGravity:AVLayerVideoGravityResizeAspectFill toGravity:AVLayerVideoGravityResize]];
        [[self exposeBox] setPosition:[self translatePoint:[[self exposeBox] position] fromGravity:AVLayerVideoGravityResizeAspectFill toGravity:AVLayerVideoGravityResize]];
        [videoPreviewLayer setVideoGravity:AVLayerVideoGravityResize];
    }
    
    [self drawFocusBoxAtPointOfInterest:[[self focusBox] position]];
    [self drawExposeBoxAtPointOfInterest:[[self exposeBox] position]];
}

@end

@implementation AVCamDemoViewController (InternalMethods)

+ (CGRect)cleanApertureFromPorts:(NSArray *)ports
{
    CGRect cleanAperture;
    for (AVCaptureInputPort *port in ports) {
        if ([port mediaType] == AVMediaTypeVideo) {
            cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
            break;
        }
    }
    return cleanAperture;
}

+ (CGSize)sizeForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
    
    return size;
}

+ (void)addAdjustingAnimationToLayer:(CALayer *)layer removeAnimation:(BOOL)remove
{
    if (remove) {
        [layer removeAnimationForKey:@"animateOpacity"];
    }
    if ([layer animationForKey:@"animateOpacity"] == nil) {
        [layer setHidden:NO];
        CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        [opacityAnimation setDuration:.3f];
        [opacityAnimation setRepeatCount:1.f];
        [opacityAnimation setAutoreverses:YES];
        [opacityAnimation setFromValue:[NSNumber numberWithFloat:1.f]];
        [opacityAnimation setToValue:[NSNumber numberWithFloat:.0f]];
        [layer addAnimation:opacityAnimation forKey:@"animateOpacity"];
    }
}

- (CGPoint)translatePoint:(CGPoint)point fromGravity:(NSString *)oldGravity toGravity:(NSString *)newGravity
{
    CGPoint newPoint;
    
    CGSize frameSize = [[self videoPreviewView] frame].size;
    
    CGSize apertureSize = [AVCamDemoViewController cleanApertureFromPorts:[[[self captureManager] videoInput] ports]].size;
    
    CGSize oldSize = [AVCamDemoViewController sizeForGravity:oldGravity frameSize:frameSize apertureSize:apertureSize];
    
    CGSize newSize = [AVCamDemoViewController sizeForGravity:newGravity frameSize:frameSize apertureSize:apertureSize];
    
    if (oldSize.height < newSize.height) {
        newPoint.y = ((point.y * newSize.height) / oldSize.height) - ((newSize.height - oldSize.height) / 2.f);
    } else if (oldSize.height > newSize.height) {
        newPoint.y = ((point.y * newSize.height) / oldSize.height) + ((oldSize.height - newSize.height) / 2.f) * (newSize.height / oldSize.height);
    } else if (oldSize.height == newSize.height) {
        newPoint.y = point.y;
    }
    
    if (oldSize.width < newSize.width) {
        newPoint.x = (((point.x - ((newSize.width - oldSize.width) / 2.f)) * newSize.width) / oldSize.width);
    } else if (oldSize.width > newSize.width) {
        newPoint.x = ((point.x * newSize.width) / oldSize.width) + ((oldSize.width - newSize.width) / 2.f);
    } else if (oldSize.width == newSize.width) {
        newPoint.x = point.x;
    }
    
    return newPoint;
}

- (void)drawFocusBoxAtPointOfInterest:(CGPoint)point
{
    
    AVCamDemoCaptureManager *captureManager = [self captureManager];
    if ([captureManager hasFocus]) {
        CGSize frameSize = [[self videoPreviewView] frame].size;
        
        CGSize apertureSize = [AVCamDemoViewController cleanApertureFromPorts:[[[self captureManager] videoInput] ports]].size;
        
        //        CGSize oldBoxSize = [AVCamDemoViewController sizeForGravity:[[self captureVideoPreviewLayer] videoGravity] frameSize:frameSize apertureSize:apertureSize];
        
        CGSize oldBoxSize = CGSizeMake(320, 524);
        
        CGPoint focusPointOfInterest = [[[captureManager videoInput] device] focusPointOfInterest];
        CGSize newBoxSize;
        if (focusPointOfInterest.x == .5f && focusPointOfInterest.y == .5f) {
            newBoxSize.width = (116.f / frameSize.width) * oldBoxSize.width;
            newBoxSize.height = (158.f / frameSize.height) * oldBoxSize.height;
        } else {
            newBoxSize.width = (80.f / frameSize.width) * oldBoxSize.width;
            newBoxSize.height = (110.f / frameSize.height) * oldBoxSize.height;
        }
        
        CALayer *focusBox = [self focusBox];
        //        [focusBox setFrame:CGRectMake(0.f, 0.f, newBoxSize.width, newBoxSize.height)];
        [focusBox setFrame:CGRectMake(0.f, 0.f, 100, 100)];
        [focusBox setPosition:point];
        [AVCamDemoViewController addAdjustingAnimationToLayer:focusBox removeAnimation:YES];
    }
}

- (void)drawExposeBoxAtPointOfInterest:(CGPoint)point
{
    AVCamDemoCaptureManager *captureManager = [self captureManager];
    if ([captureManager hasExposure]) {
        CGSize frameSize = [[self videoPreviewView] frame].size;
        
        CGSize apertureSize = [AVCamDemoViewController cleanApertureFromPorts:[[[self captureManager] videoInput] ports]].size;
        
        //        CGSize oldBoxSize = [AVCamDemoViewController sizeForGravity:[[self captureVideoPreviewLayer] videoGravity] frameSize:frameSize apertureSize:apertureSize];
        
        CGSize oldBoxSize = CGSizeMake(320, 524);
        
        CGPoint exposurePointOfInterest = [[[captureManager videoInput] device] exposurePointOfInterest];
        CGSize newBoxSize;
        if (exposurePointOfInterest.x == .5f && exposurePointOfInterest.y == .5f) {
            newBoxSize.width = (290.f / frameSize.width) * oldBoxSize.width;
            newBoxSize.height = (395.f / frameSize.height) * oldBoxSize.height;
        } else {
            newBoxSize.width = (114.f / frameSize.width) * oldBoxSize.width;
            newBoxSize.height = (154.f / frameSize.height) * oldBoxSize.height;
        }
        
        CALayer *exposeBox = [self exposeBox];
        [exposeBox setFrame:CGRectMake(0.f, 0.f, newBoxSize.width, newBoxSize.height)];
        [exposeBox setPosition:point];
        [AVCamDemoViewController addAdjustingAnimationToLayer:exposeBox removeAnimation:YES];
    }
}

- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = [[self videoPreviewView] frame].size;
    
    AVCaptureVideoPreviewLayer *videoPreviewLayer = [self captureVideoPreviewLayer];
    
    //CHANGEDD
    //    if ([[self captureVideoPreviewLayer] isMirrored]) {
    //        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    //    }
    BOOL videoMirrored;
    if ([self.captureVideoPreviewLayer respondsToSelector:@selector(connection)])
    {
        videoMirrored = self.captureVideoPreviewLayer.connection.isVideoMirrored;
    }
    else
    {
        videoMirrored = self.captureVideoPreviewLayer.isMirrored;
    }
    
    if (videoMirrored)
    {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }
    
    if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in [[[self captureManager] videoInput] ports]) {
            if ([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2;
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2);
                        xc = point.y / frameSize.height;
                    }
                    
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    NSLog(@"AVCamDemoViewController convertToPointOfInterestFromViewCoordinates pointofinterest: %@", NSStringFromCGPoint(pointOfInterest));
    return pointOfInterest;
}

@end

@implementation AVCamDemoViewController (AVCamDemoCaptureManagerDelegate)

- (void) captureStillImageFailedWithError:(NSError *)error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Still Image Capture Failure"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
    [alertView show];
    //    [alertView release];
}

- (void) acquiringDeviceLockFailedWithError:(NSError *)error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Device Configuration Lock Failure"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
    [alertView show];
    //    [alertView release];
}

- (void) cannotWriteToAssetLibrary
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Incompatible with Asset Library"
                                                        message:@"The captured file cannot be written to the asset library. It is likely an audio-only file."
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
    [alertView show];
    //    [alertView release];
}

- (void) assetLibraryError:(NSError *)error forURL:(NSURL *)assetURL
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Asset Library Error"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
    [alertView show];
    //    [alertView release];
}

- (void) someOtherError:(NSError *)error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
    [alertView show];
    //    [alertView release];
}

- (void) recordingBegan
{
    [[self recordButton] setTitle:@"Stop"];
    [[self recordButton] setEnabled:YES];
}

- (void) recordingFinished
{
    [[self recordButton] setTitle:@"Record"];
    [[self recordButton] setEnabled:YES];
}

- (void) deviceCountChanged
{
    AVCamDemoCaptureManager *captureManager = [self captureManager];
    if ([captureManager cameraCount] >= 1 || [captureManager micCount] >= 1) {
        [[self recordButton] setEnabled:YES];
    } else {
        [[self recordButton] setEnabled:NO];
    }
    
}

@end

@implementation AVCamDemoViewController (AVCamDemoPreviewViewDelegate)

- (void)tapToFocus:(CGPoint)point
{
    AVCamDemoCaptureManager *captureManager = [self captureManager];
    if ([[[captureManager videoInput] device] isFocusPointOfInterestSupported]) {
        CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:point];
        [captureManager focusAtPoint:convertedFocusPoint];
        [self drawFocusBoxAtPointOfInterest:point];
    }
}

- (void)tapToExpose:(CGPoint)point
{
    AVCamDemoCaptureManager *captureManager = [self captureManager];
    if ([[[captureManager videoInput] device] isExposurePointOfInterestSupported]) {
        CGPoint convertedExposurePoint = [self convertToPointOfInterestFromViewCoordinates:point];
        [captureManager exposureAtPoint:convertedExposurePoint];
        //[self drawExposeBoxAtPointOfInterest:point];
    }
}

- (void)resetFocusAndExpose
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    [[self captureManager] focusAtPoint:pointOfInterest];
    [[self captureManager] exposureAtPoint:pointOfInterest];
    
    CGRect bounds = [[self videoPreviewView] bounds];
    CGPoint screenCenter = CGPointMake(bounds.size.width / 2.f, bounds.size.height / 2.f);
    
    [self drawFocusBoxAtPointOfInterest:screenCenter];
    [self drawExposeBoxAtPointOfInterest:screenCenter];
    
    [[self captureManager] setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
}

@end
