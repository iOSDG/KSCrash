//
//  KSCrashReportFilterGZip.h
//
//  Created by Karl Stenerud on 2012-05-10.
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
 * 定义崩溃报告Gzip压缩级别的枚举
 *
 * 压缩级别范围从0到9，其中：
 * - 0: 无压缩
 * - 9: 最佳压缩
 * - -1: 默认压缩级别
 *
 * 可以使用0到9之间的任何整数值初始化此类型
 */
typedef NSInteger KSCrashReportCompressionLevel NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(CrashReportCompressionLevel);
/** 无压缩级别 */
static KSCrashReportCompressionLevel const KSCrashReportCompressionLevelNone = 0;
/** 最佳压缩级别 */
static KSCrashReportCompressionLevel const KSCrashReportCompressionLevelBest = 9;
/** 默认压缩级别 */
static KSCrashReportCompressionLevel const KSCrashReportCompressionLevelDefault = -1;

/**
 * Gzip压缩报告的过滤器
 *
 * 输入: NSData
 * 输出: NSData（压缩后的数据）
 */
NS_SWIFT_NAME(CrashReportFilterGZipCompress)
@interface KSCrashReportFilterGZipCompress : NSObject <KSCrashReportFilter>

// 禁止使用init方法
- (instancetype)init NS_UNAVAILABLE;
// 禁止使用new方法
+ (instancetype)new NS_UNAVAILABLE;

/** 初始化方法
 *
 * @param compressionLevel Gzip压缩的压缩级别。可以是以下`KSCrashReportCompressionLevel`值之一：
 *                         - `KSCrashReportCompressionLevelNone` (0): 无压缩
 *                         - `KSCrashReportCompressionLevelBest` (9): 最佳压缩
 *                         - `KSCrashReportCompressionLevelDefault` (-1): 默认压缩级别
 *                         压缩级别可以是0到9之间的任何整数值
 */
- (instancetype)initWithCompressionLevel:(KSCrashReportCompressionLevel)compressionLevel;

@end

/** Gzip解压缩报告的过滤器
 *
 * 输入: NSData（压缩后的数据）
 * 输出: NSData（解压缩后的数据）
 */
NS_SWIFT_NAME(CrashReportFilterGZipDecompress)
@interface KSCrashReportFilterGZipDecompress : NSObject <KSCrashReportFilter>

@end

NS_ASSUME_NONNULL_END
