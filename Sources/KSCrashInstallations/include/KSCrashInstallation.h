//
//  KSCrashInstallation.h
//
//  Created by Karl Stenerud on 2013-02-10.
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
// 导入崩溃报告写入器，用于在崩溃时写入报告
#import "KSCrashReportWriter.h"
// 导入崩溃报告写入器回调定义
#import "KSCrashReportWriterCallbacks.h"

// 开始非空假设（在此范围内的指针默认非空，除非明确标记为nullable）
NS_ASSUME_NONNULL_BEGIN

// 前向声明KSCrashConfiguration类（避免循环依赖）
@class KSCrashConfiguration;

/**
 * Crash system installation which handles backend-specific details.
 *
 * Only one installation can be installed at a time.
 *
 * This is an abstract class.
 */
// 崩溃系统安装类，处理特定后端的详细信息
// 注意：一次只能安装一个安装对象
// 这是一个抽象类（子类必须实现sink方法）
NS_SWIFT_NAME(CrashInstallation)
@interface KSCrashInstallation : NSObject

/** C Function to call during a crash report to give the callee an opportunity to
 * add to the report. NULL = ignore (DEPRECATED).
 *
 * @deprecated Use `isWritingReportCallback` for async-safety awareness (since v2.4.0).
 * This callback does not receive plan information and may not handle crash
 * scenarios safely.
 *
 * WARNING: Only call async-safe functions from this function! DO NOT call
 * Swift/Objective-C methods!!!
 */
// C函数回调，在崩溃报告时调用，允许调用者向报告添加数据。NULL = 忽略（已弃用）
// @deprecated 使用`isWritingReportCallback`以获得异步安全感知（自v2.4.0起）
// 此回调不接收计划信息，可能无法安全处理崩溃场景
// 警告：在此函数中只能调用异步安全函数！不要调用Swift/Objective-C方法！！！
@property(atomic, readwrite, assign, nullable) KSReportWriteCallback onCrash
    __attribute__((deprecated("Use `isWritingReportCallback` for async-safety awareness (since v2.4.0).")));

/** C Function to call during a crash report to give the callee an opportunity to
 * add to the `user` section of the report. NULL = ignore.
 *
 * The plan parameter provides crucial information about the crash context and
 * safety constraints that must be observed within the callback.
 *
 * @see KSCrash_ExceptionHandlingPlan
 *
 * WARNING: Only call async-safe functions from this function when `plan.requiresAsyncSafety` is true!
 * DO NOT call Swift/Objective-C methods unless the plan allows it!!!
 */
// C函数回调，在崩溃报告时调用，允许调用者向报告的`user`部分添加数据。NULL = 忽略
// plan参数提供关于崩溃上下文和安全约束的关键信息，必须在回调中遵守
// @see KSCrash_ExceptionHandlingPlan
// 警告：当`plan.requiresAsyncSafety`为true时，在此函数中只能调用异步安全函数！
// 除非计划允许，否则不要调用Swift/Objective-C方法！！！
@property(atomic, readwrite, assign, nullable) KSCrashIsWritingReportCallback isWritingReportCallback;

/** Flag for disabling built-in demangling pre-filter.
 * If enabled an additional `KSCrashReportFilterDemangle` filter will be applied first.
 * @note Enabled by-default.
 */
// 禁用内置符号反混淆前置过滤器的标志
// 如果启用，将首先应用额外的`KSCrashReportFilterDemangle`过滤器
// @note 默认启用
@property(nonatomic, assign) BOOL isDemangleEnabled;

/** Flag for disabling a pre-filter for automated diagnostics.
 * If enabled an additional `KSCrashReportFilterDoctor` filter will be applied.
 * @note Enabled by-default.
 */
// 禁用自动化诊断前置过滤器的标志
// 如果启用，将应用额外的`KSCrashReportFilterDoctor`过滤器
// @note 默认启用
@property(nonatomic, assign) BOOL isDoctorEnabled;

/** Install this crash handler with a specific configuration.
 * Call this method instead of `-[KSCrash installWithConfiguration:error:]` to set up the crash handler
 * tailored for your specific backend requirements.
 *
 * @param configuration The configuration object containing the settings for the crash handler.
 * @param error         On input, a pointer to an error object. If an error occurs, this pointer
 *                      is set to an actual error object containing the error information.
 *                      You may specify nil for this parameter if you do not want the error information.
 *                      See KSCrashError.h for specific error codes that may be returned.
 *
 * @return YES if the installation was successful, NO otherwise.
 *
 * @note The `crashNotifyCallback` property of the provided `KSCrashConfiguration` will not take effect
 *       when using this method. The callback will be internally managed to ensure proper integration
 *       with the backend.
 *
 * @see KSCrashError.h for a complete list of possible error codes.
 */
// 使用特定配置安装此崩溃处理器
// 调用此方法而不是`-[KSCrash installWithConfiguration:error:]`来设置崩溃处理器，
// 以适应您的特定后端需求
// @param configuration 包含崩溃处理器设置配置对象
// @param error 输入时，指向错误对象的指针。如果发生错误，此指针将被设置为包含错误信息的实际错误对象
//              如果您不需要错误信息，可以将此参数指定为nil
//              参见KSCrashError.h了解可能返回的特定错误代码
// @return 如果安装成功返回YES，否则返回NO
// @note 提供的`KSCrashConfiguration`的`crashNotifyCallback`属性在使用此方法时不会生效
//       回调将由内部管理以确保与后端的正确集成
// @see KSCrashError.h了解可能的错误代码的完整列表
- (BOOL)installWithConfiguration:(KSCrashConfiguration *)configuration error:(NSError **)error;

/** Convenience method to call -[KSCrash sendAllReportsWithCompletion:].
 * This method will set the KSCrash sink and then send all outstanding reports.
 *
 * Note: Pay special attention to KSCrashConfiguration's `reportCleanupPolicy` property.
 *
 * @param onCompletion Called when sending is complete (nil = ignore).
 */
// 便捷方法，调用-[KSCrash sendAllReportsWithCompletion:]
// 此方法将设置KSCrash的sink，然后发送所有未完成的报告
// 注意：请特别注意KSCrashConfiguration的`reportCleanupPolicy`属性
// @param onCompletion 发送完成时调用（nil = 忽略）
- (void)sendAllReportsWithCompletion:(nullable KSCrashReportFilterCompletion)onCompletion;

/** Add a filter that gets executed before all normal filters.
 * Prepended filters will be executed in the order in which they were added.
 *
 * @param filter the filter to prepend.
 */
// 添加在所有正常过滤器之前执行的过滤器
// 前置过滤器将按照添加的顺序执行
// @param filter 要前置的过滤器
- (void)addPreFilter:(id<KSCrashReportFilter>)filter;

/** Creates a sink to be used for reports sending.
 * @note Subclasses MUST implement this, otherwise `sendAllReportsWithCompletion:` will complete with error.
 *
 * @return An instance that implements `KSCrashReportFilter` protocol to be used as a reports sending sink.
 */
// 创建用于发送报告的sink
// @note 子类必须实现此方法，否则`sendAllReportsWithCompletion:`将完成并返回错误
// @return 实现`KSCrashReportFilter`协议的实例，用作报告发送sink
- (id<KSCrashReportFilter>)sink;

/** Show an alert before sending any reports. Reports will only be sent if the user
 * presses the "yes" button.
 *
 * @param title The alert title.
 * @param message The message to show the user.
 * @param yesAnswer The text to display in the "yes" box.
 * @param noAnswer The text to display in the "no" box.
 */
// 在发送任何报告之前显示警报。只有当用户按下"是"按钮时才会发送报告
// @param title 警报标题
// @param message 向用户显示的消息
// @param yesAnswer 在"是"框中显示的文本
// @param noAnswer 在"否"框中显示的文本
- (void)addConditionalAlertWithTitle:(NSString *)title
                             message:(nullable NSString *)message
                           yesAnswer:(NSString *)yesAnswer
                            noAnswer:(nullable NSString *)noAnswer;

/** Show an alert before sending any reports. Reports will be unconditionally sent
 * when the alert is dismissed.
 *
 * @param title The alert title.
 * @param message The message to show the user.
 * @param dismissButtonText The text to display in the dismiss button.
 */
// 在发送任何报告之前显示警报。当警报被关闭时，报告将无条件发送
// @param title 警报标题
// @param message 向用户显示的消息
// @param dismissButtonText 在关闭按钮中显示的文本
- (void)addUnconditionalAlertWithTitle:(NSString *)title
                               message:(nullable NSString *)message
                     dismissButtonText:(NSString *)dismissButtonText;

/** Validates properties of installation.
 *
 * Intended to be overriden in subclasses to handle properties validation
 * in the installation logic (e.g. before sending crash reports).
 *
 * @param error Pointer to an error object to store validation error.
 * @return `NO` if there is a validation error.
 */
// 验证安装的属性
// 旨在在子类中重写，以处理安装逻辑中的属性验证（例如，在发送崩溃报告之前）
// @param error 指向错误对象的指针，用于存储验证错误
// @return 如果存在验证错误返回`NO`
- (BOOL)validateSetupWithError:(NSError **)error;

@end

// 结束非空假设
NS_ASSUME_NONNULL_END
