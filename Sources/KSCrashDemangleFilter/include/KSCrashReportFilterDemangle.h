//
//  KSCrashReportFilterDemangle.h
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

// 导入命名空间头文件
#include "KSCrashNamespace.h"
// 导入崩溃报告过滤器协议
#import "KSCrashReportFilter.h"
// 导入JSON编解码器Objective-C接口
#import "KSJSONCodecObjC.h"

// 导入Foundation框架
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Demangle symbols in raw crash reports.
 *
 * Input: NSDictionary
 * Output: NSDictionary
 */
// 反混淆原始崩溃报告中的符号
// 此过滤器用于将崩溃报告中的混淆符号（C++和Swift）转换为可读的符号名称。
// 它会递归遍历报告中的特定路径，查找并反混淆符号名称。
// 输入: NSDictionary（包含混淆符号的崩溃报告）
// 输出: NSDictionary（符号已反混淆的崩溃报告）
NS_SWIFT_NAME(CrashReportFilterDemangle)
@interface KSCrashReportFilterDemangle : NSObject <KSCrashReportFilter>

/** Demangles a C++ symbol.
 *
 * @param symbol The mangled symbol.
 *
 * @return A demangled symbol, or `nil` if demangling failed.
 */
// 反混淆C++符号
// @param symbol 混淆的C++符号字符串
// @return 反混淆后的符号字符串，如果反混淆失败则返回nil
+ (nullable NSString *)demangledCppSymbol:(NSString *)symbol;

/** Demangles a Swift symbol.
 *
 * @param symbol The mangled symbol.
 *
 * @return A demangled symbol, or `nil` if demangling failed.
 */
// 反混淆Swift符号
// @param symbol 混淆的Swift符号字符串
// @return 反混淆后的符号字符串，如果反混淆失败或系统不支持Swift则返回nil
+ (nullable NSString *)demangledSwiftSymbol:(NSString *)symbol;

@end

NS_ASSUME_NONNULL_END
