//
//  KSDemangle_Swift.h
//
//  Created by Karl Stenerud on 2016-11-04.
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

#ifndef HDR_KSDemangle_Swift_h
#define HDR_KSDemangle_Swift_h

// 导入命名空间头文件
#include "KSCrashNamespace.h"

#ifdef __cplusplus
extern "C" {
#endif

/** Demangle a Swift symbol.
 *
 * @warning MEMORY MANAGEMENT WARNING: User is responsible for calling free() on the returned value.
 *
 * @param mangledSymbol The mangled symbol.
 *
 * @return A demangled symbol, or NULL if demangling failed.
 */
// 反混淆Swift符号
// 使用Swift运行时的swift_demangle函数来反混淆Swift符号名称。
// 此函数通过动态链接（dlsym）获取Swift运行时的反混淆函数。
// 如果Swift运行时不可用，则返回NULL。
// @warning 内存管理警告：调用者负责对返回值调用free()释放内存
// @param mangledSymbol 混淆的Swift符号字符串（以null结尾）
// @return 反混淆后的符号字符串（使用malloc分配，需要调用者释放），如果反混淆失败或Swift运行时不可用则返回NULL
char *ksdm_demangleSwift(const char *mangledSymbol);

#ifdef __cplusplus
}
#endif

#endif  // HDR_KSDemangle_Swift_h
