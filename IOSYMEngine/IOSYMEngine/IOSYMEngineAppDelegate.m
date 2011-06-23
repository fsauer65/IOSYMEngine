//
//  IOSYMEngineAppDelegate.m
//  IOSYMEngine
//
//  Created by FRANK SAUER on 6/23/11.
//  Copyright 2011 DST Health Solutions. All rights reserved.
//

#import "IOSYMEngineAppDelegate.h"
#import "YMEngine.h"
#import "MainViewController.h"

#define OAUTH_CONSUMER_KEY    @"your-consumer-key"
#define OAUTH_CONSUMER_SECRET @"your-consumer-secret"

#define USERNAME @"setme"
#define PASSWORD @"setme"

@implementation IOSYMEngineAppDelegate


@synthesize window=_window;

@synthesize mainViewController=_mainViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    // Add the main view controller's view to the window and display.
    self.window.rootViewController = self.mainViewController;
    [self.window makeKeyAndVisible];
    
    // just testing for now
    
    YMEngine *ym = [[YMEngine alloc] initWithConsumerKey:OAUTH_CONSUMER_KEY 
                                               secretKey:OAUTH_CONSUMER_SECRET 
                                                userName:USERNAME password:PASSWORD];
    [ym onError:^(NSError *error) {
        NSLog(@"Error in YM: %@", error);
    }];
    
    [ym withSignOn:@"Hello from test client" signoffAfter: YES do:^(NSArray *contacts) {
        for (NSDictionary *c in contacts) {
            NSLog(@"%@", c);
        }
        [ym sendMessage:@"Neuken in de Keuken!" to:@"eileensauer64"];
    }];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)dealloc
{
    [_window release];
    [_mainViewController release];
    [super dealloc];
}

@end