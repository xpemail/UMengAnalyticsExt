// 
//

#import "UMengAnalyticsManager.h"
#import "MobClick.h"

#define DEFAULT_APPSTORE_CHANNELID @"App Store"

#define DEFAULT_TEST_CHANNELID @"TEST"

@interface NSString (Version)
-(BOOL) isOlderVersionThan:(NSString*)otherVersion;
-(BOOL) isNewerVersionThan:(NSString*)otherVersion;

@end

@implementation NSString (Version)

-(BOOL) isOlderVersionThan:(NSString*)otherVersion
{
    return ([self compare:otherVersion options:NSNumericSearch] == NSOrderedAscending);
}
-(BOOL) isNewerVersionThan:(NSString*)otherVersion
{
    return ([self compare:otherVersion options:NSNumericSearch] == NSOrderedDescending);
}
@end

@interface UMengAnalyticsManager()

@property (nonatomic,assign) BOOL checkConfig;

@property (nonatomic,strong) NSString *CHANNEL_ID;

@property (nonatomic,strong) NSString *appStoreId;

@property (nonatomic,strong) NSString *umengKey;

@property (strong) NSString *updatePath;
@property (assign) BOOL igronUpdate;
@property (assign) BOOL updateAlert; 

@end

@implementation UMengAnalyticsManager

@synthesize checkConfig;
@synthesize igronUpdate,updateAlert,updatePath;
@synthesize appStoreId,umengKey;

static NSObject *lock;
+ (UMengAnalyticsManager *)sharedInstance
{
    static UMengAnalyticsManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[UMengAnalyticsManager alloc] init];
        lock =[[NSObject alloc] init];
    });
    
    return sharedInstance;
}


-(void)prepareUMSetting:(NSString *)umeng_appkey  appStoreId:(NSString *)app_store_id   checkConfig:(BOOL)_checkConfig;{
    checkConfig =_checkConfig;
    umengKey =umeng_appkey;
    appStoreId=app_store_id;
    
    NSString *bundleIdentifier =[[[NSBundle mainBundle]infoDictionary]objectForKey:@"CFBundleIdentifier"];
    if([bundleIdentifier isEqualToString:self.appStoreId]){
        self.CHANNEL_ID = nil;
    }else{
        self.CHANNEL_ID = DEFAULT_TEST_CHANNELID;
    }
    
    
    //友盟异常统计
#if  DEBUG
    [MobClick setLogEnabled:YES];
#else
    [MobClick setLogEnabled:NO];
#endif
    [MobClick startWithAppkey:umengKey reportPolicy:REALTIME channelId:self.CHANNEL_ID];
    
    if(checkConfig){
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configLoading:) name:UMOnlineConfigDidFinishedNotification object:nil];
    }
    
    
}

-(void)startCheckUpdate{
    
    if(!updateAlert){
        if(checkConfig){
            [self performSelectorOnMainThread:@selector(checkConfigInMainThread) withObject:nil waitUntilDone:NO];
        }else{
            [self performSelectorOnMainThread:@selector(checkUpdateInMainThread) withObject:nil waitUntilDone:NO];
        }
    }
}

-(void)checkConfigInMainThread{
    @try {
        [MobClick updateOnlineConfig];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[[exception callStackSymbols] componentsJoinedByString:@"\n"]);
    }
}

-(void)checkUpdateInMainThread{
    @try {
        [MobClick checkUpdateWithDelegate:self selector:@selector(callBackUpdate:)];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[[exception callStackSymbols] componentsJoinedByString:@"\n"]);
    }
    //{"fource_version":"2.0"}
}

-(void)configLoading:(NSNotification *)note{
    [self performSelectorOnMainThread:@selector(checkUpdateInMainThread) withObject:nil waitUntilDone:NO];
}

-(NSDictionary *)loadConfig{
    
    if(checkConfig){
        
        NSString *channelID =self.CHANNEL_ID;
        if(!channelID)
            channelID = DEFAULT_APPSTORE_CHANNELID;
        
        
        NSString *configString = [MobClick getConfigParams:channelID];
        
        NSData *data =[configString dataUsingEncoding:NSUTF8StringEncoding];
        
        if(data==nil)
            return nil;
        NSError *jsonError = nil;
        id _result= [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        if(jsonError != nil){
            NSLog(@"%@",jsonError);
        }
        
        return _result;
    }else{
        return nil;
    }
}


-(void)callBackUpdate:(NSDictionary *)dic{
    
    NSDictionary *configDic =[self loadConfig];
    
    NSString *fource_version = [configDic objectForKey:@"fource_version"];
    
    NSString *version = [dic objectForKey:@"version"];
    
    NSString *current_version = [dic objectForKey:@"current_version"];
    
    updatePath = [dic objectForKey:@"path"];
    
    
    //是否有更新
    if([version isNewerVersionThan:current_version]){
        
        NSString *update_log=[dic objectForKey:@"update_log"];
        
        //强制更新版本与新版本号一致，强制更新
        if(fource_version!=nil&&[fource_version isEqualToString:version]){
            
            if(!updateAlert){
                
                updateAlert = YES;
#if  DEBUG
                if(self.CHANNEL_ID==nil){
                    NSMutableString *versionString =[[NSMutableString alloc] init];
                    
                    [versionString appendFormat:@"强制更新代码 v%@",version];
                    
                    UIAlertView *alertView=[[UIAlertView alloc] initWithTitle:versionString message:@"开发人员请更新代码到最新版本" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                    alertView.tag = 10000;
                    
                    [alertView show];
                }else{
                    NSMutableString *versionString =[[NSMutableString alloc] init];
                    
                    [versionString appendFormat:@"需要您更新版本 v%@",version];
                    
                    UIAlertView *alertView=[[UIAlertView alloc] initWithTitle:versionString message:update_log delegate:self cancelButtonTitle:nil otherButtonTitles:@"点击更新", nil];
                    alertView.tag = 10000;
                    
                    [alertView show];
                }
#else
                NSMutableString *versionString =[[NSMutableString alloc] init];
                
                [versionString appendFormat:@"需要您更新版本 v%@",version];
                
                UIAlertView *alertView=[[UIAlertView alloc] initWithTitle:versionString message:update_log delegate:self cancelButtonTitle:nil otherButtonTitles:@"点击更新", nil];
                alertView.tag = 10000;
                
                [alertView show];
#endif
                
                
            }
        
        }else{
            
            if(!updateAlert&&!igronUpdate){
                
                updateAlert = YES;
                
                NSMutableString *versionString =[[NSMutableString alloc] init];
                
                [versionString appendFormat:@"发现新版本 v%@",version];
                
                
                UIAlertView *alertView=[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"发现新版本 v%@",version] message:update_log delegate:self cancelButtonTitle:@"忽略" otherButtonTitles:@"更新", nil];
                alertView.tag = 20000;
                
                [alertView show];
                
            }
        
        }
    }
    
}



-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if(alertView.tag==10000){
        
        //直接开始安装：itms-services://
        //网站地址： http://
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:updatePath]];
        
        updatePath =nil;
        exit(0);
        
        return;
    }else{
        if(buttonIndex==0){
            //忽略版本更新，下次启动应用时再提示
            igronUpdate=YES;
        }else{
            //直接开始安装：itms-services://
            //网站地址： http://
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:updatePath]];
            if([updatePath hasPrefix:@"itms-services://"]){
                updatePath =nil;
                exit(0);
            }else{
                igronUpdate =NO;
                updatePath =nil;
            }
        }
    }
    
    updateAlert = NO;
}




@end
