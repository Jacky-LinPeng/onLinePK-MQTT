//
//  AppDelegate.m
//  XPYReader
//
//  Created by zhangdu_imac on 2020/8/3.
//  Copyright © 2020 xiang. All rights reserved.
//

#import "AppDelegate.h"
#import "XPYNavigationController.h"
#import "XPYTabBarController.h"
#import "XPYGameVC.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window makeKeyAndVisible];
    
//    XPYTabBarController *tabBarController = [[XPYTabBarController alloc] init];
    XPYGameVC *stackController = [[XPYGameVC alloc] init];
    
    XPYNavigationController *stackNavigation = [[XPYNavigationController alloc] initWithRootViewController:stackController];
    
    NSArray* familys = [UIFont familyNames];
    for (int i = 0; i < [familys count]; i++) {
        NSString* family = [familys objectAtIndex:i];
        NSLog(@"字体族名称:%@=====", family);
        NSArray* fonts = [UIFont fontNamesForFamilyName:family];
        for (int j = 0; j < [fonts count]; j++) {
            NSLog(@"字体名称:%@", [fonts objectAtIndex:j]);
        }
    }
   
    self.window.rootViewController = stackController;
    
    return YES;
}

@end
