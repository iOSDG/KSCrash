//
//  Profile.Report.swift
//
//  Created by Alexander Cohen on 2025-12-17.
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

// 导入Foundation框架
import Foundation

#if SWIFT_PACKAGE
    // 在Swift Package Manager环境下，导入KSCrashRecording和KSCrashRecordingCore模块
    import KSCrashRecording
    import KSCrashRecordingCore
#endif

// MARK: - Profile Report Writing

/// Extension that provides crash report writing functionality for profiles.
///
/// This extension registers a custom KSCrash monitor that allows profiles to be written
/// as crash reports. The report format uses frame deduplication to minimize file size:
/// - Unique frames are collected and symbolicated once
/// - Each sample references frames by index rather than duplicating addresses
///
/// ## Report Structure
///
/// The profile section in the crash report contains:
/// - `name`: The profile name
/// - `id`: Unique profile identifier (UUID)
/// - `time_start_epoch`: Wall-clock start time in nanoseconds since epoch
/// - `time_start_uptime`: Monotonic start timestamp
/// - `time_end_uptime`: Monotonic end timestamp
/// - `duration`: Profile duration in nanoseconds
/// - `frames`: Array of unique symbolicated frames
/// - `samples`: Array of samples, each referencing frames by index
extension Profile {

    /// Writes this profile to a crash report file.
    ///
    /// This method triggers the KSCrash report writing machinery to generate a JSON report
    /// containing the profile data. The report is written synchronously to the KSCrash
    /// reports directory.
    ///
    /// The profile data is passed to the monitor's `writeInReportSection` callback via
    /// the `callbackContext` field in the monitor context.
    ///
    /// - Returns: The URL of the written report file, or `nil` if the report could not be written.
    // 内部方法：将此分析写入崩溃报告文件
    // 触发KSCrash报告写入机制，生成包含分析数据的JSON报告
    // 分析数据通过监控器的writeInReportSection回调传递给callbackContext字段
    // @return 写入的报告文件的URL，如果无法写入报告则返回nil
    internal func _writeReport() -> URL? {

        // 获取分析监控器的API
        let api = ProfileMonitor.api
        // 获取异常处理回调，如果不存在则返回nil
        guard let callbacks = ProfileMonitor.callbacks else {
            return nil
        }

        // 创建异常处理要求结构
        // 不需要记录所有线程，需要写入报告，不是致命错误，不需要异步安全等
        let requirements = KSCrash_ExceptionHandlingRequirements(
            shouldRecordAllThreads: 0,
            shouldWriteReport: 1,
            isFatal: 0,
            asyncSafety: 0,
            asyncSafetyBecauseThreadsSuspended: 0,
            crashedDuringExceptionHandling: 0,
            shouldExitImmediately: 0
        )

        // 通知异常处理系统，获取监控器上下文
        let context = callbacks.notify(thread, requirements)
        // 填充监控器上下文
        kscm_fillMonitorContext(context, api)
        // 将Profile包装在BoxedProfile中，转换为不透明指针传递给回调上下文
        let callbackContext = Unmanaged.passRetained(BoxedProfile(self)).toOpaque()
        // 确保在退出时释放BoxedProfile
        defer {
            Unmanaged<BoxedProfile>.fromOpaque(callbackContext).release()
        }
        // 将回调上下文设置到监控器上下文中
        context?.pointee.callbackContext = callbackContext

        // 创建报告结果结构
        var result = KSCrash_ReportResult()
        // 处理异常并生成报告
        callbacks.handleWithResult(context, &result)

        // 将C字符串路径转换为Swift字符串
        let path = withUnsafePointer(to: &result.path) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(PATH_MAX)) {
                String(cString: $0)
            }
        }

        // 如果路径为空，返回nil
        guard !path.isEmpty else {
            return nil
        }

        // 返回文件URL
        return URL(fileURLWithPath: path)
    }
}

// MARK: - BoxedProfile

/// A class wrapper around `Profile` for passing through C callbacks.
///
/// Since `Profile` is a struct, we need a reference type to pass through the
/// `void*` context in the monitor callbacks. This class boxes the profile and
/// provides the `write(with:)` method to serialize it to JSON.
// Profile的类包装器，用于通过C回调传递
// 由于Profile是结构体，我们需要引用类型来通过监控器回调中的void*上下文传递
// 此类将Profile装箱并提供write(with:)方法来将其序列化为JSON
private class BoxedProfile {
    // 被包装的Profile
    let profile: Profile

    // 初始化方法
    init(_ profile: Profile) {
        self.profile = profile
    }

    /// Writes the profile data to the report using the given writer.
    ///
    /// The output format uses frame deduplication:
    /// 1. Collect all unique addresses from all samples
    /// 2. Symbolicate each unique address once
    /// 3. Build a lookup table mapping address -> index
    /// 4. Write frames array with symbolicated info
    /// 5. Write samples array with frame indexes instead of addresses
    ///
    /// - Parameter writer: The report writer to use for JSON output.
    // 使用给定的写入器将分析数据写入报告
    // 输出格式使用帧去重：
    // 1. 从所有样本中收集所有唯一地址
    // 2. 对每个唯一地址进行一次符号化
    // 3. 构建地址到索引的查找表
    // 4. 写入包含符号化信息的帧数组
    // 5. 写入使用帧索引而不是地址的样本数组
    // @param writer 用于JSON输出的报告写入器
    func write(with writer: UnsafeReportWriter) {

        // 从所有样本中收集所有唯一地址，排序后对每个地址进行符号化
        let addresses = Array(Set(profile.samples.flatMap(\.addresses)))
            .sorted()
            .map {
                // 创建符号信息结构
                var info = SymbolInformation()
                // 快速符号化地址
                _ = quickSymbolicate(address: $0, result: &info)
                // 返回符号信息
                return info
            }

        // 构建地址到索引的字典（用于查找）
        let addressToIndex = Dictionary(uniqueKeysWithValues: addresses.enumerated().map { ($1.returnAddress, $0) })

        // 为每个样本创建索引数组（将地址映射到帧索引）
        let indexedSamples: [(indexes: [Int], sample: any Sample)] = profile.samples.map { sample in
            // 将样本中的地址映射到帧索引
            let indexes = sample.addresses.compactMap { address in
                addressToIndex[address]
            }
            // 返回索引数组和样本
            return (indexes, sample)
        }

        // 写入分析的基本信息
        writer.add("name", profile.name)
        writer.add("id", profile.id.uuidString)
        writer.add("time_start_epoch", UInt64(profile.startTime.timeIntervalSince1970 * 1_000_000_000.0))
        writer.add("time_start_uptime", profile.startTimestampNs)
        writer.add("time_end_uptime", profile.endTimestampNs)
        writer.add("expected_sample_interval", profile.expectedSampleIntervalNs)
        writer.add("duration", profile.durationNs)
        writer.add("time_units", "nanoseconds")

        // 写入帧数组（包含符号化信息）
        writer.beginArray("frames")
        for address in addresses {
            writer.beginObject(nil)

            // 如果存在符号名，写入符号名
            if let symbolName = address.symbolName {
                writer.add("symbol_name", String(cString: symbolName))
            }
            // 写入符号地址
            writer.add("symbol_addr", UInt64(address.symbolAddress))
            // 写入指令地址
            writer.add("instruction_addr", UInt64(address.callInstruction))
            // 如果存在镜像名，写入镜像名（只取文件名部分）
            if let imageName = address.imageName {
                let name = URL(fileURLWithPath: String(cString: imageName)).lastPathComponent
                writer.add("object_name", name)
            }
            // 写入镜像地址
            writer.add("object_addr", UInt64(address.imageAddress))

            writer.endContainer()
        }
        writer.endContainer()

        // 写入样本数组（使用帧索引）
        writer.beginArray("samples")
        for (indexes, sample) in indexedSamples {

            writer.beginObject(nil)
            // 写入样本的时间信息
            writer.add("time_start_uptime", sample.metadata.timestampBeginNs)
            writer.add("time_end_uptime", sample.metadata.timestampEndNs)
            writer.add("duration", sample.metadata.durationNs)

            // 写入样本的帧索引数组
            writer.beginArray("frames")
            for index in indexes {
                writer.add(nil, UInt64(index))
            }
            writer.endContainer()

            writer.endContainer()
        }
        writer.endContainer()
    }
}

// MARK: - Profile Monitor API Functions

// 分析监控器的最终私有类，用于管理分析报告的写入
final private class ProfileMonitor: Sendable {

    // 用于线程安全访问的锁
    static private let lock = UnfairLock()

    /// Whether the profile monitor is enabled.
    // 分析监控器是否启用
    static private var _enabled: Bool = true
    static var enabled: Bool {
        set {
            // 在锁保护下设置启用状态
            lock.withLock { _enabled = newValue }
        }
        get {
            // 在锁保护下获取启用状态
            lock.withLock { _enabled }
        }
    }

    /// The monitor ID string. Allocated once and never freed (intentional for static lifetime).
    // 监控器ID字符串。分配一次且永不释放（有意用于静态生命周期）
    static private let _monitorId = strdup("profile")
    static var monitorId: UnsafePointer<CChar>? {
        // 在锁保护下返回监控器ID指针
        lock.withLock { _monitorId.map { UnsafePointer($0) } }
    }

    /// Cached exception handler callbacks from KSCrash initialization.
    // 从KSCrash初始化缓存的异常处理回调
    static private var _callbacks: KSCrash_ExceptionHandlerCallbacks? = nil
    static var callbacks: KSCrash_ExceptionHandlerCallbacks? {
        set {
            // 在锁保护下设置回调
            lock.withLock { _callbacks = newValue }
        }
        get {
            // 在锁保护下获取回调
            lock.withLock { _callbacks }
        }
    }

    /// The KSCrash monitor API for profile reports. Lazily initialized and registered.
    // 用于分析报告的KSCrash监控器API。延迟初始化并注册
    static let api: UnsafeMutablePointer<KSCrashMonitorAPI> = {
        // 创建监控器API结构，设置所有函数指针
        var api = KSCrashMonitorAPI(
            init: profileMonitorInit,
            monitorId: profileMonitorGetId,
            monitorFlags: profileMonitorGetFlags,
            setEnabled: profileMonitorSetEnabled,
            isEnabled: profileMonitorIsEnabled,
            addContextualInfoToEvent: profileMonitorAddContextualInfoToEvent,
            notifyPostSystemEnable: profileMonitorNotifyPostSystemEnable,
            writeInReportSection: profileMonitorWriteInReportSection
        )

        // 分配API结构的内存（永不释放）
        let p = UnsafeMutablePointer<KSCrashMonitorAPI>.allocate(capacity: 1)  // never deallocated
        // 初始化API结构
        p.initialize(to: api)
        // 将监控器添加到监控器系统
        kscm_addMonitor(p)
        // 返回指针
        return p
    }()
}

// 监控器初始化函数：保存异常处理回调
private func profileMonitorInit(
    _ callbacks: UnsafeMutablePointer<KSCrash_ExceptionHandlerCallbacks>?
) {
    // 保存回调结构的内容
    ProfileMonitor.callbacks = callbacks?.pointee
}

// 获取监控器ID函数
private func profileMonitorGetId() -> UnsafePointer<CChar>? {
    // 返回监控器ID指针
    ProfileMonitor.monitorId
}

// 获取监控器标志函数
private func profileMonitorGetFlags() -> KSCrashMonitorFlag {
    // 返回标志0（无特殊标志）
    .init(0)
}

// 设置监控器启用状态函数
private func profileMonitorSetEnabled(_ enabled: Bool) {
    // 设置启用状态
    ProfileMonitor.enabled = enabled
}

// 检查监控器是否启用函数
private func profileMonitorIsEnabled() -> Bool {
    // 返回启用状态
    ProfileMonitor.enabled
}

// 向事件添加上下文信息函数（分析监控器不需要）
private func profileMonitorAddContextualInfoToEvent(
    _ eventContext: UnsafeMutablePointer<KSCrash_MonitorContext>?
) {
    // 空实现
}

// 系统启用后通知函数（分析监控器不需要）
private func profileMonitorNotifyPostSystemEnable() {
    // 空实现
}

// 在报告部分写入函数：从回调上下文中获取BoxedProfile并写入报告
private func profileMonitorWriteInReportSection(
    _ context: UnsafePointer<KSCrash_MonitorContext>?,
    _ writerRef: UnsafePointer<ReportWriter>?
) {
    // 创建报告写入器包装器，如果失败则返回
    guard let writer = UnsafeReportWriter(writerRef) else {
        return
    }
    // 获取回调上下文，如果不存在则返回
    guard let callbackContext = context?.pointee.callbackContext else {
        return
    }

    // 从回调上下文中获取BoxedProfile（不保留引用，因为上下文会管理生命周期）
    let profileBox = Unmanaged<BoxedProfile>.fromOpaque(callbackContext).takeUnretainedValue()
    // 使用写入器写入分析数据
    profileBox.write(with: writer)
}
