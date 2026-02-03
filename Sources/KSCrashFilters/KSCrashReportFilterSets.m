//
//  KSCrashFilterSets.m
//
//  Created by Karl Stenerud on 2012-08-21.
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

// 导入过滤器集合头文件
#import "KSCrashReportFilterSets.h"
// 导入崩溃报告字段常量
#import "KSCrashReportFields.h"
// 导入基础过滤器
#import "KSCrashReportFilterBasic.h"
// 导入GZip压缩过滤器
#import "KSCrashReportFilterGZip.h"
// 导入JSON过滤器
#import "KSCrashReportFilterJSON.h"

// 过滤器集合实现
@implementation KSCrashFilterSets

// 创建包含Apple格式报告和用户/系统数据的过滤器
// @param reportStyle Apple报告样式（符号化选项）
// @param compressed 是否压缩最终输出
// @return 配置好的过滤器管道
+ (id<KSCrashReportFilter>)appleFmtWithUserAndSystemData:(KSAppleReportStyle)reportStyle compressed:(BOOL)compressed
{
    // Apple报告部分的名称常量
    NSString *const kAppleReportName = @"Apple Report";
    // 用户和系统数据部分的名称常量
    NSString *const kUserSystemDataName = @"User & System Data";

    // 创建Apple格式过滤器，使用指定的报告样式
    id<KSCrashReportFilter> appleFilter = [[KSCrashReportFilterAppleFmt alloc] initWithReportStyle:reportStyle];
    // 创建用户和系统数据过滤器管道
    id<KSCrashReportFilter> userSystemFilter = [self createUserSystemFilterPipeline];

    // 创建组合过滤器，将Apple报告和用户/系统数据组合在一起
    id<KSCrashReportFilter> combineFilter = [[KSCrashReportFilterCombine alloc]
        initWithFilters:@{ kAppleReportName : appleFilter, kUserSystemDataName : userSystemFilter }];

    // 创建连接过滤器，使用分隔符格式将两部分连接起来
    id<KSCrashReportFilter> concatenateFilter =
        [[KSCrashReportFilterConcatenate alloc] initWithSeparatorFmt:@"\n\n-------- %@ --------\n\n"
                                                                keys:@[ kAppleReportName, kUserSystemDataName ]];

    // 创建主过滤器数组，包含组合过滤器和连接过滤器
    NSMutableArray *mainFilters = [NSMutableArray arrayWithObjects:combineFilter, concatenateFilter, nil];

    // 如果需要压缩
    if (compressed) {
        // 添加字符串到数据的转换过滤器
        [mainFilters addObject:[KSCrashReportFilterStringToData new]];
        // 添加GZip压缩过滤器，使用默认压缩级别（-1）
        [mainFilters addObject:[[KSCrashReportFilterGZipCompress alloc] initWithCompressionLevel:-1]];
    }

    // 创建并返回过滤器管道，按顺序应用所有过滤器
    return [[KSCrashReportFilterPipeline alloc] initWithFilters:mainFilters];
}

// 创建用户和系统数据过滤器管道
// @return 配置好的过滤器管道，提取系统信息和用户数据，编码为JSON并转换为字符串
+ (id<KSCrashReportFilter>)createUserSystemFilterPipeline
{
    // 创建过滤器管道，包含三个步骤
    return [[KSCrashReportFilterPipeline alloc] initWithFilters:@[
        // 第一步：提取子集，只保留系统和用户字段
        [[KSCrashReportFilterSubset alloc] initWithKeys:@[ KSCrashField_System, KSCrashField_User ]],
        // 第二步：将字典编码为JSON，使用美化格式和排序选项
        [[KSCrashReportFilterJSONEncode alloc] initWithOptions:KSJSONEncodeOptionPretty | KSJSONEncodeOptionSorted],
        // 第三步：将JSON数据转换为字符串
        [KSCrashReportFilterDataToString new]
    ]];
}

@end
