//
//  KSCrashReportFilterDemangle.m
//
//  Created by Nikolay Volosatov on 2024-08-16.
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

// 导入反混淆过滤器头文件
#import "KSCrashReportFilterDemangle.h"

// 导入崩溃报告协议
#import "KSCrashReport.h"
// 导入崩溃报告字段常量
#import "KSCrashReportFields.h"
// 导入C++符号反混淆头文件
#import "KSDemangle_CPP.h"
// 导入系统能力检测头文件
#import "KSSystemCapabilities.h"
#if KSCRASH_HAS_SWIFT
// 导入Swift符号反混淆头文件（仅在支持Swift时导入）
#import "KSDemangle_Swift.h"
#endif

// #define KSLogger_LocalLevel TRACE
// 导入日志工具
#import "KSLogger.h"

// 反混淆过滤器的私有接口扩展
@interface KSCrashReportFilterDemangle ()

@end

// 反混淆过滤器实现
@implementation KSCrashReportFilterDemangle

// 类方法：反混淆C++符号
// @param symbol 混淆的C++符号字符串
// @return 反混淆后的符号字符串，如果反混淆失败则返回nil
+ (NSString *)demangledCppSymbol:(NSString *)symbol
{
    // 调用C++反混淆函数，传入UTF-8编码的符号字符串
    char *demangled = ksdm_demangleCPP(symbol.UTF8String);
    // 如果反混淆成功（返回非NULL）
    if (demangled != NULL) {
        // 使用initWithBytesNoCopy创建NSString，自动管理内存（freeWhenDone:YES）
        NSString *result = [[NSString alloc] initWithBytesNoCopy:demangled
                                                          length:strlen(demangled)
                                                        encoding:NSUTF8StringEncoding
                                                    freeWhenDone:YES];
        // 记录调试日志：显示反混淆前后的符号
        KSLOG_DEBUG(@"Demangled a C++ symbol '%@' -> '%@'", symbol, result);
        // 返回反混淆后的字符串
        return result;
    }
    // 反混淆失败，返回nil
    return nil;
}

// 类方法：反混淆Swift符号
// @param symbol 混淆的Swift符号字符串
// @return 反混淆后的符号字符串，如果反混淆失败或系统不支持Swift则返回nil
+ (NSString *)demangledSwiftSymbol:(NSString *)symbol
{
#if KSCRASH_HAS_SWIFT
    // 调用Swift反混淆函数，传入UTF-8编码的符号字符串
    char *demangled = ksdm_demangleSwift(symbol.UTF8String);
    // 如果反混淆成功（返回非NULL）
    if (demangled != NULL) {
        // 使用initWithBytesNoCopy创建NSString，自动管理内存（freeWhenDone:YES）
        NSString *result = [[NSString alloc] initWithBytesNoCopy:demangled
                                                          length:strlen(demangled)
                                                        encoding:NSUTF8StringEncoding
                                                    freeWhenDone:YES];
        // 记录调试日志：显示反混淆前后的符号
        KSLOG_DEBUG(@"Demangled a Swift symbol '%@' -> '%@'", symbol, result);
        // 返回反混淆后的字符串
        return result;
    }
#endif
    // 反混淆失败或系统不支持Swift，返回nil
    return nil;
}

// 类方法：反混淆符号（自动尝试C++和Swift）
// @param symbol 混淆的符号字符串
// @return 反混淆后的符号字符串，如果反混淆失败则返回nil
+ (NSString *)demangledSymbol:(NSString *)symbol
{
    // 先尝试C++反混淆，如果失败则尝试Swift反混淆
    return [self demangledCppSymbol:symbol] ?: [self demangledSwiftSymbol:symbol];
}

/** Recurcively demangles strings within the report.
 * @param reportObj An object within the report (dictionary, array, string etc)
 * @param path An array of strings representing keys in dictionaries. An empty key means an itteration within the array.
 * @param depth Current depth of the path
 * @return An updated object or `nil` if no changes were applied.
 */
// 递归反混淆报告中的字符串
// @param reportObj 报告中的对象（字典、数组、字符串等）
// @param path 字符串数组，表示字典中的键路径。空字符串表示在数组中进行迭代
// @param depth 路径的当前深度
// @return 更新后的对象，如果没有应用任何更改则返回nil
+ (id)demangleReportObj:(id)reportObj path:(NSArray<NSString *> *)path depth:(NSUInteger)depth
{
    // Check for NSString and try demangle
    // 检查是否为NSString并尝试反混淆
    // 如果已到达路径末尾
    if (depth == path.count) {
        // 如果对象不是NSString类型，返回nil
        if ([reportObj isKindOfClass:[NSString class]] == NO) {
            return nil;
        }
        // 尝试反混淆符号
        NSString *demangled = [self demangledSymbol:reportObj];
        // 返回反混淆后的字符串（如果反混淆失败则返回nil）
        return demangled;
    }

    // 获取当前深度的路径组件
    NSString *pathComponent = path[depth];

    // NSArray:
    // 处理NSArray：空字符串表示在数组中迭代
    if (pathComponent.length == 0) {
        // 如果对象不是NSArray类型，返回nil
        if ([reportObj isKindOfClass:[NSArray class]] == NO) {
            return nil;
        }
        // 转换为数组
        NSArray *reportArray = reportObj;
        // 创建可变数组用于存储结果（使用__block修饰以便在块中修改）
        NSMutableArray *__block result = nil;
        // 遍历数组中的每个对象
        [reportArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, __unused BOOL *_Nonnull stop) {
            // 递归反混淆当前对象
            id demangled = [self demangleReportObj:obj path:path depth:depth + 1];
            // 如果反混淆成功且结果数组尚未初始化
            if (demangled != nil && result == nil) {
                // Initializing the updated array only on first demangled result
                // 仅在第一次反混淆成功时初始化更新后的数组
                result = [NSMutableArray arrayWithCapacity:reportArray.count];
                // 复制当前索引之前的所有元素
                for (NSUInteger subIdx = 0; subIdx < idx; ++subIdx) {
                    [result addObject:reportArray[subIdx]];
                }
            }
            // 如果结果数组已初始化，设置当前索引的元素（使用反混淆后的对象，如果为nil则使用原对象）
            if (result != nil) {
                result[idx] = demangled ?: obj;
            }
        }];
        // 返回结果数组的不可变副本（如果result为nil则返回nil）
        return result ? [result copy] : nil;
    }

    // NSDictionary:
    // 处理NSDictionary
    // 如果对象不是NSDictionary类型，返回nil
    if ([reportObj isKindOfClass:[NSDictionary class]] == NO) {
        return nil;
    }
    // 转换为字典
    NSDictionary *reportDict = reportObj;
    // 递归反混淆路径组件对应的元素
    id demangledElement = [self demangleReportObj:reportDict[pathComponent] path:path depth:depth + 1];
    // 如果反混淆失败，返回nil
    if (demangledElement == nil) {
        return nil;
    }
    // 创建字典的可变副本
    NSMutableDictionary *result = [reportDict mutableCopy];
    // 更新路径组件对应的元素为反混淆后的值
    result[pathComponent] = demangledElement;
    // 返回结果字典的不可变副本
    return [result copy];
}

#pragma mark - KSCrashReportFilter

// 过滤报告：对报告中的符号进行反混淆
// @param reports 待过滤的报告数组（期望为字典格式）
// @param onCompletion 完成回调，返回反混淆后的报告数组
- (void)filterReports:(NSArray<id<KSCrashReport>> *)reports onCompletion:(KSCrashReportFilterCompletion)onCompletion
{
    // 定义需要反混淆的路径数组
    // 每个路径数组表示从报告根到符号名的键路径
    NSArray *demanglePaths = @[
        // 路径1：崩溃报告 -> 线程 -> 数组 -> 回溯 -> 内容 -> 数组 -> 符号名
        @[
            KSCrashField_Crash, KSCrashField_Threads, @"", KSCrashField_Backtrace, KSCrashField_Contents, @"",
            KSCrashField_SymbolName
        ],
        // 路径2：重崩溃报告 -> 崩溃报告 -> 线程 -> 数组 -> 回溯 -> 内容 -> 数组 -> 符号名
        @[
            KSCrashField_RecrashReport, KSCrashField_Crash, KSCrashField_Threads, @"", KSCrashField_Backtrace,
            KSCrashField_Contents, @"", KSCrashField_SymbolName
        ],
        // 路径3：崩溃报告 -> 错误 -> C++异常 -> 名称
        @[ KSCrashField_Crash, KSCrashField_Error, KSCrashField_CPPException, KSCrashField_Name ],
        // 路径4：重崩溃报告 -> 崩溃报告 -> 错误 -> C++异常 -> 名称
        @[
            KSCrashField_RecrashReport, KSCrashField_Crash, KSCrashField_Error, KSCrashField_CPPException,
            KSCrashField_Name
        ],
    ];

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
        // 获取报告字典值
        NSDictionary *reportDict = report.value;
        // 遍历每个反混淆路径
        for (NSArray *path in demanglePaths) {
            // 尝试对报告对象进行反混淆，如果失败则使用原字典
            reportDict = [[self class] demangleReportObj:reportDict path:path depth:0] ?: reportDict;
        }
        // 将更新后的报告字典包装为KSCrashReportDictionary对象并添加到结果数组
        [filteredReports addObject:[KSCrashReportDictionary reportWithValue:reportDict]];
    }

    // 所有报告处理完成，调用完成回调，传递过滤后的报告数组（无错误）
    kscrash_callCompletion(onCompletion, filteredReports, nil);
}

@end
