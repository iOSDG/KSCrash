//
//  KSCrashMonitor_DiscSpace.c
//
//  Created by Gleb Linnik on 04.06.2024.
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

// 导入磁盘空间监控器头文件
#import "KSCrashMonitor_DiscSpace.h"

// 导入崩溃监控器上下文头文件
#import "KSCrashMonitorContext.h"
// 导入崩溃监控器辅助工具头文件
#import "KSCrashMonitorHelper.h"

// 导入Foundation框架
#import <Foundation/Foundation.h>

// 全局变量：监控器是否启用的标志（使用volatile确保多线程可见性）
static volatile bool g_isEnabled = false;

__attribute__((unused))  // For tests. Declared as extern in TestCase
// 重置监控器状态（用于测试，在TestCase中声明为extern）
void kscm_discSpace_resetState(void)
{
    // 将启用标志设置为false
    g_isEnabled = false;
}

// 获取存储总大小
// @return 存储总大小（字节数）
static uint64_t getStorageSize(void)
{
    // 获取文件系统属性，使用主目录路径
    // NSFileSystemSize键表示文件系统的总大小
    NSNumber *storageSize = [[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil]
        objectForKey:NSFileSystemSize];
    // 将NSNumber转换为64位无符号整数并返回
    return storageSize.unsignedLongLongValue;
}

// 获取可用存储空间大小
// @return 可用存储空间大小（字节数）
static uint64_t getFreeStorageSize(void)
{
    // 获取文件系统属性，使用主目录路径
    // NSFileSystemFreeSize键表示文件系统的可用空间大小
    NSNumber *freeStorageSize =
        [[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory()
                                                                 error:nil] objectForKey:NSFileSystemFreeSize];
    // 将NSNumber转换为64位无符号整数并返回
    return freeStorageSize.unsignedLongLongValue;
}

#pragma mark - API -

// 获取监控器ID
// @return 监控器ID字符串"DiscSpace"
static const char *monitorId(void) { return "DiscSpace"; }

// 设置监控器启用状态
// @param isEnabled 是否启用监控器
static void setEnabled(bool isEnabled)
{
    // 只有当状态发生变化时才更新
    if (isEnabled != g_isEnabled) {
        // 更新全局启用标志
        g_isEnabled = isEnabled;
    }
}

// 检查监控器是否启用
// @return 如果监控器已启用则返回true，否则返回false
static bool isEnabled(void) { return g_isEnabled; }

// 向事件添加上下文信息（磁盘空间信息）
// @param eventContext 崩溃监控器上下文，用于存储崩溃相关信息
static void addContextualInfoToEvent(KSCrash_MonitorContext *eventContext)
{
    // 如果监控器已启用
    if (g_isEnabled) {
        // 获取存储总大小并添加到事件上下文中
        eventContext->System.storageSize = getStorageSize();
        // 获取可用存储空间大小并添加到事件上下文中
        eventContext->System.freeStorageSize = getFreeStorageSize();
    }
}

// 获取磁盘空间监控器的API
// @return 指向KSCrashMonitorAPI结构的指针，包含监控器的所有函数指针
KSCrashMonitorAPI *kscm_discspace_getAPI(void)
{
    // 静态API结构，只初始化一次
    static KSCrashMonitorAPI api = { 0 };
    // 如果API尚未初始化，则初始化它
    if (kscma_initAPI(&api)) {
        // 设置监控器ID函数指针
        api.monitorId = monitorId;
        // 设置启用/禁用函数指针
        api.setEnabled = setEnabled;
        // 设置检查启用状态函数指针
        api.isEnabled = isEnabled;
        // 设置添加上下文信息函数指针
        api.addContextualInfoToEvent = addContextualInfoToEvent;
    }
    // 返回API结构指针
    return &api;
}

#pragma mark - Injection -

// 构造函数：在程序启动时自动注册监控器
// 使用__attribute__((constructor))确保此函数在main函数之前执行
__attribute__((constructor)) static void kscm_discspace_register(void) { kscm_addMonitor(kscm_discspace_getAPI()); }
