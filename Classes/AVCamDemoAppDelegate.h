#import <UIKit/UIKit.h>

@class AVCamDemoViewController;

@interface AVCamDemoAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    AVCamDemoViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet AVCamDemoViewController *viewController;

@end

