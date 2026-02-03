//
//  KSCrashReportSinkEMail.h
//
//  Created by Karl Stenerud on 2012-05-06.
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

// 导入Foundation框架，提供基础类（NSObject、NSString等）
#import <Foundation/Foundation.h>
// 包含KSCrash命名空间定义
#include "KSCrashNamespace.h"
// 导入崩溃报告过滤器协议，定义过滤器接口
#import "KSCrashReportFilter.h"

// 开始非空假设（在此范围内的指针默认非空，除非明确标记为nullable）
NS_ASSUME_NONNULL_BEGIN

/** Sends reports via email.
 *
 * Input: NSData
 * Output: Same as input (passthrough)
 */
// 通过邮件发送报告
// 输入：NSData（崩溃报告数据，通常是GZip压缩的数据）
// 输出：与输入相同（透传，不修改报告内容）
// 注意：此功能需要MessageUI框架支持（iOS/macOS）
NS_SWIFT_NAME(CrashReportSinkEmail)
@interface KSCrashReportSinkEMail : NSObject <KSCrashReportFilter>

// 禁用默认初始化方法（必须使用initWithRecipients:subject:message:filenameFmt:初始化）
- (instancetype)init NS_UNAVAILABLE;
// 禁用new方法（必须使用initWithRecipients:subject:message:filenameFmt:初始化）
+ (instancetype)new NS_UNAVAILABLE;

/**
 * @param recipients List of email addresses to send to.
 * @param subject What to put in the subject field.
 * @param message A message to accompany the reports (optional - nil = ignore).
 * @param filenameFmt How to name the attachments. You may use "%d" to differentiate
 *                    when multiple reports are sent at once.
 *                    Note: With the default filter set, files are gzipped text.
 */
// 使用指定参数初始化邮件报告输出目标
// @param recipients 要发送到的电子邮件地址列表（至少需要一个收件人）
// @param subject 邮件主题字段的内容
// @param message 伴随报告的消息（可选 - nil = 忽略）
// @param filenameFmt 如何命名附件。可以使用"%d"来区分同时发送多个报告时的情况
//                    注意：使用默认过滤器集时，文件是gzip压缩的文本
- (instancetype)initWithRecipients:(NSArray<NSString *> *)recipients
                           subject:(NSString *)subject
                           message:(nullable NSString *)message
                       filenameFmt:(NSString *)filenameFmt;

// 默认崩溃报告过滤器集合（JSON格式，只读）
// 包含JSON编码过滤器和GZip压缩过滤器
@property(nonatomic, readonly) id<KSCrashReportFilter> defaultCrashReportFilterSet;

// 默认崩溃报告过滤器集合（Apple格式，只读）
// 包含Apple格式过滤器、字符串转数据过滤器和GZip压缩过滤器
@property(nonatomic, readonly) id<KSCrashReportFilter> defaultCrashReportFilterSetAppleFmt;

@end

// 结束非空假设
NS_ASSUME_NONNULL_END
