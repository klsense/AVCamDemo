//
//  AVCamDemoViewController.h
//  AVCamDemo
//
//  Created by Pat Law on 7/30/13.
//  Copyright (c) 2013 Patrick Law. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class AVCamDemoCaptureManager, AVCamDemoPreviewView;

@interface AVCamDemoViewController : UIViewController <UIImagePickerControllerDelegate,UINavigationControllerDelegate> {
@private
    AVCamDemoCaptureManager *_captureManager;
    AVCamDemoPreviewView *_videoPreviewView;
    AVCaptureVideoPreviewLayer *_captureVideoPreviewLayer;
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
@property (nonatomic, assign) BOOL bFirstScan;
- (IBAction)still:(id)sender;


@end

