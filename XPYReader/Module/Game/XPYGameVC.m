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

#define kXPYGameTopic       @"kXPYGameTopic"

@interface XPYGameVC ()<XPYMQTTManagerProxy>
{
    int globalIntenger;
    UIView *tapView;
    int tapCount;
}

@property (nonatomic, strong) AAChartView *aaChartView;
@property (nonatomic, strong) AAChartModel *aaChartModel;
//PK的人员对象数据信息
@property (nonatomic, strong) NSMutableArray <AASeriesElement *>*users;
//数据
@property (nonatomic, strong) NSMutableDictionary *MQTTData;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation XPYGameVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
    [self setupTimer];
    
    [[XPYMQTTManager sharedInstance] addObserver:self];
    [[XPYMQTTManager sharedInstance] addSubscribeWithTopic:kXPYGameTopic];
}

-(void)setupUI {
    //0xd5e6ca  4b2b7f  F1CE49  DE7DA6
    self.view.backgroundColor = DMRGBColor(232, 221, 203);//DMRGBColor(30, 41, 61);//DMRGBColor(131, 175, 155);//[UIColor colorWithHexString:@"#FF7CA6" andAlpha:1];
    self.navigationController.navigationBar.barTintColor = self.view.backgroundColor;
    
    CGFloat chartViewWidth  = self.view.frame.size.width;
    CGFloat chartViewHeight = self.view.frame.size.height - 250;
    
    UILabel *tip = [UILabel new];
    tip.frame = CGRectMake(0, chartViewHeight + 80, chartViewWidth, 170);
    tip.text = @"快速点击此区域,参与PK";
    tip.textColor =  DMRGBColor(32, 36, 46);//[UIColor whiteColor];
    tip.textAlignment = NSTextAlignmentCenter;
    tip.backgroundColor = DMRGBColor(250, 179, 128);//DMRGBColor(0, 0, 0); //DMRGBColor(252, 157, 154);//[UIColor colorWithHexString:@"#4b2b7f" andAlpha:1];
    tip.font = [UIFont fontWithName:@"SnellRoundhand-Bold" size:30];//[UIFont boldSystemFontOfSize:25];
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
    
    NSString *TEMP = @"#20242E";
    
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
    _aaChartModel.colorsTheme = @[@"#E0A09E",@"#20242E",@"#FC9D9A",@"#FFB6C1",@"#FF7CA6",@"#FE4365"];
    
    _aaChartView.isClearBackgroundColor = YES;
    _aaChartView.scrollEnabled = NO;//禁用 AAChartView 滚动效果
    _aaChartView.tintColor = [UIColor whiteColor];
    
    AAOptions *aaOptions = _aaChartModel.aa_toAAOptions;
    aaOptions.legend
       .itemStyleSet(AAItemStyle.new
                     .colorSet(@"#20242E")//字体颜色
                     .fontSizeSet(@"13px")//字体大小
                     .fontWeightSet(AAChartFontWeightTypeThin)//字体为细体字
                     );
    
//    aaOptions
    [_aaChartView aa_drawChartWithChartModel:_aaChartModel];
    //https://api.highcharts.com.cn/highcharts#xAxis.title
    [_aaChartView aa_refreshChartWithOptions:aaOptions];
}

- (void)setupTimer {
    self->_timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self updateUI];
        
        [self sendRate:tapCount];
        tapCount = 0;
    }];
    [self->_timer fire];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
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

-(void)updateUI {
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

@end
