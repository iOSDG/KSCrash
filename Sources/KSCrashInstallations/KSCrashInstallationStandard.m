//
//  KSCrashInstallationStandard.m
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

// 导入标准安装类头文件，包含类接口声明
#import "KSCrashInstallationStandard.h"
// 导入安装类私有接口，包含私有方法和属性
#import "KSCrashInstallation+Private.h"
// 导入基础过滤器，提供过滤器管道等功能
#import "KSCrashReportFilterBasic.h"
// 导入标准报告输出目标，用于通过HTTP发送报告
#import "KSCrashReportSinkStandard.h"
// 导入NSError辅助工具，用于创建和操作错误对象
#import "KSNSErrorHelper.h"

// 实现KSCrashInstallationStandard类
// 这是标准安装类，通过HTTP POST请求将崩溃报告发送到指定URL
@implementation KSCrashInstallationStandard

// 返回共享的单例实例
// 使用单例模式确保整个应用程序只有一个标准安装实例
+ (instancetype)sharedInstance
{
    // 声明静态变量存储共享实例
    static KSCrashInstallationStandard *sharedInstance = nil;
    // 声明静态变量用于dispatch_once，确保只初始化一次
    static dispatch_once_t onceToken;

    // 使用dispatch_once确保线程安全地只初始化一次
    dispatch_once(&onceToken, ^{
        // 创建并初始化共享实例
        sharedInstance = [[KSCrashInstallationStandard alloc] init];
    });
    // 返回共享实例
    return sharedInstance;
}

// 验证安装配置
// error: 错误输出参数（如果验证失败，会设置此参数）
// 返回YES表示验证通过，NO表示验证失败
- (BOOL)validateSetupWithError:(NSError *__autoreleasing _Nullable *)error
{
    // 先调用父类的验证方法（检查基类的配置）
    if ([super validateSetupWithError:error] == NO) {
        // 父类验证失败，直接返回NO
        return NO;
    }

    // 检查URL是否已设置（标准安装需要URL来发送报告）
    if (self.url == nil) {
        // URL为nil，检查错误参数是否不为NULL
        if (error != NULL) {
            // 错误参数不为NULL，创建错误对象并设置
            *error = [KSNSErrorHelper errorWithDomain:[[self class] description] code:0 description:@"No URL provided"];
        }
        // URL为nil，验证失败，返回NO
        return NO;
    }

    // 所有验证通过，返回YES
    return YES;
}

// 获取Sink（报告输出目标）
// 返回报告过滤器对象（包含标准Sink的过滤器管道）
- (id<KSCrashReportFilter>)sink
{
    // 创建标准报告输出目标（使用配置的URL）
    KSCrashReportSinkStandard *sink = [[KSCrashReportSinkStandard alloc] initWithURL:self.url];
    // 创建过滤器管道（包含Sink的默认过滤器集合）
    // defaultCrashReportFilterSet: Sink的默认过滤器集合（可能包含JSON编码等过滤器）
    return [[KSCrashReportFilterPipeline alloc] initWithFilters:@[ sink.defaultCrashReportFilterSet ]];
}

@end
