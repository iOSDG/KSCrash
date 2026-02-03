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
// 导入不公平锁头文件
#import "KSUnfairLock.h"
// 导入操作系统锁头文件
#import <os/lock.h>

// 不公平锁的私有接口扩展
@interface KSUnfairLock () {
    // 底层的不公平锁结构
    os_unfair_lock _lock;
}
@end

// 不公平锁实现
@implementation KSUnfairLock

// 初始化方法
- (instancetype)init
{
    // 调用父类初始化方法
    if ((self = [super init])) {
        // 初始化底层不公平锁为未锁定状态
        _lock = OS_UNFAIR_LOCK_INIT;
    }
    // 返回初始化后的实例
    return self;
}

// 获取锁：阻塞直到获取到锁为止
- (void)lock
{
    // 调用操作系统的不公平锁锁定函数
    os_unfair_lock_lock(&_lock);
}

// 释放锁：释放之前获取的锁
- (void)unlock
{
    // 调用操作系统的不公平锁解锁函数
    os_unfair_lock_unlock(&_lock);
}

// 在锁保护下执行代码块：自动获取和释放锁
// @param block 要在锁保护下执行的代码块
- (void)withLock:(dispatch_block_t)block
{
    // 获取锁
    os_unfair_lock_lock(&_lock);
    // 执行代码块
    block();
    // 释放锁
    os_unfair_lock_unlock(&_lock);
}

@end
