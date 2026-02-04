//
//  Profiler.swift
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

// 导入Foundation框架，提供基础数据类型和API
import Foundation
// 导入os模块，提供日志记录功能
import os

#if SWIFT_PACKAGE
    // 在Swift Package Manager环境下，导入KSCrashRecordingCore模块
    import KSCrashRecordingCore
#endif

/// A sampling profiler that captures backtraces of a specific thread at regular intervals.
///
/// The profiler uses a pre-allocated ring buffer of `Sample` structs to store captured backtraces.
/// Samples are captured directly into the ring buffer to minimize allocations during profiling.
/// When the buffer is full, the oldest samples are overwritten.
///
/// Multiple profile sessions can be active simultaneously on the same profiler instance.
/// Sampling runs continuously as long as at least one session is active, and samples are
/// shared across overlapping sessions based on their time windows.
///
/// ## Usage
///
/// ```swift
/// let profiler = Profiler<Sample128>(thread: pthread_self())
/// let id = profiler.beginProfile(named: "MyOperation")
/// // ... do work ...
/// let profile = profiler.endProfile(id: id)!
/// print("Captured \(profile.samples.count) samples")
/// ```
///
/// ## Report Writing
///
/// To write a crash report containing the profile data, call `writeReport()` on the
/// returned profile. Since this performs synchronous disk I/O, it should be called
/// from a background queue:
///
/// ```swift
/// let profile = profiler.endProfile(id: id)!
/// DispatchQueue.global().async {
///     if let url = profile.writeReport() {
///         print("Report written to: \(url.path)")
///     }
/// }
/// ```
///
/// ## Thread Safety
///
/// All public methods are thread-safe. The profiler uses an unfair lock to protect
/// internal state and the ring buffer.
///
/// - Note: On watchOS, backtrace capture is not supported and samples will contain empty addresses.
// 采样分析器类，用于定期捕获指定线程的堆栈回溯
// T是Sample协议的实现类型，用于指定样本的存储容量
// @unchecked Sendable表示该类是线程安全的，但需要手动保证
public final class Profiler<T: Sample>: @unchecked Sendable {
    /// The mach thread being profiled
    // 被分析的Mach线程端口
    let machThread: thread_t

    /// The interval between samples in nanoseconds
    // 采样间隔（纳秒）
    let intervalNs: UInt64

    /// Maximum number of samples to retain
    // 环形缓冲区中保留的最大样本数
    let capacity: Int

    /// The queue on which sampling occurs
    // 执行采样的调度队列
    let samplingQueue: DispatchQueue

    /// Lock for thread-safe access
    // 用于线程安全访问的锁
    let lock = UnfairLock()

    /// Ring buffer of samples (pre-allocated)
    // 预分配的样本环形缓冲区
    var samples: ContiguousArray<T>

    /// Next write position in ring buffer
    // 环形缓冲区中的下一个写入位置
    var writeIndex: Int = 0

    /// Number of valid samples in buffer (0...capacity)
    // 缓冲区中有效样本的数量（范围：0到capacity）
    var count: Int = 0

    /// Active profile sessions
    // 活动的分析会话字典，键为ProfileID，值为ActiveProfile
    var activeSessions: [ProfileID: ActiveProfile] = [:]

    /// The timer used for periodic sampling
    // 用于定期采样的定时器
    var timer: DispatchSourceTimer?

    /// Whether profiling is currently active
    // 检查分析器是否正在运行
    // 如果存在活动的分析会话，则返回true
    public var isRunning: Bool {
        // 在锁保护下检查活动会话是否为空
        lock.withLock { !activeSessions.isEmpty }
    }

    /// Calculates the memory footprint in bytes for a profiler with the given configuration.
    /// - Parameters:
    ///   - interval: The time interval between samples
    ///   - maxFrames: The maximum number of frames to capture per backtrace
    ///   - retentionSeconds: How many seconds of samples to retain
    /// - Returns: The total memory footprint in bytes
    // 计算分析器在给定配置下的内存占用（字节数）
    // @param interval 采样间隔（秒）
    // @param retentionSeconds 保留样本的秒数
    // @return 总内存占用（字节数）
    public static func storageSize(
        interval: TimeInterval,
        retentionSeconds: Int
    ) -> Int {
        // 将采样间隔限制在最小值0.001秒（1毫秒）
        let clampedInterval = max(0.001, interval)
        // 根据保留时间和采样间隔计算容量，向上取整到最近的整数
        let capacity = max(1, Int((Double(retentionSeconds) / clampedInterval).rounded(.toNearestOrAwayFromZero)))

        // Estimate: Sample struct size (includes inline address storage)
        // 估算：样本结构体大小（包括内联地址存储）
        let sampleOverhead = MemoryLayout<T>.size

        // 计算总内存占用，检查是否溢出
        let (total, overflow) = capacity.multipliedReportingOverflow(by: sampleOverhead)

        // 如果溢出则返回Int.max，否则返回总大小
        return overflow ? Int.max : total
    }

    /// Creates a new profiler
    /// - Parameters:
    ///   - thread: The pthread to profile
    ///   - interval: The time interval between samples (default: 10ms)
    ///   - retentionSeconds: How many seconds of samples to retain in the ring buffer (default: 30)
    // 创建新的分析器实例
    // @param thread 要分析的pthread线程
    // @param interval 采样间隔（默认0.01秒，即10毫秒）
    // @param retentionSeconds 在环形缓冲区中保留样本的秒数（默认30秒）
    public init(
        thread: pthread_t,
        interval: TimeInterval = 0.01,
        retentionSeconds: Int = 30
    ) {
        // 将pthread转换为Mach线程端口
        self.machThread = pthread_mach_thread_np(thread)

        // 将采样间隔限制在最小值0.001秒
        let clampedInterval = max(0.001, interval)
        // 将采样间隔转换为纳秒
        self.intervalNs = UInt64(clampedInterval * 1_000_000_000)
        // 创建用于采样的调度队列，使用用户交互优先级
        self.samplingQueue = DispatchQueue(label: "com.kscrash.profiler.sampling", qos: .userInteractive)

        // 根据保留时间和采样间隔计算容量
        let computed = Int((Double(retentionSeconds) / clampedInterval).rounded(.toNearestOrAwayFromZero))
        // 确保容量至少为1
        self.capacity = max(1, computed)

        // Pre-allocate ring buffer
        // 预分配环形缓冲区，使用零初始化的样本填充
        self.samples = ContiguousArray(repeating: T.make(), count: self.capacity)

        // 计算存储大小
        let bytes = Self.storageSize(interval: interval, retentionSeconds: retentionSeconds)
        // 如果存储大小超过20MB，记录警告日志
        if bytes > 20 * 1024 * 1024 {
            // 格式化字节数为可读字符串
            let formatted = ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
            // 记录错误日志，建议减少maxFrames或retentionSeconds
            os_log(
                .error,
                "Profiler storage size is very large: %{public}@. Consider reducing maxFrames or retentionSeconds.",
                formatted
            )
        }
    }

    /// Begins a new profile session.
    ///
    /// If this is the first active session, starts sampling. The profile name is used
    /// to identify this profiling session in reports and logs.
    ///
    /// - Parameter named: A human-readable name for this profile session (e.g., "AppLaunch", "NetworkRequest").
    /// - Returns: A unique identifier for this profile session. Pass this to `endProfile(id:)` to complete the session.
    // 开始新的分析会话
    // @param named 分析会话的人类可读名称（例如："AppLaunch", "NetworkRequest"）
    // @return 此分析会话的唯一标识符，传递给endProfile(id:)以完成会话
    public func beginProfile(named: String) -> ProfileID {
        // 生成唯一的会话ID（UUID）
        let id = ProfileID()
        // 记录墙钟时间（用于与外部事件关联）
        let startTime = Date()
        // 获取单调时间戳（纳秒，从CLOCK_UPTIME_RAW开始）
        let timestamp = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
        // 创建活动分析会话对象
        let profile = ActiveProfile(id: id, name: named, startTime: startTime, startTimestampNs: timestamp)

        // 在锁保护下更新状态
        lock.withLock {
            // 检查在添加新会话前是否为空
            let wasEmpty = activeSessions.isEmpty
            // 将新会话添加到活动会话字典
            activeSessions[id] = profile
            // 如果这是第一个会话，启动采样定时器
            if wasEmpty {
                startLocked()
            }
        }

        // 返回会话ID
        return id
    }

    /// Ends a profile session and returns the captured profile.
    ///
    /// If this is the last active session, stops sampling.
    ///
    /// - Parameter id: The profile session identifier returned by `beginProfile(named:)`.
    /// - Returns: The completed profile with timing info and samples, or `nil` if the id is invalid.
    // 结束分析会话并返回捕获的分析结果
    // @param id 由beginProfile(named:)返回的分析会话标识符
    // @return 包含时间信息和样本的已完成分析，如果id无效则返回nil
    public func endProfile(id: ProfileID) -> Profile? {
        // 获取结束时的单调时间戳
        let endTimestamp = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)

        // 在锁保护下处理会话结束
        return lock.withLock {
            // 从活动会话中移除并获取会话信息，如果不存在则返回nil
            guard let activeProfile = activeSessions.removeValue(forKey: id) else {
                return nil
            }

            // 获取时间范围内的匹配样本
            let matchingSamples = samplesInRangeLocked(
                from: activeProfile.startTimestampNs,
                to: endTimestamp
            )

            // 如果没有活动会话了，停止采样定时器
            if activeSessions.isEmpty {
                stopLocked()
            }

            // 创建并返回Profile对象
            return Profile(
                id: id,
                name: activeProfile.name,
                thread: machThread,
                startTime: activeProfile.startTime,
                startTimestampNs: activeProfile.startTimestampNs,
                endTimestampNs: endTimestamp,
                expectedSampleIntervalNs: intervalNs,
                samples: matchingSamples
            )
        }
    }

    // 析构函数：确保在对象销毁时停止采样
    deinit {
        // 在锁保护下停止采样定时器
        lock.withLock {
            stopLocked()
        }
    }
}

// MARK: - Private

/// Internal state for an active profile session.
///
/// Tracks the session's unique identifier and start times for correlating
/// samples with the profile's time window.
// 活动分析会话的内部状态结构
// 跟踪会话的唯一标识符和开始时间，用于将样本与分析的时间窗口关联
struct ActiveProfile {
    /// Unique identifier for the profile session.
    // 分析会话的唯一标识符
    let id: ProfileID
    /// Name for this profile session.
    // 此分析会话的名称
    let name: String
    /// Wall-clock time when the session started.
    // 会话开始时的墙钟时间
    let startTime: Date
    /// Monotonic timestamp (in nanoseconds) when the session started.
    // 会话开始时的单调时间戳（纳秒）
    let startTimestampNs: UInt64
}

extension Profiler {
    /// Starts the sampling timer.
    ///
    /// Resets ring buffer state and starts a repeating timer that calls `captureSample()`.
    ///
    /// - Important: Must be called while holding `lock`.
    // 启动采样定时器
    // 重置环形缓冲区状态并启动重复定时器，定时器调用captureSample()
    // 重要：必须在持有lock的情况下调用
    func startLocked() {
        // Reset ring buffer state
        // 重置环形缓冲区状态
        writeIndex = 0
        count = 0

        // 在采样队列上创建定时器源
        let timer = DispatchSource.makeTimerSource(queue: samplingQueue)
        // 调度定时器：立即开始，按采样间隔重复，允许1毫秒的误差
        timer.schedule(
            deadline: .now(),
            repeating: Double(intervalNs) / 1_000_000_000,
            leeway: .milliseconds(1)
        )
        // 设置事件处理程序：每次触发时捕获样本
        timer.setEventHandler { [weak self] in
            self?.captureSample()
        }
        // 启动定时器
        timer.resume()
        // 保存定时器引用
        self.timer = timer
    }

    /// Stops the sampling timer.
    ///
    /// Cancels and releases the timer.
    ///
    /// - Important: Must be called while holding `lock`.
    // 停止采样定时器
    // 取消并释放定时器
    // 重要：必须在持有lock的情况下调用
    func stopLocked() {
        // 取消定时器
        timer?.cancel()
        // 清空定时器引用
        timer = nil
    }

    /// Captures a single backtrace sample from the profiled thread.
    ///
    /// Called periodically by the timer on the profiler's dispatch queue.
    ///
    /// ## Implementation Notes
    ///
    /// The backtrace capture happens while holding the lock. This design choice trades
    /// some lock contention for simpler, more predictable code:
    ///
    /// - **Simplicity**: Capturing directly into the ring buffer slot eliminates the need
    ///   to copy sample data, reducing overhead and complexity.
    /// - **Correctness**: Holding the lock ensures the ring buffer slot remains valid
    ///   throughout the capture operation, avoiding race conditions with concurrent
    ///   `endProfile()` calls that read from the buffer.
    ///
    /// The lock is held for approximately 100-300µs per sample (depending on stack depth),
    /// which is acceptable for the typical 1-10ms sampling intervals.
    // 从被分析的线程捕获单个堆栈回溯样本
    // 由定时器在分析器的调度队列上定期调用
    // 实现说明：堆栈回溯捕获在持有锁的情况下进行，这个设计选择用一些锁竞争换取更简单、更可预测的代码
    func captureSample() {
        // 在锁保护下执行捕获操作
        lock.withLock {
            // 如果没有活动会话，直接返回
            guard !activeSessions.isEmpty else { return }

            // 获取当前写入位置
            let slot = writeIndex

            // Capture directly into the ring buffer slot to avoid struct copy overhead
            // 直接捕获到环形缓冲区槽中，避免结构体复制开销
            // 记录捕获开始时间戳
            samples[slot].metadata.timestampBeginNs = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
            // 从指定线程捕获堆栈回溯
            samples[slot].capture(thread: machThread, using: captureBacktrace)
            // 记录捕获结束时间戳
            samples[slot].metadata.timestampEndNs = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)

            // Advance ring buffer position
            // 推进环形缓冲区位置（使用模运算实现环形）
            writeIndex = (writeIndex + 1) % capacity
            // 如果缓冲区未满，增加计数
            if count < capacity {
                count += 1
            }
        }
    }

    /// Retrieves samples from the ring buffer that overlap the given time range.
    ///
    /// Iterates through valid samples in the ring buffer (from oldest to newest) and
    /// returns those whose capture time window overlaps with `[startNs, endNs]`.
    ///
    /// A sample overlaps the range if:
    /// - The sample's end time is at or after the range start, AND
    /// - The sample's begin time is at or before the range end
    ///
    /// - Parameters:
    ///   - startNs: Start of the time range (monotonic nanoseconds from `CLOCK_UPTIME_RAW`).
    ///   - endNs: End of the time range (monotonic nanoseconds from `CLOCK_UPTIME_RAW`).
    /// - Returns: Array of samples that overlap the time range, in chronological order.
    ///
    /// - Important: Must be called while holding `lock`.
    // 从环形缓冲区中检索与给定时间范围重叠的样本
    // 遍历环形缓冲区中的有效样本（从最旧到最新），返回捕获时间窗口与[startNs, endNs]重叠的样本
    // 样本与范围重叠的条件：
    // - 样本的结束时间在范围开始时间之后或相等，且
    // - 样本的开始时间在范围结束时间之前或相等
    // @param startNs 时间范围的开始（从CLOCK_UPTIME_RAW开始的单调纳秒）
    // @param endNs 时间范围的结束（从CLOCK_UPTIME_RAW开始的单调纳秒）
    // @return 与时间范围重叠的样本数组，按时间顺序排列
    // 重要：必须在持有lock的情况下调用
    func samplesInRangeLocked(from startNs: UInt64, to endNs: UInt64) -> [T] {
        // 如果没有样本，返回空数组
        guard count > 0 else { return [] }

        // 结果数组
        var result: [T] = []

        // Calculate the oldest sample's position in the ring buffer
        // 计算环形缓冲区中最旧样本的位置
        let oldest = (writeIndex - count + capacity) % capacity

        // Iterate from oldest to newest
        // 从最旧到最新迭代
        for i in 0..<count {
            // 计算当前槽的位置（使用模运算处理环形）
            let slot = (oldest + i) % capacity
            // 获取样本
            let sample = samples[slot]

            // Check for time range overlap and valid capture
            // 检查时间范围重叠和有效捕获
            // 样本的结束时间必须 >= 范围开始时间
            // 样本的开始时间必须 <= 范围结束时间
            // 样本必须包含有效的地址（addressCount > 0）
            guard
                sample.metadata.timestampEndNs >= startNs
                    && sample.metadata.timestampBeginNs <= endNs
                    && sample.addressCount > 0
            else { continue }

            // 将匹配的样本添加到结果数组
            result.append(sample)
        }

        // 返回结果数组
        return result
    }
}
