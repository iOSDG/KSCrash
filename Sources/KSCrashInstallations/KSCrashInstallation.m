//
//  KSCrashInstallation.m
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
// 导入运行时库，用于动态属性访问和反射
#import <objc/runtime.h>
// 导入C字符串工具，用于管理C字符串的生命周期
#import "KSCString.h"
// 导入KSCrash主类，提供崩溃处理功能
#import "KSCrash.h"
// 导入崩溃配置类，用于配置崩溃监控器
#import "KSCrashConfiguration.h"
// 导入安装类私有接口，包含私有方法和属性
#import "KSCrashInstallation+Private.h"
// 导入警报过滤器，用于显示用户确认对话框
#import "KSCrashReportFilterAlert.h"
// 导入基础过滤器，提供过滤器管道等功能
#import "KSCrashReportFilterBasic.h"
// 导入符号反混淆过滤器，用于反混淆C++和Swift符号
#import "KSCrashReportFilterDemangle.h"
// 导入崩溃诊断过滤器，用于分析崩溃原因
#import "KSCrashReportFilterDoctor.h"
// 导入JSON编解码器（Objective-C版本），用于序列化数据
#import "KSJSONCodecObjC.h"
// 导入日志记录工具，用于记录调试和错误信息
#import "KSLogger.h"
// 导入NSError辅助工具，用于创建和操作错误对象
#import "KSNSErrorHelper.h"

/** Max number of properties that can be defined for writing to the report */
// 可以定义用于写入报告的最大属性数量（限制为500个）
#define kMaxProperties 500

// 报告字段结构体
// 用于在崩溃报告中存储自定义字段（键值对）
typedef struct {
    // 字段键（C字符串，指向键名）
    const char *key;
    // 字段值（C字符串，JSON格式，指向序列化后的值）
    const char *value;
} ReportField;

// 崩溃处理器数据结构体
// 用于存储崩溃处理器的回调和自定义字段
typedef struct {
    // TODO: 在3.0版本中移除 - 已弃用的回调字段，用于向后兼容
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // 用户崩溃回调（已弃用，保留用于向后兼容）
    KSReportWriteCallback userCrashCallback;
#pragma clang diagnostic pop
    // 正在写入报告时的回调（新版本，支持异步安全）
    KSCrashIsWritingReportCallback isWritingReportCallback;
    // 报告字段数量（实际使用的字段数）
    int reportFieldsCount;
    // 报告字段数组（可变长度数组，使用0长度表示，实际大小由分配决定）
    ReportField *reportFields[0];
} CrashHandlerData;

// 全局崩溃处理器数据指针
// 指向当前激活的安装对象的崩溃处理器数据（用于在崩溃时访问自定义字段）
static CrashHandlerData *g_crashHandlerData;

// 定义KSCrashInstReportField类
// 用于管理报告字段的Objective-C包装类，将NSString和对象转换为C字符串
@interface KSCrashInstReportField : NSObject

// 字段索引（在数组中的位置，只读）
@property(nonatomic, readonly, assign) int index;
// 字段结构体指针（指向ReportField，只读）
@property(nonatomic, readonly, assign) ReportField *field;

// 字段键（NSString，可读写）
@property(nonatomic, readwrite, copy) NSString *key;
// 字段值（任意对象，会被序列化为JSON，可读写）
@property(nonatomic, readwrite, strong) id value;

// 字段结构体的内存备份（NSMutableData，用于存储ReportField结构体）
@property(nonatomic, readwrite, strong) NSMutableData *fieldBacking;
// 键的C字符串备份（KSCString，用于管理C字符串的生命周期）
@property(nonatomic, readwrite, strong) KSCString *keyBacking;
// 值的C字符串备份（KSCString，JSON格式，用于管理C字符串的生命周期）
@property(nonatomic, readwrite, strong) KSCString *valueBacking;

@end

// 实现KSCrashInstReportField类
@implementation KSCrashInstReportField

// 类方法：使用指定索引创建字段对象
// index: 字段索引（在数组中的位置）
// 返回新创建的字段对象
+ (KSCrashInstReportField *)fieldWithIndex:(int)index
{
    // 调用初始化方法创建实例
    return [(KSCrashInstReportField *)[self alloc] initWithIndex:index];
}

// 初始化方法：使用指定索引创建字段对象
// index: 字段索引
// 返回初始化后的实例
- (id)initWithIndex:(int)index
{
    // 调用父类初始化方法
    if ((self = [super init])) {
        // 保存字段索引
        _index = index;
        // 分配ReportField结构体的内存（使用NSMutableData存储）
        _fieldBacking = [NSMutableData dataWithLength:sizeof(*self.field)];
    }
    // 返回初始化后的实例
    return self;
}

// 获取字段结构体指针
// 返回指向ReportField结构体的指针（从NSMutableData的字节缓冲区获取）
- (ReportField *)field
{
    // 将NSMutableData的字节指针转换为ReportField指针
    return (ReportField *)self.fieldBacking.mutableBytes;
}

// 设置字段键
// key: 字段键字符串（NSString）
- (void)setKey:(NSString *)key
{
    // 保存键字符串（使用copy确保不可变）
    _key = key;
    // 检查键是否为nil
    if (key == nil) {
        // 键为nil，清除C字符串备份
        self.keyBacking = nil;
    } else {
        // 键不为nil，创建C字符串备份（KSCString管理C字符串的生命周期）
        self.keyBacking = [KSCString stringWithString:key];
    }
    // 设置字段结构体的键指针（指向C字符串）
    self.field->key = self.keyBacking.bytes;
}

// 设置字段值
// value: 字段值（任意对象，会被序列化为JSON）
- (void)setValue:(id)value
{
    // 检查值是否为nil
    if (value == nil) {
        // 值为nil，清除所有相关数据
        _value = nil;
        self.valueBacking = nil;
        return;
    }

    // 声明错误变量
    NSError *error = nil;
    // 将值序列化为JSON数据
    // KSJSONEncodeOptionPretty: 美化输出（格式化，添加换行和缩进）
    // KSJSONEncodeOptionSorted: 按键排序（确保输出一致）
    NSData *jsonData = [KSJSONCodec encode:value
                                   options:KSJSONEncodeOptionPretty | KSJSONEncodeOptionSorted
                                     error:&error];
    // 检查序列化是否成功
    if (jsonData == nil) {
        // 序列化失败，记录错误日志
        KSLOG_ERROR(@"Could not set value %@ for property %@: %@", value, self.key, error);
    } else {
        // 序列化成功，保存值对象
        _value = value;
        // 创建C字符串备份（JSON格式，KSCString管理C字符串的生命周期）
        self.valueBacking = [KSCString stringWithData:jsonData];
        // 设置字段结构体的值指针（指向C字符串）
        self.field->value = self.valueBacking.bytes;
    }
}

@end

// 定义KSCrashInstallation类的私有扩展
@interface KSCrashInstallation ()

// 下一个字段索引（用于分配新字段，自动递增）
@property(nonatomic, readwrite, assign) int nextFieldIndex;
// 崩溃处理器数据指针（只读，从crashHandlerDataBacking获取）
@property(nonatomic, readonly, assign) CrashHandlerData *crashHandlerData;
// 崩溃处理器数据的内存备份（NSMutableData，存储CrashHandlerData结构体）
@property(nonatomic, readwrite, strong) NSMutableData *crashHandlerDataBacking;
// 字段字典（键为属性名，值为KSCrashInstReportField对象）
@property(nonatomic, readwrite, strong) NSMutableDictionary *fields;
// 前置过滤器管道（在默认过滤器之前执行的过滤器，可以添加自定义过滤器）
@property(nonatomic, readwrite, strong) KSCrashReportFilterPipeline *prependedFilters;

@end

// 实现KSCrashInstallation类
// 这是崩溃安装的基类，提供配置和安装崩溃处理器的功能
@implementation KSCrashInstallation

// 初始化方法
// 返回初始化后的实例
- (instancetype)init
{
    // 调用父类初始化方法
    if ((self = [super init])) {
        // 默认启用符号反混淆（将C++和Swift的混淆符号转换为可读形式）
        _isDemangleEnabled = YES;
        // 默认启用崩溃诊断（分析崩溃原因并提供诊断信息）
        _isDoctorEnabled = YES;
        // 分配崩溃处理器数据的内存
        // 大小 = CrashHandlerData结构体大小 + ReportField指针数组大小（kMaxProperties个指针）
        // 使用NSMutableData存储，确保内存连续且可管理
        _crashHandlerDataBacking =
            [NSMutableData dataWithLength:sizeof(*self.crashHandlerData) +
                                          sizeof(*self.crashHandlerData->reportFields) * kMaxProperties];
        // 初始化字段字典（用于存储属性名到字段对象的映射）
        _fields = [NSMutableDictionary dictionary];
        // 创建前置过滤器管道（用于在默认过滤器之前添加自定义过滤器）
        _prependedFilters = [KSCrashReportFilterPipeline new];
    }
    // 返回初始化后的实例
    return self;
}

// 析构方法
// 在对象释放时调用，清理资源
- (void)dealloc
{
    // 获取KSCrash共享实例
    KSCrash *handler = [KSCrash sharedInstance];
    // 使用同步块确保线程安全（防止多线程同时访问）
    @synchronized(handler) {
        // 检查当前对象的崩溃处理器数据是否是全局激活的数据
        if (g_crashHandlerData == self.crashHandlerData) {
            // 是激活的数据，清除全局指针（防止悬空指针）
            g_crashHandlerData = NULL;
            // FIXME: 修改内部状态
            // 注意：这里可能需要清理handler的其他状态，但目前被注释掉了
            //            handler.onCrash = NULL;
        }
    }
}

// 获取崩溃处理器数据指针
// 返回指向CrashHandlerData结构体的指针（从NSMutableData的字节缓冲区获取）
- (CrashHandlerData *)crashHandlerData
{
    // 将NSMutableData的字节指针转换为CrashHandlerData指针
    return (CrashHandlerData *)self.crashHandlerDataBacking.mutableBytes;
}

// 获取指定属性的报告字段对象
// propertyName: 属性名称（用于标识字段）
// 返回对应的报告字段对象，如果不存在则创建新的
- (KSCrashInstReportField *)reportFieldForProperty:(NSString *)propertyName
{
    // 从字段字典中获取字段对象（如果已存在）
    KSCrashInstReportField *field = [self.fields objectForKey:propertyName];
    // 检查字段是否存在
    if (field == nil) {
        // 字段不存在，创建新字段（使用当前的下一个索引）
        field = [KSCrashInstReportField fieldWithIndex:self.nextFieldIndex];
        // 递增下一个字段索引（为下一个字段做准备）
        self.nextFieldIndex++;
        // 更新崩溃处理器数据中的字段数量（反映实际使用的字段数）
        self.crashHandlerData->reportFieldsCount = self.nextFieldIndex;
        // 将字段指针添加到数组中（存储在CrashHandlerData的reportFields数组中）
        self.crashHandlerData->reportFields[field.index] = field.field;
        // 将字段对象添加到字典中（建立属性名到字段对象的映射）
        [self.fields setObject:field forKey:propertyName];
    }
    // 返回字段对象（可能是已存在的或新创建的）
    return field;
}

// 为指定属性设置报告字段的键
// propertyName: 属性名称
// key: 字段键（NSString或任意对象，会被转换为字符串）
- (void)reportFieldForProperty:(NSString *)propertyName setKey:(id)key
{
    // 获取或创建字段对象（如果不存在则创建）
    KSCrashInstReportField *field = [self reportFieldForProperty:propertyName];
    // 设置字段键（会自动转换为C字符串并存储）
    field.key = key;
}

// 为指定属性设置报告字段的值
// propertyName: 属性名称
// value: 字段值（任意对象，会被序列化为JSON）
- (void)reportFieldForProperty:(NSString *)propertyName setValue:(id)value
{
    // 获取或创建字段对象（如果不存在则创建）
    KSCrashInstReportField *field = [self reportFieldForProperty:propertyName];
    // 设置字段值（会自动序列化为JSON并存储为C字符串）
    field.value = value;
}

// 验证安装配置
// error: 错误输出参数（如果验证失败，会设置此参数）
// 返回YES表示验证通过，NO表示验证失败
- (BOOL)validateSetupWithError:(NSError **)error
{
    // 在基类中没有需要验证的属性（子类可以重写此方法添加验证逻辑）
    return YES;
}

// 创建键路径（用于报告中的字段路径）
// keyPath: 原始键路径（如果以'/'开头则为绝对路径，否则为相对路径）
// 返回处理后的键路径（相对路径会添加"user/"前缀）
- (NSString *)makeKeyPath:(NSString *)keyPath
{
    // 检查键路径是否为空
    if ([keyPath length] == 0) {
        // 为空，直接返回（不处理空字符串）
        return keyPath;
    }
    // 检查是否为绝对路径（以'/'开头）
    BOOL isAbsoluteKeyPath = [keyPath length] > 0 && [keyPath characterAtIndex:0] == '/';
    // 如果是绝对路径，直接返回；否则添加"user/"前缀（相对路径放在user命名空间下）
    return isAbsoluteKeyPath ? keyPath : [@"user/" stringByAppendingString:keyPath];
}

// 创建键路径数组（批量处理键路径）
// keyPaths: 原始键路径数组
// 返回处理后的键路径数组（每个相对路径都会添加"user/"前缀）
- (NSArray *)makeKeyPaths:(NSArray *)keyPaths
{
    // 检查键路径数组是否为空
    if ([keyPaths count] == 0) {
        // 为空，直接返回（不处理空数组）
        return keyPaths;
    }
    // 创建结果数组（预分配容量以提高性能）
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[keyPaths count]];
    // 遍历所有键路径
    for (NSString *keyPath in keyPaths) {
        // 处理每个键路径（添加"user/"前缀如果是相对路径）并添加到结果数组
        [result addObject:[self makeKeyPath:keyPath]];
    }
    // 返回处理后的键路径数组
    return result;
}

// TODO: 在3.0版本中移除 - 已弃用的onCrash属性方法，用于向后兼容
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
// 获取onCrash回调（已弃用，使用isWritingReportCallback代替）
// 返回用户崩溃回调函数指针
- (KSReportWriteCallback)onCrash
{
    // 使用同步块确保线程安全
    @synchronized(self) {
        // 返回崩溃处理器数据中的用户崩溃回调
        return self.crashHandlerData->userCrashCallback;
    }
}

// 设置onCrash回调（已弃用，使用setIsWritingReportCallback代替）
// onCrash: 用户崩溃回调函数指针
- (void)setOnCrash:(KSReportWriteCallback)onCrash
{
    // 使用同步块确保线程安全
    @synchronized(self) {
        // 设置崩溃处理器数据中的用户崩溃回调
        self.crashHandlerData->userCrashCallback = onCrash;
    }
}
#pragma clang diagnostic pop

// 获取isWritingReportCallback回调（新版本，支持异步安全）
// 返回正在写入报告时的回调函数指针
- (KSCrashIsWritingReportCallback)isWritingReportCallback
{
    // 使用同步块确保线程安全
    @synchronized(self) {
        // 返回崩溃处理器数据中的写入报告回调
        return self.crashHandlerData->isWritingReportCallback;
    }
}

// 设置isWritingReportCallback回调（新版本，支持异步安全）
// isWritingReportCallback: 正在写入报告时的回调函数指针
- (void)setIsWritingReportCallback:(KSCrashIsWritingReportCallback)isWritingReportCallback
{
    // 使用同步块确保线程安全
    @synchronized(self) {
        // 设置崩溃处理器数据中的写入报告回调
        self.crashHandlerData->isWritingReportCallback = isWritingReportCallback;
    }
}

// 写入报告时的回调函数（静态函数，用于在崩溃时添加自定义字段）
// plan: 异常处理计划（包含异常处理需求信息）
// writer: 报告写入器（用于向报告添加数据）
static void isWritingReportCallback(const KSCrash_ExceptionHandlingPlan *plan,
                                    const struct KSCrashReportWriter *_Nonnull writer)
{
    // 获取全局崩溃处理器数据（指向当前激活的安装对象的数据）
    CrashHandlerData *crashHandlerData = g_crashHandlerData;
    // 检查数据是否有效
    if (crashHandlerData == NULL) {
        // 数据无效，直接返回（没有自定义字段需要添加）
        return;
    }
    // 遍历所有报告字段（将自定义字段添加到报告中）
    for (int i = 0; i < crashHandlerData->reportFieldsCount; i++) {
        // 获取当前字段
        ReportField *field = crashHandlerData->reportFields[i];
        // 检查字段是否有效（键和值都不为NULL）
        if (field->key != NULL && field->value != NULL) {
            // 字段有效，添加到报告中
            // addJSONElement: 添加JSON元素到报告
            // field->key: 字段键（C字符串）
            // field->value: 字段值（C字符串，JSON格式）
            // true: 表示值已经是JSON格式（不需要再次编码）
            writer->addJSONElement(writer, field->key, field->value, true);
        }
    }

    // 检查是否有新版本的写入报告回调
    if (crashHandlerData->isWritingReportCallback != NULL) {
        // 有新版本回调，调用它（传入异常处理计划）
        crashHandlerData->isWritingReportCallback(plan, writer);
    } else if (crashHandlerData->userCrashCallback != NULL) {
        // TODO: 在3.0版本中移除 - 已弃用的回调调用，用于向后兼容
        // 没有新版本回调，但有旧版本回调，调用旧版本（不传入异常处理计划）
        crashHandlerData->userCrashCallback(writer);
    }
}

// 使用指定配置安装崩溃处理器
// configuration: 崩溃配置对象（包含监控器类型、报告存储路径等配置）
// error: 错误输出参数（如果安装失败，会设置此参数）
// 返回YES表示安装成功，NO表示安装失败
- (BOOL)installWithConfiguration:(KSCrashConfiguration *)configuration error:(NSError **)error
{
    // 获取KSCrash共享实例
    KSCrash *handler = [KSCrash sharedInstance];
    // 使用同步块确保线程安全（防止多个安装对象同时安装）
    @synchronized(handler) {
        // 设置全局崩溃处理器数据指针（指向当前安装对象的数据，用于崩溃时访问）
        g_crashHandlerData = self.crashHandlerData;

        // 设置配置对象的写入报告回调（在崩溃时调用，用于添加自定义字段）
        configuration.isWritingReportCallback = isWritingReportCallback;

        // 声明错误变量
        NSError *installError = nil;
        // 调用KSCrash的安装方法（实际执行崩溃处理器的安装）
        BOOL success = [handler installWithConfiguration:configuration error:&installError];

        // 检查安装是否成功
        if (success == NO && error != NULL) {
            // 安装失败且错误参数不为NULL，设置错误信息
            *error = installError;
        }

        // 返回安装结果
        return success;
    }
}

// 发送所有报告（读取所有已存储的崩溃报告，处理后发送）
// onCompletion: 完成回调（在发送完成后调用，传入处理后的报告和错误信息）
- (void)sendAllReportsWithCompletion:(KSCrashReportFilterCompletion)onCompletion
{
    // 声明错误变量
    NSError *error = nil;
    // 验证安装配置（检查必要的属性是否已设置）
    if ([self validateSetupWithError:&error] == NO) {
        // 验证失败，检查是否有完成回调
        if (onCompletion != nil) {
            // 有完成回调，调用它并传入nil报告和错误信息
            onCompletion(nil, error);
        }
        // 验证失败，直接返回
        return;
    }

    // 获取Sink（报告输出目标，由子类实现）
    id<KSCrashReportFilter> sink = [self sink];
    // 检查Sink是否为nil
    if (sink == nil) {
        // Sink为nil，调用完成回调并传入错误信息（子类必须实现sink方法）
        onCompletion(nil,
                     [KSNSErrorHelper errorWithDomain:[[self class] description]
                                                 code:0
                                          description:@"Sink was nil (subclasses must implement method \"sink\")"]);
        // Sink为nil，直接返回
        return;
    }

    // 获取报告存储对象（用于读取和发送报告）
    KSCrashReportStore *store = [KSCrash sharedInstance].reportStore;
    // 检查报告存储对象是否为nil
    if (store == nil) {
        // 报告存储对象为nil，调用完成回调并传入错误信息（必须先调用installWithConfiguration:error:）
        onCompletion(
            nil, [KSNSErrorHelper
                     errorWithDomain:[[self class] description]
                                code:0
                         description:@"Reporting is not allowed before the call of `installWithConfiguration:error:`"]);
        // 报告存储对象为nil，直接返回
        return;
    }

    // 创建安装过滤器数组（用于构建报告处理管道）
    NSMutableArray *installationFilters = [NSMutableArray array];
    // 检查是否启用符号反混淆
    if (self.isDemangleEnabled) {
        // 启用，添加符号反混淆过滤器（将混淆符号转换为可读形式）
        [installationFilters addObject:[KSCrashReportFilterDemangle new]];
    }
    // 检查是否启用崩溃诊断
    if (self.isDoctorEnabled) {
        // 启用，添加崩溃诊断过滤器（分析崩溃原因）
        [installationFilters addObject:[KSCrashReportFilterDoctor new]];
    }
    // 添加前置过滤器（用户自定义的过滤器）和Sink（报告输出目标）
    [installationFilters addObjectsFromArray:@[
        self.prependedFilters,
        sink,
    ]];
    // 创建过滤器管道（按顺序处理报告：前置过滤器 -> 符号反混淆 -> 崩溃诊断 -> Sink）
    store.sink = [[KSCrashReportFilterPipeline alloc] initWithFilters:installationFilters];

    // 发送所有报告（读取所有报告，通过过滤器管道处理，然后发送）
    [store sendAllReportsWithCompletion:onCompletion];
}

// 添加前置过滤器（在默认过滤器之前执行的自定义过滤器）
// filter: 要添加的过滤器对象
- (void)addPreFilter:(id<KSCrashReportFilter>)filter
{
    // 将过滤器添加到前置过滤器管道中（会在符号反混淆和崩溃诊断之前执行）
    [self.prependedFilters addFilter:filter];
}

// 获取Sink（报告输出目标，抽象方法，子类必须实现）
// 返回报告过滤器对象（通常是Sink对象或包含Sink的过滤器管道）
- (id<KSCrashReportFilter>)sink
{
    // 如果子类没有实现此方法，抛出异常（这是抽象方法）
    [self doesNotRecognizeSelector:_cmd];
    // 标记为不可达（编译器优化提示）
    __builtin_unreachable();
}

// 添加条件警报（显示确认对话框，用户可以选择是否发送报告）
// title: 对话框标题
// message: 对话框消息内容
// yesAnswer: "是"按钮的文本（用户同意发送报告）
// noAnswer: "否"按钮的文本（用户拒绝发送报告）
- (void)addConditionalAlertWithTitle:(NSString *)title
                             message:(NSString *)message
                           yesAnswer:(NSString *)yesAnswer
                            noAnswer:(NSString *)noAnswer
{
    // 创建警报过滤器并添加到前置过滤器（在发送报告前显示确认对话框）
    [self addPreFilter:[[KSCrashReportFilterAlert alloc] initWithTitle:title
                                                               message:message
                                                             yesAnswer:yesAnswer
                                                              noAnswer:noAnswer]];

    // 获取报告存储对象
    KSCrashReportStore *store = [KSCrash sharedInstance].reportStore;
    // 检查报告清理策略是否为"仅在成功时删除"
    if (store.reportCleanupPolicy == KSCrashReportCleanupPolicyOnSuccess) {
        // 如果是，改为"总是删除"
        // 原因：如果用户拒绝发送报告，报告不会被删除，用户会一直被提示
        // 直到用户同意发送报告。改为总是删除可以避免这个问题。
        store.reportCleanupPolicy = KSCrashReportCleanupPolicyAlways;
    }
}

// 添加无条件警报（显示信息对话框，用户只能确认，不能拒绝）
// title: 对话框标题
// message: 对话框消息内容
// dismissButtonText: 确认按钮的文本（用户只能点击确认）
- (void)addUnconditionalAlertWithTitle:(NSString *)title
                               message:(NSString *)message
                     dismissButtonText:(NSString *)dismissButtonText
{
    // 创建警报过滤器并添加到前置过滤器（noAnswer为nil表示无条件警报）
    [self addPreFilter:[[KSCrashReportFilterAlert alloc] initWithTitle:title
                                                               message:message
                                                             yesAnswer:dismissButtonText
                                                              noAnswer:nil]];
}

@end
