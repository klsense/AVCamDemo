//
//  AVCamDemoPreviewView.h
//  AVCamDemo
//
//  Created by Pat Law on 7/30/13.
//  Copyright (c) 2013 Patrick Law. All rights reserved.
//
#import <UIKit/UIKit.h>

@protocol AVCamDemoPreviewViewDelegate
@optional
- (void)tapToFocus:(CGPoint)point;
- (void)tapToExpose:(CGPoint)point;
- (void)resetFocusAndExpose;
-(void)cycleGravity;
@end

@interface AVCamDemoPreviewView : UIView {
    id <AVCamDemoPreviewViewDelegate> _delegate;
}

@property (nonatomic,retain) IBOutlet id <AVCamDemoPreviewViewDelegate> delegate;

@end















