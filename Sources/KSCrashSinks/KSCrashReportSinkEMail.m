//
//  KSCrashReportSinkEMail.m
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

// 导入邮件报告输出目标头文件，包含类接口声明
#import "KSCrashReportSinkEMail.h"

// 导入崩溃报告协议，定义报告接口
#import "KSCrashReport.h"
// 导入Apple格式过滤器，用于将报告转换为Apple格式
#import "KSCrashReportFilterAppleFmt.h"
// 导入基础过滤器，提供过滤器管道等功能
#import "KSCrashReportFilterBasic.h"
// 导入GZip压缩过滤器，用于压缩报告数据
#import "KSCrashReportFilterGZip.h"
// 导入JSON过滤器，用于JSON编码
#import "KSCrashReportFilterJSON.h"
// 导入NSError辅助工具，用于创建和操作错误对象
#import "KSNSErrorHelper.h"
// 导入系统能力检测，用于检测是否支持MessageUI
#import "KSSystemCapabilities.h"

// #define KSLogger_LocalLevel TRACE
// 导入日志记录工具
#import "KSLogger.h"

#if KSCRASH_HAS_MESSAGEUI
// 如果支持MessageUI框架，导入MessageUI框架（用于发送邮件）
#import <MessageUI/MessageUI.h>

// 定义KSCrashMailProcess类
// 用于管理邮件发送过程，处理邮件控制器的显示和隐藏
@interface KSCrashMailProcess : NSObject <MFMailComposeViewControllerDelegate>

// 要发送的报告数组（可读写，复制）
@property(nonatomic, readwrite, copy) NSArray<id<KSCrashReport>> *reports;
// 完成回调（可读写，复制）
@property(nonatomic, readwrite, copy) KSCrashReportFilterCompletion onCompletion;

// 虚拟视图控制器（用于显示邮件控制器，可读写）
@property(nonatomic, readwrite, strong) UIViewController *dummyVC;

// 类方法：创建邮件处理对象
+ (KSCrashMailProcess *)process;

// 开始邮件发送过程
// controller: 邮件编写视图控制器
// reports: 要发送的报告数组
// filenameFmt: 文件名格式（用于附件命名）
// onCompletion: 完成回调
- (void)startWithController:(MFMailComposeViewController *)controller
                    reports:(NSArray<id<KSCrashReport>> *)reports
                filenameFmt:(NSString *)filenameFmt
               onCompletion:(KSCrashReportFilterCompletion)onCompletion;

// 显示模态视图控制器
// vc: 要显示的视图控制器
- (void)presentModalVC:(UIViewController *)vc;
// 隐藏模态视图控制器
- (void)dismissModalVC;

@end

// 实现KSCrashMailProcess类
@implementation KSCrashMailProcess

// 类方法：创建邮件处理对象
// 返回新创建的邮件处理对象
+ (KSCrashMailProcess *)process
{
    // 创建并返回新实例
    return [[self alloc] init];
}

// 开始邮件发送过程
// controller: 邮件编写视图控制器（已配置好收件人、主题等）
// reports: 要发送的报告数组（应该是KSCrashReportData类型）
// filenameFmt: 文件名格式（用于附件命名，可以使用"%d"作为报告编号占位符）
// onCompletion: 完成回调（在邮件发送完成后调用）
- (void)startWithController:(MFMailComposeViewController *)controller
                    reports:(NSArray<id<KSCrashReport>> *)reports
                filenameFmt:(NSString *)filenameFmt
               onCompletion:(KSCrashReportFilterCompletion)onCompletion
{
    // 保存报告数组（使用copy确保不可变）
    self.reports = [reports copy];
    // 保存完成回调
    self.onCompletion = onCompletion;

    // 设置邮件控制器的代理（用于接收邮件发送结果）
    controller.mailComposeDelegate = self;

    // 初始化报告计数器（从1开始）
    int i = 1;
    // 遍历所有报告，添加为邮件附件
    for (KSCrashReportData *report in reports) {
        // 检查报告类型是否为数据类型且值不为nil
        if ([report isKindOfClass:[KSCrashReportData class]] == NO || report.value == nil) {
            // 报告类型不正确或值为nil，记录错误日志并跳过
            KSLOG_ERROR(@"Unexpected non-data report: %@", report);
            continue;
        }
        // 将报告数据添加为邮件附件
        // report.value: 报告数据（NSData，通常是GZip压缩的数据）
        // mimeType: MIME类型（"binary"表示二进制数据）
        // fileName: 文件名（使用filenameFmt格式化，%d会被替换为报告编号）
        [controller addAttachmentData:report.value
                             mimeType:@"binary"
                             fileName:[NSString stringWithFormat:filenameFmt, i++]];
    }

    // 显示邮件控制器（模态显示）
    [self presentModalVC:controller];
}

// 邮件编写控制器完成时的回调（MFMailComposeViewControllerDelegate协议方法）
// mailController: 邮件编写视图控制器（未使用）
// result: 邮件发送结果（已发送、已保存、已取消、失败）
// error: 错误信息（如果发送失败）
- (void)mailComposeController:(__unused MFMailComposeViewController *)mailController
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    // 隐藏邮件控制器（模态隐藏）
    [self dismissModalVC];

    // 根据邮件发送结果处理
    switch (result) {
        case MFMailComposeResultSent:
            // 邮件已发送，调用完成回调并传入nil错误（表示成功）
            kscrash_callCompletion(self.onCompletion, self.reports, nil);
            break;
        case MFMailComposeResultSaved:
            // 邮件已保存到草稿箱，调用完成回调并传入nil错误（表示成功）
            kscrash_callCompletion(self.onCompletion, self.reports, nil);
            break;
        case MFMailComposeResultCancelled:
            // 用户取消了邮件发送，调用完成回调并传入取消错误
            kscrash_callCompletion(self.onCompletion, self.reports,
                                   [KSNSErrorHelper errorWithDomain:[[self class] description]
                                                               code:0
                                                        description:@"User cancelled"]);
            break;
        case MFMailComposeResultFailed:
            // 邮件发送失败，调用完成回调并传入错误信息
            kscrash_callCompletion(self.onCompletion, self.reports, error);
            break;
        default: {
            // 未知的邮件发送结果，调用完成回调并传入未知错误
            kscrash_callCompletion(self.onCompletion, self.reports,
                                   [KSNSErrorHelper errorWithDomain:[[self class] description]
                                                               code:0
                                                        description:@"Unknown MFMailComposeResult: %d", result]);
        }
    }
}

// 显示模态视图控制器
// vc: 要显示的视图控制器（邮件编写视图控制器）
- (void)presentModalVC:(UIViewController *)vc
{
    // 创建虚拟视图控制器（用于显示邮件控制器）
    self.dummyVC = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    // 创建虚拟视图（空视图，用于添加到窗口）
    self.dummyVC.view = [[UIView alloc] init];

    // 获取应用程序的主窗口（通过应用程序代理获取）
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    // 将虚拟视图添加到窗口（使虚拟视图控制器成为窗口的一部分）
    [window addSubview:self.dummyVC.view];

    // 检查是否支持新的视图控制器呈现方法（iOS 5.0+）
    if ([self.dummyVC respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        // 支持新方法，使用新方法显示视图控制器（推荐方式）
        [self.dummyVC presentViewController:vc animated:YES completion:nil];
    } else {
        // 不支持新方法，使用旧方法显示视图控制器（iOS 4.x兼容）
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self.dummyVC presentModalViewController:vc animated:YES];
#pragma clang diagnostic pop
    }
}

// 隐藏模态视图控制器
- (void)dismissModalVC
{
    // 检查是否支持新的视图控制器隐藏方法（iOS 5.0+）
    if ([self.dummyVC respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        // 支持新方法，使用新方法隐藏视图控制器（推荐方式）
        [self.dummyVC dismissViewControllerAnimated:YES
                                         completion:^{
                                             // 隐藏完成后，从窗口中移除虚拟视图
                                             [self.dummyVC.view removeFromSuperview];
                                             // 清除虚拟视图控制器引用
                                             self.dummyVC = nil;
                                         }];
    } else {
        // 不支持新方法，使用旧方法隐藏视图控制器（iOS 4.x兼容）
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self.dummyVC dismissModalViewControllerAnimated:NO];
#pragma clang diagnostic pop
        // 从窗口中移除虚拟视图
        [self.dummyVC.view removeFromSuperview];
        // 清除虚拟视图控制器引用
        self.dummyVC = nil;
    }
}

@end

// 定义KSCrashReportSinkEMail类的私有扩展
@interface KSCrashReportSinkEMail ()

// 收件人列表（可读写，复制）
@property(nonatomic, readwrite, copy) NSArray *recipients;
// 邮件主题（可读写，复制）
@property(nonatomic, readwrite, copy) NSString *subject;
// 邮件消息（可读写，复制，可选）
@property(nonatomic, readwrite, copy) NSString *message;
// 文件名格式（可读写，复制）
@property(nonatomic, readwrite, copy) NSString *filenameFmt;

@end

// 实现KSCrashReportSinkEMail类
// 这是邮件报告输出目标，通过邮件将崩溃报告发送给指定收件人
@implementation KSCrashReportSinkEMail

// 使用指定参数初始化邮件报告输出目标
// recipients: 收件人列表（至少需要一个收件人）
// subject: 邮件主题
// message: 邮件消息（可选，可以为nil）
// filenameFmt: 文件名格式（用于附件命名，可以使用"%d"作为报告编号占位符）
// 返回初始化后的实例
- (instancetype)initWithRecipients:(NSArray<NSString *> *)recipients
                           subject:(NSString *)subject
                           message:(nullable NSString *)message
                       filenameFmt:(NSString *)filenameFmt
{
    // 调用父类初始化方法
    if ((self = [super init])) {
        // 保存收件人列表（使用copy确保不可变）
        _recipients = [recipients copy];
        // 保存邮件主题（使用copy确保不可变）
        _subject = [subject copy];
        // 保存邮件消息（使用copy确保不可变，可能为nil）
        _message = [message copy];
        // 保存文件名格式（使用copy确保不可变）
        _filenameFmt = [filenameFmt copy];
    }
    // 返回初始化后的实例
    return self;
}

// 返回默认的崩溃报告过滤器集合（JSON格式）
// 包含JSON编码过滤器、GZip压缩过滤器和此Sink本身
- (id<KSCrashReportFilter>)defaultCrashReportFilterSet
{
    // 创建过滤器管道（JSON编码 -> GZip压缩 -> 邮件Sink）
    return [[KSCrashReportFilterPipeline alloc] initWithFilters:@[
        // JSON编码过滤器（按键排序并美化输出）
        [[KSCrashReportFilterJSONEncode alloc] initWithOptions:KSJSONEncodeOptionSorted | KSJSONEncodeOptionPretty],
        // GZip压缩过滤器（压缩级别-1表示使用默认压缩级别）
        [[KSCrashReportFilterGZipCompress alloc] initWithCompressionLevel:-1],
        // 邮件Sink（将压缩后的数据作为附件发送）
        self,
    ]];
}

// 返回默认的崩溃报告过滤器集合（Apple格式）
// 包含Apple格式过滤器、字符串转数据过滤器、GZip压缩过滤器和此Sink本身
- (id<KSCrashReportFilter>)defaultCrashReportFilterSetAppleFmt
{
    // 创建过滤器管道（Apple格式转换 -> 字符串转数据 -> GZip压缩 -> 邮件Sink）
    return [[KSCrashReportFilterPipeline alloc] initWithFilters:@[
        // Apple格式过滤器（符号化并并排显示样式，类似Xcode崩溃报告）
        [[KSCrashReportFilterAppleFmt alloc] initWithReportStyle:KSAppleReportStyleSymbolicatedSideBySide],
        // 字符串转数据过滤器（将Apple格式字符串转换为NSData）
        [KSCrashReportFilterStringToData new],
        // GZip压缩过滤器（压缩级别-1表示使用默认压缩级别）
        [[KSCrashReportFilterGZipCompress alloc] initWithCompressionLevel:-1],
        // 邮件Sink（将压缩后的数据作为附件发送）
        self,
    ]];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
// 获取应用程序的主窗口（辅助函数）
// 返回主窗口，如果无法获取则返回nil
static UIWindow *getKeyWindow(void)
{
    // 检查是否支持iOS 15+的窗口场景API
    if (@available(iOS 15, tvOS 15, *)) {
        // 支持新API，遍历所有连接的窗口场景
        for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
            // 检查场景是否有主窗口
            if (scene.keyWindow != nil) {
                // 找到主窗口，返回它
                return scene.keyWindow;
            }
        }
    } else {
        // 不支持新API，使用旧API遍历所有窗口
        for (UIWindow *window in UIApplication.sharedApplication.windows) {
            // 检查窗口是否是主窗口
            if (window.keyWindow) {
                // 找到主窗口，返回它
                return window;
            }
        }
    }
    // 未找到主窗口，返回nil
    return nil;
}
#pragma clang diagnostic pop

// 过滤并发送报告（实现KSCrashReportFilter协议）
// 通过邮件发送报告
// reports: 要发送的报告数组（应该是KSCrashReportData类型，GZip压缩的数据）
// onCompletion: 完成回调，在发送完成后调用，传入报告和错误信息
- (void)filterReports:(NSArray<id<KSCrashReport>> *)reports onCompletion:(KSCrashReportFilterCompletion)onCompletion
{
    // 检查设备是否可以发送邮件
    if (![MFMailComposeViewController canSendMail]) {
        // 设备无法发送邮件，显示错误提示
        // 创建警报控制器
        UIAlertController *alertController =
            [UIAlertController alertControllerWithTitle:@"Email Error"
                                                message:@"This device is not configured to send email."
                                         preferredStyle:UIAlertControllerStyleAlert];
        // 创建确认按钮
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        // 添加确认按钮到警报控制器
        [alertController addAction:okAction];
        // 获取主窗口
        UIWindow *keyWindow = getKeyWindow();
        // 在主窗口的根视图控制器上显示警报
        [keyWindow.rootViewController presentViewController:alertController animated:YES completion:NULL];

        // 调用完成回调并传入错误信息（设备未配置邮件）
        kscrash_callCompletion(onCompletion, reports,
                               [KSNSErrorHelper errorWithDomain:[[self class] description]
                                                           code:0
                                                    description:@"E-Mail not enabled on device"]);
        // 设备无法发送邮件，直接返回
        return;
    }

    // 设备可以发送邮件，创建邮件编写视图控制器
    MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
    // 设置收件人列表
    [mailController setToRecipients:self.recipients];
    // 设置邮件主题
    [mailController setSubject:self.subject];
    // 检查是否有邮件消息
    if (self.message != nil) {
        // 有消息，设置邮件正文（isHTML:NO表示纯文本）
        [mailController setMessageBody:self.message isHTML:NO];
    }
    // 保存文件名格式（用于后续添加附件）
    NSString *filenameFmt = self.filenameFmt;

    // 在主队列异步执行（确保UI操作在主线程）
    dispatch_async(dispatch_get_main_queue(), ^{
        // 创建邮件处理对象（使用__block修饰符，允许在block中修改）
        __block KSCrashMailProcess *process = [[KSCrashMailProcess alloc] init];
        // 开始邮件发送过程
        [process startWithController:mailController
                             reports:reports
                         filenameFmt:filenameFmt
                        onCompletion:^(NSArray *filteredReports, NSError *error) {
                            // 邮件发送完成，调用完成回调
                            kscrash_callCompletion(onCompletion, filteredReports, error);
                            // 在主队列异步清除邮件处理对象（延迟释放，确保UI操作完成）
                            dispatch_async(dispatch_get_main_queue(), ^{
                                process = nil;
                            });
                        }];
    });
}

@end

#else
// 如果不支持MessageUI框架（如macOS等平台），提供降级实现

// 导入NSError辅助工具，用于创建和操作错误对象
#import "KSNSErrorHelper.h"

// 实现KSCrashReportSinkEMail类（不支持MessageUI的降级实现）
@implementation KSCrashReportSinkEMail

// 类方法：使用指定参数创建邮件报告输出目标
// recipients: 收件人列表（未使用）
// subject: 邮件主题（未使用）
// message: 邮件消息（未使用）
// filenameFmt: 文件名格式（未使用）
// 返回新创建的实例
+ (KSCrashReportSinkEMail *)sinkWithRecipients:(NSArray *)recipients
                                       subject:(NSString *)subject
                                       message:(NSString *)message
                                   filenameFmt:(NSString *)filenameFmt
{
    // 调用初始化方法创建实例
    return [[self alloc] initWithRecipients:recipients subject:subject message:message filenameFmt:filenameFmt];
}

// 初始化方法（降级实现，不支持MessageUI的平台）
// recipients: 收件人列表（未使用，标记为__unused避免警告）
// subject: 邮件主题（未使用，标记为__unused避免警告）
// message: 邮件消息（未使用，标记为__unused避免警告）
// filenameFmt: 文件名格式（未使用，标记为__unused避免警告）
// 返回初始化后的实例
- (id)initWithRecipients:(__unused NSArray *)recipients
                 subject:(__unused NSString *)subject
                 message:(__unused NSString *)message
             filenameFmt:(__unused NSString *)filenameFmt
{
    // 只调用父类初始化方法（不保存任何参数，因为此平台不支持邮件发送）
    return [super init];
}

// 过滤并发送报告（降级实现）
// 在不支持MessageUI的平台上，只打印报告到控制台并返回错误
// reports: 要发送的报告数组
// onCompletion: 完成回调，在完成后调用，传入报告和错误信息
- (void)filterReports:(NSArray<id<KSCrashReport>> *)reports onCompletion:(KSCrashReportFilterCompletion)onCompletion
{
    // 遍历所有报告，打印到控制台（用于调试）
    for (id<KSCrashReport> report in reports) {
        // 使用NSLog打印报告（此平台不支持邮件发送，只能打印）
        NSLog(@"Report\n%@", report);
    }
    // 调用完成回调并传入错误信息（此平台无法发送邮件）
    kscrash_callCompletion(onCompletion, reports,
                           [KSNSErrorHelper errorWithDomain:[[self class] description]
                                                       code:0
                                                description:@"Cannot send mail on this platform"]);
}

// 返回默认的崩溃报告过滤器集合（JSON格式）
// 即使不支持邮件发送，也提供过滤器集合（用于兼容性）
- (id<KSCrashReportFilter>)defaultCrashReportFilterSet
{
    // 创建过滤器管道（JSON编码 -> GZip压缩 -> 邮件Sink）
    // 注意：虽然此平台不支持邮件发送，但过滤器集合仍然有效（会打印到控制台）
    return [[KSCrashReportFilterPipeline alloc] initWithFilters:@[
        // JSON编码过滤器（按键排序并美化输出）
        [[KSCrashReportFilterJSONEncode alloc] initWithOptions:KSJSONEncodeOptionSorted | KSJSONEncodeOptionPretty],
        // GZip压缩过滤器（压缩级别-1表示使用默认压缩级别）
        [[KSCrashReportFilterGZipCompress alloc] initWithCompressionLevel:-1],
        // 邮件Sink（在此平台上会打印到控制台）
        self,
    ]];
}

// 返回默认的崩溃报告过滤器集合（Apple格式）
// 即使不支持邮件发送，也提供过滤器集合（用于兼容性）
- (id<KSCrashReportFilter>)defaultCrashReportFilterSetAppleFmt
{
    // 创建过滤器管道（Apple格式转换 -> 字符串转数据 -> GZip压缩 -> 邮件Sink）
    // 注意：虽然此平台不支持邮件发送，但过滤器集合仍然有效（会打印到控制台）
    return [[KSCrashReportFilterPipeline alloc] initWithFilters:@[
        // Apple格式过滤器（符号化并并排显示样式）
        [[KSCrashReportFilterAppleFmt alloc] initWithReportStyle:KSAppleReportStyleSymbolicatedSideBySide],
        // 字符串转数据过滤器（将Apple格式字符串转换为NSData）
        [KSCrashReportFilterStringToData new],
        // GZip压缩过滤器（压缩级别-1表示使用默认压缩级别）
        [[KSCrashReportFilterGZipCompress alloc] initWithCompressionLevel:-1],
        // 邮件Sink（在此平台上会打印到控制台）
        self,
    ]];
}

@end

#endif
