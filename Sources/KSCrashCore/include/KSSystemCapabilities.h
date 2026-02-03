//
//  KSSystemCapabilities.h
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

#ifndef HDR_KSSystemCapabilities_h
#define HDR_KSSystemCapabilities_h

// 如果编译目标是Apple平台
#ifdef __APPLE__
// 导入目标条件头文件（用于检测具体平台）
#include <TargetConditionals.h>
// 定义Apple平台标志
#define KSCRASH_HOST_APPLE 1
#endif

// 如果编译目标是Android平台
#ifdef __ANDROID__
// 定义Android平台标志
#define KSCRASH_HOST_ANDROID 1
#endif

// 检测是否为Vision平台（Apple Vision Pro）
#if defined(TARGET_OS_VISION) && TARGET_OS_VISION
// 定义Vision平台标志
#define KSCRASH_HOST_VISION 1
#else
// 非Vision平台
#define KSCRASH_HOST_VISION 0
#endif

// 检测是否为iOS平台（Apple平台且目标为iOS）
#define KSCRASH_HOST_IOS (KSCRASH_HOST_APPLE && TARGET_OS_IOS)
// 检测是否为tvOS平台（Apple平台且目标为tvOS）
#define KSCRASH_HOST_TV (KSCRASH_HOST_APPLE && TARGET_OS_TV)
// 检测是否为watchOS平台（Apple平台且目标为watchOS）
#define KSCRASH_HOST_WATCH (KSCRASH_HOST_APPLE && TARGET_OS_WATCH)
// 检测是否为macOS平台（Apple平台且目标为macOS，但不是iOS、tvOS、watchOS或Vision）
#define KSCRASH_HOST_MAC \
    (KSCRASH_HOST_APPLE && TARGET_OS_MAC && !(TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH || KSCRASH_HOST_VISION))

// 检测是否可以获取MAC地址（仅Apple平台支持）
#if KSCRASH_HOST_APPLE
#define KSCRASH_CAN_GET_MAC_ADDRESS 1
#else
#define KSCRASH_CAN_GET_MAC_ADDRESS 0
#endif

// 检测是否支持Objective-C和Swift（仅Apple平台支持）
#if KSCRASH_HOST_APPLE
#define KSCRASH_HAS_OBJC 1
#define KSCRASH_HAS_SWIFT 1
#else
#define KSCRASH_HAS_OBJC 0
#define KSCRASH_HAS_SWIFT 0
#endif

// 检测是否支持kinfo_proc（进程信息，仅Apple平台支持）
#if KSCRASH_HOST_APPLE
#define KSCRASH_HAS_KINFO_PROC 1
#else
#define KSCRASH_HAS_KINFO_PROC 0
#endif

// 检测是否支持strnstr函数（字符串搜索，仅Apple平台支持）
#if KSCRASH_HOST_APPLE
#define KSCRASH_HAS_STRNSTR 1
#else
#define KSCRASH_HAS_STRNSTR 0
#endif

// 检测是否支持UIKit框架（iOS、tvOS、watchOS、Vision平台）
#if KSCRASH_HOST_IOS || KSCRASH_HOST_TV || KSCRASH_HOST_WATCH || KSCRASH_HOST_VISION
#define KSCRASH_HAS_UIKIT 1
#else
#define KSCRASH_HAS_UIKIT 0
#endif

// 检测是否支持UIApplication（iOS、tvOS、Vision平台）
#if KSCRASH_HOST_IOS || KSCRASH_HOST_TV || KSCRASH_HOST_VISION
#define KSCRASH_HAS_UIAPPLICATION 1
#else
#define KSCRASH_HAS_UIAPPLICATION 0
#endif

// 检测是否支持NSExtension（watchOS平台）
#if KSCRASH_HOST_WATCH
#define KSCRASH_HAS_NSEXTENSION 1
#else
#define KSCRASH_HAS_NSEXTENSION 0
#endif

// 检测是否支持MessageUI框架（仅iOS平台）
#if KSCRASH_HOST_IOS
#define KSCRASH_HAS_MESSAGEUI 1
#else
#define KSCRASH_HAS_MESSAGEUI 0
#endif

// 检测是否支持UIDevice（iOS、tvOS、Vision平台）
#if KSCRASH_HOST_IOS || KSCRASH_HOST_TV || KSCRASH_HOST_VISION
#define KSCRASH_HAS_UIDEVICE 1
#else
#define KSCRASH_HAS_UIDEVICE 0
#endif

// 检测是否支持警报视图（iOS、macOS、tvOS、Vision平台）
#if KSCRASH_HOST_IOS || KSCRASH_HOST_MAC || KSCRASH_HOST_TV || KSCRASH_HOST_VISION
#define KSCRASH_HAS_ALERTVIEW 1
#else
#define KSCRASH_HAS_ALERTVIEW 0
#endif

// 检测是否支持UIAlertController（iOS、tvOS平台）
#if KSCRASH_HOST_IOS || KSCRASH_HOST_TV
#define KSCRASH_HAS_UIALERTCONTROLLER 1
#else
#define KSCRASH_HAS_UIALERTCONTROLLER 0
#endif

// 检测是否支持NSAlert（macOS平台）
#if KSCRASH_HOST_MAC
#define KSCRASH_HAS_NSALERT 1
#else
#define KSCRASH_HAS_NSALERT 0
#endif

// 检测是否支持Mach异常（iOS、macOS、Vision平台）
#if KSCRASH_HOST_IOS || KSCRASH_HOST_MAC || KSCRASH_HOST_VISION
#define KSCRASH_HAS_MACH 1
#else
#define KSCRASH_HAS_MACH 0
#endif

// 检测是否支持syscall（iOS、tvOS平台）
#if KSCRASH_HOST_IOS || KSCRASH_HOST_TV
#define KSCRASH_HAS_SYSCALL 1
#else
#define KSCRASH_HAS_SYSCALL 0
#endif

// watchOS 3.1及以后版本的信号处理存在问题
// 检测是否支持信号处理（Android、iOS、macOS、tvOS、Vision平台）
#if KSCRASH_HOST_ANDROID || KSCRASH_HOST_IOS || KSCRASH_HOST_MAC || KSCRASH_HOST_TV || KSCRASH_HOST_VISION
#define KSCRASH_HAS_SIGNAL 1
#else
#define KSCRASH_HAS_SIGNAL 0
#endif

// 检测是否支持信号栈（Android、macOS、iOS、Vision平台）
#if KSCRASH_HOST_ANDROID || KSCRASH_HOST_MAC || KSCRASH_HOST_IOS || KSCRASH_HOST_VISION
#define KSCRASH_HAS_SIGNAL_STACK 1
#else
#define KSCRASH_HAS_SIGNAL_STACK 0
#endif

// 检测是否支持线程API（macOS、iOS、tvOS、Vision平台）
#if KSCRASH_HOST_MAC || KSCRASH_HOST_IOS || KSCRASH_HOST_TV || KSCRASH_HOST_VISION
#define KSCRASH_HAS_THREADS_API 1
#else
#define KSCRASH_HAS_THREADS_API 0
#endif

// 检测是否支持网络可达性检测（macOS、iOS、tvOS、Vision平台）
#if KSCRASH_HOST_MAC || KSCRASH_HOST_IOS || KSCRASH_HOST_TV || KSCRASH_HOST_VISION
#define KSCRASH_HAS_REACHABILITY 1
#else
#define KSCRASH_HAS_REACHABILITY 0
#endif

// ============================================================================
#pragma mark - Sanitizer Detection -
// ============================================================================

// 检测是否在编译时启用了清理器（Sanitizer）
// 清理器（ASan、TSan等）会拦截某些函数，可能与KSCrash自己的拦截机制冲突
#if defined(__SANITIZE_ADDRESS__) || defined(__SANITIZE_THREAD__) || defined(__SANITIZE_UNDEFINED__)
#define KSCRASH_HAS_SANITIZER 1
#elif defined(__has_feature)
// 使用编译器特性检测
#if __has_feature(address_sanitizer) || __has_feature(thread_sanitizer) || __has_feature(undefined_behavior_sanitizer)
#define KSCRASH_HAS_SANITIZER 1
#endif
#endif

// 如果未定义，默认为未启用清理器
#ifndef KSCRASH_HAS_SANITIZER
#define KSCRASH_HAS_SANITIZER 0
#endif

// ============================================================================
#pragma mark - Compiler Attributes -
// ============================================================================

// 定义废弃属性宏（用于标记已废弃的API）
#ifndef KSCRASH_DEPRECATED
// 如果编译器支持deprecated属性
#if defined(__has_attribute) && __has_attribute(deprecated)
// 定义废弃属性，包含废弃消息
#define KSCRASH_DEPRECATED(msg) __attribute__((deprecated(msg)))
#else
// 编译器不支持，定义为空
#define KSCRASH_DEPRECATED(msg)
#endif
#endif

#endif  // HDR_KSSystemCapabilities_h
