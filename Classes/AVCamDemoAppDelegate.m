#import "AVCamDemoAppDelegate.h"
#import "AVCamDemoViewController.h"
#import "AVCamDemoCaptureManager.h"
#import <AVFoundation/AVCaptureSession.h>

@implementation AVCamDemoAppDelegate

@synthesize window;
@synthesize viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:@"firstRun"])
        [defaults setObject:[NSDate date] forKey:@"firstRun"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return YES;
}


//- (void)dealloc {
//    [viewController release];
//    [window release];
//    [super dealloc];
//}


@end
