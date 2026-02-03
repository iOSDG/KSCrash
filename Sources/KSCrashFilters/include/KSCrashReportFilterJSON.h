//
//  KSCrashReportFilterJSON.h
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

// 导入命名空间头文件
#include "KSCrashNamespace.h"
// 导入崩溃报告过滤器协议
#import "KSCrashReportFilter.h"
// 导入JSON编解码器Objective-C接口
#import "KSJSONCodecObjC.h"

// 导入Foundation框架
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** 将报告从字典格式转换为JSON格式的过滤器
 *
 * 输入: NSDictionary
 * 输出: NSData
 */
NS_SWIFT_NAME(CrashReportFilterJSONEncode)
@interface KSCrashReportFilterJSONEncode : NSObject <KSCrashReportFilter>

/** 使用编码选项初始化
 * @param options 要使用的JSON编码选项（如美化、排序等）
 * @return 初始化后的实例
 */
- (instancetype)initWithOptions:(KSJSONEncodeOption)options;

/** 默认初始化方法
 * @return 使用KSJSONEncodeOptionNone选项初始化的实例
 */
- (instancetype)init;

@end

/** 将报告从JSON格式转换为字典格式的过滤器
 *
 * 输入: NSData
 * 输出: NSDictionary
 */
NS_SWIFT_NAME(CrashReportFilterJSONDecode)
@interface KSCrashReportFilterJSONDecode : NSObject <KSCrashReportFilter>

/** 使用解码选项初始化
 * @param options 要使用的JSON解码选项（如严格解析等）
 * @return 初始化后的实例
 */
- (instancetype)initWithOptions:(KSJSONDecodeOption)options;

/** 默认初始化方法
 * @return 使用KSJSONDecodeOptionNone选项初始化的实例
 */
- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
