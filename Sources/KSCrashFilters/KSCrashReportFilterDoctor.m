//
//  KSCrashReportFilterDoctor.m
//
//  Created by Karl Stenerud on 2024-09-05.
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

// 导入崩溃诊断过滤器头文件
#import "KSCrashReportFilterDoctor.h"
// 导入崩溃诊断器类
#import "KSCrashDoctor.h"
// 导入崩溃报告协议
#import "KSCrashReport.h"
// 导入崩溃报告字段常量
#import "KSCrashReportFields.h"

// #define KSLogger_LocalLevel TRACE
// 导入日志工具
#import "KSLogger.h"

// 崩溃诊断过滤器的私有接口扩展
@interface KSCrashReportFilterDoctor ()

@end

// 崩溃诊断过滤器实现
@implementation KSCrashReportFilterDoctor

// 类方法：诊断崩溃报告
// @param crashReport 崩溃报告字典
// @return 诊断结果字符串，如果无法诊断则返回nil
+ (NSString *)diagnoseCrash:(NSDictionary *)crashReport
{
    // 创建新的崩溃诊断器实例并调用诊断方法
    return [[KSCrashDoctor new] diagnoseCrash:crashReport];
}

// 过滤报告：为崩溃报告添加诊断信息
// @param reports 待过滤的报告数组（期望为字典格式）
// @param onCompletion 完成回调，返回添加诊断后的报告数组
- (void)filterReports:(NSArray<id<KSCrashReport>> *)reports onCompletion:(KSCrashReportFilterCompletion)onCompletion
{
    // 创建可变数组，容量与输入报告数量相同
    NSMutableArray<id<KSCrashReport>> *filteredReports = [NSMutableArray arrayWithCapacity:[reports count]];
    // 遍历每个报告
    for (KSCrashReportDictionary *report in reports) {
        // 检查报告是否为字典类型
        if ([report isKindOfClass:[KSCrashReportDictionary class]] == NO) {
            // 如果不是字典类型，记录错误日志
            KSLOG_ERROR(@"Unexpected non-dictionary report: %@", report);
            // 跳过此报告，继续处理下一个
            continue;
        }

        // 调用类方法诊断崩溃报告，获取诊断结果
        NSString *diagnose = [[self class] diagnoseCrash:report.value];
        // 创建崩溃报告的可变副本，以便添加诊断信息
        NSMutableDictionary *crashReport = [report.value mutableCopy];
        // 如果诊断结果不为空，则添加到报告中
        if (diagnose != nil) {
            // 检查是否存在崩溃信息字段
            if (crashReport[KSCrashField_Crash] != nil) {
                // 创建崩溃字典的可变副本
                NSMutableDictionary *crashDict = [crashReport[KSCrashField_Crash] mutableCopy];
                // 将诊断结果添加到崩溃字典中
                crashDict[KSCrashField_Diagnosis] = diagnose;
                // 将更新后的崩溃字典放回崩溃报告
                crashReport[KSCrashField_Crash] = crashDict;
            }
            // 检查是否存在重崩溃报告字段（处理崩溃处理过程中再次崩溃的情况）
            if (crashReport[KSCrashField_RecrashReport][KSCrashField_Crash] != nil) {
                // 创建重崩溃报告的可变副本
                NSMutableDictionary *recrashReport = [crashReport[KSCrashField_RecrashReport] mutableCopy];
                // 创建重崩溃报告的崩溃字典的可变副本
                NSMutableDictionary *crashDict = [recrashReport[KSCrashField_Crash] mutableCopy];
                // 将诊断结果添加到重崩溃报告的崩溃字典中
                crashDict[KSCrashField_Diagnosis] = diagnose;
                // 将更新后的崩溃字典放回重崩溃报告
                recrashReport[KSCrashField_Crash] = crashDict;
                // 将更新后的重崩溃报告放回崩溃报告
                crashReport[KSCrashField_RecrashReport] = recrashReport;
            }
        }

        // 将更新后的崩溃报告包装为KSCrashReportDictionary对象并添加到结果数组
        [filteredReports addObject:[KSCrashReportDictionary reportWithValue:crashReport]];
    }

    // 所有报告处理完成，调用完成回调，传递过滤后的报告数组（无错误）
    kscrash_callCompletion(onCompletion, filteredReports, nil);
}

@end
