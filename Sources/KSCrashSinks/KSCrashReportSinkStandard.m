//
//  KSCrashReportSinkStandard.m
//
//  Created by Karl Stenerud on 2012-02-18.
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

// 导入标准报告输出目标头文件，包含类接口声明
#import "KSCrashReportSinkStandard.h"

// 导入崩溃报告协议，定义报告接口
#import "KSCrashReport.h"
// 导入GZip压缩辅助工具（当前未使用，但保留以备将来使用）
#import "KSGZipHelper.h"
// 导入HTTP多部分表单数据构建工具，用于构建multipart/form-data请求体
#import "KSHTTPMultipartPostBody.h"
// 导入HTTP请求发送工具，用于发送HTTP请求
#import "KSHTTPRequestSender.h"
// 导入JSON编码解码工具，用于将报告编码为JSON
#import "KSJSONCodecObjC.h"
// 导入网络可达性检测工具，用于在网络可用时发送报告
#import "KSReachabilityKSCrash.h"

// #define KSLogger_LocalLevel TRACE
// 导入日志记录工具
#import "KSLogger.h"

// 定义KSCrashReportSinkStandard类的私有扩展
@interface KSCrashReportSinkStandard ()

// 报告上传的目标URL（可读写）
@property(nonatomic, readwrite, strong) NSURL *url;

// 网络可达性操作，用于在网络可用时发送报告（可读写）
@property(nonatomic, readwrite, strong) KSReachableOperationKSCrash *reachableOperation;

@end

// 实现KSCrashReportSinkStandard类
// 这是标准的报告输出目标，通过HTTP POST请求将崩溃报告发送到服务器
@implementation KSCrashReportSinkStandard

// 使用指定URL初始化报告输出目标
// url: 报告上传的目标URL
// 返回初始化后的实例
- (instancetype)initWithURL:(NSURL *)url
{
    // 调用父类初始化方法
    if ((self = [super init])) {
        // 保存目标URL
        _url = url;
    }
    // 返回初始化后的实例
    return self;
}

// 返回默认的崩溃报告过滤器集合
// 此Sink本身就是一个过滤器，所以返回self
- (id<KSCrashReportFilter>)defaultCrashReportFilterSet
{
    // 返回自身，因为此Sink实现了过滤器协议
    return self;
}

// 过滤并发送报告（实现KSCrashReportFilter协议）
// 将报告编码为JSON，通过HTTP POST请求发送到服务器
// reports: 要发送的报告数组
// onCompletion: 完成回调，在发送完成后调用，传入过滤后的报告和错误信息
- (void)filterReports:(NSArray<id<KSCrashReport>> *)reports onCompletion:(KSCrashReportFilterCompletion)onCompletion
{
    // 声明错误变量
    NSError *error = nil;
    // 创建HTTP请求对象
    // cachePolicy设置为忽略本地缓存，确保每次都发送新请求
    // timeoutInterval设置为15秒，超时后取消请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:15];
    // 创建多部分表单数据构建器（用于构建multipart/form-data格式的请求体）
    KSHTTPMultipartPostBody *body = [KSHTTPMultipartPostBody body];
    // 创建可变数组用于存储报告数据（用于JSON编码）
    NSMutableArray *jsonArray = [NSMutableArray array];
    // 遍历所有报告，提取数据
    for (id<KSCrashReport> report in reports) {
        // 检查报告类型是否为字典类型
        if ([report isKindOfClass:[KSCrashReportDictionary class]]) {
            // 转换为字典类型报告
            KSCrashReportDictionary *dReport = report;
            // 如果报告值不为nil，添加到数组
            if (dReport.value != nil) {
                [jsonArray addObject:dReport.value];
            }
        } else if ([report isKindOfClass:[KSCrashReportString class]]) {
            // 检查报告类型是否为字符串类型
            // 转换为字符串类型报告
            KSCrashReportString *sReport = report;
            // 如果报告值不为nil，添加到数组
            if (sReport.value != nil) {
                [jsonArray addObject:sReport.value];
            }
        } else {
            // 遇到意外的报告类型，记录错误日志
            KSLOG_ERROR(@"Unexpected non-dictionary/non-string report: %@", report);
        }
    }
    // 将报告数组编码为JSON数据
    // KSJSONEncodeOptionSorted选项确保JSON键按字母顺序排序，便于比较和调试
    NSData *jsonData = [KSJSONCodec encode:jsonArray options:KSJSONEncodeOptionSorted error:&error];
    // 检查编码是否成功
    if (jsonData == nil) {
        // 编码失败，调用完成回调并返回错误
        kscrash_callCompletion(onCompletion, reports, error);
        return;
    }

    // 将JSON数据添加到多部分表单数据中
    // name: 表单字段名称（"reports"）
    // contentType: 内容类型为application/json
    // filename: 文件名（"reports.json"，用于多部分表单）
    [body appendData:jsonData name:@"reports" contentType:@"application/json" filename:@"reports.json"];
    // TODO: 已禁用gzip压缩，直到服务器端添加支持
    // 并且修复了appendUTF8String中的一个bug
    //    [body appendUTF8String:@"json"
    //                      name:@"encoding"
    //               contentType:@"string"
    //                  filename:nil];

    // 设置HTTP方法为POST
    request.HTTPMethod = @"POST";
    // 设置请求体为多部分表单数据
    request.HTTPBody = [body data];
    // 设置Content-Type头，指定多部分表单数据的边界
    [request setValue:body.contentType forHTTPHeaderField:@"Content-Type"];
    // 设置User-Agent头，标识发送方为KSCrashReporter
    [request setValue:@"KSCrashReporter" forHTTPHeaderField:@"User-Agent"];

    // 注释掉的GZip压缩代码（将来可能启用）
    //    [request setHTTPBody:[[body data] gzippedWithError:nil]];
    //    [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];

    // 创建网络可达性操作
    // 只有当网络可用时（WiFi或WWAN）才执行发送操作
    self.reachableOperation = [KSReachableOperationKSCrash
        // 从URL中提取主机名
        operationWithHost:[self.url host]
        // 允许使用WWAN（蜂窝网络）
        allowWWAN:YES
        // 网络可用时执行的代码块
        block:^{
            // 发送HTTP请求
            [[KSHTTPRequestSender sender] sendRequest:request
                // 请求成功时的回调（HTTP状态码2xx）
                onSuccess:^(__unused NSHTTPURLResponse *response, __unused NSData *data) {
                    // 调用完成回调，传入报告和nil错误（表示成功）
                    kscrash_callCompletion(onCompletion, reports, nil);
                }
                // 请求失败时的回调（HTTP错误状态码，非2xx）
                onFailure:^(NSHTTPURLResponse *response, NSData *data) {
                    // 将响应数据转换为字符串（用于错误信息）
                    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    // 创建错误对象，包含HTTP状态码和响应文本
                    kscrash_callCompletion(
                        onCompletion, reports,
                        [NSError
                            errorWithDomain:[[self class] description]
                            // 使用HTTP状态码作为错误代码
                            code:response.statusCode
                            // 将响应文本作为错误描述
                            userInfo:[NSDictionary dictionaryWithObject:text
                                                                forKey:NSLocalizedDescriptionKey]]);
                }
                // 请求错误时的回调（网络错误等）
                onError:^(NSError *error2) {
                    // 调用完成回调，传入报告和错误信息
                    kscrash_callCompletion(onCompletion, reports, error2);
                }];
        }];
}

@end
