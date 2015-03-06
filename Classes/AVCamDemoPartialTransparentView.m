//
//  PartialTransparentView.m
//  AVCamDemo
//
//  Created by Pat Law on 7/23/13.
//
//

#import "AVCamDemoPartialTransparentView.h"
#import <QuartzCore/QuartzCore.h>

@implementation AVCamDemoPartialTransparentView


- (id)initWithFrame:(CGRect)frame backgroundImage:(UIImage*)image andTransparentRects:(NSArray*)rects;
{
    backgroundImage = image;
    rectsArray = rects;
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.opaque = NO;
        self.alpha = .8;
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([touches count] == 1) {
        UITouch *touch = [touches anyObject];
        CGPoint tapPoint = [touch locationInView:self];
        if ([touch tapCount] == 1) {
            NSValue *value = [NSValue valueWithCGPoint:tapPoint];
            NSDictionary *tapInfo = [NSDictionary dictionaryWithObject:value forKey:@"point"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kFocus object:nil userInfo:tapInfo];
        }
    }
}


- (void)drawRect:(CGRect)rect
{    
    // Drawing code
    UIImageView *image0 =[[UIImageView alloc] initWithFrame:rect];
    image0.image = backgroundImage;
    //image0.alpha = .9;
    [image0 drawRect:rect];
    // clear the background in the given rectangles
    for (NSValue *holeRectValue in rectsArray) {
        CGRect holeRect = [holeRectValue CGRectValue];
        [[UIColor clearColor] setFill];
        UIRectFill(holeRect);
    }
    
}

@end
