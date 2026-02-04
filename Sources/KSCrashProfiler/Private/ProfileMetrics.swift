//
//  ProfileMetrics.swift
//
//  Created by Alexander Cohen on 2025-12-14.
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

/// Performance metrics computed from sample capture timings.
///
/// Provides statistical analysis of sample capture overhead, useful for understanding
/// profiler performance characteristics and tuning sampling intervals.
///
/// ## Example
///
/// ```swift
/// let metrics = profile.metrics
/// print("Captured \(metrics.count) samples")
/// print("Avg: \(metrics.avgNs / 1000)µs, P99: \(metrics.p99Ns / 1000)µs")
/// ```
///
/// All timing values represent `durationNs` from each sample's metadata.
// 从样本捕获时间计算的性能指标
// 提供样本捕获开销的统计分析，有助于理解分析器性能特征和调整采样间隔
// 所有时间值表示每个样本元数据中的durationNs
public struct ProfileMetrics: Sendable {
    /// Per-sample capture timing in nanoseconds.
    // 每个样本的捕获时间（纳秒）
    public let sampleTimingsNs: [UInt64]

    /// Number of samples with timing data.
    // 具有时间数据的样本数量
    public var count: Int { sampleTimingsNs.count }

    /// Minimum capture time in nanoseconds.
    // 最小捕获时间（纳秒）
    public var minNs: UInt64 { sampleTimingsNs.min() ?? 0 }

    /// Maximum capture time in nanoseconds.
    // 最大捕获时间（纳秒）
    public var maxNs: UInt64 { sampleTimingsNs.max() ?? 0 }

    /// Average (mean) capture time in nanoseconds.
    // 平均（均值）捕获时间（纳秒）
    public var avgNs: Double {
        // 如果数组为空，返回0
        guard !sampleTimingsNs.isEmpty else { return 0 }
        // 计算总和并除以数量
        return Double(sampleTimingsNs.reduce(0, +)) / Double(sampleTimingsNs.count)
    }

    /// Standard deviation of capture times in nanoseconds.
    ///
    /// Uses population standard deviation (divides by N, not N-1).
    // 捕获时间的标准差（纳秒）
    // 使用总体标准差（除以N，而不是N-1）
    public var stdDevNs: Double {
        // 如果样本数少于2，返回0
        guard sampleTimingsNs.count > 1 else { return 0 }
        // 获取平均值
        let avg = avgNs
        // 计算方差：每个值与平均值的差的平方的平均值
        let variance =
            sampleTimingsNs.map { pow(Double($0) - avg, 2) }.reduce(0, +)
            / Double(sampleTimingsNs.count)
        // 返回标准差（方差的平方根）
        return sqrt(variance)
    }

    /// Returns the capture time at the given percentile.
    ///
    /// - Parameter p: Percentile value from 0 to 100.
    /// - Returns: The capture time at that percentile in nanoseconds.
    // 返回给定百分位数的捕获时间
    // @param p 百分位数值（0到100）
    // @return 该百分位数的捕获时间（纳秒）
    public func percentileNs(_ p: Double) -> UInt64 {
        // 如果数组为空，返回0
        guard !sampleTimingsNs.isEmpty else { return 0 }
        // 对时间数组进行排序
        let sorted = sampleTimingsNs.sorted()
        // 计算百分位数对应的索引（确保不超过数组边界）
        let index = min(Int(Double(sorted.count) * p / 100.0), sorted.count - 1)
        // 返回该索引的值
        return sorted[index]
    }

    /// P50 (median) capture time in nanoseconds.
    // P50（中位数）捕获时间（纳秒）
    public var p50Ns: UInt64 { percentileNs(50) }

    /// P95 capture time in nanoseconds.
    // P95捕获时间（纳秒）
    public var p95Ns: UInt64 { percentileNs(95) }

    /// P99 capture time in nanoseconds.
    // P99捕获时间（纳秒）
    public var p99Ns: UInt64 { percentileNs(99) }

    /// Creates metrics from an array of samples.
    ///
    /// Extracts `durationNs` from each sample's metadata.
    // 从样本数组创建指标
    // 从每个样本的元数据中提取durationNs
    internal init(samples: [any Sample]) {
        // 将每个样本的持续时间提取到数组中
        self.sampleTimingsNs = samples.map { $0.metadata.durationNs }
    }
}

// Profile的扩展，添加性能指标计算
extension Profile {

    /// Performance metrics computed from sample capture timings.
    ///
    /// This property is computed on demand. For repeated access, store the result
    /// in a local variable.
    // 从样本捕获时间计算的性能指标
    // 此属性按需计算。对于重复访问，应将结果存储在局部变量中
    public var metrics: ProfileMetrics {
        // 从样本创建指标对象
        ProfileMetrics(samples: samples)
    }
}
