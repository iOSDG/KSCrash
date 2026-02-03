//
//  KSCrashReportFilterAppleFmt.h
//
//  Created by Karl Stenerud on 2012-02-24.
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

/** 影响Apple风格崩溃报告的生成方式
 *
 * KSCrashReporter报告包含符号化数据，可以在生成Apple风格报告时替代普通偏移量。
 * 您应该选择的报告样式取决于应用程序中将存在哪些符号，以及离线符号化可用的信息
 * （例如，使用Apple的符号化工具）。
 *
 * 有三种符号化级别：
 *
 * - 未符号化：包含基址和偏移量。
 *                   例如：0x0000347a 0x1000 + 9338
 *
 * - 基本符号化：包含基址、方法名和方法内的偏移量。
 *               例如：0x372bd97e -[UIControl sendAction:to:forEvent:] + 38
 *
 * - 完整符号化：与基本符号化类似，但偏移量转换为行号。
 *               例如：0x0000347a +[MyObject someMethod] (MyObject.m:21)
 *
 * 完整符号化只能（并且只对）您自己的代码进行。完整符号化信息只能从与您的应用
 * 匹配的dSYM文件中获得，因此只能通过离线符号化检索。对于动态库（如libc、UIKit、
 * Foundation等），只有基本符号化可用（在线或离线）。
 *
 * 所有iOS设备都内置了动态库的基本符号信息（如libc、UIKit、Foundation等）。
 * 建议在设备上对这些进行符号化，因为不能保证您进行离线符号化的机器将具有相同
 * 的版本可用（例如，iOS 4.2 - 5.01的符号可用，但iOS 4.0的不可用）。
 *
 * 应用符号只有在您将构建设置中的"Strip Style"设置为"Debugging Symbols"时才会存在
 * （这会剥离所有调试符号，但保留基本符号信息完整）。这会使应用的代码占用增加约10%，
 * 但允许在设备上进行基本符号化。
 *
 * 选择KSAppleReportStylePartiallySymbolicated会对除主可执行文件条目外的所有内容
 * 进行符号化，以便您可以使用离线符号化工具。您需要dSYM文件来对这些条目进行符号化。
 *
 * KSAppleReportStyleSymbolicatedSideBySide生成一个两全其美的报告，其中所有内容都已
 * 符号化，但主可执行文件中的任何偏移量将同时保留其"未符号化"和"符号化"版本，
 * 以便离线符号化工具仍然可以解析该行并确定行号（前提是您有匹配的dSYM文件）。
 *
 * 简而言之，如果您不关心行号，或者不想进行离线符号化，请使用KSAppleReportStyleSymbolicated。
 * 如果您确实关心行号，有dSYM文件可用，并且将进行离线符号化，请使用KSAppleReportStyleSymbolicatedSideBySide。
 */
typedef NS_ENUM(NSInteger, KSAppleReportStyle) {
    /** 保留所有栈跟踪条目未符号化 */
    KSAppleReportStyleUnsymbolicated,

    /** 对除主可执行文件中的条目外的所有栈跟踪条目进行符号化 */
    KSAppleReportStylePartiallySymbolicated,

    /** 对所有栈跟踪条目进行符号化，但对于主可执行文件中的任何条目，
     *  同时保留未符号化和符号化的条目
     */
    KSAppleReportStyleSymbolicatedSideBySide,

    /** 对所有内容进行符号化 */
    KSAppleReportStyleSymbolicated
} NS_SWIFT_NAME(AppleReportStyle);

/** 转换为Apple格式的过滤器
 *
 * 输入: NSDictionary
 * 输出: NSString（Apple格式的崩溃报告字符串）
 */
NS_SWIFT_NAME(CrashReportFilterAppleFmt)
@interface KSCrashReportFilterAppleFmt : NSObject <KSCrashReportFilter>

/** 使用特定的Apple报告样式初始化
 * @param reportStyle 用于符号化的Apple报告样式
 * @return 初始化后的实例
 * @see KSAppleReportStyle 获取符号化选项的详细信息
 */
- (instancetype)initWithReportStyle:(KSAppleReportStyle)reportStyle;

/** 默认初始化方法
 * @return 使用KSAppleReportStyleSymbolicated样式初始化的实例
 * @note 此样式对所有栈跟踪条目进行符号化
 */
- (instancetype)init;

/** 为Apple风格崩溃报告生成标题字符串
 * @param system 包含系统信息的字典（例如，设备、操作系统、应用详情）
 * @param reportID 崩溃报告的唯一标识符（可为nil）
 * @param crashTime 崩溃发生的时间戳（可为nil）
 * @return 格式化的标题字符串，包括事件标识符、硬件型号、进程信息、操作系统版本等
 */
- (NSString *)headerStringForSystemInfo:(NSDictionary<NSString *, id> *)system
                               reportID:(nullable NSString *)reportID
                              crashTime:(nullable NSDate *)crashTime;

@end

NS_ASSUME_NONNULL_END
