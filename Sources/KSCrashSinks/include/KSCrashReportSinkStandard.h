//
//  KSCrashReportSinkStandard.h
//
//  Created by Karl Stenerud on 2012-02-18.
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

// 包含KSCrash命名空间定义
#include "KSCrashNamespace.h"
// 导入崩溃报告过滤器协议，定义过滤器接口
#import "KSCrashReportFilter.h"

// 导入Foundation框架，提供基础类（NSObject、NSURL等）
#import <Foundation/Foundation.h>

// 开始非空假设（在此范围内的指针默认非空，除非明确标记为nullable）
NS_ASSUME_NONNULL_BEGIN

/**
 * Sends crash reports to an HTTP server.
 *
 * Input: NSDictionary
 * Output: Same as input (passthrough)
 */
// 将崩溃报告发送到HTTP服务器
// 输入：NSDictionary（崩溃报告字典）
// 输出：与输入相同（透传，不修改报告内容）
NS_SWIFT_NAME(CrashReportSinkStandard)
@interface KSCrashReportSinkStandard : NSObject <KSCrashReportFilter>

// 禁用默认初始化方法（必须使用initWithURL:初始化）
- (instancetype)init NS_UNAVAILABLE;
// 禁用new方法（必须使用initWithURL:初始化）
+ (instancetype)new NS_UNAVAILABLE;

/** Constructor.
 *
 * @param url The URL to connect to.
 */
// 构造函数
// @param url 要连接到的URL（报告发送的目标地址）
- (instancetype)initWithURL:(NSURL *)url;

// 默认崩溃报告过滤器集合（只读）
// 返回此Sink的默认过滤器集合（通常只包含Sink本身）
@property(nonatomic, readonly) id<KSCrashReportFilter> defaultCrashReportFilterSet;

@end

// 结束非空假设
NS_ASSUME_NONNULL_END
