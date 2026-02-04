//
//  KSDemangle_CPP.cpp
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

// 导入C++反混淆头文件
#include "KSDemangle_CPP.h"

// 导入C++ ABI头文件（包含符号反混淆函数）
#include <cxxabi.h>

// C接口：反混淆C++符号
// @param mangledSymbol 混淆的C++符号字符串（以null结尾）
// @return 反混淆后的符号字符串（使用malloc分配，需要调用者释放），如果反混淆失败则返回NULL
extern "C" char *ksdm_demangleCPP(const char *mangledSymbol)
{
    // 状态变量，用于接收反混淆操作的状态
    int status = 0;
    // 调用C++ ABI的反混淆函数
    // 参数说明：
    // - mangledSymbol: 混淆的符号字符串
    // - NULL: 输出缓冲区（NULL表示自动分配）
    // - NULL: 输出缓冲区大小（NULL表示自动分配）
    // - &status: 状态指针，用于接收操作结果
    char *demangled = __cxxabiv1::__cxa_demangle(mangledSymbol, NULL, NULL, &status);
    // 如果状态为0（成功），返回反混淆后的字符串；否则返回NULL
    return status == 0 ? demangled : NULL;
}
