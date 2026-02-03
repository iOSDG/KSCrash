//
//  KSCrashReportFilterSets.h
//
//  Created by Karl Stenerud on 2012-08-21.
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
// 导入Apple格式过滤器
#import "KSCrashReportFilterAppleFmt.h"

// 导入Foundation框架
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 常用过滤器集合
 * 提供预配置的过滤器组合，方便快速使用
 */
NS_SWIFT_NAME(CrashFilterSets)
@interface KSCrashFilterSets : NSObject

// 禁止使用init方法
- (instancetype)init NS_UNAVAILABLE;
// 禁止使用new方法
+ (instancetype)new NS_UNAVAILABLE;

/** 创建包含系统和用户数据的Apple格式过滤器
 * @param reportStyle Apple报告样式（符号化选项）
 * @param compressed 是否压缩最终输出
 * @return 配置好的过滤器管道，包含Apple格式报告和JSON格式的系统/用户数据
 */
+ (id<KSCrashReportFilter>)appleFmtWithUserAndSystemData:(KSAppleReportStyle)reportStyle compressed:(BOOL)compressed;

@end

NS_ASSUME_NONNULL_END
