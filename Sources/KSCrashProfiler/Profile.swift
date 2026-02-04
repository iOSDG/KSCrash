//
//  Profile.swift
//
//  Created by Alexander Cohen on 2025-12-12.
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

/// Unique identifier for a profiling session.
// 分析会话的唯一标识符类型（UUID）
public typealias ProfileID = UUID

/// A completed profile containing timing information and captured samples.
///
/// A `Profile` represents the results of a profiling session between `beginProfile(named:)` and
/// `endProfile(id:)` calls. It contains all samples captured during that time window, along
/// with timing metadata.
///
/// To write the profile to a crash report, call `writeReport()`. Since this performs synchronous
/// disk I/O, it should be called from a background queue.
///
/// ## Example
///
/// ```swift
/// let id = profiler.beginProfile(named: "MyOperation")
/// // ... do work ...
/// let profile = profiler.endProfile(id: id)!
/// print("Profile: \(profile.name)")
/// print("Duration: \(Double(profile.durationNs) / 1_000_000)ms")
///
/// DispatchQueue.global().async {
///     if let url = profile.writeReport() {
///         print("Report written to: \(url.path)")
///     }
/// }
/// ```
// 已完成的分析结构，包含时间信息和捕获的样本
public struct Profile: Sendable {
    /// Unique identifier for this profile session.
    // 此分析会话的唯一标识符
    public let id: ProfileID

    /// Human-readable name for this profile session.
    ///
    /// This is the name provided to `beginProfile(named:)`. Use it to identify
    /// the operation or code path being profiled.
    // 此分析会话的人类可读名称
    // 这是提供给beginProfile(named:)的名称，用于标识被分析的操作或代码路径
    public let name: String

    /// Wall-clock time when profiling started.
    ///
    /// Use this for correlating with external events or logs. For duration calculations,
    /// use the monotonic timestamps instead.
    // 分析开始时的墙钟时间
    // 用于与外部事件或日志关联。对于持续时间计算，应使用单调时间戳
    public let startTime: Date

    /// Monotonic timestamp when profiling started (nanoseconds from `CLOCK_UPTIME_RAW`).
    // 分析开始时的单调时间戳（从CLOCK_UPTIME_RAW开始的纳秒）
    public let startTimestampNs: UInt64

    /// Monotonic timestamp when profiling ended (nanoseconds from `CLOCK_UPTIME_RAW`).
    // 分析结束时的单调时间戳（从CLOCK_UPTIME_RAW开始的纳秒）
    public let endTimestampNs: UInt64

    /// Expected interval between samples in nanoseconds.
    ///
    /// This is the configured sampling interval. Actual intervals may vary slightly
    /// due to timer precision and system load.
    // 样本之间的预期间隔（纳秒）
    // 这是配置的采样间隔。实际间隔可能因定时器精度和系统负载而略有变化
    public let expectedSampleIntervalNs: UInt64

    /// Captured backtrace samples within this profile's time window.
    ///
    /// Samples are returned in chronological order. Only samples whose capture time
    /// overlaps with `[startTimestampNs, endTimestampNs]` are included.
    // 此分析时间窗口内捕获的堆栈回溯样本
    // 样本按时间顺序返回。只包含捕获时间与[startTimestampNs, endTimestampNs]重叠的样本
    public let samples: [any Sample]

    /// Total duration of this profile in nanoseconds.
    // 此分析的总持续时间（纳秒）
    public var durationNs: UInt64 {
        // 计算结束时间戳与开始时间戳的差值
        endTimestampNs - startTimestampNs
    }

    /// Writes this profile to a crash report file.
    ///
    /// This method triggers the KSCrash report writing machinery to generate a JSON report
    /// containing the profile data. The report is written synchronously to the KSCrash
    /// reports directory.
    ///
    /// - Returns: The URL of the written report file, or `nil` if the report could not be written.
    ///
    /// - Note: This method performs synchronous disk I/O and should be called from a background
    ///   queue or task to avoid blocking the main thread.
    // 将此分析写入崩溃报告文件
    // 此方法触发KSCrash报告写入机制，生成包含分析数据的JSON报告
    // 报告同步写入KSCrash报告目录
    // @return 写入的报告文件的URL，如果无法写入报告则返回nil
    // 注意：此方法执行同步磁盘I/O，应从后台队列或任务调用以避免阻塞主线程
    public func writeReport() -> URL? {
        // 调用内部实现方法
        _writeReport()
    }

    /// The Mach thread port of the thread that was profiled.
    ///
    /// This is the thread from which backtraces were captured during the profiling session.
    /// Note that this is a Mach thread port (`thread_t`), not a pthread.
    // 被分析线程的Mach线程端口
    // 这是在分析会话期间捕获堆栈回溯的线程
    // 注意：这是Mach线程端口（thread_t），不是pthread
    public let thread: thread_t

    // 内部初始化方法
    // @param id 分析会话的唯一标识符
    // @param name 分析会话的名称
    // @param thread 被分析的Mach线程端口
    // @param startTime 分析开始时的墙钟时间
    // @param startTimestampNs 分析开始时的单调时间戳（纳秒）
    // @param endTimestampNs 分析结束时的单调时间戳（纳秒）
    // @param expectedSampleIntervalNs 预期的采样间隔（纳秒）
    // @param samples 捕获的样本数组
    internal init(
        id: ProfileID,
        name: String,
        thread: thread_t,
        startTime: Date,
        startTimestampNs: UInt64,
        endTimestampNs: UInt64,
        expectedSampleIntervalNs: UInt64,
        samples: [any Sample]
    ) {
        // 初始化所有属性
        self.id = id
        self.name = name
        self.thread = thread
        self.startTime = startTime
        self.startTimestampNs = startTimestampNs
        self.endTimestampNs = endTimestampNs
        self.expectedSampleIntervalNs = expectedSampleIntervalNs
        self.samples = samples
    }
}
