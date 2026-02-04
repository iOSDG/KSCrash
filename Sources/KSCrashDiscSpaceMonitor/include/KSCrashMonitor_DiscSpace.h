//
//  KSCrashMonitor_DiscSpace.h
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

#ifndef KSCrashMonitor_DiscSpace_h
#define KSCrashMonitor_DiscSpace_h

// 导入崩溃监控器API头文件
#include "KSCrashMonitorAPI.h"
// 导入命名空间头文件
#include "KSCrashNamespace.h"

#ifdef __cplusplus
extern "C" {
#endif

/** Access the Monitor API.
 */
// 访问磁盘空间监控器API
// 此函数返回磁盘空间监控器的API结构，该监控器用于捕获和报告设备的磁盘空间信息。
// 磁盘空间信息包括总存储大小和可用存储空间大小，通过NSFileManager获取。
// @return 指向KSCrashMonitorAPI结构的指针，包含监控器的所有函数指针
//         包括：monitorId、setEnabled、isEnabled、addContextualInfoToEvent等
KSCrashMonitorAPI *kscm_discspace_getAPI(void);

#ifdef __cplusplus
}
#endif

#endif /* KSCrashMonitor_DiscSpace_h */
