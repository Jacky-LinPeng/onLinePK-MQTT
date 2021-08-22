//
//  XPYGameVC.m
//  XPYReader
//
//  Created by mac on 2021/8/21.
//  Copyright © 2021 xiang. All rights reserved.
//

#import "XPYGameVC.h"
#import "UIColor+Extension.h"
#import "XPYMQTTManager.h"
#import "DMHeartFlyView.h"
#import "XPYLottieView.h"
#import "XPYGameHUD.h"
#import <Toast/Toast.h>
#define kXPYGameTopic       @"kXPYGameTopic"
#define kFlag       NO//切换两种UI风格
#define kShowWinner     10

@interface XPYGameVC ()<XPYMQTTManagerProxy>
{
    UILabel *tapView;//点击视图
    int tapCount;//当前s点击次数
    int timeCount;//时间
    BOOL isInitFlag;
}

@property (nonatomic, strong) AAChartView *aaChartView;
@property (nonatomic, strong) AAChartModel *aaChartModel;
//PK的人员对象数据信息
@property (nonatomic, strong) NSMutableArray <AASeriesElement *>*users;
//数据
@property (nonatomic, strong) NSMutableDictionary *MQTTData;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) XPYLottieView *animationView;
@property (nonatomic, strong) XPYGameHUD *hud;

@end

@implementation XPYGameVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
    [[XPYMQTTManager sharedInstance] addObserver:self];
    [[XPYMQTTManager sharedInstance] addSubscribeWithTopic:kXPYGameTopic];
}

-(void)setupUI {
    
    //0xd5e6ca  4b2b7f  F1CE49  DE7DA6
    self.view.backgroundColor = kFlag ? DMRGBColor(232, 221, 203) : [UIColor colorWithHexString:@"#FF7CA6" andAlpha:1];
    self.navigationController.navigationBar.barTintColor = self.view.backgroundColor;
    
    CGFloat chartViewWidth  = self.view.frame.size.width;
    CGFloat chartViewHeight = self.view.frame.size.height - 250;
    
    UILabel *tip = [UILabel new];
    tip.frame = CGRectMake(0, chartViewHeight + 80, chartViewWidth, 170);
    tip.text = @"猛戳此处 参与PK";
    tip.textColor = kFlag ? DMRGBColor(32, 36, 46) : [UIColor whiteColor];
    tip.textAlignment = NSTextAlignmentCenter;
    tip.backgroundColor = kFlag ? DMRGBColor(250, 179, 128) : [UIColor colorWithHexString:@"#4b2b7f" andAlpha:1];//DMRGBColor(0, 0, 0); //DMRGBColor(252, 157, 154);//[UIColor colorWithHexString:@"#4b2b7f" andAlpha:1];
    tip.font = [UIFont fontWithName:@"PingFangSC-Regular" size:25];// [UIFont fontWithName:@"华康少女字体" size:110];//[UIFont boldSystemFontOfSize:25];
    [self.view addSubview:tip];
    tapView = tip;
    tapView.userInteractionEnabled = NO;
    
    _aaChartView = [[AAChartView alloc]init];
    _aaChartView.frame = CGRectMake(0, XPYTopHeight, chartViewWidth, chartViewHeight);
    //_aaChartView.scrollEnabled = NO;
    [self.view addSubview:_aaChartView];
    
    CGFloat rate = 1;
    NSString *deviceID = [[XPYMQTTManager sharedInstance] getDeviceUniId];
    AASeriesElement *value = AASeriesElement.new
    .nameSet(deviceID)
//    .colorSet((id)AAGradientColor.deepSeaColor)
    .dataSet(@[@(rate)]);
    [self.users addObject:value];
    
    _aaChartModel = AAChartModel.new
    .chartTypeSet(AAChartTypeBar)
    .titleSet(@"手速王 - 在线PK")
    .subtitleSet(@"实时数据（1秒更新）")
    .categoriesSet(@[@"次/秒"])
    .yAxisTitleSet(nil)
    .seriesSet(@[
        value
    ])
    ;
    
    NSString *TEMP = kFlag? @"#20242E" : @"#ffffff";
    
    AAStyle *titleStyle = [AAStyle styleWithColor:TEMP];
    _aaChartModel.titleStyle = titleStyle;
    
    AAStyle *subtitleStyle = [AAStyle styleWithColor:TEMP];
    _aaChartModel.subtitleStyle = subtitleStyle;
   
    //数据线
    AAStyle *dataLabelsStyle = [AAStyle styleWithColor:TEMP];
    _aaChartModel.dataLabelsStyle = dataLabelsStyle;
    
    AAStyle *xAxisLabelsStyle = [AAStyle styleWithColor:TEMP];
    _aaChartModel.xAxisLabelsStyle = xAxisLabelsStyle;
    
    AAStyle *yAxisLabelsStyle = [AAStyle styleWithColor:TEMP];
    yAxisLabelsStyle.fontSize = @"15";
    _aaChartModel.yAxisLabelsStyle = yAxisLabelsStyle;
    
    _aaChartModel.tooltipEnabled = YES;
    _aaChartModel.yAxisTitle = @"单位每秒点击次数（次/秒）";
    _aaChartModel.yAxisLabelsStyle = yAxisLabelsStyle;
    _aaChartModel.yAxisCrosshair = [AACrosshair crosshairWithColor:@"#F1CE49"];
    if (kFlag) {
        _aaChartModel.colorsTheme = @[@"#E0A09E",@"#20242E",@"#FC9D9A",@"#FFB6C1",@"#FF7CA6",@"#FE4365"];
    }
    
    _aaChartView.isClearBackgroundColor = YES;
    _aaChartView.scrollEnabled = NO;//禁用 AAChartView 滚动效果
    _aaChartView.tintColor = [UIColor whiteColor];
    
    AAOptions *aaOptions = _aaChartModel.aa_toAAOptions;
    aaOptions.legend
       .itemStyleSet(AAItemStyle.new
                     .colorSet(kFlag?@"#20242E":@"#ffffff")//字体颜色
                     .fontSizeSet(@"13px")//字体大小
                     .fontWeightSet(AAChartFontWeightTypeThin)//字体为细体字
                     );
    //禁用图例点击事件
    aaOptions.plotOptions.series.events = AAEvents.new
    .legendItemClickSet(@AAJSFunc(function() {
        return false;
    }));
    
    //hud loading
    [self.hud play];
    
    //    aaOptions
    [_aaChartView aa_drawChartWithChartModel:_aaChartModel];
    //https://api.highcharts.com.cn/highcharts#xAxis.title
    [_aaChartView aa_refreshChartWithOptions:aaOptions];
    
    //dismiss hud
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.hud stop];
    });
    
}

- (void)setupTimer {
    self->_timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (self.animationView.isPlaying) {
            return;
        }
        
        [self sendRate:tapCount];
        tapCount = 0;
        
        timeCount++;
        tapView.text = [NSString stringWithFormat:@"本场PK倒计时:%d",kShowWinner - timeCount % kShowWinner];

        [self updateUI];
    }];
    [self->_timer fire];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if (!isInitFlag) {
        [self setupTimer];
    }
    isInitFlag = YES;
    
    
    //点赞动画
    UITouch *touch = [event.allTouches anyObject];
    CGPoint locationPointWindow = [touch preciseLocationInView:touch.window];
    NSString *sender = [[XPYMQTTManager sharedInstance] getDeviceUniId];
    [self showTheLove:locationPointWindow.x y:locationPointWindow.y];
    
    
    //同步点赞动画
    [[XPYMQTTManager sharedInstance] sendPageInfo:@{@"x":@(locationPointWindow.x),@"sender":sender} topicId:kXPYGameTopic];
    
    tapCount ++;
}

-(void)sendRate:(int)rate {
    NSLog(@"count %d",rate);
    NSString *uid = [[XPYMQTTManager sharedInstance] getDeviceUniId];
    [[XPYMQTTManager sharedInstance] sendTxtMessage:@{@"data": @[@{@"sender": uid ,@"rate": @(rate)}]} topicId:kXPYGameTopic];
}

-(AASeriesElement *)findElementByName:(NSString *)name {
    NSPredicate *predict = [NSPredicate predicateWithFormat:@"name == %@",name];
    return [self.users filteredArrayUsingPredicate:predict].firstObject;
}

-(void)didRecivePageChangedWithOrignal:(NSDictionary *)orignal topicId:(NSString *)topicId {
    if (![topicId isEqualToString:kXPYGameTopic]) {
        return;
    }
    NSString *sender = [[XPYMQTTManager sharedInstance] getDeviceUniId];
    if ([sender isEqualToString:orignal[@"sender"]]) {
        return;
    }
    [self showTheLove:[orignal[@"x"] floatValue] y:tapView.frame.origin.y - 10];
}

-(void)didReciveMessage:(NSDictionary *)data topicId:(NSString *)topicId {
    if (![topicId isEqualToString:kXPYGameTopic]) {
        return;
    }
    self.MQTTData = [data mutableCopy];
    
    NSArray *pkList = self.MQTTData[@"data"];
    for (NSDictionary *user in pkList) {
        NSString *sender =  user[@"sender"];
        CGFloat rate = [user[@"rate"] floatValue];
        AASeriesElement *newUer = AASeriesElement.new
        .nameSet(sender)
        .dataSet(@[@(rate)]);
        
        AASeriesElement *curUser = [self findElementByName:sender];
        if (curUser == nil) {
            //cache
            [self.users addObject:newUer];
            //reload
            [self.aaChartView aa_addElementToChartSeriesWithElement:newUer];
        } else {
            NSUInteger index = [self.users indexOfObject:curUser];
            [self.users replaceObjectAtIndex:index withObject:newUer];
        }
    }
}

-(void)sort {
    NSArray *list = [self.users sortedArrayUsingComparator:^NSComparisonResult(AASeriesElement *obj1, AASeriesElement *obj2) {

        NSNumber *tNumber1 = (NSNumber *)obj1.data.firstObject;
        NSNumber *tNumber2 = (NSNumber *)obj2.data.firstObject;
        //因为不满足sortedArrayUsingComparator方法的默认排序顺序，则需要交换
        if ([tNumber1 floatValue] < [tNumber2 floatValue])
            return NSOrderedDescending;
        return NSOrderedAscending;
    }];
    self.users = [list mutableCopy];
}

-(void)checkResult {
    [self sort];
    AASeriesElement *user =  self.users.firstObject;
    if ([user.name isEqualToString:[[XPYMQTTManager sharedInstance] getDeviceUniId]]) {
        if ([user.data.firstObject intValue] > 0) {
            if (!self.animationView.isPlaying) {
                [self.animationView play];
            }
        }
    } else {
        [self.view makeToast:[NSString stringWithFormat:@"本场冠军🏆:%@",user.name] duration:2 position:CSToastPositionCenter];
//        [MBProgressHUD xpy_showSuccessTips:[NSString stringWithFormat:@"本场🏆:%@",user.name]];
    }
}

-(void)updateUI {
    //间隔5秒检测一次冠军
    if (timeCount % kShowWinner == 0) {
        [self checkResult];
    }
    //reload
    [self.aaChartView aa_onlyRefreshTheChartDataWithChartModelSeries:self.users
                                                           animation:true];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(NSMutableArray *)users {
    if (!_users) {
        _users = [[NSMutableArray alloc] init];
    }
    return _users;;
}

CGFloat _heartSize;
NSTimer *_burstTimer;
-(void)showTheLove:(CGFloat)x y:(CGFloat)y {
    _heartSize = 60;
    DMHeartFlyView* heart = [[DMHeartFlyView alloc]initWithFrame:CGRectMake(0, 0, _heartSize, _heartSize)];
    [self.view addSubview:heart];
    CGPoint fountainSource = CGPointMake(x + _heartSize/2.0, y - _heartSize/2.0 - 10);
    heart.center = fountainSource;
    [heart animateInView:self.view];
}

-(XPYLottieView *)animationView {
    if(!_animationView) {
        _animationView = [[XPYLottieView alloc] init];
        [self.view addSubview:_animationView];
        [_animationView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.bottom.right.top.equalTo(self.view);
        }];
    }
    return _animationView;;
}

-(XPYGameHUD *)hud {
    if (!_hud) {
        _hud = [[XPYGameHUD alloc] init];
        [self.view addSubview:_hud];
        [_hud mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.bottom.right.top.equalTo(self.view);
        }];
    }
    return _hud;;
}

@end
