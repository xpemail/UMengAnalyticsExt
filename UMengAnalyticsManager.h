// 
//

#import <Foundation/Foundation.h>



@interface UMengAnalyticsManager : NSObject


+ (UMengAnalyticsManager *)sharedInstance;
/**
 checkConfig   YES/NO  检测在线设置数据 {"fource_version":"1.0.1"}，强制升级
 

 
 */
-(void)prepareUMSetting:(NSString *)umeng_appkey  appStoreId:(NSString *)app_store_id   checkConfig:(BOOL)checkConfig;

-(void)startCheckUpdate;

@end
