#import "AVCamDemoViewController.h"
#import "AVCamDemoCaptureManager.h"
#import "AVCamDemoPreviewView.h"
#import "MDCSwipeToChoose.h"
#import "PartialTransparentView.h"

@interface AVCamDemoViewController ()

@property (nonatomic,retain) CALayer *focusBox;
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;

@end

@interface AVCamDemoViewController (InternalMethods)

+ (CGRect)cleanApertureFromPorts:(NSArray *)ports;
+ (void)addAdjustingAnimationToLayer:(CALayer *)layer removeAnimation:(BOOL)remove;
- (void)drawFocusBoxAtPointOfInterest:(CGPoint)point;
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
@synthesize focusBox = _focusBox;
@synthesize cameraButton;
@synthesize folderButton;
@synthesize closeTransparentView;

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:(NSCoder *)decoder];
    if (self != nil) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushAcceptView) name:kPushAcceptView object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tapToFocusExpose:) name:kFocus object:nil];
    }
    return self;
}



//handles landscape and portrait mode for scan button and toolbar
-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                        duration:(NSTimeInterval)duration {
    
    [CATransaction begin];
    //landscape left
    if (toInterfaceOrientation==UIInterfaceOrientationLandscapeLeft){
        [[self.captureVideoPreviewLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        self.captureVideoPreviewLayer.frame = [[[self view] layer]bounds];
    }
    //portrait
    else if (toInterfaceOrientation==UIInterfaceOrientationPortrait){
        [[self.captureVideoPreviewLayer connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
        self.captureVideoPreviewLayer.frame = [[[self view] layer]bounds];
        NSLog(@"portrait");
    }
    //landscape right
    else if (toInterfaceOrientation==UIInterfaceOrientationLandscapeRight){
        [[self.captureVideoPreviewLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        self.captureVideoPreviewLayer.frame = [[[self view] layer]bounds];
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
    AVCamDemoCaptureManager *captureManager = [[AVCamDemoCaptureManager alloc] init];
    if ([captureManager setupSessionWithPreset:AVCaptureSessionPresetHigh error:&error]) {
        [self setCaptureManager:captureManager];
        
        AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[captureManager session]];
        UIView *view = [self videoPreviewView];
        CALayer *viewLayer = [view layer];
        [viewLayer setMasksToBounds:YES];
        
        CGRect bounds = [view bounds];
        [captureVideoPreviewLayer setFrame:bounds];
        
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

        
        CGPoint screenCenter = CGPointMake(bounds.size.width / 2.f, bounds.size.height / 2.f);
        
        [self drawFocusBoxAtPointOfInterest:screenCenter];
//        [self drawExposeBoxAtPointOfInterest:screenCenter];
        
        if ([[captureManager session] isRunning]) {
//            [self setConfigHidden:YES];
            NSInteger count = 0;

            [captureManager setDelegate:self];
            
            NSUInteger cameraCount = [captureManager cameraCount];
            if (cameraCount < 1) {
//                [[self cameraToggleButton] setEnabled:NO];
//                [[self stillImageButton] setEnabled:NO];
            } else if (cameraCount < 2) {
//                [[self cameraToggleButton] setEnabled:NO];
            }
            
            if (cameraCount < 1 && [captureManager micCount] < 1) {
//                [[self recordButton] setEnabled:NO];
            }
            
            [viewLayer insertSublayer:captureVideoPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
        }
        else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                                message:@"Failed to start session."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Okay"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Input Device Init Failed"
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Okay"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    

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
    [picker dismissViewControllerAnimated:YES completion:nil]; //dismisses the camera controller
    UIView *viewToRemove = [self.view viewWithTag:101];
    [viewToRemove removeFromSuperview];
    
}

- (void) showLibrary: (id) sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum; //UIImagePickerControllerSourceTypeSavedPhotosAlbum
    [imagePicker setDelegate:self];
    imagePicker.view.tag = 101;
    imagePicker.allowsEditing = NO;
    [self presentViewController:imagePicker animated:YES completion: nil];
    
}

-(void)tapToFocusExpose:(NSNotification *) notification {
    if ([notification.name isEqualToString:kFocus]) {
        NSDictionary* userInfo = notification.userInfo;
        CGPoint tapPoint = [[userInfo valueForKey:@"point"] CGPointValue];
        [self tapToFocus:tapPoint];
        [self tapToExpose:tapPoint];
        
    }
    
}

-(void)pushAcceptView {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"firstLaunch"]) {
        NSLog(@"First time used");
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
        UIImageWriteToSavedPhotosAlbum([[self captureManager] stillImage], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        self.bFirstScan = FALSE;
        //            NSLog(@"First Scan: True");
        
        
        //create transparent border based on orientation
        UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
        NSArray *transparentRects;
        if (deviceOrientation == UIDeviceOrientationLandscapeRight || deviceOrientation == UIDeviceOrientationLandscapeLeft) {
            transparentRects = [[NSArray alloc] initWithObjects:[NSValue valueWithCGRect:CGRectMake(25, 50, 270, 418)], nil];

        }
        if (UIInterfaceOrientationIsPortrait(deviceOrientation)){
            transparentRects = [[NSArray alloc] initWithObjects:[NSValue valueWithCGRect:CGRectMake(25, 50, 270, 418)], nil];
            
        }
        
        PartialTransparentView *transparentView = [[PartialTransparentView alloc] initWithFrame:[[[self view] layer]bounds] backgroundImage: [self.captureManager stillImage] andTransparentRects:transparentRects];  //CGRectMake(0,0,320,568)
        transparentView.tag = 2001;
        [transparentView setNeedsDisplay];
        [transparentView setContentMode:UIViewContentModeRedraw];
        [self.view addSubview:transparentView];
        [self.view addSubview:closeTransparentView];
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

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error != NULL) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Image couldn't be saved" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
    }
    else {
        NSLog(@"avcamedmoviewcontroller didfinishsavingwitherror finished saving");
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark Capture Buttons

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
                     }
     ];
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


- (void)drawFocusBoxAtPointOfInterest:(CGPoint)point
{
    
    AVCamDemoCaptureManager *captureManager = [self captureManager];
    if ([captureManager hasFocus]) {
        CGSize frameSize = [[self videoPreviewView] frame].size;
        
        CGSize apertureSize = [AVCamDemoViewController cleanApertureFromPorts:[[[self captureManager] videoInput] ports]].size;
        
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



- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = [[self videoPreviewView] frame].size;
    
    AVCaptureVideoPreviewLayer *videoPreviewLayer = [self captureVideoPreviewLayer];

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
}

- (void) acquiringDeviceLockFailedWithError:(NSError *)error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Device Configuration Lock Failure"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
    [alertView show];
}



- (void) deviceCountChanged
{
    AVCamDemoCaptureManager *captureManager = [self captureManager];
    if ([captureManager cameraCount] >= 1 || [captureManager micCount] >= 1) {
//        [[self recordButton] setEnabled:YES];
    } else {
//        [[self recordButton] setEnabled:NO];
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
//    [self drawExposeBoxAtPointOfInterest:screenCenter];
    
    [[self captureManager] setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
}

@end
