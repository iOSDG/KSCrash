//
//  KSCrashInstallationConsole.h
//  KSCrash-iOS
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

// 导入Foundation框架，提供基础类（NSObject等）
#import <Foundation/Foundation.h>

// 开始非空假设（在此范围内的指针默认非空，除非明确标记为nullable）
NS_ASSUME_NONNULL_BEGIN

/** Prints all reports to the console.
 * This class is intended for testing purposes.
 */
// 将所有报告打印到控制台
// 此类用于测试目的（在开发调试时查看崩溃报告）
NS_SWIFT_NAME(CrashInstallationConsole)
@interface KSCrashInstallationConsole : KSCrashInstallation

// 是否打印Apple格式（YES = Apple格式，NO = JSON格式）
// 如果为YES，报告将以Apple格式（类似Xcode崩溃报告）输出
// 如果为NO，报告将以JSON格式（美化并按键排序）输出
@property(nonatomic, readwrite) BOOL printAppleFormat;

// 共享单例实例（类属性，只读，原子性）
// 使用单例模式确保整个应用程序只有一个控制台安装实例
@property(class, atomic, readonly) KSCrashInstallationConsole *sharedInstance NS_SWIFT_NAME(shared);

@end

// 结束非空假设
NS_ASSUME_NONNULL_END
