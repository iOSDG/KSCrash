//
//  KSCrashDoctor.h
//  KSCrash
//
//  Created by Karl Stenerud on 2012-11-10.
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
//

// 导入Foundation框架
#import <Foundation/Foundation.h>
// 导入命名空间头文件
#include "KSCrashNamespace.h"

/** 崩溃诊断器类
 * 用于分析崩溃报告并生成人类可读的诊断信息
 */
@interface KSCrashDoctor : NSObject

/** 诊断崩溃报告
 * @param crashReport 崩溃报告字典
 * @return 诊断结果字符串，如果无法诊断则返回nil
 */
- (NSString *)diagnoseCrash:(NSDictionary *)crashReport;

@end
