//
//  KSCrashInstallationEmail.h
//
//  Created by Karl Stenerud on 2013-03-02.
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

// 导入崩溃安装类头文件，包含基类接口声明
#import "KSCrashInstallation.h"
// 包含KSCrash命名空间定义
#include "KSCrashNamespace.h"

// 导入Foundation框架，提供基础类（NSObject、NSString等）
#import <Foundation/Foundation.h>

// 开始非空假设（在此范围内的指针默认非空，除非明确标记为nullable）
NS_ASSUME_NONNULL_BEGIN

// 邮件报告样式枚举
// 定义邮件中报告的格式类型
typedef NS_ENUM(NSUInteger, KSCrashEmailReportStyle) {
    // JSON格式（默认格式，JSON编码的报告）
    KSCrashEmailReportStyleJSON,
    // Apple格式（类似Xcode崩溃报告的格式）
    KSCrashEmailReportStyleApple,
} NS_SWIFT_NAME(EmailReportStyle);

/**
 * Email installation.
 * Sends reports via email.
 */
// 邮件安装类
// 通过邮件发送报告
NS_SWIFT_NAME(CrashInstallationEmail)
@interface KSCrashInstallationEmail : KSCrashInstallation

// 共享单例实例（类属性，只读，原子性）
// 使用单例模式确保整个应用程序只有一个邮件安装实例
@property(class, atomic, readonly) KSCrashInstallationEmail *sharedInstance NS_SWIFT_NAME(shared);

/** List of email addresses to send to (mandatory) */
// 要发送到的电子邮件地址列表（必需）
// 必须至少包含一个收件人地址
@property(nonatomic, readwrite, copy) NSArray<NSString *> *recipients;

/** Email subject (mandatory).
 *
 * Default: "Crash Report (YourBundleID)"
 */
// 邮件主题（必需）
// 默认值："Crash Report (YourBundleID)"（YourBundleID会被替换为实际的应用包ID）
@property(nonatomic, readwrite, copy) NSString *subject;

/** Message to accompany the reports (optional).
 *
 * Default: nil
 */
// 伴随报告的消息（可选）
// 此消息将包含在邮件正文中
// 默认值：nil（无消息）
@property(nonatomic, readwrite, copy, nullable) NSString *message;

/** How to name the attachments (mandatory)
 *
 * You may use "%d" to differentiate when multiple reports are sent at once.
 *
 * Note: With the default filter set, files are gzipped text.
 *
 * Default: "crash-report-YourBundleID-%d.txt.gz"
 */
// 如何命名附件（必需）
// 可以使用"%d"来区分同时发送多个报告时的情况（%d会被替换为报告编号）
// 注意：使用默认过滤器集时，文件是gzip压缩的文本
// 默认值："crash-report-YourBundleID-%d.txt.gz"（YourBundleID会被替换为实际的应用包ID）
@property(nonatomic, readwrite, copy) NSString *filenameFmt;

/** Which report style to use.
 */
// 要使用的报告样式
// 可以是JSON格式或Apple格式
@property(nonatomic, readwrite, assign) KSCrashEmailReportStyle reportStyle;

/** Use the specified report format.
 *
 * useDefaultFilenameFormat If true, also change the filename format to the default
 *                          suitable for the report format.
 */
// 使用指定的报告格式
// @param reportStyle 报告样式（JSON或Apple格式）
// @param useDefaultFilenameFormat 如果为true，同时将文件名格式更改为适合报告格式的默认值
//                                 如果为true，会根据报告样式自动设置文件名格式
//                                 例如：Apple格式使用.txt.gz，JSON格式使用.json.gz
- (void)setReportStyle:(KSCrashEmailReportStyle)reportStyle useDefaultFilenameFormat:(BOOL)useDefaultFilenameFormat;

@end

// 结束非空假设
NS_ASSUME_NONNULL_END
