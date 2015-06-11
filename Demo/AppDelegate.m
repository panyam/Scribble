//
//  AppDelegate.m
//  Scribble
//
//  Created by Sri Panyam on 8/06/2015.
//  Copyright (c) 2015 Panyam. All rights reserved.
//

#import "AppDelegate.h"
#import "ScribbleVC.h"

@interface AppDelegate ()

@property (nonatomic, strong) ScribbleVC *mainVC;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *) launchOptions {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    self.window = [[UIWindow alloc] initWithFrame:screenBounds];

    // Override point for customization after application launch.
    self.mainVC = [[ScribbleVC alloc] initWithNibName:nil bundle:nil];
    self.window.rootViewController = self.mainVC;
    [self.window addSubview:self.mainVC.view];
    self.mainVC.view.frame = screenBounds;
    [self.window makeKeyAndVisible];

    return YES;
}

@end
