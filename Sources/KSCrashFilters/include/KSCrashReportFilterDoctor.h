//
//  KSCrashReportFilterDoctor.h
//
//  Created by Karl Stenerud on 2024-09-15.
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
 * 为报告添加自动化诊断部分的过滤器
 *
 * 输入: NSDictionary
 * 输出: NSDictionary（包含诊断信息）
 */
NS_SWIFT_NAME(CrashReportFilterDoctor)
@interface KSCrashReportFilterDoctor : NSObject <KSCrashReportFilter>

/** 类方法：诊断崩溃报告
 * @param crashReport 崩溃报告字典
 * @return 诊断结果字符串，如果无法诊断则返回nil
 */
+ (NSString *)diagnoseCrash:(NSDictionary *)crashReport;

@end

NS_ASSUME_NONNULL_END
