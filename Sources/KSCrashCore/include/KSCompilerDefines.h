//
//  KSCompilerDefines.h
//
//  Created by Nikolay Volosatov on 2024-11-03.
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

#ifndef HDR_KSCompilerDefines_h
#define HDR_KSCompilerDefines_h

/** 禁用优化以确保函数保留在堆栈跟踪中
 * 通常与`KS_THWART_TAIL_CALL_OPTIMISATION`配对使用
 * 用于防止尾调用优化，确保函数在崩溃报告中可见
 */
#define KS_KEEP_FUNCTION_IN_STACKTRACE __attribute__((disable_tail_calls))

/** 禁用内联优化
 * 通常与`KS_KEEP_FUNCTION_IN_STACKTRACE`配对使用
 * 用于确保函数不会被内联，从而在堆栈跟踪中可见
 */
#define KS_NOINLINE __attribute__((noinline))

/** 额外的安全措施，确保方法不会被尾调用优化
 * 此定义应放置在函数的末尾
 * 通常与`KS_KEEP_FUNCTION_IN_STACKTRACE`配对使用
 * 使用内联汇编作为编译器屏障，防止尾调用优化
 */
#define KS_THWART_TAIL_CALL_OPTIMISATION __asm__ __volatile__("");

#endif  // HDR_KSCompilerDefines_h
