//
//  UnfairLock.swift
//
//  Created by Alexander Cohen on 2025-12-14.
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
import Foundation
// 导入os模块
import os

// 不公平锁的最终内部类，用于线程同步
// @unchecked Sendable表示该类是线程安全的，但需要手动保证
final internal class UnfairLock: @unchecked Sendable {
    // 指向os_unfair_lock的指针
    private var _lock: UnsafeMutablePointer<os_unfair_lock>

    // 初始化不公平锁
    internal init() {
        // 分配一个os_unfair_lock的内存空间
        _lock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        // 初始化为默认的os_unfair_lock值
        _lock.initialize(to: os_unfair_lock())
    }

    // 析构函数：释放锁的内存
    deinit {
        // 释放分配的内存
        _lock.deallocate()
    }

    // 在锁保护下执行代码块
    // @param block 要执行的代码块
    // @return 代码块的返回值
    // @throws 如果代码块抛出异常，则重新抛出
    internal func withLock<T>(_ block: () throws -> T) rethrows -> T {
        // 获取锁
        os_unfair_lock_lock(_lock)
        // 确保在退出时释放锁
        defer { os_unfair_lock_unlock(_lock) }
        // 执行代码块并返回结果
        return try block()
    }
}
