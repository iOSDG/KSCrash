//
//  KSCrashReportFilterAlert.m
//
//  Created by Karl Stenerud on 2012-08-24.
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

// 导入警报过滤器头文件
#import "KSCrashReportFilterAlert.h"

// 导入崩溃报告协议
#import "KSCrashReport.h"
// 导入NSError辅助工具
#import "KSNSErrorHelper.h"
// 导入系统能力检测头文件
#import "KSSystemCapabilities.h"

// #define KSLogger_LocalLevel TRACE
// 导入日志工具
#import "KSLogger.h"

// 如果系统支持警报视图
#if KSCRASH_HAS_ALERTVIEW

// 如果系统支持UIKit框架
#if KSCRASH_HAS_UIKIT
// 导入UIKit框架（iOS）
#import <UIKit/UIKit.h>
#endif

// 如果系统支持NSAlert（macOS）
#if KSCRASH_HAS_NSALERT
// 导入AppKit框架（macOS）
#import <AppKit/AppKit.h>
#endif

// 警报视图处理过程类（用于管理警报显示和用户交互）
@interface KSCrashAlertViewProcess : NSObject

// 待处理的报告数组（只读，复制）
@property(nonatomic, readwrite, copy) NSArray<id<KSCrashReport>> *reports;
// 完成回调（只读，复制）
@property(nonatomic, readwrite, copy) KSCrashReportFilterCompletion onCompletion;
// 期望的按钮索引（只读，赋值）
@property(nonatomic, readwrite, assign) NSInteger expectedButtonIndex;

// 类方法：创建处理过程实例
+ (KSCrashAlertViewProcess *)process;

// 启动警报视图处理过程
// @param title 警报标题
// @param message 警报消息
// @param yesAnswer "是"按钮文本
// @param noAnswer "否"按钮文本（可为nil）
// @param reports 待处理的报告数组
// @param onCompletion 完成回调
- (void)startWithTitle:(NSString *)title
               message:(NSString *)message
             yesAnswer:(NSString *)yesAnswer
              noAnswer:(NSString *)noAnswer
               reports:(NSArray<id<KSCrashReport>> *)reports
          onCompletion:(KSCrashReportFilterCompletion)onCompletion;

@end

// 警报视图处理过程实现
@implementation KSCrashAlertViewProcess

// 类方法：创建处理过程实例
// @return 新创建的处理过程实例
+ (KSCrashAlertViewProcess *)process
{
    // 创建并返回新实例
    return [[self alloc] init];
}

// 如果系统支持UIAlertController（iOS 8+）
#if KSCRASH_HAS_UIALERTCONTROLLER
// 忽略废弃声明警告（因为某些API在不同iOS版本中已废弃）
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
// 获取当前关键窗口的辅助函数
// @return 当前关键窗口，如果不存在则返回nil
static UIWindow *getKeyWindow(void)
{
    // 如果系统版本为iOS 15或tvOS 15及以上
    if (@available(iOS 15, tvOS 15, *)) {
        // 遍历所有连接的窗口场景
        for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
            // 如果场景有关键窗口，返回它
            if (scene.keyWindow != nil) {
                return scene.keyWindow;
            }
        }
    } else {
        // iOS 15以下版本，遍历应用程序的所有窗口
        for (UIWindow *window in UIApplication.sharedApplication.windows) {
            // 如果窗口是关键窗口，返回它
            if (window.keyWindow) {
                return window;
            }
        }
    }
    // 未找到关键窗口，返回nil
    return nil;
}
// 恢复警告设置
#pragma clang diagnostic pop
#endif

// 启动警报视图处理过程
// @param title 警报标题
// @param message 警报消息
// @param yesAnswer "是"按钮文本
// @param noAnswer "否"按钮文本（可为nil）
// @param reports 待处理的报告数组
// @param onCompletion 完成回调
- (void)startWithTitle:(NSString *)title
               message:(NSString *)message
             yesAnswer:(NSString *)yesAnswer
              noAnswer:(NSString *)noAnswer
               reports:(NSArray<id<KSCrashReport>> *)reports
          onCompletion:(KSCrashReportFilterCompletion)onCompletion
{
    // 记录跟踪日志：开始警报视图处理过程
    KSLOG_TRACE(@"Starting alert view process");
    // 复制报告数组并保存
    _reports = [reports copy];
    // 复制完成回调并保存
    _onCompletion = [onCompletion copy];
    // 计算期望的按钮索引：如果没有"否"按钮，期望索引为0（"是"按钮），否则为1（"否"按钮）
    _expectedButtonIndex = noAnswer == nil ? 0 : 1;

    // 在无头测试环境中运行时，UIApplication可能不存在
    if (!NSClassFromString(@"UIApplication")) {
        // 如果UIApplication不存在，直接调用完成回调，传递报告（无错误）
        kscrash_callCompletion(self.onCompletion, self.reports, nil);
        // 提前返回
        return;
    }

// 如果系统支持UIAlertController（iOS 8+）
#if KSCRASH_HAS_UIALERTCONTROLLER
    // 创建警报控制器，使用指定的标题和消息，样式为警报
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    // 创建"是"按钮动作，样式为默认，点击时调用完成回调（无错误）
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:yesAnswer
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(__unused UIAlertAction *_Nonnull action) {
                                                          // 用户点击"是"按钮，调用完成回调，传递报告（无错误）
                                                          kscrash_callCompletion(self.onCompletion, self.reports, nil);
                                                      }];
    // 创建"否"按钮动作，样式为取消，点击时调用完成回调（带取消错误）
    UIAlertAction *noAction = [UIAlertAction
        actionWithTitle:noAnswer
                  style:UIAlertActionStyleCancel
                handler:^(__unused UIAlertAction *_Nonnull action) {
                    // 用户点击"否"按钮，调用完成回调，传递报告和取消错误
                    kscrash_callCompletion(self.onCompletion, self.reports, [[self class] cancellationError]);
                }];
    // 将"是"按钮添加到警报控制器
    [alertController addAction:yesAction];
    // 将"否"按钮添加到警报控制器
    [alertController addAction:noAction];
    // 获取当前关键窗口
    UIWindow *keyWindow = getKeyWindow();
    // 在关键窗口的根视图控制器上显示警报控制器，带动画
    [keyWindow.rootViewController presentViewController:alertController animated:YES completion:NULL];
// 如果系统支持NSAlert（macOS）
#elif KSCRASH_HAS_NSALERT
    // 创建NSAlert实例
    NSAlert *alert = [[NSAlert alloc] init];
    // 添加"是"按钮
    [alert addButtonWithTitle:yesAnswer];
    // 如果提供了"否"按钮文本，添加"否"按钮
    if (noAnswer != nil) {
        [alert addButtonWithTitle:noAnswer];
    }
    // 设置警报消息文本（标题）
    [alert setMessageText:title];
    // 设置警报信息文本（消息内容）
    [alert setInformativeText:message];
    // 设置警报样式为信息样式
    [alert setAlertStyle:NSAlertStyleInformational];

    // 以模态方式运行警报，等待用户响应
    NSModalResponse response = [alert runModal];
    // 错误对象，初始为nil
    NSError *error = nil;
    // 如果提供了"否"按钮且用户点击了第二个按钮（"否"按钮）
    if (noAnswer != nil && response == NSAlertSecondButtonReturn) {
        // 创建取消错误
        error = [[self class] cancellationError];
    }
    // 调用完成回调，传递报告和错误（如果有）
    kscrash_callCompletion(self.onCompletion, self.reports, error);
#endif
}

// 类方法：创建取消错误
// @return 表示用户取消的NSError对象
+ (NSError *)cancellationError
{
    // 使用NSError辅助工具创建错误，域为类描述，代码为0，描述为"用户取消"
    return [KSNSErrorHelper errorWithDomain:[[self class] description] code:0 description:@"Cancelled by user"];
}

// 警报视图代理方法：用户点击按钮时调用（已废弃，保留用于兼容）
// @param alertView 警报视图
// @param buttonIndex 被点击的按钮索引
- (void)alertView:(__unused id)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // 检查点击的按钮索引是否与期望的索引相同
    BOOL success = buttonIndex == self.expectedButtonIndex;
    // 如果成功（点击了期望的按钮），调用完成回调（无错误），否则传递取消错误
    kscrash_callCompletion(self.onCompletion, self.reports, success ? nil : [[self class] cancellationError]);
}

@end

// 警报过滤器的私有接口扩展
@interface KSCrashReportFilterAlert ()

// 警报标题（只读，复制）
@property(nonatomic, readwrite, copy) NSString *title;
// 警报消息（只读，复制）
@property(nonatomic, readwrite, copy) NSString *message;
// "是"按钮文本（只读，复制）
@property(nonatomic, readwrite, copy) NSString *yesAnswer;
// "否"按钮文本（只读，复制，可为nil）
@property(nonatomic, readwrite, copy) NSString *noAnswer;

@end

// 警报过滤器实现
@implementation KSCrashReportFilterAlert

// 初始化警报过滤器
// @param title 警报标题
// @param message 警报消息（可为nil）
// @param yesAnswer "是"按钮文本
// @param noAnswer "否"按钮文本（可为nil，如果为nil则无条件继续）
// @return 初始化后的实例
- (instancetype)initWithTitle:(NSString *)title
                      message:(nullable NSString *)message
                    yesAnswer:(NSString *)yesAnswer
                     noAnswer:(nullable NSString *)noAnswer
{
    // 调用父类初始化方法
    if ((self = [super init])) {
        // 复制并保存标题
        _title = [title copy];
        // 复制并保存消息
        _message = [message copy];
        // 复制并保存"是"按钮文本
        _yesAnswer = [yesAnswer copy];
        // 复制并保存"否"按钮文本
        _noAnswer = [noAnswer copy];
    }
    // 返回初始化后的实例
    return self;
}

// 过滤报告：显示警报并等待用户响应
// @param reports 待过滤的报告数组
// @param onCompletion 完成回调，返回报告数组或错误
- (void)filterReports:(NSArray<id<KSCrashReport>> *)reports onCompletion:(KSCrashReportFilterCompletion)onCompletion
{
    // 在主队列上异步执行（UI操作必须在主线程）
    dispatch_async(dispatch_get_main_queue(), ^{
        // 记录跟踪日志：启动新的警报视图处理过程
        KSLOG_TRACE(@"Launching new alert view process");
        // 创建警报视图处理过程实例（使用__block修饰以便在块中修改）
        __block KSCrashAlertViewProcess *process = [[KSCrashAlertViewProcess alloc] init];
        // 启动处理过程，传递所有参数
        [process startWithTitle:self.title
                        message:self.message
                      yesAnswer:self.yesAnswer
                       noAnswer:self.noAnswer
                        reports:reports
                   onCompletion:^(NSArray *filteredReports, NSError *error) {
                       // 记录跟踪日志：警报处理过程完成
                       KSLOG_TRACE(@"alert process complete");
                       // 调用外部完成回调，传递过滤后的报告和错误
                       kscrash_callCompletion(onCompletion, filteredReports, error);
                       // 在主队列上异步执行，释放处理过程实例
                       dispatch_async(dispatch_get_main_queue(), ^{
                           // 将处理过程实例置为nil，释放内存
                           process = nil;
                       });
                   }];
    });
}

@end

// 如果系统不支持警报视图
#else

// 警报过滤器实现（不支持警报的平台）
@implementation KSCrashReportFilterAlert

// 类方法：创建警报过滤器（便利构造器）
// @param title 警报标题
// @param message 警报消息
// @param yesAnswer "是"按钮文本
// @param noAnswer "否"按钮文本
// @return 新创建的实例
+ (KSCrashReportFilterAlert *)filterWithTitle:(NSString *)title
                                      message:(NSString *)message
                                    yesAnswer:(NSString *)yesAnswer
                                     noAnswer:(NSString *)noAnswer
{
    // 调用指定初始化方法创建实例
    return [[self alloc] initWithTitle:title message:message yesAnswer:yesAnswer noAnswer:noAnswer];
}

// 初始化警报过滤器（不支持警报的平台）
// @param title 警报标题（未使用）
// @param message 警报消息（未使用）
// @param yesAnswer "是"按钮文本（未使用）
// @param noAnswer "否"按钮文本（未使用）
// @return 初始化后的实例
- (id)initWithTitle:(__unused NSString *)title
            message:(__unused NSString *)message
          yesAnswer:(__unused NSString *)yesAnswer
           noAnswer:(__unused NSString *)noAnswer
{
    // 调用父类初始化方法
    if ((self = [super init])) {
        // 记录警告日志：此平台不支持警报过滤器
        KSLOG_WARN(@"Alert filter not available on this platform.");
    }
    // 返回初始化后的实例
    return self;
}

// 过滤报告：在不支持警报的平台上直接通过报告
// @param reports 待过滤的报告数组
// @param onCompletion 完成回调
- (void)filterReports:(NSArray<id<KSCrashReport>> *)reports onCompletion:(KSCrashReportFilterCompletion)onCompletion
{
    // 记录警告日志：此平台不支持警报过滤器
    KSLOG_WARN(@"Alert filter not available on this platform.");
    // 直接调用完成回调，传递原始报告（无错误）
    kscrash_callCompletion(onCompletion, reports, nil);
}

@end

#endif
