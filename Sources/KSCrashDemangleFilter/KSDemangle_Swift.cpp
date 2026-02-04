//
//  KSDemangle_Swift.cc
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

// 导入Swift反混淆头文件
#include "KSDemangle_Swift.h"

// 导入动态链接库头文件（用于动态加载符号）
#include <dlfcn.h>
// 导入标准库头文件
#include <stdlib.h>
// 导入字符串处理头文件
#include <string.h>

/// https://github.com/swiftlang/swift/blob/main/stdlib/public/runtime/Demangle.cpp#L987
/// Demangles a Swift symbol name.
///
/// \param mangledName is the symbol name that needs to be demangled.
/// \param mangledNameLength is the length of the string that should be
/// demangled.
/// \param outputBuffer is the user provided buffer where the demangled name
/// will be placed. If nullptr, a new buffer will be malloced. In that case,
/// the user of this API is responsible for freeing the returned buffer.
/// \param outputBufferSize is the size of the output buffer. If the demangled
/// name does not fit into the outputBuffer, the output will be truncated and
/// the size will be updated, indicating how large the buffer should be.
/// \param flags can be used to select the demangling style. TODO: We should
//// define what these will be.
/// \returns the demangled name. Returns nullptr if the input String is not a
/// Swift mangled name.
// Swift反混淆函数的类型定义
// 参考：https://github.com/swiftlang/swift/blob/main/stdlib/public/runtime/Demangle.cpp#L987
// 反混淆Swift符号名称
// \param mangledName 需要反混淆的符号名称
// \param mangledNameLength 需要反混淆的字符串长度
// \param outputBuffer 用户提供的缓冲区，反混淆后的名称将放置在此处。如果为nullptr，将malloc一个新的缓冲区。在这种情况下，此API的用户负责释放返回的缓冲区。
// \param outputBufferSize 输出缓冲区的大小。如果反混淆后的名称无法放入outputBuffer，输出将被截断，大小将被更新，指示缓冲区应该多大。
// \param flags 可用于选择反混淆样式。TODO: 我们应该定义这些标志的含义。
// \returns 反混淆后的名称。如果输入字符串不是Swift混淆名称则返回nullptr。
typedef char *(swift_demangle_func)(const char *mangledName, size_t mangledNameLength, char *outputBuffer,
                                    size_t *outputBufferSize, uint32_t flags);

// 默认的Swift反混淆函数（当Swift运行时不可用时使用）
// 所有参数标记为未使用，避免编译器警告
static char *default_swift_demangle(__unused const char *mangledName, __unused size_t mangledNameLength,
                                    __unused char *outputBuffer, __unused size_t *outputBufferSize,
                                    __unused uint32_t flags)
{
    // 返回nullptr表示反混淆失败
    return nullptr;
}

// Swift反混淆函数指针（初始为nullptr，首次调用时动态加载）
static swift_demangle_func *swift_demangle = nullptr;

// C接口：反混淆Swift符号
// @param mangledSymbol 混淆的Swift符号字符串（以null结尾）
// @return 反混淆后的符号字符串（使用malloc分配，需要调用者释放），如果反混淆失败则返回NULL
extern "C" char *ksdm_demangleSwift(const char *mangledSymbol)
{
    // 如果Swift反混淆函数尚未加载
    if (swift_demangle == nullptr) {
        // 打开当前进程的符号表（NULL表示当前进程）
        void *handle = dlopen(NULL, RTLD_NOW);
        // 如果成功打开
        if (handle != nullptr) {
            // 查找Swift运行时的swift_demangle符号
            void *symbol = dlsym(handle, "swift_demangle");
            // 如果找到符号
            if (symbol != nullptr) {
                // 将符号转换为函数指针
                swift_demangle = (swift_demangle_func *)symbol;
            }
            // 关闭句柄（符号已加载到进程空间，不需要保持句柄打开）
            dlclose(handle);
        }
        // 如果未能加载Swift反混淆函数
        if (swift_demangle == nullptr) {
            // 使用默认函数（总是返回nullptr）
            swift_demangle = default_swift_demangle;
        }
    }

    // 初始化输出缓冲区大小为0（让函数自动分配）
    size_t outputBufferSize = 0;
    // 调用Swift反混淆函数
    // 参数说明：
    // - mangledSymbol: 混淆的符号字符串
    // - strlen(mangledSymbol): 符号字符串长度
    // - nullptr: 输出缓冲区（nullptr表示自动分配）
    // - &outputBufferSize: 输出缓冲区大小指针（初始为0，函数会更新）
    // - 0: 标志（使用默认样式）
    return swift_demangle(mangledSymbol, strlen(mangledSymbol), nullptr, &outputBufferSize, 0);
}
