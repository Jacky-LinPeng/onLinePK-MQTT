//
//  XPYLottieView.m
//  XPYReader
//
//  Created by mac on 2021/8/22.
//  Copyright © 2021 xiang. All rights reserved.
//

#import "XPYLottieView.h"
#import <XPYReader-Swift.h>

@interface XPYLottieView ()

@property (nonatomic, strong) PWLOTAnimationView *animationView;

@end

@implementation XPYLottieView

-(instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        //动画
        [self addSubview:self.animationView];
        [self.animationView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.width.height.equalTo(@(XPYScreenWidth  * 0.8));
        }];
        
        self.alpha = 0;
        [self addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

-(void)play {
    self.userInteractionEnabled = NO;
    self.isPlaying = YES;
    self.alpha = 0;
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 1;
    } completion:^(BOOL finished) {
        [self.animationView play];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.userInteractionEnabled = YES;
        });
    }];
}

-(void)click {
    self.alpha = 1;
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 0;
        [self.animationView stop];
        self.isPlaying = NO;
    }];
}

// MARK: - Lazy
- (PWLOTAnimationView *)animationView {
    if (!_animationView) {
        _animationView = [PWLOTAnimationView animationNamed:@"champion"];
        _animationView.userInteractionEnabled = NO;
        _animationView.loopAnimation = YES;
        _animationView.alpha = 1;
    }
    return _animationView;
}

@end
