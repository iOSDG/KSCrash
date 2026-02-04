//
//  Sample.swift
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

// MARK: - Protocol

/// Protocol for backtrace samples with fixed-size inline storage.
///
/// Sample types use tuple-based storage to hold stack frame addresses inline,
/// avoiding heap allocations during capture. Each concrete type (Sample32, Sample64, etc.)
/// provides storage for a different maximum number of frames.
///
/// ## Choosing a Sample Type
///
/// Choose based on your expected maximum stack depth:
/// - `Sample32`: Shallow stacks (UI code, simple callbacks)
/// - `Sample64`: Common case (most application code)
/// - `Sample128`: Deep stacks (recursive algorithms, deep call chains)
/// - `Sample256`: Very deep stacks (complex frameworks)
/// - `Sample512`: Extremely deep stacks (rare edge cases)
///
/// Using a smaller sample type reduces memory usage but may truncate deep stacks.
// 具有固定大小内联存储的堆栈回溯样本协议
// 样本类型使用基于元组的存储来内联保存堆栈帧地址，避免在捕获期间进行堆分配
// 每个具体类型（Sample32、Sample64等）为不同最大帧数提供存储
public protocol Sample: Sendable {
    /// The tuple type used for inline address storage.
    // 用于内联地址存储的元组类型
    associatedtype Storage

    /// Maximum number of stack frames this sample type can hold.
    // 此样本类型可以保存的最大堆栈帧数
    static var capacity: Int { get }

    /// Number of valid addresses captured (0...capacity).
    // 捕获的有效地址数量（范围：0到capacity）
    var addressCount: Int { get set }

    /// Timing metadata for this sample.
    // 此样本的时间元数据
    var metadata: SampleMetadata { get set }

    /// Inline tuple storage for stack frame addresses.
    // 堆栈帧地址的内联元组存储
    var storage: Storage { get set }

    /// Creates a new zero-initialized sample.
    // 创建新的零初始化样本
    init()
}

// MARK: - Default Implementations

// Sample协议的默认实现
extension Sample {
    /// Returns the captured stack frame addresses as an array.
    ///
    /// This creates a new array from the inline storage. For performance-critical
    /// code paths, prefer accessing `storage` directly via `withUnsafeBytes`.
    // 将捕获的堆栈帧地址作为数组返回
    // 这从内联存储创建一个新数组。对于性能关键的代码路径，建议通过withUnsafeBytes直接访问storage
    public var addresses: [UInt] {
        // 使用不安全字节访问存储
        withUnsafeBytes(of: storage) { ptr in
            // 将内存绑定到UInt类型，取前addressCount个元素，转换为数组
            Array(ptr.bindMemory(to: UInt.self).prefix(addressCount))
        }
    }

    /// Captures a backtrace from the specified thread into this sample's storage.
    ///
    /// - Parameters:
    ///   - thread: The mach thread port to capture the backtrace from.
    ///   - captureBacktrace: The backtrace capture function (typically from KSCrashRecordingCore).
    ///
    /// After capture, `addressCount` contains the number of valid frames captured.
    // 从指定线程捕获堆栈回溯到此样本的存储中
    // @param thread 要捕获堆栈回溯的Mach线程端口
    // @param captureBacktrace 堆栈回溯捕获函数（通常来自KSCrashRecordingCore）
    // 捕获后，addressCount包含捕获的有效帧数
    public mutating func capture(
        thread: mach_port_t,
        using captureBacktrace: (mach_port_t, UnsafeMutablePointer<UInt>, Int32) -> Int32
    ) {
        // 使用可变不安全字节访问存储
        addressCount = withUnsafeMutableBytes(of: &storage) { ptr in
            // 调用捕获函数，将基地址转换为UInt指针，传入容量
            Int(
                captureBacktrace(
                    thread,
                    ptr.baseAddress!.assumingMemoryBound(to: UInt.self),
                    Int32(Self.capacity)
                ))
        }
    }

    /// Creates a new zero-initialized sample instance.
    // 创建新的零初始化样本实例
    public static func make() -> Self {
        // 调用默认初始化器
        Self()
    }
}

// MARK: - Metadata

/// Timing metadata for a captured sample.
///
/// Contains timestamps that mark the beginning and end of the backtrace capture operation.
///
/// - `timestampBeginNs`: When backtrace capture began.
/// - `timestampEndNs`: When backtrace capture completed.
/// - `durationNs`: Time spent capturing the backtrace (computed).
// 捕获样本的时间元数据
// 包含标记堆栈回溯捕获操作开始和结束的时间戳
public struct SampleMetadata: Sendable {
    /// Monotonic timestamp when backtrace capture began (nanoseconds from `CLOCK_UPTIME_RAW`).
    // 堆栈回溯捕获开始时的单调时间戳（从CLOCK_UPTIME_RAW开始的纳秒）
    public var timestampBeginNs: UInt64 = 0

    /// Monotonic timestamp when backtrace capture completed (nanoseconds from `CLOCK_UPTIME_RAW`).
    // 堆栈回溯捕获完成时的单调时间戳（从CLOCK_UPTIME_RAW开始的纳秒）
    public var timestampEndNs: UInt64 = 0

    /// Duration of the backtrace capture in nanoseconds.
    // 堆栈回溯捕获的持续时间（纳秒）
    // 使用溢出安全的减法运算符（&-）计算
    public var durationNs: UInt64 { timestampEndNs &- timestampBeginNs }

    // 默认初始化器
    public init() {}
}

// MARK: - Concrete Sample Types

/// A sample with storage for up to 32 frames (shallow stacks).
// 最多可存储32帧的样本（浅堆栈）
public struct Sample32: Sample {
    // 容量为32帧
    public static let capacity = 32
    // 地址计数初始化为0
    public var addressCount: Int = 0
    // 时间元数据
    public var metadata = SampleMetadata()
    // 32个UInt的元组存储，初始化为0
    public var storage: Storage32 = (
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    )
    // 默认初始化器
    public init() {}
}

/// A sample with storage for up to 64 frames (common case).
// 最多可存储64帧的样本（常见情况）
public struct Sample64: Sample {
    // 容量为64帧
    public static let capacity = 64
    // 地址计数初始化为0
    public var addressCount: Int = 0
    // 时间元数据
    public var metadata = SampleMetadata()
    // 64个UInt的元组存储，初始化为0
    public var storage: Storage64 = (
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    )
    // 默认初始化器
    public init() {}
}

/// A sample with storage for up to 128 frames (deep stacks).
// 最多可存储128帧的样本（深堆栈）
public struct Sample128: Sample {
    // 容量为128帧
    public static let capacity = 128
    // 地址计数初始化为0
    public var addressCount: Int = 0
    // 时间元数据
    public var metadata = SampleMetadata()
    // 128个UInt的元组存储，初始化为0
    public var storage: Storage128 = (
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    )
    // 默认初始化器
    public init() {}
}

/// A sample with storage for up to 256 frames (very deep stacks).
// 最多可存储256帧的样本（非常深的堆栈）
public struct Sample256: Sample {
    // 容量为256帧
    public static let capacity = 256
    // 地址计数初始化为0
    public var addressCount: Int = 0
    // 时间元数据
    public var metadata = SampleMetadata()
    // 256个UInt的元组存储，初始化为0
    public var storage: Storage256 = (
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    )
    // 默认初始化器
    public init() {}
}

/// A sample with storage for up to 512 frames (extremely deep stacks).
// 最多可存储512帧的样本（极其深的堆栈）
public struct Sample512: Sample {
    // 容量为512帧
    public static let capacity = 512
    // 地址计数初始化为0
    public var addressCount: Int = 0
    // 时间元数据
    public var metadata = SampleMetadata()
    // 512个UInt的元组存储，初始化为0
    public var storage: Storage512 = (
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    )
    // 默认初始化器
    public init() {}
}

// MARK: - Storage Typealiases

// 存储类型别名：定义用于内联存储堆栈帧地址的元组类型
// Storage32：32个UInt的元组，用于Sample32
public typealias Storage32 = (
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt
)

// Storage64：64个UInt的元组，用于Sample64
public typealias Storage64 = (
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt
)

// Storage128：128个UInt的元组，用于Sample128
public typealias Storage128 = (
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt
)

// Storage256：256个UInt的元组，用于Sample256
public typealias Storage256 = (
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt
)

// Storage512：512个UInt的元组，用于Sample512
public typealias Storage512 = (
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt,
    UInt, UInt, UInt, UInt, UInt, UInt, UInt, UInt
)
