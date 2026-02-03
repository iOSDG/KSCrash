//
//  KSUnfairLock.h
//
//  Created by Alexander Cohen on 2025-12-07.
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

#ifdef __OBJC__

// 导入Foundation框架
#import <Foundation/Foundation.h>
// 导入命名空间头文件
#include "KSCrashNamespace.h"

/** 不公平锁类
 *  os_unfair_lock的Objective-C包装器，提供线程同步功能
 *  实现了NSLocking协议，可以在需要锁定的地方使用
 */
@interface KSUnfairLock : NSObject <NSLocking>

/** 获取锁
 *  阻塞直到获取到锁为止
 */
- (void)lock;

/** 释放锁
 *  释放之前获取的锁
 */
- (void)unlock;

/** 在锁保护下执行代码块
 *  @param block 要在锁保护下执行的代码块
 *  此方法会自动获取锁，执行代码块，然后释放锁
 */
- (void)withLock:(dispatch_block_t)block;

@end

#endif
