 
Pod::Spec.new do |s|
 

  s.name         = "UMengAnalyticsExt"
  s.version      = "1.0.2"
  s.summary      = "简化友盟更新提醒方法"

    s.author             = { "yangjunhai" => "junhaiyang@gmail.com" }
  s.homepage     = "https://github.com/xpemail/UMengAnalyticsExt"
 
  s.license      = "MIT"

  s.ios.deployment_target = "6.0" 
  
  s.source = { :git => 'https://github.com/xpemail/UMengAnalyticsExt.git' , :tag => '1.0.2'}
 
  s.requires_arc = true
   
  s.source_files = '*.{h,m,mm}' 

  s.dependency 'UMengAnalytics', "~> 3.5.10"

end
