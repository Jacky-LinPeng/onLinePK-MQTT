//
//  DMHeartFlyView.h
//  DMHeartFlyAnimation
//
//  Created by Rick on 16/3/9.
//  Copyright © 2016年 Rick. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define DMRGBColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define DMRGBAColor(r, g, b ,a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]
#define DMRandColor DMRGBColor(arc4random_uniform(255), arc4random_uniform(255), arc4random_uniform(255))


@interface DMHeartFlyView : UIView

-(void)animateInView:(UIView *)view;

@end

