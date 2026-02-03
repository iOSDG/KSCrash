//
//  KSCrashReportFilterJSON.m
//
//  Created by Karl Stenerud on 2012-05-09.
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

// 导入JSON过滤器头文件
#import "KSCrashReportFilterJSON.h"
// 导入崩溃报告协议
#import "KSCrashReport.h"

// #define KSLogger_LocalLevel TRACE
// 导入日志工具
#import "KSLogger.h"

// JSON编码过滤器的私有接口扩展
@interface KSCrashReportFilterJSONEncode ()

// JSON编码选项属性（只读，赋值）
@property(nonatomic, readwrite, assign) KSJSONEncodeOption encodeOptions;

@end

// JSON编码过滤器实现
@implementation KSCrashReportFilterJSONEncode

// 使用指定选项初始化JSON编码过滤器
// @param options JSON编码选项（如美化、排序等）
// @return 初始化后的实例
- (instancetype)initWithOptions:(KSJSONEncodeOption)options
{
    // 调用父类初始化方法
    if ((self = [super init])) {
        // 保存编码选项
        _encodeOptions = options;
    }
    // 返回初始化后的实例
    return self;
}

// 默认初始化方法
// @return 使用默认选项（KSJSONEncodeOptionNone）初始化的实例
- (instancetype)init
{
    // 调用指定选项初始化方法，使用无选项
    return [self initWithOptions:KSJSONEncodeOptionNone];
}

// 过滤报告：将字典格式的报告编码为JSON数据
// @param reports 待过滤的报告数组（期望为字典格式）
// @param onCompletion 完成回调，返回编码后的报告数组或错误
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

        // 错误对象，用于接收编码过程中的错误
        NSError *error = nil;
        // 将字典编码为JSON数据，使用指定的编码选项
        NSData *jsonData = [KSJSONCodec encode:report.value options:self.encodeOptions error:&error];
        // 检查编码是否成功
        if (jsonData == nil) {
            // 编码失败，调用完成回调并传递错误
            kscrash_callCompletion(onCompletion, filteredReports, error);
            // 提前返回，不再处理后续报告
            return;
        } else {
            // 编码成功，将JSON数据包装为KSCrashReportData对象并添加到结果数组
            [filteredReports addObject:[KSCrashReportData reportWithValue:jsonData]];
        }
    }

    // 所有报告处理完成，调用完成回调，传递过滤后的报告数组（无错误）
    kscrash_callCompletion(onCompletion, filteredReports, nil);
}

@end

// JSON解码过滤器的私有接口扩展
@interface KSCrashReportFilterJSONDecode ()

// JSON解码选项属性（只读，赋值）
@property(nonatomic, readwrite, assign) KSJSONDecodeOption decodeOptions;

@end

// JSON解码过滤器实现
@implementation KSCrashReportFilterJSONDecode

// 使用指定选项初始化JSON解码过滤器
// @param options JSON解码选项（如严格解析等）
// @return 初始化后的实例
- (instancetype)initWithOptions:(KSJSONDecodeOption)options
{
    // 调用父类初始化方法
    if ((self = [super init])) {
        // 保存解码选项
        _decodeOptions = options;
    }
    // 返回初始化后的实例
    return self;
}

// 默认初始化方法
// @return 使用默认选项（KSJSONDecodeOptionNone）初始化的实例
- (instancetype)init
{
    // 调用指定选项初始化方法，使用无选项
    return [self initWithOptions:KSJSONDecodeOptionNone];
}

// 过滤报告：将JSON数据解码为字典格式的报告
// @param reports 待过滤的报告数组（期望为数据格式）
// @param onCompletion 完成回调，返回解码后的报告数组或错误
- (void)filterReports:(NSArray<id<KSCrashReport>> *)reports onCompletion:(KSCrashReportFilterCompletion)onCompletion
{
    // 创建可变数组，容量与输入报告数量相同
    NSMutableArray<id<KSCrashReport>> *filteredReports = [NSMutableArray arrayWithCapacity:[reports count]];
    // 遍历每个报告
    for (KSCrashReportData *report in reports) {
        // 检查报告是否为数据类型
        if ([report isKindOfClass:[KSCrashReportData class]] == NO) {
            // 如果不是数据类型，记录错误日志
            KSLOG_ERROR(@"Unexpected non-data report: %@", report);
            // 跳过此报告，继续处理下一个
            continue;
        }

        // 错误对象，用于接收解码过程中的错误
        NSError *error = nil;
        // 将JSON数据解码为字典，使用指定的解码选项
        NSDictionary *decodedReport = [KSJSONCodec decode:report.value options:self.decodeOptions error:&error];
        // 检查解码是否成功且结果为字典类型
        if (decodedReport == nil || [decodedReport isKindOfClass:[NSDictionary class]] == NO) {
            // 解码失败或结果不是字典，调用完成回调并传递错误
            kscrash_callCompletion(onCompletion, filteredReports, error);
            // 提前返回，不再处理后续报告
            return;
        } else {
            // 解码成功，将字典包装为KSCrashReportDictionary对象并添加到结果数组
            [filteredReports addObject:[KSCrashReportDictionary reportWithValue:decodedReport]];
        }
    }

    // 所有报告处理完成，调用完成回调，传递过滤后的报告数组（无错误）
    kscrash_callCompletion(onCompletion, filteredReports, nil);
}

@end
