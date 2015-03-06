//
//  PartialTransparentView.h
//  AVCamDemo
//
//  Created by Pat Law on 7/23/13.
//
//

#import <UIKit/UIKit.h>
#define kFocus @"tapToFocus"
#define kExpose @"tapToExpose"



@interface AVCamDemoPartialTransparentView : UIView {
    NSArray *rectsArray;
    UIColor *backgroundColor;
    UIImage *backgroundImage;
}

- (id)initWithFrame:(CGRect)frame backgroundImage:(UIImage*)image andTransparentRects:(NSArray*)rects;
//- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor*)color andTransparentRects:(NSArray*)rects;

@end
