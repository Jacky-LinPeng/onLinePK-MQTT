//
//  HXMQTTManager.m
//  HXChallengeApp
//
//  Created by mac on 2021/8/10.
//

#import "XPYMQTTManager.h"
#import <CommonCrypto/CommonHMAC.h>
#import <AFNetworking/AFNetworking.h>
#import <MQTTClient/MQTTClient.h>
#import <MQTTClient/MQTTSessionManager.h>
#import "sys/utsname.h"

#define getToken_url        @"https://a1.easemob.com/540933120/look/token"

//区别消息还是操作类型的消息指令
#define kHXMQTTTxtTopic     @"kHXMQTTTxtTopic"
#define kHXMQTTOPTopic      @"kHXMQTTOPTopic"

@interface XPYMQTTManager ()<MQTTSessionManagerDelegate>

@property (nonatomic,strong) MQTTSessionManager *manager;
@property (nonatomic,strong) NSString *appId;
@property (nonatomic,strong) NSString *host;
@property (nonatomic,assign) NSInteger port;
@property (nonatomic,assign) NSInteger tls;
@property (nonatomic,strong) NSString *clientId;
@property (nonatomic,assign) NSInteger qos;

@end


@implementation XPYMQTTManager

-(instancetype)init {
    if (self = [super init]) {
        [self loadConfiguation];
    }
    return self;
}

-(void)sendTxtMessage:(NSDictionary *)data topicId:(NSString *)topicId {
    [self.manager sendData:[data yy_modelToJSONData]
                     topic:[NSString stringWithFormat:@"%@/%@",
                            kHXMQTTTxtTopic,
                            topicId]//此处设置多级子topic
                       qos:self.qos
                    retain:FALSE];
}

-(void)sendPageInfo:(NSDictionary *)data topicId:(NSString *)topicId {
    [self.manager sendData:[data yy_modelToJSONData]
                     topic:[NSString stringWithFormat:@"%@/%@",
                            kHXMQTTOPTopic,
                            topicId]//此处设置多级子topic
                       qos:self.qos
                    retain:FALSE];
    
}

-(void)addSubscribeWithTopic:(NSString *)topicId {
    NSDictionary *subscribes = self.manager.subscriptions;
    NSMutableDictionary *desktinations = [[NSMutableDictionary alloc] init];
    if (subscribes) {
        [desktinations addEntriesFromDictionary:subscribes];
    }
    NSDictionary *op = @{[NSString stringWithFormat:@"%@/%@",
                                    kHXMQTTOPTopic,
                          topicId]:@(self.qos)};
    NSDictionary *msg = @{[NSString stringWithFormat:@"%@/%@",
                                    kHXMQTTTxtTopic,
                           topicId]:@(self.qos)};
    [desktinations addEntriesFromDictionary:op];
    [desktinations addEntriesFromDictionary:msg];
    self.manager.subscriptions = desktinations;
}

//MARK: private method

- (void)loadConfiguation {
    self.appId = @"u5hji0";
    self.host = @"u5hji0.cn1.mqtt.chat";
    self.port = 1883;
    self.qos = 0;
    self.tls = 0;
    
    NSString *deviceID = [UIDevice currentDevice].identifierForVendor.UUIDString;
    self.clientId = [NSString stringWithFormat:@"%@@%@",deviceID,self.appId];

    if (!self.manager) {
        self.manager = [[MQTTSessionManager alloc] init];
        self.manager.delegate = self;
        //【userName && passWord】需要从后台创建获取
        NSString *userName = @"demo";
        NSString *passWord = @"123456";
        
        //生成token（请求服务器api）
        [self getTokenWithUsername:userName password:passWord completion:^(NSString *token) {
            NSLog(@"=======token:%@==========",token);
            
            [self.manager connectTo:self.host
                               port:self.port
                                tls:self.tls
                          keepalive:60
                              clean:true
                               auth:true
                               user:userName
                               pass:token
                               will:false
                          willTopic:nil
                            willMsg:nil
                            willQos:MQTTQosLevelAtMostOnce
                     willRetainFlag:nil
                       withClientId:self.clientId
                     securityPolicy:nil
                       certificates:nil
                      protocolLevel:MQTTProtocolVersion311
                     connectHandler:^(NSError *error) {
                
            }];
            
//            // 从console管理平台获取连接地址
//           [self.manager connectTo:self.host
//                              port:self.port
//                               tls:self.tls
//                         keepalive:60
//                             clean:true
//                              auth:true
//                              user:userName
//                              pass:token
//                              will:false
//                         willTopic:nil
//                           willMsg:nil
//                           willQos:0
//                    willRetainFlag:FALSE
//                      withClientId:self.clientId];
            
        }];
    } else {
        [self.manager connectToLast:^(NSError *error) {
            
        }];
    }
    
    [self.manager addObserver:self
                   forKeyPath:@"state"
                      options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                      context:nil];
}

#pragma mark private method
- (void)getTokenWithUsername:(NSString *)username password:(NSString *)password completion:(void (^)(NSString *token))response {
    

    NSString *urlString = getToken_url;
    //初始化一个AFHTTPSessionManager
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //设置请求体数据为json类型
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    //设置响应体数据为json类型
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    //请求体，参数（NSDictionary 类型）
    
    NSDictionary *parameters = @{@"grant_type":@"password",
                                 @"username":username,
                                 @"password":password
    };
    __block NSString *token  = @"";
    
    [manager POST:urlString parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:&error];
        NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        NSLog(@"%s jsonDic:%@",__func__,jsonDic);
        token = jsonDic[@"access_token"];
        
        response(token);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"%s error:%@",__func__,error.debugDescription);
            response(token);
    }];
    
}


/*
 * 重新连接
 */
- (void)connect {
    [self.manager connectToLast:^(NSError *error) {
        
    }];
}

/*
 * 断开连接
 */
- (void)disConnect {
    [self.manager disconnectWithDisconnectHandler:^(NSError *error) {
        
    }];
    self.manager.subscriptions = @{};
}
/**
  取消订阅主题
*/
- (void)unSubScribeTopic {
    self.manager.subscriptions = @{};
}


#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    switch (self.manager.state) {
        case MQTTSessionManagerStateClosed:
           
            break;
        case MQTTSessionManagerStateClosing:
           
            break;
        case MQTTSessionManagerStateConnected:
           
            break;
        case MQTTSessionManagerStateConnecting:
           
            break;
        case MQTTSessionManagerStateError:
         
            break;
        case MQTTSessionManagerStateStarting:
        default:
//            [self.manager connectToLast:^(NSError *error) {
//
//            }];
            break;
    }
}


#pragma mark MQTTSessionManagerDelegate
/*
 * MQTTSessionManagerDelegate
 */
- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained {
    NSArray *subTopics = [topic componentsSeparatedByString:@"/"];
    NSString *topicId = subTopics.firstObject;
    NSString *dataJson = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *dataDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];;
    
    if ([topicId isEqualToString:kHXMQTTTxtTopic]) {
        [self notifyObserversWithSelector:@selector(didReciveMessage:topicId:) withObjectOne:dataDict objectTwo:subTopics.lastObject];
    } else if ([topicId isEqualToString:kHXMQTTOPTopic]) {
        [self notifyObserversWithSelector:@selector(didRecivePageChangedWithOrignal:topicId:) withObjectOne:dataDict objectTwo:subTopics.lastObject];
    }
    NSLog(@"rec:%@",dataJson);
}

-(void)messageDelivered:(UInt16)msgID {
    NSLog(@"%s msgId:%@",__func__,@(msgID));
    
}

- (NSString *)getDeviceUniId {
    NSString *deviceID = [UIDevice currentDevice].identifierForVendor.UUIDString;
    return [NSString stringWithFormat:@"%@(%@)",[[XPYMQTTManager sharedInstance] getDeviceName],[deviceID substringToIndex:4]];
}

- (NSString *)getDeviceName {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    //模拟器
    if ([deviceString isEqualToString:@"i386"])         return @"Simulator";
    if ([deviceString isEqualToString:@"x86_64"])       return @"Simulator";
    
    //iPhone
    if ([deviceString isEqualToString:@"iPhone1,1"])    return @"iPhone";
    if ([deviceString isEqualToString:@"iPhone1,2"])    return @"iPhone_3G";
    if ([deviceString isEqualToString:@"iPhone2,1"])    return @"iPhone_3GS";
    if ([deviceString isEqualToString:@"iPhone3,1"])    return @"iPhone_4";
    if ([deviceString isEqualToString:@"iPhone3,2"])    return @"iPhone_4";
    if ([deviceString isEqualToString:@"iPhone3,3"])    return @"iPhone_4";
    if ([deviceString isEqualToString:@"iPhone4,1"])    return @"iPhone_4S";
    if ([deviceString isEqualToString:@"iPhone5,1"])    return @"iPhone_5";
    if ([deviceString isEqualToString:@"iPhone5,2"])    return @"iPhone_5";
    if ([deviceString isEqualToString:@"iPhone5,3"])    return @"iPhone_5c";
    if ([deviceString isEqualToString:@"iPhone5,4"])    return @"iPhone_5c";
    if ([deviceString isEqualToString:@"iPhone6,1"])    return @"iPhone_5s";
    if ([deviceString isEqualToString:@"iPhone6,2"])    return @"iPhone_5s";
    if ([deviceString isEqualToString:@"iPhone7,1"])    return @"iPhone_6_Plus";
    if ([deviceString isEqualToString:@"iPhone7,2"])    return @"iPhone_6";
    if ([deviceString isEqualToString:@"iPhone8,1"])    return @"iPhone_6s";
    if ([deviceString isEqualToString:@"iPhone8,2"])    return @"iPhone_6s_Plus";
    if ([deviceString isEqualToString:@"iPhone8,4"])    return @"iPhone_SE";
    if ([deviceString isEqualToString:@"iPhone9,1"])    return @"iPhone_7";
    if ([deviceString isEqualToString:@"iPhone9,2"])    return @"iPhone_7_Plus";
    if ([deviceString isEqualToString:@"iPhone9,3"])    return @"iPhone_7";
    if ([deviceString isEqualToString:@"iPhone9,4"])    return @"iPhone_7_Plus";
    if ([deviceString isEqualToString:@"iPhone10,1"])   return @"iPhone_8";
    if ([deviceString isEqualToString:@"iPhone10,2"])   return @"iPhone_8_Plus";
    if ([deviceString isEqualToString:@"iPhone10,3"])   return @"iPhone_X";
    if ([deviceString isEqualToString:@"iPhone10,4"])   return @"iPhone_8";
    if ([deviceString isEqualToString:@"iPhone10,5"])   return @"iPhone_8_Plus";
    if ([deviceString isEqualToString:@"iPhone10,6"])   return @"iPhone_X";
    if ([deviceString isEqualToString:@"iPhone11,2"])   return @"iPhone_XS";
    if ([deviceString isEqualToString:@"iPhone11,4"])   return @"iPhone_XS_Max";
    if ([deviceString isEqualToString:@"iPhone11,6"])   return @"iPhone_XS_Max";
    if ([deviceString isEqualToString:@"iPhone11,8"])   return @"iPhone_XR";
    if ([deviceString isEqualToString:@"iPhone12,1"])   return @"iPhone_11";
    if ([deviceString isEqualToString:@"iPhone12,3"])   return @"iPhone_11_Pro";
    if ([deviceString isEqualToString:@"iPhone12,5"])   return @"iPhone_11_Pro_Max";
    if ([deviceString isEqualToString:@"iPhone12,8"])   return @"iPhone_SE2";
    if ([deviceString isEqualToString:@"iPhone13,1"])   return @"iPhone_12_mini";
    if ([deviceString isEqualToString:@"iPhone13,2"])   return @"iPhone_12";
    if ([deviceString isEqualToString:@"iPhone13,3"])   return @"iPhone_12_Pro";
    if ([deviceString isEqualToString:@"iPhone13,4"])   return @"iPhone_12_Pro_Max";
    
    //iPad
    if ([deviceString isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([deviceString isEqualToString:@"iPad2,1"])      return @"iPad_2nd";
    if ([deviceString isEqualToString:@"iPad2,2"])      return @"iPad_2nd";
    if ([deviceString isEqualToString:@"iPad2,3"])      return @"iPad_2nd";
    if ([deviceString isEqualToString:@"iPad2,4"])      return @"iPad_2nd";
    if ([deviceString isEqualToString:@"iPad2,5"])      return @"iPad_mini";
    if ([deviceString isEqualToString:@"iPad2,6"])      return @"iPad_mini";
    if ([deviceString isEqualToString:@"iPad2,7"])      return @"iPad_mini";
    if ([deviceString isEqualToString:@"iPad3,1"])      return @"iPad_3rd";
    if ([deviceString isEqualToString:@"iPad3,2"])      return @"iPad_3rd";
    if ([deviceString isEqualToString:@"iPad3,3"])      return @"iPad_3rd";
    if ([deviceString isEqualToString:@"iPad3,4"])      return @"iPad_4th";
    if ([deviceString isEqualToString:@"iPad3,5"])      return @"iPad_4th";
    if ([deviceString isEqualToString:@"iPad3,6"])      return @"iPad_4th";
    if ([deviceString isEqualToString:@"iPad4,1"])      return @"iPadAir";
    if ([deviceString isEqualToString:@"iPad4,2"])      return @"iPadAir";
    if ([deviceString isEqualToString:@"iPad4,3"])      return @"iPadAir";
    if ([deviceString isEqualToString:@"iPad4,4"])      return @"iPad_mini_2nd";
    if ([deviceString isEqualToString:@"iPad4,5"])      return @"iPad_mini_2nd";
    if ([deviceString isEqualToString:@"iPad4,6"])      return @"iPad_mini_2nd";
    if ([deviceString isEqualToString:@"iPad4,7"])      return @"iPad_mini_3rd";
    if ([deviceString isEqualToString:@"iPad4,8"])      return @"iPad_mini_3rd";
    if ([deviceString isEqualToString:@"iPad4,9"])      return @"iPad_mini_3rd";
    if ([deviceString isEqualToString:@"iPad5,1"])      return @"iPad_mini_4th";
    if ([deviceString isEqualToString:@"iPad5,2"])      return @"iPad_mini_4th";
    if ([deviceString isEqualToString:@"iPad5,3"])      return @"iPadAir_2nd";
    if ([deviceString isEqualToString:@"iPad5,4"])      return @"iPadAir_2nd";
    if ([deviceString isEqualToString:@"iPad6,3"])      return @"iPadPro_9.7";
    if ([deviceString isEqualToString:@"iPad6,4"])      return @"iPadPro_9.7";
    if ([deviceString isEqualToString:@"iPad6,7"])      return @"iPadPro_12.9";
    if ([deviceString isEqualToString:@"iPad6,8"])      return @"iPadPro_12.9";
    if ([deviceString isEqualToString:@"iPad6,11"])     return @"iPad_5th";
    if ([deviceString isEqualToString:@"iPad6,12"])     return @"iPad_5th";
    if ([deviceString isEqualToString:@"iPad7,1"])      return @"iPadPro_12.9_2nd";
    if ([deviceString isEqualToString:@"iPad7,2"])      return @"iPadPro_12.9_2nd";
    if ([deviceString isEqualToString:@"iPad7,3"])      return @"iPadPro_10.5";
    if ([deviceString isEqualToString:@"iPad7,4"])      return @"iPadPro_10.5";
    if ([deviceString isEqualToString:@"iPad7,5"])      return @"iPad_6th";
    if ([deviceString isEqualToString:@"iPad7,6"])      return @"iPad_6th";
    if ([deviceString isEqualToString:@"iPad7,11"])     return @"iPad_7th";
    if ([deviceString isEqualToString:@"iPad7,12"])     return @"iPad_7th";
    if ([deviceString isEqualToString:@"iPad8,1"])      return @"iPadPro_11";
    if ([deviceString isEqualToString:@"iPad8,2"])      return @"iPadPro_11";
    if ([deviceString isEqualToString:@"iPad8,3"])      return @"iPadPro_11";
    if ([deviceString isEqualToString:@"iPad8,4"])      return @"iPadPro_11";
    if ([deviceString isEqualToString:@"iPad8,5"])      return @"iPadPro_12.9_3rd";
    if ([deviceString isEqualToString:@"iPad8,6"])      return @"iPadPro_12.9_3rd";
    if ([deviceString isEqualToString:@"iPad8,7"])      return @"iPadPro_12.9_3rd";
    if ([deviceString isEqualToString:@"iPad8,8"])      return @"iPadPro_12.9_3rd";
    if ([deviceString isEqualToString:@"iPad8,9"])      return @"iPadPro_11_2nd";
    if ([deviceString isEqualToString:@"iPad8,10"])     return @"iPadPro_11_2nd";
    if ([deviceString isEqualToString:@"iPad8,11"])     return @"iPadPro_12.9_4th";
    if ([deviceString isEqualToString:@"iPad8,12"])     return @"iPadPro_12.9_4th";
    if ([deviceString isEqualToString:@"iPad11,1"])     return @"iPad_mini_5th";
    if ([deviceString isEqualToString:@"iPad11,2"])     return @"iPad_mini_5th";
    if ([deviceString isEqualToString:@"iPad11,3"])     return @"iPadAir_3rd";
    if ([deviceString isEqualToString:@"iPad11,4"])     return @"iPadAir_3rd";
    if ([deviceString isEqualToString:@"iPad11,6"])     return @"iPad_8th";
    if ([deviceString isEqualToString:@"iPad11,7"])     return @"iPad_8th";
    if ([deviceString isEqualToString:@"iPad13,1"])     return @"iPadAir_4th";
    if ([deviceString isEqualToString:@"iPad13,2"])     return @"iPadAir_4th";
    
    //iPod touch
    if ([deviceString isEqualToString:@"iPod1,1"])      return @"iPod_touch";
    if ([deviceString isEqualToString:@"iPod2,1"])      return @"iPod_touch_2nd";
    if ([deviceString isEqualToString:@"iPod3,1"])      return @"iPod_touch_3rd";
    if ([deviceString isEqualToString:@"iPod4,1"])      return @"iPod_touch_4th";
    if ([deviceString isEqualToString:@"iPod5,1"])      return @"iPod_touch_5th";
    if ([deviceString isEqualToString:@"iPod7,1"])      return @"iPod_touch_6th";
    if ([deviceString isEqualToString:@"iPod9,1"])      return @"iPod_touch_7th";
    
    //Apple Watch
    if ([deviceString isEqualToString:@"Watch1,1"])    return @"Apple_Watch_1st";
    if ([deviceString isEqualToString:@"Watch1,2"])    return @"Apple_Watch_1st";
    if ([deviceString isEqualToString:@"Watch2,6"])    return @"Apple_Watch_Series_1";
    if ([deviceString isEqualToString:@"Watch2,7"])    return @"Apple_Watch_Series_1";
    if ([deviceString isEqualToString:@"Watch2,3"])    return @"Apple_Watch_Series_2";
    if ([deviceString isEqualToString:@"Watch2,4"])    return @"Apple_Watch_Series_2";
    if ([deviceString isEqualToString:@"Watch3,1"])    return @"Apple_Watch_Series_3";
    if ([deviceString isEqualToString:@"Watch3,2"])    return @"Apple_Watch_Series_3";
    if ([deviceString isEqualToString:@"Watch3,3"])    return @"Apple_Watch_Series_3";
    if ([deviceString isEqualToString:@"Watch3,4"])    return @"Apple_Watch_Series_3";
    if ([deviceString isEqualToString:@"Watch4,1"])    return @"Apple_Watch_Series_4";
    if ([deviceString isEqualToString:@"Watch4,2"])    return @"Apple_Watch_Series_4";
    if ([deviceString isEqualToString:@"Watch4,3"])    return @"Apple_Watch_Series_4";
    if ([deviceString isEqualToString:@"Watch4,4"])    return @"Apple_Watch_Series_4";
    if ([deviceString isEqualToString:@"Watch5,1"])    return @"Apple_Watch_Series_5";
    if ([deviceString isEqualToString:@"Watch5,2"])    return @"Apple_Watch_Series_5";
    if ([deviceString isEqualToString:@"Watch5,3"])    return @"Apple_Watch_Series_5";
    if ([deviceString isEqualToString:@"Watch5,4"])    return @"Apple_Watch_Series_5";
    if ([deviceString isEqualToString:@"Watch5,9"])    return @"Apple_Watch_SE";
    if ([deviceString isEqualToString:@"Watch5,10"])   return @"Apple_Watch_SE";
    if ([deviceString isEqualToString:@"Watch5,11"])   return @"Apple_Watch_SE";
    if ([deviceString isEqualToString:@"Watch5,12"])   return @"Apple_Watch_SE";
    if ([deviceString isEqualToString:@"Watch6,1"])    return @"Apple_Watch_Series_6";
    if ([deviceString isEqualToString:@"Watch6,2"])    return @"Apple_Watch_Series_6";
    if ([deviceString isEqualToString:@"Watch6,3"])    return @"Apple_Watch_Series_6";
    if ([deviceString isEqualToString:@"Watch6,4"])    return @"Apple_Watch_Series_6";
    
    //Apple TV
    if ([deviceString isEqualToString:@"AppleTV1,1"])    return @"AppleTV_1st";
    if ([deviceString isEqualToString:@"AppleTV2,1"])    return @"AppleTV_2nd";
    if ([deviceString isEqualToString:@"AppleTV3,1"])    return @"AppleTV_3rd";
    if ([deviceString isEqualToString:@"AppleTV3,2"])    return @"AppleTV_3rd";
    if ([deviceString isEqualToString:@"AppleTV5,3"])    return @"AppleTV_HD";
    if ([deviceString isEqualToString:@"AppleTV6,2"])    return @"AppleTV_4K";
    
    //AirPods
    if ([deviceString isEqualToString:@"AirPods1,1"])    return @"AirPods_1st";
    if ([deviceString isEqualToString:@"AirPods2,1"])    return @"AirPods_2nd";
    if ([deviceString isEqualToString:@"iProd8,1"])      return @"AirPods_Pro";
    
    //HomePod
    if ([deviceString isEqualToString:@"AudioAccessory1,1"])    return @"HomePod";
    if ([deviceString isEqualToString:@"AudioAccessory1,2"])    return @"HomePod";
    if ([deviceString isEqualToString:@"AudioAccessory5,1"])    return @"HomePod_mini";
    
    return deviceString;
}




@end
