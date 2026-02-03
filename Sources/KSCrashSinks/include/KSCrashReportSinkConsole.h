//
//  KSCrashReportSinkConsole.h
//
//  Created by Karl Stenerud on 12-05-11.
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

// 导入Foundation框架，提供基础类（NSObject等）
#import <Foundation/Foundation.h>

// 开始非空假设（在此范围内的指针默认非空，除非明确标记为nullable）
NS_ASSUME_NONNULL_BEGIN

/**
 * Prints reports directly to the console.
 *
 * Input: Anything
 * Output: Same as input (passthrough)
 */
// 直接将报告打印到控制台
// 输入：任意类型（通常是字符串类型）
// 输出：与输入相同（透传，不修改报告内容）
// 注意：此类主要用于测试和调试目的
NS_SWIFT_NAME(CrashReportSinkConsole)
@interface KSCrashReportSinkConsole : NSObject <KSCrashReportFilter>

/** Returns the default crash report filter set. */
// 返回默认的崩溃报告过滤器集合（只读）
// 包含Apple格式过滤器（将报告转换为Apple格式）和此Sink本身
@property(nonatomic, readonly) id<KSCrashReportFilter> defaultCrashReportFilterSet;

@end

// 结束非空假设
NS_ASSUME_NONNULL_END
