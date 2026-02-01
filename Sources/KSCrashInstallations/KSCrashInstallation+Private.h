//
//  KSCrashReportFieldProperties.h
//
//  Created by Karl Stenerud on 2013-02-10.
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

// 导入崩溃安装类头文件，包含类接口声明
#import "KSCrashInstallation.h"

/** Implement a property to be used as a "key". */
// 实现用作"键"的属性
// 此宏用于生成一个键属性，当设置键时，会自动调用reportFieldForProperty:setKey:方法
// NAME: 属性名称（小写）
// NAMEUPPER: 属性名称（首字母大写，用于生成setter方法名）
#define IMPLEMENT_REPORT_KEY_PROPERTY(NAME, NAMEUPPER)      \
    // 合成属性（自动生成getter和setter）                    \
    @synthesize NAME##Key = _##NAME##Key;                   \
    // 实现setter方法                                        \
    -(void)set##NAMEUPPER##Key : (NSString *)value          \
    {                                                       \
        // 引用实例变量（避免未使用警告）                     \
        _##NAME##Key;                                       \
        // 设置实例变量                                      \
        _##NAME##Key = value;                               \
        // 调用报告字段设置键方法（将键存储到报告中）         \
        [self reportFieldForProperty:@ #NAME setKey:value]; \
    }

/** Implement a property to be used as a "value". */
// 实现用作"值"的属性
// 此宏用于生成一个值属性，当设置值时，会自动调用reportFieldForProperty:setValue:方法
// NAME: 属性名称（小写）
// NAMEUPPER: 属性名称（首字母大写，用于生成setter方法名）
// TYPE: 属性类型
#define IMPLEMENT_REPORT_VALUE_PROPERTY(NAME, NAMEUPPER, TYPE) \
    // 合成属性（自动生成getter和setter）                      \
    @synthesize NAME = _##NAME;                                \
    // 实现setter方法                                          \
    -(void)set##NAMEUPPER : (TYPE)value                        \
    {                                                          \
        // 引用实例变量（避免未使用警告）                       \
        _##NAME;                                               \
        // 设置实例变量                                        \
        _##NAME = value;                                       \
        // 调用报告字段设置值方法（将值序列化为JSON并存储到报告中） \
        [self reportFieldForProperty:@ #NAME setValue:value];  \
    }

/** Implement a standard report property (with key and value properties) */
// 实现标准报告属性（包含键和值属性）
// 此宏用于生成一个完整的报告属性，包含键属性和值属性
// NAME: 属性名称（小写）
// NAMEUPPER: 属性名称（首字母大写，用于生成setter方法名）
// TYPE: 属性类型
#define IMPLEMENT_REPORT_PROPERTY(NAME, NAMEUPPER, TYPE)   \
    // 先实现值属性                                          \
    IMPLEMENT_REPORT_VALUE_PROPERTY(NAME, NAMEUPPER, TYPE) \
    // 再实现键属性                                          \
    IMPLEMENT_REPORT_KEY_PROPERTY(NAME, NAMEUPPER)

// 定义KSCrashInstallation类的私有扩展（类扩展，用于声明私有方法）
@interface KSCrashInstallation ()

/** Set the key to be used for the specified report property.
 *
 * @param propertyName The name of the property.
 * @param key The key to use.
 */
// 为指定的报告属性设置要使用的键
// @param propertyName 属性名称
// @param key 要使用的键
- (void)reportFieldForProperty:(NSString *)propertyName setKey:(id)key;

/** Set the value of the specified report property.
 *
 * @param propertyName The name of the property.
 * @param value The value to set.
 */
// 设置指定报告属性的值
// @param propertyName 属性名称
// @param value 要设置的值（会被序列化为JSON）
- (void)reportFieldForProperty:(NSString *)propertyName setValue:(id)value;

/** Make an absolute key path if the specified path is not already absolute. */
// 如果指定的路径还不是绝对路径，则创建绝对键路径
// 如果路径以'/'开头则为绝对路径，否则会添加"user/"前缀
// @param keyPath 原始键路径
// @return 处理后的键路径（绝对路径）
- (NSString *)makeKeyPath:(NSString *)keyPath;

/** Make an absolute key paths from the specified paths. */
// 从指定的路径创建绝对键路径数组
// 批量处理键路径，为每个相对路径添加"user/"前缀
// @param keyPaths 原始键路径数组
// @return 处理后的键路径数组（所有路径都是绝对路径）
- (NSArray *)makeKeyPaths:(NSArray *)keyPaths;

@end
