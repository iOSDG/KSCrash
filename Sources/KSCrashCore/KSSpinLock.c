//
//  KSSpinLock.c
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

// 导入自旋锁头文件
#include "KSSpinLock.h"

// 导入标准原子操作头文件
#include <stdatomic.h>

// ============================================================================
#pragma mark - CPU Pause -
// ============================================================================

/** CPU暂停/让出提示，用于自旋等待循环
 *
 *  这比忙自旋更高效，因为：
 *  - 减少自旋期间的功耗
 *  - 在超线程CPU上提高性能
 *  - 是异步信号安全的（只是一个CPU指令）
 *
 *  内存破坏子（memory clobber）充当编译器屏障，防止
 *  编译器在此点重新排序或缓存内存访问
 */
static inline void ks_cpu_pause(void)
{
// 如果是x86_64或i386架构
#if defined(__x86_64__) || defined(__i386__)
    // 使用pause指令（x86架构的CPU暂停提示）
    __asm__ volatile("pause" ::: "memory");
// 如果是ARM64、AArch64或ARM架构
#elif defined(__arm64__) || defined(__aarch64__) || defined(__arm__)
    // 使用yield指令（ARM架构的CPU让出提示）
    __asm__ volatile("yield" ::: "memory");
// 其他架构
#else
    // 使用空的内联汇编作为编译器屏障
    __asm__ volatile("" ::: "memory");
#endif
}

// ============================================================================
#pragma mark - Constants -
// ============================================================================

/** 有界锁获取的默认最大自旋迭代次数
 *  在3GHz CPU上，每次迭代约50-150个周期，这给出约1-2.5ms的自旋时间
 */
static const uint32_t kSpinLockBoundedMaxIterations = 50000;

// ============================================================================
#pragma mark - API -
// ============================================================================

// 初始化自旋锁：将锁状态设置为0（未锁定），使用宽松内存顺序
void ks_spinlock_init(KSSpinLock *lock) { atomic_store_explicit(&lock->_opaque, 0, memory_order_relaxed); }

// 获取自旋锁：自旋直到成功获取锁
void ks_spinlock_lock(KSSpinLock *lock)
{
    // 无限循环，直到成功获取锁
    for (;;) {
        // TTAS（Test-Test-And-Set）策略：首先使用宽松读取自旋（缓存友好，无失效）
        while (atomic_load_explicit(&lock->_opaque, memory_order_relaxed) != 0) {
            // 如果锁被持有，执行CPU暂停提示
            ks_cpu_pause();
        }
        // 只有当锁看起来空闲时才尝试交换
        // 使用获取内存顺序，确保后续操作不会重排序到此之前
        if (atomic_exchange_explicit(&lock->_opaque, 1, memory_order_acquire) == 0) {
            // 成功获取锁，返回
            return;
        }
    }
}

// 尝试获取自旋锁而不阻塞：立即尝试一次，不进行自旋
bool ks_spinlock_try_lock(KSSpinLock *lock)
{
    // 尝试原子交换：如果锁为0则设置为1，返回旧值
    // 如果旧值为0，说明成功获取锁，返回true；否则返回false
    return atomic_exchange_explicit(&lock->_opaque, 1, memory_order_acquire) == 0;
}

// 尝试获取自旋锁，在有限次数的迭代中自旋
bool ks_spinlock_try_lock_with_spin(KSSpinLock *lock, uint32_t maxIterations)
{
    // 循环最多maxIterations次
    for (uint32_t i = 0; i < maxIterations; i++) {
        // TTAS策略：首先使用宽松读取检查
        if (atomic_load_explicit(&lock->_opaque, memory_order_relaxed) == 0) {
            // 如果锁看起来空闲，尝试原子交换
            if (atomic_exchange_explicit(&lock->_opaque, 1, memory_order_acquire) == 0) {
                // 成功获取锁，返回true
                return true;
            }
        }
        // 如果锁被持有或交换失败，执行CPU暂停提示
        ks_cpu_pause();
    }
    // 达到最大迭代次数仍未获取锁，返回false
    return false;
}

// 使用有界自旋获取自旋锁：使用默认的最大迭代次数
bool ks_spinlock_lock_bounded(KSSpinLock *lock)
{
    // 调用try_lock_with_spin，使用默认的最大迭代次数
    return ks_spinlock_try_lock_with_spin(lock, kSpinLockBoundedMaxIterations);
}

// 释放自旋锁：将锁状态设置为0（未锁定），使用释放内存顺序
void ks_spinlock_unlock(KSSpinLock *lock) { atomic_store_explicit(&lock->_opaque, 0, memory_order_release); }
