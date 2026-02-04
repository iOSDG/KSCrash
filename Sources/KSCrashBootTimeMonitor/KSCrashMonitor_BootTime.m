//
//  KSCrashMonitor_BootTime.c
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

// 导入启动时间监控器头文件
#import "KSCrashMonitor_BootTime.h"

// 导入崩溃监控器上下文头文件
#import "KSCrashMonitorContext.h"
// 导入崩溃监控器辅助工具头文件
#import "KSCrashMonitorHelper.h"
// 导入日期处理头文件
#import "KSDate.h"
// 导入系统控制头文件
#import "KSSysCtl.h"

// 导入Foundation框架
#import <Foundation/Foundation.h>
// 导入系统类型头文件
#import <sys/types.h>

// 全局变量：监控器是否启用的标志（使用volatile确保多线程可见性）
static volatile bool g_isEnabled = false;

// 重置监控器状态（用于测试，在TestCase中声明为extern）
__attribute__((unused))  // 标记为未使用，避免编译器警告（用于测试）
void kscm_bootTime_resetState(void)
{
    // 将启用标志设置为false
    g_isEnabled = false;
}

/** 获取sysctl值并转换为日期字符串
 *
 * @param name sysctl名称（如"kern.boottime"）
 *
 * @return sysctl调用的结果，返回UTC格式的日期字符串（需要调用者释放内存）
 */
static const char *dateSysctl(const char *name)
{
    // 通过sysctl获取时间值（timeval结构）
    struct timeval value = kssysctl_timevalForName(name);
    // 分配缓冲区用于存储日期字符串
    char *buffer = malloc(KSDATE_BUFFERSIZE);
    // 将时间戳转换为UTC格式的字符串
    ksdate_utcStringFromTimestamp(value.tv_sec, buffer, KSDATE_BUFFERSIZE);
    // 返回日期字符串（调用者需要释放内存）
    return buffer;
}

#pragma mark - API -

// 获取监控器ID
// @return 监控器ID字符串"BootTime"
static const char *monitorId(void) { return "BootTime"; }

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

// 向事件添加上下文信息（启动时间）
// @param eventContext 崩溃监控器上下文，用于存储崩溃相关信息
static void addContextualInfoToEvent(KSCrash_MonitorContext *eventContext)
{
    // 如果监控器已启用
    if (g_isEnabled) {
        // 获取系统启动时间（通过sysctl获取"kern.boottime"）并添加到事件上下文中
        eventContext->System.bootTime = dateSysctl("kern.boottime");
    }
}

// 获取启动时间监控器的API
// @return 指向KSCrashMonitorAPI结构的指针，包含监控器的所有函数指针
KSCrashMonitorAPI *kscm_boottime_getAPI(void)
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
__attribute__((constructor)) static void kscm_boottime_register(void) { kscm_addMonitor(kscm_boottime_getAPI()); }
