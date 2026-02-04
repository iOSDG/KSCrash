//
//  UnsafeReportWriter.swift
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

#if SWIFT_PACKAGE
    // 在Swift Package Manager环境下，导入KSCrashRecording模块
    import KSCrashRecording
#endif

/// A Swift-friendly wrapper around the C `ReportWriter` struct.
///
/// This wrapper provides type-safe methods for writing JSON elements to a KSCrash report.
/// It handles the conversion between Swift strings and C strings internally.
///
/// - Important: This struct holds an unsafe pointer and should only be used within the
///   scope where the underlying `ReportWriter` is valid (i.e., during a report write callback).
// C ReportWriter结构的Swift友好包装器
// 此包装器提供类型安全的方法来将JSON元素写入KSCrash报告
// 它在内部处理Swift字符串和C字符串之间的转换
// 重要：此结构持有不安全的指针，应仅在其底层ReportWriter有效的范围内使用（即在报告写入回调期间）
struct UnsafeReportWriter {
    // 指向C ReportWriter结构的指针
    private let ptr: UnsafePointer<ReportWriter>

    /// Creates a wrapper around the given report writer pointer.
    ///
    /// - Parameter writer: A pointer to a C `ReportWriter` struct.
    /// - Returns: `nil` if the pointer is `nil`.
    // 围绕给定的报告写入器指针创建包装器
    // @param writer 指向C ReportWriter结构的指针
    // @return 如果指针为nil则返回nil
    init?(_ writer: UnsafePointer<ReportWriter>?) {
        // 如果指针为nil，返回nil
        guard let writer else { return nil }
        // 保存指针
        self.ptr = writer
    }

    // MARK: - Primitives

    /// Adds a boolean element to the report.
    // 向报告添加布尔元素
    func add(_ name: String, _ value: Bool) {
        // 将Swift字符串转换为C字符串并调用C函数
        name.withCString { cName in
            ptr.pointee.addBooleanElement(ptr, cName, value)
        }
    }

    /// Adds a floating-point element to the report.
    // 向报告添加浮点元素
    func add(_ name: String, _ value: Double) {
        // 将Swift字符串转换为C字符串并调用C函数
        name.withCString { cName in
            ptr.pointee.addFloatingPointElement(ptr, cName, value)
        }
    }

    /// Adds a signed integer element to the report.
    ///
    /// - Parameter name: The key name, or `nil` when adding to an array.
    // 向报告添加有符号整数元素
    // @param name 键名，或在添加到数组时为nil
    func add(_ name: String?, _ value: Int64) {
        // 如果提供了名称，转换为C字符串
        if let name {
            name.withCString { cName in
                ptr.pointee.addIntegerElement(ptr, cName, value)
            }
        } else {
            // 如果没有名称（数组元素），直接传递nil
            ptr.pointee.addIntegerElement(ptr, nil, value)
        }
    }

    /// Adds an unsigned integer element to the report.
    ///
    /// - Parameter name: The key name, or `nil` when adding to an array.
    // 向报告添加无符号整数元素
    // @param name 键名，或在添加到数组时为nil
    func add(_ name: String?, _ value: UInt64) {
        // 如果提供了名称，转换为C字符串
        if let name {
            name.withCString { cName in
                ptr.pointee.addUIntegerElement(ptr, cName, value)
            }
        } else {
            // 如果没有名称（数组元素），直接传递nil
            ptr.pointee.addUIntegerElement(ptr, nil, value)
        }
    }

    /// Adds a string element to the report.
    // 向报告添加字符串元素
    func add(_ name: String, _ value: String) {
        // 将名称和值都转换为C字符串并调用C函数
        name.withCString { cName in
            value.withCString { cValue in
                ptr.pointee.addStringElement(ptr, cName, cValue)
            }
        }
    }

    // MARK: - Containers

    /// Begins a new JSON object.
    ///
    /// - Parameter name: The key name for the object, or `nil` when adding to an array.
    // 开始新的JSON对象
    // @param name 对象的键名，或在添加到数组时为nil
    func beginObject(_ name: String?) {
        // 如果提供了名称，转换为C字符串
        if let name {
            name.withCString { cName in
                ptr.pointee.beginObject(ptr, cName)
            }
        } else {
            // 如果没有名称（数组元素），直接传递nil
            ptr.pointee.beginObject(ptr, nil)
        }
    }

    /// Begins a new JSON array.
    ///
    /// - Parameter name: The key name for the array, or `nil` when adding to an array.
    // 开始新的JSON数组
    // @param name 数组的键名，或在添加到数组时为nil
    func beginArray(_ name: String?) {
        // 如果提供了名称，转换为C字符串
        if let name {
            name.withCString { cName in
                ptr.pointee.beginArray(ptr, cName)
            }
        } else {
            // 如果没有名称（数组元素），直接传递nil
            ptr.pointee.beginArray(ptr, nil)
        }
    }

    /// Ends the current container (object or array).
    // 结束当前容器（对象或数组）
    func endContainer() {
        // 调用C函数结束容器
        ptr.pointee.endContainer(ptr)
    }
}
