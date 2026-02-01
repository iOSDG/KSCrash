//
//  KSCrashInstallationStandard.h
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

// 导入Foundation框架，提供基础类（NSObject、NSURL等）
#import <Foundation/Foundation.h>

// 开始非空假设（在此范围内的指针默认非空，除非明确标记为nullable）
NS_ASSUME_NONNULL_BEGIN

// 标准崩溃安装类
// 通过HTTP POST请求将崩溃报告发送到指定URL
NS_SWIFT_NAME(CrashInstallationStandard)
@interface KSCrashInstallationStandard : KSCrashInstallation

// 共享单例实例（类属性，只读，原子性）
// 使用单例模式确保整个应用程序只有一个标准安装实例
@property(class, atomic, readonly) KSCrashInstallationStandard *sharedInstance NS_SWIFT_NAME(shared);

/** The URL to connect to. */
// 要连接到的URL（报告发送的目标地址）
// 此属性必须在调用installWithConfiguration:error:之前设置
@property(nonatomic, readwrite, strong) NSURL *url;

@end

// 结束非空假设
NS_ASSUME_NONNULL_END
