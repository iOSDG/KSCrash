//
//  KSCrashDoctor.m
//  KSCrash
//
//  Created by Karl Stenerud on 2012-11-10.
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
//

// 导入崩溃诊断器头文件
#import "KSCrashDoctor.h"
// 导入崩溃报告字段常量
#import "KSCrashReportFields.h"

// CPU架构族枚举：用于识别不同的CPU架构
typedef enum { CPUFamilyUnknown, CPUFamilyArm, CPUFamilyX86, CPUFamilyX86_64 } CPUFamily;

// 崩溃诊断参数类：用于存储函数调用参数的信息
@interface KSCrashDoctorParam : NSObject

// 参数所属的类名（只读，复制）
@property(nonatomic, readwrite, copy) NSString *className;
// 参数之前所属的类名（用于检测僵尸对象，只读，复制）
@property(nonatomic, readwrite, copy) NSString *previousClassName;
// 参数类型（只读，复制）
@property(nonatomic, readwrite, copy) NSString *type;
// 是否为实例对象（只读，赋值）
@property(nonatomic, readwrite, assign) BOOL isInstance;
// 参数地址（只读，赋值）
@property(nonatomic, readwrite, assign) uintptr_t address;
// 参数值（只读，复制）
@property(nonatomic, readwrite, copy) NSString *value;

@end

// 崩溃诊断参数实现
@implementation KSCrashDoctorParam

@end

// 崩溃诊断函数调用类：用于存储函数调用信息
@interface KSCrashDoctorFunctionCall : NSObject

// 函数名称（只读，复制）
@property(nonatomic, readwrite, copy) NSString *name;
// 函数参数数组（只读，复制）
@property(nonatomic, readwrite, copy) NSArray *params;

@end

@implementation KSCrashDoctorFunctionCall

// 生成Objective-C方法调用的描述字符串
// @return Objective-C方法调用格式的字符串（如 -[ClassName method:param1 param2:]），如果不是objc_msgSend则返回nil
- (NSString *)descriptionForObjCCall
{
    // 检查函数名是否为objc_msgSend（Objective-C消息发送函数）
    if (![self.name isEqualToString:@"objc_msgSend"]) {
        // 不是objc_msgSend，返回nil
        return nil;
    }
    // 获取第一个参数（接收者对象）
    KSCrashDoctorParam *receiverParam = [self.params objectAtIndex:0];
    // 优先使用之前的类名（用于检测僵尸对象）
    NSString *receiver = receiverParam.previousClassName;
    // 如果之前的类名为空，使用当前类名
    if (receiver == nil) {
        receiver = receiverParam.className;
        // 如果当前类名也为空，使用"id"作为默认值
        if (receiver == nil) {
            receiver = @"id";
        }
    }

    // 获取第二个参数（选择器）
    KSCrashDoctorParam *selectorParam = [self.params objectAtIndex:1];
    // 检查选择器参数是否为字符串类型
    if (![selectorParam.type isEqualToString:KSCrashMemType_String]) {
        // 不是字符串类型，返回nil
        return nil;
    }
    // 将选择器字符串按冒号分割，获取方法名和参数名
    NSArray *splitSelector = [selectorParam.value componentsSeparatedByString:@":"];
    // 计算参数数量（分割后的数组长度减1）
    int paramCount = (int)splitSelector.count - 1;

    // 开始构建方法调用字符串，格式为 -[接收者 方法名
    NSMutableString *string = [NSMutableString stringWithFormat:@"-[%@ %@", receiver, [splitSelector objectAtIndex:0]];
    // 遍历每个参数
    for (int paramNum = 0; paramNum < paramCount; paramNum++) {
        // 添加冒号（Objective-C方法参数分隔符）
        [string appendString:@":"];
        // 只处理前两个参数（因为寄存器中通常只保存前几个参数）
        if (paramNum < 2) {
            // 获取参数（从索引2开始，因为0是接收者，1是选择器）
            KSCrashDoctorParam *param = [self.params objectAtIndex:(NSUInteger)paramNum + 2];
            // 如果参数有值
            if (param.value != nil) {
                // 如果参数类型是字符串，用引号包围
                if ([param.type isEqualToString:KSCrashMemType_String]) {
                    [string appendFormat:@"\"%@\"", param.value];
                } else {
                    // 其他类型直接添加值
                    [string appendString:param.value];
                }
            } else if (param.previousClassName != nil) {
                // 如果参数没有值但有之前的类名（可能是僵尸对象），添加类名
                [string appendString:param.previousClassName];
            } else if (param.className != nil) {
                // 如果参数有类名，添加类名和类型（实例或类）
                [string appendFormat:@"%@ (%@)", param.className, param.isInstance ? @"instance" : @"class"];
            } else {
                // 无法确定参数信息，使用问号占位
                [string appendString:@"?"];
            }
        } else {
            // 超过前两个参数，使用问号占位
            [string appendString:@"?"];
        }
        // 如果不是最后一个参数，添加空格分隔
        if (paramNum < paramCount - 1) {
            [string appendString:@" "];
        }
    }

    // 添加右方括号，完成方法调用字符串
    [string appendString:@"]"];
    // 返回构建好的字符串
    return string;
}

// 生成带参数数量的函数调用描述字符串
// @param paramCount 要显示的参数数量
// @return 函数调用描述字符串
- (NSString *)descriptionWithParamCount:(int)paramCount
{
    // 尝试生成Objective-C方法调用描述
    NSString *objCCall = [self descriptionForObjCCall];
    // 如果成功生成，直接返回
    if (objCCall != nil) {
        return objCCall;
    }

    // 如果请求的参数数量超过实际参数数量，限制为实际数量
    if (paramCount > (int)self.params.count) {
        paramCount = (int)self.params.count;
    }
    // 创建可变字符串用于构建描述
    NSMutableString *str = [NSMutableString string];
    // 添加函数名
    [str appendFormat:@"Function: %@\n", self.name];
    // 遍历每个参数
    for (int i = 0; i < paramCount; i++) {
        // 获取参数对象
        KSCrashDoctorParam *param = [self.params objectAtIndex:(NSUInteger)i];
        // 添加参数编号
        [str appendFormat:@"Param %d:  ", i + 1];
        // 如果参数有类名，添加类名和类型信息
        if (param.className != nil) {
            [str appendFormat:@"%@ (%@) ", param.className, param.isInstance ? @"instance" : @"class"];
        }
        // 如果参数有值，添加值
        if (param.value != nil) {
            [str appendFormat:@"%@ ", param.value];
        }
        // 如果参数有之前的类名（可能是僵尸对象），添加提示
        if (param.previousClassName != nil) {
            [str appendFormat:@"(was %@)", param.previousClassName];
        }
        // 如果不是最后一个参数，添加换行符
        if (i < paramCount - 1) {
            [str appendString:@"\n"];
        }
    }
    // 返回构建好的描述字符串
    return str;
}

@end

// 崩溃诊断器实现
@implementation KSCrashDoctor

// 获取重崩溃报告（处理崩溃时再次崩溃的情况）
// @param report 崩溃报告字典
// @return 重崩溃报告字典，如果不存在则返回nil
- (NSDictionary *)recrashReport:(NSDictionary *)report
{
    // 从报告中提取重崩溃报告字段
    return [report objectForKey:KSCrashField_RecrashReport];
}

// 获取系统信息报告
// @param report 崩溃报告字典
// @return 系统信息字典，如果不存在则返回nil
- (NSDictionary *)systemReport:(NSDictionary *)report
{
    // 从报告中提取系统字段
    return [report objectForKey:KSCrashField_System];
}

// 获取崩溃信息报告
// @param report 崩溃报告字典
// @return 崩溃信息字典，如果不存在则返回nil
- (NSDictionary *)crashReport:(NSDictionary *)report
{
    // 从报告中提取崩溃字段
    return [report objectForKey:KSCrashField_Crash];
}

// 获取报告信息
// @param report 崩溃报告字典
// @return 报告信息字典，如果不存在则返回nil
- (NSDictionary *)infoReport:(NSDictionary *)report
{
    // 从报告中提取报告字段
    return [report objectForKey:KSCrashField_Report];
}

// 获取错误信息报告
// @param report 崩溃报告字典
// @return 错误信息字典，如果不存在则返回nil
- (NSDictionary *)errorReport:(NSDictionary *)report
{
    // 从崩溃报告中提取错误字段
    return [[self crashReport:report] objectForKey:KSCrashField_Error];
}

// 识别CPU架构族
// @param report 崩溃报告字典
// @return CPU架构族枚举值
- (CPUFamily)cpuFamily:(NSDictionary *)report
{
    // 获取系统信息
    NSDictionary *system = [self systemReport:report];
    // 获取CPU架构字符串
    NSString *cpuArch = [system objectForKey:KSCrashField_CPUArch];
    // 检查是否为ARM架构（以"arm"开头）
    if ([cpuArch rangeOfString:@"arm"].location == 0) {
        return CPUFamilyArm;
    }
    // 检查是否为x86架构（以"i"开头，第三个字符开始是"86"）
    if ([cpuArch rangeOfString:@"i"].location == 0 && [cpuArch rangeOfString:@"86"].location == 2) {
        return CPUFamilyX86;
    }
    // 检查是否为x86_64架构（不区分大小写）
    if ([cpuArch rangeOfString:@"x86_64" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        return CPUFamilyX86_64;
    }
    // 无法识别，返回未知
    return CPUFamilyUnknown;
}

// 根据CPU架构族和参数索引获取寄存器名称
// @param family CPU架构族
// @param index 参数索引（0-3）
// @return 寄存器名称字符串，如果索引超出范围则返回nil
- (NSString *)registerNameForFamily:(CPUFamily)family paramIndex:(int)index
{
    // 根据CPU架构族选择寄存器命名规则
    switch (family) {
        // ARM架构
        case CPUFamilyArm: {
            // 根据参数索引返回对应的ARM寄存器名称
            switch (index) {
                case 0:
                    return @"r0";
                case 1:
                    return @"r1";
                case 2:
                    return @"r2";
                case 3:
                    return @"r3";
                default:
                    // 索引超出范围，返回nil
                    return nil;
            }
        }
        // x86架构（32位）
        case CPUFamilyX86: {
            // 根据参数索引返回对应的x86寄存器名称
            switch (index) {
                case 0:
                    return @"edi";
                case 1:
                    return @"esi";
                case 2:
                    return @"edx";
                case 3:
                    return @"ecx";
                default:
                    // 索引超出范围，返回nil
                    return nil;
            }
        }
        // x86_64架构（64位）
        case CPUFamilyX86_64: {
            // 根据参数索引返回对应的x86_64寄存器名称
            switch (index) {
                case 0:
                    return @"rdi";
                case 1:
                    return @"rsi";
                case 2:
                    return @"rdx";
                case 3:
                    return @"rcx";
                default:
                    // 索引超出范围，返回nil
                    return nil;
            }
        }
        default:
            // 未知架构，返回nil
            return nil;
    }
}

// 获取主可执行文件名
// @param report 崩溃报告字典
// @return 主可执行文件名，如果不存在则返回nil
- (NSString *)mainExecutableNameForReport:(NSDictionary *)report
{
    // 获取报告信息
    NSDictionary *info = [self infoReport:report];
    // 从报告信息中提取进程名称
    return [info objectForKey:KSCrashField_ProcessName];
}

// 获取崩溃线程报告
// @param report 崩溃报告字典
// @return 崩溃线程字典，如果不存在则返回nil
- (NSDictionary *)crashedThreadReport:(NSDictionary *)report
{
    // 获取崩溃报告
    NSDictionary *crashReport = [self crashReport:report];
    // 尝试直接获取崩溃线程字段
    NSDictionary *crashedThread = [crashReport objectForKey:KSCrashField_CrashedThread];
    // 如果存在，直接返回
    if (crashedThread != nil) {
        return crashedThread;
    }

    // 如果直接字段不存在，遍历所有线程查找崩溃线程
    for (NSDictionary *thread in [crashReport objectForKey:KSCrashField_Threads]) {
        // 检查线程的崩溃标志
        if ([[thread objectForKey:KSCrashField_Crashed] boolValue]) {
            // 找到崩溃线程，返回它
            return thread;
        }
    }
    // 未找到崩溃线程，返回nil
    return nil;
}

// 从线程报告中获取回溯信息
// @param threadReport 线程报告字典
// @return 回溯内容数组，如果不存在则返回nil
- (NSArray *)backtraceFromThreadReport:(NSDictionary *)threadReport
{
    // 从线程报告中提取回溯字典
    NSDictionary *backtrace = [threadReport objectForKey:KSCrashField_Backtrace];
    // 从回溯字典中提取内容数组
    return [backtrace objectForKey:KSCrashField_Contents];
}

// 从线程报告中获取基本寄存器信息
// @param threadReport 线程报告字典
// @return 基本寄存器字典，如果不存在则返回nil
- (NSDictionary *)basicRegistersFromThreadReport:(NSDictionary *)threadReport
{
    // 从线程报告中提取寄存器字典
    NSDictionary *registers = [threadReport objectForKey:KSCrashField_Registers];
    // 从寄存器字典中提取基本寄存器字典
    NSDictionary *basic = [registers objectForKey:KSCrashField_Basic];
    // 返回基本寄存器字典
    return basic;
}

// 获取应用程序中最后一个栈条目（用于定位崩溃发生在应用代码中的位置）
// @param report 崩溃报告字典
// @return 最后一个应用栈条目字典，如果不存在则返回nil
- (NSDictionary *)lastInAppStackEntry:(NSDictionary *)report
{
    // 获取主可执行文件名
    NSString *executableName = [self mainExecutableNameForReport:report];
    // 获取崩溃线程报告
    NSDictionary *crashedThread = [self crashedThreadReport:report];
    // 获取回溯数组
    NSArray *backtrace = [self backtraceFromThreadReport:crashedThread];
    // 遍历回溯数组，查找属于主可执行文件的栈条目
    for (NSDictionary *entry in backtrace) {
        // 获取栈条目的对象名
        NSString *objectName = [entry objectForKey:KSCrashField_ObjectName];
        // 如果对象名与主可执行文件名相同，返回此条目
        if ([objectName isEqualToString:executableName]) {
            return entry;
        }
    }
    // 未找到应用栈条目，返回nil
    return nil;
}

// 获取最后一个栈条目（栈顶条目，通常是崩溃发生的位置）
// @param report 崩溃报告字典
// @return 最后一个栈条目字典，如果不存在则返回nil
- (NSDictionary *)lastStackEntry:(NSDictionary *)report
{
    // 获取崩溃线程报告
    NSDictionary *crashedThread = [self crashedThreadReport:report];
    // 获取回溯数组
    NSArray *backtrace = [self backtraceFromThreadReport:crashedThread];
    // 如果回溯数组不为空，返回第一个条目（栈顶）
    if ([backtrace count] > 0) {
        return [backtrace objectAtIndex:0];
    }
    // 回溯数组为空，返回nil
    return nil;
}

// 检查是否为无效地址错误（访问无效内存地址）
// @param errorReport 错误报告字典
// @return 如果是无效地址错误则返回YES，否则返回NO
- (BOOL)isInvalidAddress:(NSDictionary *)errorReport
{
    // 获取Mach异常信息
    NSDictionary *machError = [errorReport objectForKey:KSCrashField_Mach];
    // 如果存在Mach异常信息
    if (machError != nil) {
        // 获取异常名称
        NSString *exceptionName = [machError objectForKey:KSCrashField_ExceptionName];
        // 检查是否为EXC_BAD_ACCESS异常（无效内存访问）
        return [exceptionName isEqualToString:@"EXC_BAD_ACCESS"];
    }
    // 如果不存在Mach异常，检查信号信息
    NSDictionary *signal = [errorReport objectForKey:KSCrashField_Signal];
    // 获取信号名称
    NSString *sigName = [signal objectForKey:KSCrashField_Name];
    // 检查是否为SIGSEGV信号（段错误，通常由无效内存访问引起）
    return [sigName isEqualToString:@"SIGSEGV"];
}

// 检查是否为数学错误（如除零）
// @param errorReport 错误报告字典
// @return 如果是数学错误则返回YES，否则返回NO
- (BOOL)isMathError:(NSDictionary *)errorReport
{
    // 获取Mach异常信息
    NSDictionary *machError = [errorReport objectForKey:KSCrashField_Mach];
    // 如果存在Mach异常信息
    if (machError != nil) {
        // 获取异常名称
        NSString *exceptionName = [machError objectForKey:KSCrashField_ExceptionName];
        // 检查是否为EXC_ARITHMETIC异常（算术异常）
        return [exceptionName isEqualToString:@"EXC_ARITHMETIC"];
    }
    // 如果不存在Mach异常，检查信号信息
    NSDictionary *signal = [errorReport objectForKey:KSCrashField_Signal];
    // 获取信号名称
    NSString *sigName = [signal objectForKey:KSCrashField_Name];
    // 检查是否为SIGFPE信号（浮点异常，通常由除零引起）
    return [sigName isEqualToString:@"SIGFPE"];
}

// 检查是否为内存损坏错误
// @param report 崩溃报告字典
// @return 如果是内存损坏错误则返回YES，否则返回NO
- (BOOL)isMemoryCorruption:(NSDictionary *)report
{
    // 获取崩溃线程报告
    NSDictionary *crashedThread = [self crashedThreadReport:report];
    // 获取显著地址数组（包含内存损坏相关的地址信息）
    NSArray *notableAddresses = [crashedThread objectForKey:KSCrashField_NotableAddresses];
    // 遍历显著地址
    for (NSDictionary *address in [notableAddresses objectEnumerator]) {
        // 获取地址类型
        NSString *type = [address objectForKey:KSCrashField_Type];
        // 如果类型为字符串
        if ([type isEqualToString:@"string"]) {
            // 获取地址值
            NSString *value = [address objectForKey:KSCrashField_Value];
            // 检查是否包含"autorelease pool page"和"corrupted"（自动释放池页损坏）
            if ([value rangeOfString:@"autorelease pool page"].location != NSNotFound &&
                [value rangeOfString:@"corrupted"].location != NSNotFound) {
                return YES;
            }
            // 检查是否包含"incorrect checksum for freed object"（已释放对象的校验和不正确）
            if ([value rangeOfString:@"incorrect checksum for freed object"].location != NSNotFound) {
                return YES;
            }
        }
    }

    // 获取回溯数组
    NSArray *backtrace = [self backtraceFromThreadReport:crashedThread];
    // 遍历回溯条目，查找内存损坏相关的符号
    for (NSDictionary *entry in backtrace) {
        // 获取对象名
        NSString *objectName = [entry objectForKey:KSCrashField_ObjectName];
        // 获取符号名
        NSString *symbolName = [entry objectForKey:KSCrashField_SymbolName];
        // 检查是否为自动释放池推送（可能表示自动释放池损坏）
        if ([symbolName isEqualToString:@"objc_autoreleasePoolPush"]) {
            return YES;
        }
        // 检查是否为释放列表校验和错误（内存损坏的典型标志）
        if ([symbolName isEqualToString:@"free_list_checksum_botch"]) {
            return YES;
        }
        // 检查是否为内存分配区域清理函数（可能表示内存损坏）
        if ([symbolName isEqualToString:@"szone_malloc_should_clear"]) {
            return YES;
        }
        // 检查是否为Objective-C运行时的方法查找函数（在libobjc中，可能表示对象损坏）
        if ([symbolName isEqualToString:@"lookUpMethod"] && [objectName isEqualToString:@"libobjc.A.dylib"]) {
            return YES;
        }
    }

    // 未发现内存损坏标志，返回NO
    return NO;
}

// 获取最后一个函数调用信息（从栈顶和寄存器中提取）
// @param report 崩溃报告字典
// @return 函数调用对象，包含函数名和参数信息
- (KSCrashDoctorFunctionCall *)lastFunctionCall:(NSDictionary *)report
{
    // 创建函数调用对象
    KSCrashDoctorFunctionCall *function = [[KSCrashDoctorFunctionCall alloc] init];
    // 获取最后一个栈条目
    NSDictionary *lastStackEntry = [self lastStackEntry:report];
    // 从栈条目中提取符号名（函数名）
    function.name = [lastStackEntry objectForKey:KSCrashField_SymbolName];

    // 获取崩溃线程报告
    NSDictionary *crashedThread = [self crashedThreadReport:report];
    // 获取显著地址字典（包含寄存器中地址的详细信息）
    NSDictionary *notableAddresses = [crashedThread objectForKey:KSCrashField_NotableAddresses];
    // 识别CPU架构族
    CPUFamily family = [self cpuFamily:report];
    // 获取基本寄存器字典
    NSDictionary *registers = [self basicRegistersFromThreadReport:crashedThread];
    // 根据CPU架构族获取前4个参数寄存器的名称
    NSArray *regNames = [NSArray arrayWithObjects:[self registerNameForFamily:family paramIndex:0],
                                                  [self registerNameForFamily:family paramIndex:1],
                                                  [self registerNameForFamily:family paramIndex:2],
                                                  [self registerNameForFamily:family paramIndex:3], nil];
    // 创建参数数组，容量为4
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:4];
    // 遍历每个寄存器名称
    for (NSString *regName in regNames) {
        // 创建参数对象
        KSCrashDoctorParam *param = [[KSCrashDoctorParam alloc] init];
        // 从寄存器中获取地址值并转换为uintptr_t类型
        param.address = (uintptr_t)[[registers objectForKey:regName] unsignedLongLongValue];
        // 查找此寄存器地址的显著地址信息
        NSDictionary *notableAddress = [notableAddresses objectForKey:regName];
        // 如果没有显著地址信息
        if (notableAddress == nil) {
            // 将地址格式化为指针字符串
            param.value = [NSString stringWithFormat:@"%p", (void *)param.address];
        } else {
            // 从显著地址信息中提取类型
            param.type = [notableAddress objectForKey:KSCrashField_Type];
            // 提取类名
            NSString *className = [notableAddress objectForKey:KSCrashField_Class];
            // 提取之前的类名（用于检测僵尸对象）
            NSString *previousClass = [notableAddress objectForKey:KSCrashField_LastDeallocObject];
            // 提取值
            NSString *value = [notableAddress objectForKey:KSCrashField_Value];

            // 根据类型设置参数属性
            if ([param.type isEqualToString:KSCrashMemType_String]) {
                // 字符串类型，直接使用值
                param.value = value;
            } else if ([param.type isEqualToString:KSCrashMemType_Object]) {
                // 对象类型，设置类名和实例标志
                param.className = className;
                param.isInstance = YES;
            } else if ([param.type isEqualToString:KSCrashMemType_Class]) {
                // 类类型，设置类名和类标志
                param.className = className;
                param.isInstance = NO;
            }
            // 设置之前的类名（用于检测僵尸对象）
            param.previousClassName = previousClass;
        }

        // 将参数添加到参数数组
        [params addObject:param];
    }

    // 设置函数的参数数组
    function.params = params;
    // 返回函数调用对象
    return function;
}

// 检查函数调用是否为僵尸对象调用
// @param functionCall 函数调用对象
// @return 如果是僵尸对象调用则返回描述字符串，否则返回nil
- (NSString *)zombieCall:(KSCrashDoctorFunctionCall *)functionCall
{
    // 检查是否为objc_msgSend调用且第一个参数有之前的类名（僵尸对象标志）
    if ([functionCall.name isEqualToString:@"objc_msgSend"] && functionCall.params.count > 0 &&
        [[functionCall.params objectAtIndex:0] previousClassName] != nil) {
        // 返回带4个参数的描述字符串
        return [functionCall descriptionWithParamCount:4];
    } else if ([functionCall.name isEqualToString:@"objc_retain"] && functionCall.params.count > 0 &&
               [[functionCall.params objectAtIndex:0] previousClassName] != nil) {
        // 检查是否为objc_retain调用且第一个参数有之前的类名（僵尸对象标志）
        // 返回带1个参数的描述字符串
        return [functionCall descriptionWithParamCount:1];
    }
    // 不是僵尸对象调用，返回nil
    return nil;
}

// 检查是否为栈溢出错误
// @param crashedThreadReport 崩溃线程报告字典
// @return 如果是栈溢出则返回YES，否则返回NO
- (BOOL)isStackOverflow:(NSDictionary *)crashedThreadReport
{
    // 获取栈信息字典
    NSDictionary *stack = [crashedThreadReport objectForKey:KSCrashField_Stack];
    // 检查栈溢出标志
    return [[stack objectForKey:KSCrashField_Overflow] boolValue];
}

// 检查是否为死锁错误
// @param report 崩溃报告字典
// @return 如果是死锁则返回YES，否则返回NO
- (BOOL)isDeadlock:(NSDictionary *)report
{
    // 获取错误报告
    NSDictionary *errorReport = [self errorReport:report];
    // 获取崩溃类型
    NSString *crashType = [errorReport objectForKey:KSCrashField_Type];
    // 检查是否为死锁类型
    return [KSCrashExcType_Deadlock isEqualToString:crashType];
}

// 在诊断字符串后追加原始调用信息
// @param string 原始诊断字符串
// @param callName 调用名称
// @return 追加了原始调用信息的字符串
- (NSString *)appendOriginatingCall:(NSString *)string callName:(NSString *)callName
{
    // 如果调用名不为空且不是"main"函数
    if (callName != nil && ![callName isEqualToString:@"main"]) {
        // 追加原始调用信息
        return [string stringByAppendingFormat:@"\nOriginated at or in a subcall of %@", callName];
    }
    // 如果是"main"函数或调用名为空，直接返回原字符串
    return string;
}

// 检查是否为优雅终止请求（SIGTERM信号）
// @param report 崩溃报告字典
// @return 如果是优雅终止请求则返回YES，否则返回NO
- (BOOL)isGracefulTerminationRequest:(NSDictionary *)report
{
    // 检查信号值是否为SIGTERM（优雅终止信号）
    return [report[KSCrashField_Signal][KSCrashField_Signal] integerValue] == SIGTERM;
}

// 检查是否为内存终止（OOM - Out of Memory）
// @param report 崩溃报告字典
// @return 如果是内存终止则返回YES，否则返回NO
- (BOOL)isMemoryTermination:(NSDictionary *)report
{
    // 检查崩溃类型是否为内存终止类型
    return [report[KSCrashField_Type] isEqualToString:KSCrashExcType_MemoryTermination];
}

// 检查是否为看门狗超时终止（应用无响应被系统终止）
// 看门狗超时终止的特征：
// - EXC_CRASH Mach异常
// - SIGKILL信号（信号9）
// - 退出原因代码0x8badf00d（"ate bad food"）
// @param errorReport 错误报告字典
// @return 如果是看门狗超时终止则返回YES，否则返回NO
- (BOOL)isWatchdogTimeoutTermination:(NSDictionary *)errorReport
{
    // 获取Mach异常信息
    NSDictionary *machError = [errorReport objectForKey:KSCrashField_Mach];
    // 如果不存在Mach异常信息，返回NO
    if (machError == nil) {
        return NO;
    }

    // 获取异常名称
    NSString *exceptionName = [machError objectForKey:KSCrashField_ExceptionName];
    // 检查是否为EXC_CRASH异常
    if (![exceptionName isEqualToString:@"EXC_CRASH"]) {
        return NO;
    }

    // 获取信号信息
    NSDictionary *signal = [errorReport objectForKey:KSCrashField_Signal];
    // 获取信号代码
    NSInteger signalCode = [[signal objectForKey:KSCrashField_Signal] integerValue];
    // 检查是否为SIGKILL信号（信号9）
    if (signalCode != SIGKILL) {
        return NO;
    }

    // 获取退出原因信息
    NSDictionary *exitReason = [errorReport objectForKey:KSCrashField_ExitReason];
    // 如果不存在退出原因信息，返回NO
    if (exitReason == nil) {
        return NO;
    }

    // 获取退出原因代码
    uint64_t code = [[exitReason objectForKey:KSCrashField_Code] unsignedLongLongValue];
    // 检查是否为0x8badf00d（看门狗超时的特征代码）
    return code == 0x8badf00d;
}

// 检查是否为挂起错误（应用无响应）
// @param errorReport 错误报告字典
// @return 如果是挂起错误则返回YES，否则返回NO
- (BOOL)isHang:(NSDictionary *)errorReport
{
    // 检查错误报告中是否存在挂起字段
    return [errorReport objectForKey:KSCrashField_Hang] != nil;
}

// 获取挂起持续时间
// @param errorReport 错误报告字典
// @return 挂起持续时间的字符串表示（如"2.50 seconds"），如果无法计算则返回nil
- (NSString *)hangDuration:(NSDictionary *)errorReport
{
    // 获取挂起信息字典
    NSDictionary *hang = [errorReport objectForKey:KSCrashField_Hang];
    // 如果不存在挂起信息，返回nil
    if (hang == nil) {
        return nil;
    }

    // 获取挂起开始时间（纳秒）
    uint64_t startNanos = [[hang objectForKey:KSCrashField_HangStartNanoseconds] unsignedLongLongValue];
    // 获取挂起结束时间（纳秒）
    uint64_t endNanos = [[hang objectForKey:KSCrashField_HangEndNanoseconds] unsignedLongLongValue];

    // 如果开始时间大于0且结束时间大于开始时间
    if (startNanos > 0 && endNanos > startNanos) {
        // 计算持续时间（秒），将纳秒转换为秒
        double durationSeconds = (double)(endNanos - startNanos) / 1000000000.0;
        // 格式化为字符串，保留两位小数
        return [NSString stringWithFormat:@"%.2f seconds", durationSeconds];
    }
    // 无法计算持续时间，返回nil
    return nil;
}

// 诊断崩溃报告，生成人类可读的诊断信息
// @param report 崩溃报告字典
// @return 诊断信息字符串，如果无法诊断则返回nil
- (NSString *)diagnoseCrash:(NSDictionary *)report
{
    // 使用异常处理，防止诊断过程中出现异常
    @try {
        // 获取应用程序中最后一个栈条目的函数名
        NSString *lastFunctionName = [[self lastInAppStackEntry:report] objectForKey:KSCrashField_SymbolName];
        // 获取崩溃线程报告
        NSDictionary *crashedThreadReport = [self crashedThreadReport:report];
        // 获取错误报告
        NSDictionary *errorReport = [self errorReport:report];

        // 检查是否为死锁
        if ([self isDeadlock:report]) {
            // 返回死锁诊断信息
            return [NSString stringWithFormat:@"Main thread deadlocked in %@", lastFunctionName];
        }

        // 检查是否为看门狗超时终止
        if ([self isWatchdogTimeoutTermination:errorReport]) {
            // 获取挂起持续时间
            NSString *duration = [self hangDuration:errorReport];
            // 如果存在持续时间，返回包含持续时间的诊断信息
            if (duration != nil) {
                return [NSString stringWithFormat:@"App hung for %@. Terminated by watchdog.", duration];
            }
            // 如果不存在持续时间，返回基本诊断信息
            return @"App terminated by watchdog.";
        }

        // 检查是否为栈溢出
        if ([self isStackOverflow:crashedThreadReport]) {
            // 返回栈溢出诊断信息
            return [NSString stringWithFormat:@"Stack overflow in %@", lastFunctionName];
        }

        // 获取崩溃类型
        NSString *crashType = [errorReport objectForKey:KSCrashField_Type];
        // 检查是否为NSException异常
        if ([crashType isEqualToString:KSCrashExcType_NSException]) {
            // 获取异常信息
            NSDictionary *exception = [errorReport objectForKey:KSCrashField_NSException];
            // 获取异常名称
            NSString *name = [exception objectForKey:KSCrashField_Name];
            // 获取异常原因（优先使用异常字典中的原因，否则使用错误报告中的原因）
            NSString *reason = [exception objectForKey:KSCrashField_Reason]
                                   ? [exception objectForKey:KSCrashField_Reason]
                                   : [errorReport objectForKey:KSCrashField_Reason];
            // 返回NSException诊断信息，并追加原始调用信息
            return [self
                appendOriginatingCall:[NSString stringWithFormat:@"Application threw exception %@: %@", name, reason]
                             callName:lastFunctionName];
        }

        // 检查是否为内存损坏
        if ([self isMemoryCorruption:report]) {
            // 返回内存损坏诊断信息
            return @"Rogue memory write has corrupted memory.";
        }

        // 检查是否为数学错误
        if ([self isMathError:errorReport]) {
            // 返回数学错误诊断信息，并追加原始调用信息
            return [self
                appendOriginatingCall:[NSString stringWithFormat:@"Math error (usually caused from division by 0)."]
                             callName:lastFunctionName];
        }

        // 获取最后一个函数调用信息
        KSCrashDoctorFunctionCall *functionCall = [self lastFunctionCall:report];
        // 检查是否为僵尸对象调用
        NSString *zombieCall = [self zombieCall:functionCall];
        // 如果是僵尸对象调用
        if (zombieCall != nil) {
            // 返回僵尸对象诊断信息，并追加原始调用信息
            return [self appendOriginatingCall:[NSString stringWithFormat:@"Possible zombie in call: %@", zombieCall]
                                      callName:lastFunctionName];
        }

        // 检查是否为无效地址错误
        if ([self isInvalidAddress:errorReport]) {
            // 获取访问的地址
            uintptr_t address = (uintptr_t)[[errorReport objectForKey:KSCrashField_Address] unsignedLongLongValue];
            // 如果地址为0，返回空指针诊断信息
            if (address == 0) {
                return [self appendOriginatingCall:@"Attempted to dereference null pointer." callName:lastFunctionName];
            }
            // 如果地址不为0，返回垃圾指针诊断信息
            return
                [self appendOriginatingCall:[NSString stringWithFormat:@"Attempted to dereference garbage pointer %p.",
                                                                       (void *)address]
                                   callName:lastFunctionName];
        }

        // 检查是否为优雅终止请求
        if ([self isGracefulTerminationRequest:errorReport]) {
            // 返回优雅终止诊断信息
            return @"The OS request the app be gracefully terminated.";
        }

        // 检查是否为内存终止（OOM）
        if ([self isMemoryTermination:errorReport]) {
            // 返回内存终止诊断信息
            return @"The app was terminated due to running out of memory (OOM).";
        }

        // 无法诊断，返回nil
        return nil;
    } @catch (NSException *e) {
        // 如果诊断过程中发生异常，获取调用栈符号
        NSArray *symbols = [e callStackSymbols];
        // 如果存在调用栈符号
        if (symbols) {
            // 返回包含异常和调用栈的诊断信息
            return [NSString
                stringWithFormat:
                    @"No diagnosis due to exception %@:\n%@\nPlease file a bug report to the KSCrash project.", e,
                    symbols];
        }
        // 如果不存在调用栈符号，返回基本异常信息
        return [NSString
            stringWithFormat:@"No diagnosis due to exception %@\nPlease file a bug report to the KSCrash project.", e];
    }
}

@end
