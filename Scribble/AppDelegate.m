//
//  AppDelegate.m
//  Scribble
//
//  Created by Sri Panyam on 8/06/2015.
//  Copyright (c) 2015 Panyam. All rights reserved.
//

#import "AppDelegate.h"
#import "ScribblesVC.h"

@interface AppDelegate ()

@property (nonatomic, strong) ScribblesVC *mainVC;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Override point for customization after application launch.
    self.window.rootViewController = [[ScribblesVC alloc] initWithNibName:@"ScribblesVC" bundle:[NSBundle mainBundle]];

    return YES;
}

@end
