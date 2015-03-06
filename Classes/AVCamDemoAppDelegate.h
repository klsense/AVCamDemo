//
//  AVCamDemoAppDelegate.h
//  AVCamDemo
//
//  Created by Pat Law on 7/30/13.
//  Copyright (c) 2013 Patrick Law. All rights reserved.
//
#import <UIKit/UIKit.h>

@class AVCamDemoViewController;

@interface AVCamDemoAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    AVCamDemoViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet AVCamDemoViewController *viewController;

@end

