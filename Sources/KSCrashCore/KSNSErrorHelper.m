//
//  KSNSErrorHelper.m
//
//  Created by Karl Stenerud on 2013-02-09.
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

// 导入NSError辅助工具头文件
#import "KSNSErrorHelper.h"

// NSError辅助工具实现
@implementation KSNSErrorHelper

// 创建具有指定域、代码和描述的错误对象
// @param domain 错误域（用于标识错误的来源）
// @param code 错误代码
// @param fmt 错误描述格式化字符串（支持可变参数）
// @return 创建的NSError对象
+ (NSError *)errorWithDomain:(NSString *)domain code:(NSInteger)code description:(NSString *)fmt, ...
{
    // 声明可变参数列表
    va_list args;
    // 初始化可变参数列表，从fmt之后开始
    va_start(args, fmt);

    // 使用格式化字符串和可变参数创建描述字符串
    NSString *desc = [[NSString alloc] initWithFormat:fmt arguments:args];
    // 结束可变参数列表的使用
    va_end(args);

    // 创建并返回NSError对象，将描述放在用户信息字典中，键为NSLocalizedDescriptionKey
    return [NSError errorWithDomain:domain
                               code:code
                           userInfo:[NSDictionary dictionaryWithObject:desc forKey:NSLocalizedDescriptionKey]];
}

// 如果错误指针不为nil，则用NSError对象填充它
// @param error 要填充的错误指针（如果为nil则忽略）
// @param domain 错误域（用于标识错误的来源）
// @param code 错误代码
// @param fmt 错误描述格式化字符串（支持可变参数）
// @return NO（用于保持静态分析器满意）
+ (BOOL)fillError:(NSError *__autoreleasing *)error
       withDomain:(NSString *)domain
             code:(NSInteger)code
      description:(NSString *)fmt, ...
{
    // 检查错误指针是否不为nil
    if (error != nil) {
        // 声明可变参数列表
        va_list args;
        // 初始化可变参数列表，从fmt之后开始
        va_start(args, fmt);

        // 使用格式化字符串和可变参数创建描述字符串
        NSString *desc = [[NSString alloc] initWithFormat:fmt arguments:args];
        // 结束可变参数列表的使用
        va_end(args);

        // 创建NSError对象并赋值给错误指针，将描述放在用户信息字典中，键为NSLocalizedDescriptionKey
        *error = [NSError errorWithDomain:domain
                                     code:code
                                 userInfo:[NSDictionary dictionaryWithObject:desc forKey:NSLocalizedDescriptionKey]];
    }
    // 返回NO（用于保持静态分析器满意）
    return NO;
}

// 如果错误指针不为nil，则将其清空为nil
// @param error 要清空的错误指针（如果为nil则忽略）
// @return NO（用于保持静态分析器满意）
+ (BOOL)clearError:(NSError *__autoreleasing *)error
{
    // 检查错误指针是否不为nil
    if (error != nil) {
        // 将错误指针指向的内容设置为nil
        *error = nil;
    }
    // 返回NO（用于保持静态分析器满意）
    return NO;
}

@end
