UMengAnalyticsExt
=================
  
 初始化
  
	 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
 	{
 
 
 	[[UMengAnalyticsManager sharedInstance] prepareUMSetting:UMENG_APPKEY appStoreId:@"com.sample.Test" checkConfig:NO];
 
    	.....
 
 	}
 
 
 
 调用
 
 	- (void)applicationDidBecomeActive:(UIApplication *)application
 	{
 
 	[[UMengAnalyticsManager sharedInstance] startCheckUpdate]; 
 
	 .....
 
 	}