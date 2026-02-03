//
//  KSCrashReportFilterStringify.m
//  KSCrash
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

// 导入字符串化过滤器头文件
#import "KSCrashReportFilterStringify.h"
// 导入崩溃报告协议
#import "KSCrashReport.h"

// #define KSLogger_LocalLevel TRACE
// 导入日志工具
#import "KSLogger.h"

// 字符串化过滤器实现
@implementation KSCrashReportFilterStringify

// 将报告对象转换为字符串
// @param report 待转换的报告对象
// @return 转换后的字符串
- (NSString *)stringifyReport:(id<KSCrashReport>)report
{
    // 如果报告已经是字符串类型，直接返回其值
    if ([report isKindOfClass:[KSCrashReportString class]]) {
        return ((KSCrashReportString *)report).value;
    }
    // 如果报告是数据类型，将其解码为UTF-8字符串
    if ([report isKindOfClass:[KSCrashReportData class]]) {
        // 获取数据值
        NSData *value = ((KSCrashReportData *)report).value;
        // 使用UTF-8编码将数据转换为字符串
        return [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
    }
    // 如果报告是字典类型，尝试转换为JSON字符串
    if ([report isKindOfClass:[KSCrashReportDictionary class]]) {
        // 获取字典值
        NSDictionary *value = ((KSCrashReportDictionary *)report).value;
        // 检查字典是否为有效的JSON对象
        if ([NSJSONSerialization isValidJSONObject:value]) {
            // 将字典序列化为JSON数据（无格式化选项）
            NSData *data = [NSJSONSerialization dataWithJSONObject:value options:0 error:nil];
            // 将JSON数据转换为UTF-8字符串
            return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        // 如果不是有效的JSON对象，使用格式化字符串转换
        return [NSString stringWithFormat:@"%@", value];
    }
    // 其他类型，使用描述方法，如果描述为空则返回"Unknown"
    return [report description] ?: @"Unknown";
}

// 过滤报告：将各种类型的报告转换为字符串格式
// @param reports 待过滤的报告数组
// @param onCompletion 完成回调，返回字符串格式的报告数组
- (void)filterReports:(NSArray<id<KSCrashReport>> *)reports onCompletion:(KSCrashReportFilterCompletion)onCompletion
{
    // 创建可变数组，容量与输入报告数量相同
    NSMutableArray<id<KSCrashReport>> *filteredReports = [NSMutableArray arrayWithCapacity:[reports count]];
    // 遍历每个报告
    for (id<KSCrashReport> report in reports) {
        // 将报告转换为字符串
        NSString *reportString = [self stringifyReport:report];
        // 将字符串包装为KSCrashReportString对象并添加到结果数组
        [filteredReports addObject:[KSCrashReportString reportWithValue:reportString]];
    }

    // 所有报告处理完成，调用完成回调，传递过滤后的报告数组（无错误）
    kscrash_callCompletion(onCompletion, filteredReports, nil);
}

@end
