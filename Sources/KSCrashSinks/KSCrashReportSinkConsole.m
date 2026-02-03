//
//  KSCrashReportSinkConsole.m
//
//  Created by Karl Stenerud on 2012-05-11.
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

// 导入控制台报告输出目标头文件，包含类接口声明
#import "KSCrashReportSinkConsole.h"
// 导入崩溃报告协议，定义报告接口
#import "KSCrashReport.h"
// 导入Apple格式过滤器，用于将报告转换为Apple格式
#import "KSCrashReportFilterAppleFmt.h"
// 导入基础过滤器，提供过滤器管道等功能
#import "KSCrashReportFilterBasic.h"

// #define KSLogger_LocalLevel TRACE
// 导入日志记录工具
#import "KSLogger.h"

// 实现KSCrashReportSinkConsole类
// 这是控制台报告输出目标，将崩溃报告打印到控制台（用于调试和测试）
@implementation KSCrashReportSinkConsole

// 返回默认的崩溃报告过滤器集合
// 包含Apple格式过滤器（将报告转换为Apple格式）和此Sink本身
- (id<KSCrashReportFilter>)defaultCrashReportFilterSet
{
    // 创建过滤器管道（Apple格式过滤器 -> 控制台Sink）
    return [[KSCrashReportFilterPipeline alloc] initWithFilters:@[
        // Apple格式过滤器（符号化样式，类似Xcode崩溃报告）
        [[KSCrashReportFilterAppleFmt alloc] initWithReportStyle:KSAppleReportStyleSymbolicated],
        // 控制台Sink（将报告打印到控制台）
        self,
    ]];
}

// 过滤并打印报告（实现KSCrashReportFilter协议）
// 将报告打印到控制台
// reports: 要打印的报告数组（应该是KSCrashReportString类型）
// onCompletion: 完成回调，在打印完成后调用，传入报告和错误信息
- (void)filterReports:(NSArray<id<KSCrashReport>> *)reports onCompletion:(KSCrashReportFilterCompletion)onCompletion
{
    // 初始化报告计数器
    int i = 0;
    // 遍历所有报告
    for (KSCrashReportString *report in reports) {
        // 检查报告类型是否为字符串类型
        if ([report isKindOfClass:[KSCrashReportString class]] == NO) {
            // 如果不是字符串类型，记录错误日志并跳过
            KSLOG_ERROR(@"Unexpected non-string report: %@", report);
            continue;
        }
        // 打印报告到控制台
        // 使用printf直接输出到标准输出（比NSLog更快，且不包含时间戳等额外信息）
        // 格式：Report 1: [报告内容]
        printf("Report %d:\n%s\n", ++i, report.value.UTF8String);
    }

    // 所有报告打印完成，调用完成回调，传入报告和nil错误（表示成功）
    kscrash_callCompletion(onCompletion, reports, nil);
}

@end
