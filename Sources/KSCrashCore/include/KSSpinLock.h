//
//  KSSpinLock.h
//
//  Created by Alexander Cohen on 2025-12-29.
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

#ifndef HDR_KSSpinLock_h
#define HDR_KSSpinLock_h

// 导入标准原子操作头文件
#include <stdatomic.h>
// 导入标准布尔类型头文件
#include <stdbool.h>
// 导入标准整数类型头文件
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/** 简单的自旋锁实现
 *
 *  此锁是异步信号安全的，可以在崩溃处理程序中使用。
 *  它使用原子操作和CPU暂停指令来提高效率。
 *
 *  警告：自旋锁只应用于非常短的临界区。
 *  对于较长的操作，应使用适当的操作系统锁（pthread_mutex、os_unfair_lock）。
 *
 *  用法：
 *      static KSSpinLock lock = KSSPINLOCK_INIT;
 *
 *      ks_spinlock_lock(&lock);
 *      // 临界区
 *      ks_spinlock_unlock(&lock);
 */
typedef struct {
    // 原子类型的32位无符号整数，用于存储锁状态（0=未锁定，1=已锁定）
    _Atomic(uint32_t) _opaque;
} KSSpinLock;

/** KSSpinLock的静态初始化器 */
#ifndef KSSPINLOCK_INIT
#define KSSPINLOCK_INIT ((KSSpinLock) { 0 })
#endif

/** 初始化自旋锁
 *
 *  @param lock 要初始化的自旋锁
 */
void ks_spinlock_init(KSSpinLock *lock);

/** 获取自旋锁
 *
 *  此函数将自旋直到获取到锁为止。
 *
 *  @param lock 要获取的自旋锁
 */
void ks_spinlock_lock(KSSpinLock *lock);

/** 尝试获取自旋锁而不阻塞
 *
 *  @param lock 要尝试获取的自旋锁
 *  @return 如果成功获取锁则返回true，如果锁已被持有则返回false
 */
bool ks_spinlock_try_lock(KSSpinLock *lock);

/** 尝试获取自旋锁，在有限次数的迭代中自旋
 *
 *  @param lock 要尝试获取的自旋锁
 *  @param maxIterations 放弃前最大自旋迭代次数
 *  @return 如果成功获取锁则返回true，如果达到maxIterations则返回false
 */
bool ks_spinlock_try_lock_with_spin(KSSpinLock *lock, uint32_t maxIterations);

/** 使用有界自旋获取自旋锁
 *
 *  此函数将在放弃前自旋默认次数的迭代（约50,000次）。
 *  这在异步信号安全上下文中很有用，因为无限阻塞是不可接受的。
 *
 *  @param lock 要获取的自旋锁
 *  @return 如果成功获取锁则返回true，如果达到自旋限制则返回false
 */
bool ks_spinlock_lock_bounded(KSSpinLock *lock);

/** 释放自旋锁
 *
 *  @param lock 要释放的自旋锁
 */
void ks_spinlock_unlock(KSSpinLock *lock);

#ifdef __cplusplus
}
#endif

#endif /* HDR_KSSpinLock_h */
