//
//  KSCrashInstallationConsole.m
//  KSCrash-iOS
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

// 导入控制台安装类头文件，包含类接口声明
#import "KSCrashInstallationConsole.h"
// 导入安装类私有接口，包含私有方法和属性
#import "KSCrashInstallation+Private.h"
// 导入Apple格式过滤器，用于将报告转换为Apple格式
#import "KSCrashReportFilterAppleFmt.h"
// 导入基础过滤器，提供过滤器管道等功能
#import "KSCrashReportFilterBasic.h"
// 导入JSON过滤器，用于JSON编码
#import "KSCrashReportFilterJSON.h"
// 导入字符串化过滤器，用于将数据转换为字符串
#import "KSCrashReportFilterStringify.h"
// 导入控制台报告输出目标，用于将报告输出到控制台
#import "KSCrashReportSinkConsole.h"

// 实现KSCrashInstallationConsole类
// 这是控制台安装类，将崩溃报告输出到控制台（用于调试）
@implementation KSCrashInstallationConsole

// 返回共享的单例实例
// 使用单例模式确保整个应用程序只有一个控制台安装实例
+ (instancetype)sharedInstance
{
    // 声明静态变量存储共享实例
    static KSCrashInstallationConsole *sharedInstance = nil;
    // 声明静态变量用于dispatch_once，确保只初始化一次
    static dispatch_once_t onceToken;

    // 使用dispatch_once确保线程安全地只初始化一次
    dispatch_once(&onceToken, ^{
        // 创建并初始化共享实例
        sharedInstance = [[KSCrashInstallationConsole alloc] init];
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
        // 默认不打印Apple格式（使用JSON格式）
        _printAppleFormat = NO;
    }
    // 返回初始化后的实例
    return self;
}

// 获取Sink（报告输出目标）
// 返回报告过滤器对象（包含格式过滤器和控制台Sink的过滤器管道）
- (id<KSCrashReportFilter>)sink
{
    // 声明格式过滤器变量
    id<KSCrashReportFilter> formatFilter;
    // 检查是否使用Apple格式
    if (self.printAppleFormat) {
        // 使用Apple格式，创建Apple格式过滤器（符号化样式，类似Xcode崩溃报告）
        formatFilter = [[KSCrashReportFilterAppleFmt alloc] initWithReportStyle:KSAppleReportStyleSymbolicated];
    } else {
        // 不使用Apple格式，创建JSON格式过滤器管道
        formatFilter = [[KSCrashReportFilterPipeline alloc] initWithFilters:@[
            // JSON编码过滤器（美化输出并按键排序）
            [[KSCrashReportFilterJSONEncode alloc] initWithOptions:KSJSONEncodeOptionPretty | KSJSONEncodeOptionSorted],
            // 字符串化过滤器（将JSON数据转换为字符串）
            [KSCrashReportFilterStringify new],
        ]];
    }

    // 创建最终的过滤器管道（格式过滤器 -> 控制台Sink）
    // 报告先通过格式过滤器处理，然后输出到控制台
    return [[KSCrashReportFilterPipeline alloc] initWithFilters:@[ formatFilter, [KSCrashReportSinkConsole new] ]];
}

@end
