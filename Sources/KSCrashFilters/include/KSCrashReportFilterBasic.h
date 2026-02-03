//
//  KSCrashReportFilterBasic.h
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

// 导入命名空间头文件
#include "KSCrashNamespace.h"
// 导入崩溃报告过滤器协议
#import "KSCrashReportFilter.h"

// 导入Foundation框架
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 非常基础的过滤器，原样透传报告，不做任何修改
 *
 * 输入: 任意类型
 * 输出: 与输入相同（透传）
 */
NS_SWIFT_NAME(CrashReportFilterPassthrough)
@interface KSCrashReportFilterPassthrough : NSObject <KSCrashReportFilter>

@end

/**
 * 将报告传递给一系列子过滤器，然后将这些操作的结果作为键值对存储在最终的主报告中
 *
 * 输入: 任意类型
 * 输出: NSDictionary（包含各子过滤器的输出，以键值对形式存储）
 */
NS_SWIFT_NAME(CrashReportFilterCombine)
@interface KSCrashReportFilterCombine : NSObject <KSCrashReportFilter>

// 禁止使用init方法
- (instancetype)init NS_UNAVAILABLE;
// 禁止使用new方法
+ (instancetype)new NS_UNAVAILABLE;

/**
 * 初始化方法
 *
 * @param filterDictionary 一个字典，其中每个键值对代表一个过滤器及其对应的键。
 *                         键是字符串，将用于在最终报告字典中存储相应过滤器的输出。
 *                         值是待应用的过滤器。每个过滤器都应遵循KSCrashReportFilter协议。
 *
 * @return 初始化后的类实例
 */
- (instancetype)initWithFilters:(NSDictionary<NSString *, id<KSCrashReportFilter>> *)filterDictionary;

@end

/**
 * 过滤器管道。报告按顺序通过每个子过滤器
 *
 * 输入: 取决于管道中的过滤器
 * 输出: 取决于管道中的过滤器
 */
NS_SWIFT_NAME(CrashReportFilterPipeline)
@interface KSCrashReportFilterPipeline : NSObject <KSCrashReportFilter>

/** 此管道中的过滤器数组（只读，复制） */
@property(nonatomic, readonly, copy) NSArray<id<KSCrashReportFilter>> *filters;

/** 使用过滤器数组初始化
 *
 * @param filters 过滤器数组，其中每个过滤器都遵循KSCrashReportFilter协议
 */
- (instancetype)initWithFilters:(NSArray<id<KSCrashReportFilter>> *)filters;

/** 向管道开头添加过滤器
 *
 * @param filter 要添加的过滤器。此过滤器必须遵循KSCrashReportFilter协议。
 *               它将被插入到管道中现有过滤器的开头
 */
- (void)addFilter:(id<KSCrashReportFilter>)filter;

@end

/**
 * 从报告中按键获取值并连接它们的字符串表示
 *
 * 输入: NSDictionary
 * 输出: NSString
 */
NS_SWIFT_NAME(CrashReportFilterConcatenate)
@interface KSCrashReportFilterConcatenate : NSObject <KSCrashReportFilter>

// 禁止使用init方法
- (instancetype)init NS_UNAVAILABLE;
// 禁止使用new方法
+ (instancetype)new NS_UNAVAILABLE;

/** 使用键数组初始化
 *
 * @param separatorFmt 用于分隔值的格式化文本。可以在格式化文本中包含%@以包含键名
 * @param keys 键数组，将从源报告中连接这些键对应的值
 */
- (instancetype)initWithSeparatorFmt:(NSString *)separatorFmt keys:(NSArray<NSString *> *)keys;

@end

/**
 * 从源报告中获取数据的子集。所有其他数据将被丢弃
 *
 * 输入: NSDictionary
 * 输出: NSDictionary（仅包含指定的键路径对应的数据）
 */
NS_SWIFT_NAME(CrashReportFilterSubset)
@interface KSCrashReportFilterSubset : NSObject <KSCrashReportFilter>

// 禁止使用init方法
- (instancetype)init NS_UNAVAILABLE;
// 禁止使用new方法
+ (instancetype)new NS_UNAVAILABLE;

/** 使用键路径数组初始化
 *
 * @param keyPaths 要在源报告中搜索的键路径数组。每个键路径将从报告中提取数据的子集
 */
- (instancetype)initWithKeys:(NSArray<NSString *> *)keyPaths;

@end

/**
 * 将UTF-8数据转换为NSString
 *
 * 输入: NSData
 * 输出: NSString
 */
NS_SWIFT_NAME(CrashReportFilterDataToString)
@interface KSCrashReportFilterDataToString : NSObject <KSCrashReportFilter>

@end

/**
 * 将NSString转换为UTF-8编码的NSData
 *
 * 输入: NSString
 * 输出: NSData
 */
NS_SWIFT_NAME(CrashReportFilterStringToData)
@interface KSCrashReportFilterStringToData : NSObject <KSCrashReportFilter>

@end

NS_ASSUME_NONNULL_END
