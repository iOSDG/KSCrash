//
//  KSCrashReportFilterAlert.h
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

// 导入Foundation框架
#import <Foundation/Foundation.h>
// 导入命名空间头文件
#include "KSCrashNamespace.h"
// 导入崩溃报告过滤器协议
#import "KSCrashReportFilter.h"

NS_ASSUME_NONNULL_BEGIN

/** 弹出标准警报窗口并在继续之前等待用户响应的过滤器
 *
 * 此过滤器可以设置为条件或无条件过滤器。如果同时定义了"是"和"否"按钮，
 * 则只有在用户按下"是"按钮时才会继续。如果只定义了"是"按钮（"否"按钮为nil），
 * 则在警报被关闭时将无条件继续。
 *
 * 输入: 任意类型
 * 输出: 与输入相同（透传）
 */
NS_SWIFT_NAME(CrashReportFilterAlert)
@interface KSCrashReportFilterAlert : NSObject <KSCrashReportFilter>

// 禁止使用init方法
- (instancetype)init NS_UNAVAILABLE;
// 禁止使用new方法
+ (instancetype)new NS_UNAVAILABLE;

/**
 * 初始化警报过滤器
 * @param title 警报标题
 * @param message 警报内容（可为nil）
 * @param yesAnswer "是"按钮的文本
 * @param noAnswer "否"按钮的文本。如果为nil，过滤器将无条件继续
 */
- (instancetype)initWithTitle:(NSString *)title
                      message:(nullable NSString *)message
                    yesAnswer:(NSString *)yesAnswer
                     noAnswer:(nullable NSString *)noAnswer;

@end

NS_ASSUME_NONNULL_END
