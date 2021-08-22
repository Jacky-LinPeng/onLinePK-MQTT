//
//  XPYGameHUD.m
//  XPYReader
//
//  Created by mac on 2021/8/22.
//  Copyright © 2021 xiang. All rights reserved.
//

#import "XPYGameHUD.h"
#import <XPYReader-Swift.h>

@interface XPYGameHUD ()

@property (nonatomic, strong) PWLOTAnimationView *animationView;

@end

@implementation XPYGameHUD

-(instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:1];
        //动画
        [self addSubview:self.animationView];
        [self.animationView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.width.height.equalTo(@(XPYScreenWidth  * 0.8));
        }];
        
//        self.alpha = 0;
//        [self addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

-(void)play {
    self.userInteractionEnabled = NO;
    self.alpha = 0;
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 1;
    } completion:^(BOOL finished) {
        [self.animationView play];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.25 animations:^{
                self.alpha = 0;
                [self.animationView stop];
            }];
        });
    }];
}

// MARK: - Lazy
- (PWLOTAnimationView *)animationView {
    if (!_animationView) {
        _animationView = [PWLOTAnimationView animationNamed:@"radar"];
        _animationView.userInteractionEnabled = NO;
        _animationView.loopAnimation = YES;
        _animationView.alpha = 1;
    }
    return _animationView;
}

@end
