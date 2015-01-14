#import "AVCamDemoPreviewView.h"

@interface AVCamDemoPreviewView ()
- (void)handleSingleTap:(id)tapPointValue;
- (void)handleDoubleTap:(id)tapPointValue;
- (void)handleTripleTap;
@end


@implementation AVCamDemoPreviewView

@synthesize delegate = _delegate;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([touches count] == 1) {
        UITouch *touch = [touches anyObject];
        CGPoint tapPoint = [touch locationInView:self];
        NSLog(@"AVCamDemoPreviewView tappoint: %@", NSStringFromCGPoint(tapPoint));
        if ([touch tapCount] == 1) {
            [self performSelector:@selector(handleSingleTap:) withObject:[NSValue valueWithCGPoint:tapPoint] afterDelay:0.3];
            [self performSelector:@selector(handleDoubleTap:) withObject:[NSValue valueWithCGPoint:tapPoint] afterDelay:0.3];
        } else if ([touch tapCount] == 2) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            [self performSelector:@selector(handleDoubleTap:) withObject:[NSValue valueWithCGPoint:tapPoint] afterDelay:0.3];
        } else if ([touch tapCount] == 3) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            [self handleTripleTap];
        }
    }
}

- (void)handleSingleTap:(id)tapPointValue
{
    id delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(tapToFocus:)]) {
        [delegate tapToFocus:[tapPointValue CGPointValue]];
    }
}

- (void)handleDoubleTap:(id)tapPointValue
{
    id delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(tapToExpose:)]) {
        [delegate tapToExpose:[tapPointValue CGPointValue]];
    }
}

- (void)handleTripleTap
{
    id delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(resetFocusAndExpose)]) {
        [delegate resetFocusAndExpose];
    }
}

@end
