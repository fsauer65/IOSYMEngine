//
//  IOSYMEngineAppDelegate.h
//  IOSYMEngine
//
//  Created by FRANK SAUER on 6/23/11.
//  Copyright 2011 DST Health Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MainViewController;

@interface IOSYMEngineAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet MainViewController *mainViewController;

@end
