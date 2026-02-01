//
//  KSCrashInstallationEmail.m
//
//  Created by Karl Stenerud on 2013-03-02.
//
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

// 导入邮件安装类头文件，包含类接口声明
#import "KSCrashInstallationEmail.h"
// 导入安装类私有接口，包含私有方法和属性
#import "KSCrashInstallation+Private.h"
// 导入警报过滤器，用于显示用户确认对话框
#import "KSCrashReportFilterAlert.h"
// 导入邮件报告输出目标，用于通过邮件发送报告
#import "KSCrashReportSinkEMail.h"
// 导入NSError辅助工具，用于创建和操作错误对象
#import "KSNSErrorHelper.h"

// 定义KSCrashInstallationEmail类的私有扩展
@interface KSCrashInstallationEmail ()

// 默认文件名格式字典（键为报告样式枚举值，值为文件名格式字符串）
@property(nonatomic, readwrite, copy) NSDictionary *defaultFilenameFormats;

@end

// 实现KSCrashInstallationEmail类
// 这是邮件安装类，通过邮件将崩溃报告发送给指定收件人
@implementation KSCrashInstallationEmail

// 返回共享的单例实例
// 使用单例模式确保整个应用程序只有一个邮件安装实例
+ (instancetype)sharedInstance
{
    // 声明静态变量存储共享实例
    static KSCrashInstallationEmail *sharedInstance = nil;
    // 声明静态变量用于dispatch_once，确保只初始化一次
    static dispatch_once_t onceToken;

    // 使用dispatch_once确保线程安全地只初始化一次
    dispatch_once(&onceToken, ^{
        // 创建并初始化共享实例
        sharedInstance = [[KSCrashInstallationEmail alloc] init];
    });
    // 返回共享实例
    return sharedInstance;
}

// 初始化方法
// 返回初始化后的实例
- (instancetype)init
{
    // 调用父类初始化方法
    if ((self = [super init])) {
        // 获取应用包名称（从Info.plist中获取）
        NSString *bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
        // 设置默认邮件主题（包含应用名称）
        _subject = [NSString stringWithFormat:@"Crash Report (%@)", bundleName];
        // 创建默认文件名格式字典
        // 键为报告样式枚举值，值为文件名格式字符串（使用%%d作为报告编号占位符）
        _defaultFilenameFormats = [NSDictionary
            dictionaryWithObjectsAndKeys:
            // Apple格式的文件名格式（.txt.gz扩展名）
            [NSString stringWithFormat:@"crash-report-%@-%%d.txt.gz", bundleName],
            [NSNumber numberWithInt:KSCrashEmailReportStyleApple],
            // JSON格式的文件名格式（.json.gz扩展名）
            [NSString stringWithFormat:@"crash-report-%@-%%d.json.gz", bundleName],
            [NSNumber numberWithInt:KSCrashEmailReportStyleJSON], nil];
        // 设置报告样式为JSON，并使用默认文件名格式
        [self setReportStyle:KSCrashEmailReportStyleJSON useDefaultFilenameFormat:YES];
    }
    // 返回初始化后的实例
    return self;
}

// 验证安装配置
// error: 错误输出参数（如果验证失败，会设置此参数）
// 返回YES表示验证通过，NO表示验证失败
- (BOOL)validateSetupWithError:(NSError **)error
{
    // 先调用父类的验证方法（检查基类的配置）
    if ([super validateSetupWithError:error] == NO) {
        // 父类验证失败，直接返回NO
        return NO;
    }

    // 检查收件人数组是否为空（邮件安装需要至少一个收件人）
    if (self.recipients.count == 0) {
        // 收件人数组为空，检查错误参数是否不为NULL
        if (error != NULL) {
            // 错误参数不为NULL，创建错误对象并设置
            *error = [KSNSErrorHelper errorWithDomain:[[self class] description]
                                                 code:0
                                          description:@"Empty recepients array"];
        }
        // 收件人数组为空，验证失败，返回NO
        return NO;
    }

    // 检查邮件主题是否为空（邮件安装需要主题）
    if (self.subject.length == 0) {
        // 邮件主题为空，检查错误参数是否不为NULL
        if (error != NULL) {
            // 错误参数不为NULL，创建错误对象并设置
            *error = [KSNSErrorHelper errorWithDomain:[[self class] description]
                                                 code:0
                                          description:@"No email subject provided"];
        }
        // 邮件主题为空，验证失败，返回NO
        return NO;
    }

    // 检查文件名格式是否为空（邮件安装需要文件名格式）
    if (self.filenameFmt.length == 0) {
        // 文件名格式为空，检查错误参数是否不为NULL
        if (error != NULL) {
            // 错误参数不为NULL，创建错误对象并设置
            *error = [KSNSErrorHelper errorWithDomain:[[self class] description]
                                                 code:0
                                          description:@"No filename format provided"];
        }
        // 文件名格式为空，验证失败，返回NO
        return NO;
    }

    // 所有验证通过，返回YES
    return YES;
}

// 设置报告样式和文件名格式
// reportStyle: 报告样式（Apple格式或JSON格式）
// useDefaultFilenameFormat: 是否使用默认文件名格式（如果为YES，会根据报告样式自动设置文件名格式）
- (void)setReportStyle:(KSCrashEmailReportStyle)reportStyle useDefaultFilenameFormat:(BOOL)useDefaultFilenameFormat
{
    // 设置报告样式属性
    self.reportStyle = reportStyle;

    // 检查是否使用默认文件名格式
    if (useDefaultFilenameFormat) {
        // 使用默认文件名格式，从默认文件名格式字典中获取对应样式的文件名格式
        self.filenameFmt = [self.defaultFilenameFormats objectForKey:[NSNumber numberWithInt:(int)reportStyle]];
    }
}

// 获取Sink（报告输出目标）
// 返回报告过滤器对象（根据报告样式返回不同的过滤器集合）
- (id<KSCrashReportFilter>)sink
{
    // 创建邮件报告输出目标（使用配置的收件人、主题、消息和文件名格式）
    KSCrashReportSinkEMail *sink = [[KSCrashReportSinkEMail alloc] initWithRecipients:self.recipients
                                                                              subject:self.subject
                                                                              message:self.message
                                                                          filenameFmt:self.filenameFmt];

    // 根据报告样式返回不同的过滤器集合
    switch (self.reportStyle) {
        case KSCrashEmailReportStyleApple:
            // Apple格式，返回Apple格式的默认过滤器集合（包含Apple格式转换过滤器）
            return [sink defaultCrashReportFilterSetAppleFmt];
        case KSCrashEmailReportStyleJSON:
            // JSON格式，返回JSON格式的默认过滤器集合（包含JSON编码等过滤器）
            return [sink defaultCrashReportFilterSet];
        default:
            // 未知的报告样式，返回nil
            return nil;
    }
}

@end
