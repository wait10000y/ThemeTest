说明


json 格式定义.
1. 支持多层嵌套取值,取值方式为 keypath多层嵌套定义.(数组不支持keypath.)
2. model对象 支持原值,UIColor,UIFont,UIImage,Attributes类型取值. (attributes定义key 参考 NSAttributedString.h)
3. 方法说明里分别指出 对象类型支持转换的格式. 用户可以取原值,自定义转换其他类型.

格式定义：
1. color支持形式(返回UIColor格式)：
支持 0x,#或者直接写的三种格式十六进制的字符串. [0xffddffdd,#ffddffdd,ffddffdd], 八位时格式ARGB.六位时RGB.
支持 NSNumber 类型, 该类型没有alpha项. 示例："0x00ff00" ， "#66DD2134" ， "2233FF"

2. font支持形式(返回UIFont格式)：
NSNumber,NSSting:只有数字时，转成默认字体指定字号大小值;
字符串":"分割格式时 "fontName:20":指定字体名称和字号大小,:分隔符; 示例:22 , 

3. image支持形式(返回UIImage格式):
支持的文件名类型: 支持bundle查找名称加载,本地路径加载(主题对应的resource资源目录中). 示例: "imgName" "imgName.jpg"

4.attribute支持形式（返回dict格式）：
支持 NSAttributedString.h 定义的 attributeName字符串转换的key.
对应的value值font,color类型自动转换,number,string使用原值,其他的属性暂不支持.

5. json,或字符串 支持形式:
// 内容 转换成 json格式的字符串.无法转换时,自动调用 description属性返回内容.

6. orginal 格式: 返回jsonDict的原始值.



{
"defalut":{
"示例key":"示例value,支持keypath多层嵌套定义.编辑部分支持两层嵌套编辑."
},

"navBarDefine":{
"title":"我是标题" 
"tinColor":"0x00ff00",
"barTinColor":"#66DD2134",
"barTitleAttrs":{
"NSForegroundColorAttributeName":"2233FF",
"NSFontAttributeName":22,
"NSUnderlineStyleAttributeName":2
}
},

"normalImageView":{
"background":"#EECCCC",
"defaultImage":"default.jpg",
"orginImage":"https://www.baidu.com/img/bd_logo.png",
}


"_info": {
"name": "默认主题(唯一)",
"desc": "主题描述",
"author": "作者",
"date":"2018.06"
}
}

**/

/**
使用说明:
支持 KVO属性监听,delegate委托模式,block注册(WSThemeUpdateNotificaiton通知模式)三种形式更新主题.

一. delegate委托模式:
1. 需要随theme主题切换而更新的对象,实现协议:<WSThemeChangeDelegate> , 并登记对象(登记的对象是弱引用,不改变delegate对象的生命周期,delegate被垃圾回收时,自动被删除引用的):
[[WSTheme sharedObject] addDelegate:self];

2. delegate<WSThemeChangeDelegate>委托对象实现下面的方法,主题切换时会被调用.调用线程为主线程.
// delegate回调方法.
-(void)wsThemeHasChanged:(NSString *)themeName themeModel:(WSThemeModel *)themeModel {
NSLog(@"==== delegate模式 主题切换:%@ ====",themeName);
if ([themeName isEqualToString:[WSTheme sharedObject].currentThemeName]) {
//TODO: 其他实现.
// 自定义 读取主题的设置.
[themeModel getDataWithIdentifier:@"statusBarStyple" backType:WSThemeValueTypeOriginal complete:^(NSNumber *style) {
[UIApplication sharedApplication].statusBarStyle = style.intValue; // 设定 状态条 颜色
}];
}
}

3. delegate<WSThemeChangeDelegate> 中途取消委托,可以调用下面方法,如果该delegate对象丢弃不用,可以不调用下面取消方法,该对象会自动被移除引用.
-(void)removeDelegate:(id<WSThemeChangeDelegate>)theDelegate;

二. KVO属性监听形式:
监听 WSTheme的 currentThemeName 属性.
1.当前对象添加监听:
[[WSTheme sharedObject] addObserver:self forKeyPath:@"currentThemeName" options:NSKeyValueObservingOptionNew context:nil];

2. 实现监听回调方法(调用线程为主线程):
//KVO 监听属性.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
NSLog(@"监听到属性变化:obj:%@ , keyPath:%@ , change.new:%@ , context:%@", object, keyPath, change[@"new"], context);
if(![@"currentThemeName" isEqualToString:keyPath]){
[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
return;
}

// object: WSTheme对象 change: {kind = 1,new = "theme2",old = "theme1"}
NSString *themeName = [change objectForKey:@"new"];
if (themeName && [themeName isEqualToString:[WSTheme sharedObject].currentThemeName]) {
// TODO: 其他实现.
// 自定义 读取主题的设置.
WSThemeModel *cModel = [WSTheme sharedObject].currentThemeModel;
[cModel getDataWithIdentifier:@"statusBarStyple" backType:WSThemeValueTypeOriginal complete:^(NSNumber *style) {
[UIApplication sharedApplication].statusBarStyle = style.intValue; // 设定 状态条 颜色
}];
}
}


三. block注册形式(WSThemeUpdateNotificaiton 通知模式):

主题切换时,会发送 WSThemeUpdateNotificaiton 通知, 也可以自定义接收该通知;

类对象:
WSThemeModel,WSTheme,WSThemeConfig,NSObject(WSTheme);

WSThemeConfig 是 NSObject(WSTheme) 调用扩展方法后返回绑定的对象.和NSObject 对象一一对应,生命周期与NSObject一致,随NSObject一起垃圾回收.
WSThemeConfig 可以注册各种theme更新的block. 书写方式类似jquery形式的调用接口方法.

self.view.wsTheme.color(@"normal_backgroundColor", ^(UILabel *item, UIColor *value) {
item.backgroundColor = value;
}).font(@"normal_textFont", ^(UILabel *item, UIFont *value) {
item.textFont = value;
});

WSTheme 主题的主入口文件,维持各主题的生命周期.切换主题后,会发送切换通知到各 WSThemeConfig对象维持注册对象的更新回调;
// 所有主题
-(NSArray<NSString *> *)themeNameList;
-(NSString *)currentThemeName;

// 切换新主题.
-(BOOL)startTheme:(NSString *)theName;

// 同名称的主题会被新主题覆盖更新;不同名称的主题执行添加主题更新. override
-(BOOL)addThemeJsonDictList:(NSArray<NSDictionary *> *)dictList withNameList:(NSArray<NSString *> *)nameList;
-(BOOL)removeThemes:(NSArray<NSString *> *)nameList;



WSThemeModel 切换主题后,由当前主题创建;
-(id)getDataWithIdentifier:(NSString *)identifier backType:(WSThemeValueType)type 获取value值;




void(^WSThemeConfigValueBlock)(id item , id value)
传回值 item是注册的对象,弱引用不会影响item原对象生命周期;
value 是传回调用时当前主题jsonDict定义的 identifier对应的value值.value值受WSThemeValueType约束.


示例代码:
AppDelegate.m 中设置初始主题,或者添加默认主题:

// 添加其他主题.
NSMutableArray *themeJsonList = [NSMutableArray new];
NSMutableArray *themeNameList = [NSMutableArray new];
// 逐个添加主题jsonDict内容和对应themeName值.
[[WSTheme sharedObject] addThemeJsonDictList:themeJsonList withNameList:themeNameList];

// 指定加载默认主题.
NSString *lastName = [WSTheme sharedObject].currentThemeName?:WSThemeDefaultThemeName;
[[WSTheme sharedObject] startTheme:lastName];


viewController.m 使用:
__weak typeof(self) weakSelf = self;
// 跟随主题切换更新一次.不需要返回的内容
self.btnNext.wsTheme.custom(nil, 0, ^(UIButton *item, id value) {
NSString *title = [WSTheme sharedObject].currentThemeName;
WSThemeModel *cModel = [WSTheme sharedObject].currentThemeModel;
[cModel getDataWithIdentifier:@"statusBarStyple" backType:WSThemeValueTypeOriginal complete:^(NSNumber *style) {
[UIApplication sharedApplication].statusBarStyle = style.intValue;
}];
});


self.textLabel.wsTheme.custom(@"textView.textFont", WSThemeValueTypeFont, ^(UILabel *item, UIFont *value) {
item.font = value;
}).color(@"textView.textColor", ^(UILabel *item, UIColor *value) {
item.textColor = value;
item.text = [NSString stringWithFormat:@"主题:%@,颜色:%@",[WSTheme sharedObject].currentThemeName?:@"没有主题",value?:@"默认颜色"];
});

// 支持的所有调用方法：
tempObj.custom(^);

tempObj.original(^);
tempObj.text(^);
tempObj.color(^);
tempObj.font(^);
tempObj.image(^);
tempObj.data(^);
tempObj.attribute(^);


注意:
1. 注册回调的block中,使用弱引用来引用其他对象操作,防止循环引用(或间接循环引用)注册回调的对象,造成资源无法释放.
2. 用户界面block回调已切换到主线程调用 ([NSOperationQueue mainQueue] 线程).




