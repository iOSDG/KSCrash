//
//  KSNSErrorHelper.h
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

#ifdef __OBJC__

// 导入Foundation框架
#import <Foundation/Foundation.h>
// 导入命名空间头文件
#include "KSCrashNamespace.h"

/**
 * 用于构造NSError对象的简化接口
 * 提供便利方法来创建和填充NSError对象
 */
@interface KSNSErrorHelper : NSObject

/** 便利构造器：创建具有指定本地化描述的错误
 *
 * @param domain 错误域（用于标识错误的来源）
 * @param code 错误代码
 * @param fmt 错误描述（格式化字符串，支持可变参数）
 *            此描述将被放置在用户信息字典中，键为NSLocalizedDescriptionKey
 * @return 创建的NSError对象
 */
+ (NSError *)errorWithDomain:(NSString *)domain code:(NSInteger)code description:(NSString *)fmt, ...;

/** 如果错误指针不为nil，则用NSError对象填充它
 *
 * @param error 要填充的错误指针（如果为nil则忽略）
 * @param domain 错误域（用于标识错误的来源）
 * @param code 错误代码
 * @param fmt 错误描述（格式化字符串，支持可变参数）
 *            此描述将被放置在用户信息字典中，键为NSLocalizedDescriptionKey
 * @return NO（用于保持静态分析器满意）
 */
+ (BOOL)fillError:(NSError **)error withDomain:(NSString *)domain code:(NSInteger)code description:(NSString *)fmt, ...;

/** 如果错误指针不为nil，则将其清空为nil
 *
 * @param error 要清空的错误指针（如果为nil则忽略）
 * @return NO（用于保持静态分析器满意）
 */
+ (BOOL)clearError:(NSError **)error;

@end

#endif
