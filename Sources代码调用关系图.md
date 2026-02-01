# KSCrash Sources目录代码调用关系图

## 模块层次结构

```
┌─────────────────────────────────────────────────────────────┐
│                     应用层 (Application)                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         KSCrashInstallations (安装配置层)              │   │
│  │  - KSCrashInstallation (基类)                        │   │
│  │  - KSCrashInstallationStandard (标准安装)            │   │
│  │  - KSCrashInstallationConsole (控制台安装)           │   │
│  │  - KSCrashInstallationEmail (邮件安装)               │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓ 依赖
┌─────────────────────────────────────────────────────────────┐
│                   报告处理层 (Reporting)                      │
│  ┌──────────────────────┐  ┌──────────────────────────┐   │
│  │  KSCrashSinks        │  │  KSCrashFilters          │   │
│  │  (报告输出目标)       │  │  (报告过滤器)             │   │
│  │  - Standard          │  │  - JSON编码/解码          │   │
│  │  - Console           │  │  - GZip压缩/解压          │   │
│  │  - Email             │  │  - Apple格式转换          │   │
│  └──────────────────────┘  │  - Demangle符号反混淆     │   │
│         ↓ 依赖              │  - Doctor崩溃诊断         │   │
│  ┌──────────────────────┐  │  - Basic基础过滤器       │   │
│  │  KSCrashFilters      │  └──────────────────────────┘   │
│  └──────────────────────┘                                  │
└─────────────────────────────────────────────────────────────┘
                            ↓ 依赖
┌─────────────────────────────────────────────────────────────┐
│                   记录层 (Recording)                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         KSCrashRecording (公共API层)                  │   │
│  │  - KSCrash (主入口类)                                 │   │
│  │  - KSCrashConfiguration (配置类)                     │   │
│  │  - KSCrashReportStore (报告存储)                      │   │
│  │  - KSCrashReport (报告模型)                           │   │
│  │  ┌──────────────────────────────────────────────┐  │   │
│  │  │  Monitors (监控器)                             │  │   │
│  │  │  - MachException (Mach异常)                    │  │   │
│  │  │  - Signal (信号)                               │  │   │
│  │  │  - NSException (Objective-C异常)               │  │   │
│  │  │  - CppException (C++异常)                      │  │   │
│  │  │  - User (用户自定义异常)                        │  │   │
│  │  │  - Deadlock (死锁检测)                          │  │   │
│  │  │  - Watchdog (看门狗)                            │  │   │
│  │  │  - Zombie (僵尸对象)                            │  │   │
│  │  │  - AppState (应用状态)                          │  │   │
│  │  │  - Memory (内存监控)                            │  │   │
│  │  │  - System (系统信息)                             │  │   │
│  │  └──────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓ 依赖
┌─────────────────────────────────────────────────────────────┐
│                   核心层 (Core)                              │
│  ┌──────────────────────┐  ┌──────────────────────────┐   │
│  │ KSCrashRecordingCore │  │ KSCrashReportingCore     │   │
│  │ (记录核心)            │  │ (报告核心)                │   │
│  │                      │  │                          │   │
│  │ - KSCrashMonitor     │  │ - KSHTTPRequestSender    │   │
│  │ - KSCrashMonitorAPI  │  │ - KSHTTPMultipartPostBody│   │
│  │ - KSBacktrace        │  │ - KSGZipHelper           │   │
│  │ - KSStackCursor      │  │ - KSJSONCodec             │   │
│  │ - KSSymbolicator     │  │ - KSReachability         │   │
│  │ - KSMachineContext   │  │                          │   │
│  │ - KSCrashReportWriter│  │                          │   │
│  │ - KSJSONCodec        │  │                          │   │
│  │ - KSCPU              │  │                          │   │
│  │ - KSThread           │  │                          │   │
│  │ - KSMemory           │  │                          │   │
│  │ - KSObjC             │  │                          │   │
│  │ - KSFileUtils        │  │                          │   │
│  │ - KSDynamicLinker    │  │                          │   │
│  └──────────────────────┘  └──────────────────────────┘   │
│                            ↓ 依赖                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         KSCrashCore (基础核心)                         │  │
│  │  - KSSpinLock (自旋锁)                                │  │
│  │  - KSUnfairLock (不公平锁)                            │  │
│  │  - KSNSErrorHelper (错误辅助)                          │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓ 依赖
┌─────────────────────────────────────────────────────────────┐
│                   可选模块 (Optional)                        │
│  ┌──────────────────────┐  ┌──────────────────────────┐   │
│  │KSCrashDemangleFilter │  │ KSCrashDiscSpaceMonitor   │   │
│  │(符号反混淆过滤器)      │  │ (磁盘空间监控)            │   │
│  └──────────────────────┘  └──────────────────────────┘   │
│  ┌──────────────────────┐  ┌──────────────────────────┐   │
│  │KSCrashBootTimeMonitor│  │   KSCrashProfiler        │   │
│  │(启动时间监控)          │  │   (性能分析器)           │   │
│  └──────────────────────┘  └──────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓ 独立
┌─────────────────────────────────────────────────────────────┐
│                   报告模型层 (Report Model)                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Report (Swift报告模型)                        │   │
│  │  - CrashReport (崩溃报告模型)                         │   │
│  │  - Thread (线程模型)                                  │   │
│  │  - StackFrame (栈帧模型)                              │   │
│  │  - BinaryImage (二进制镜像模型)                       │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 详细依赖关系

### 1. KSCrashCore (基础核心层)
- **功能**: 提供最基础的同步原语和工具类
- **依赖**: 无
- **被依赖**: 
  - KSCrashRecordingCore
  - KSCrashReportingCore
- **主要文件**:
  - `KSSpinLock.c` - 自旋锁实现
  - `KSUnfairLock.m` - 不公平锁封装
  - `KSNSErrorHelper.m` - NSError辅助工具

### 2. KSCrashRecordingCore (记录核心层)
- **功能**: 崩溃记录的核心功能，包括监控器管理、栈回溯、符号化等
- **依赖**: 
  - KSCrashCore
- **被依赖**:
  - KSCrashRecording
  - KSCrashFilters
  - KSCrashDiscSpaceMonitor
  - KSCrashBootTimeMonitor
  - KSCrashProfiler
  - KSCrashTestTools
- **主要模块**:
  - **监控器管理**: `KSCrashMonitor.c`, `KSCrashMonitorAPI.c`, `KSCrashMonitorRegistry.c`
  - **栈回溯**: `KSBacktrace.c`, `KSStackCursor.c`
  - **符号化**: `KSSymbolicator.c`
  - **机器上下文**: `KSMachineContext.c`, `KSCPU.c`
  - **报告写入**: `KSCrashReportWriter.c`
  - **JSON编码**: `KSJSONCodec.c`
  - **线程管理**: `KSThread.c`
  - **内存管理**: `KSMemory.c`
  - **Objective-C支持**: `KSObjC.c`
  - **文件工具**: `KSFileUtils.c`
  - **动态链接器**: `KSDynamicLinker.c`

### 3. KSCrashReportingCore (报告核心层)
- **功能**: 报告处理的核心功能，包括HTTP通信、JSON编码、GZip压缩等
- **依赖**:
  - KSCrashCore
- **被依赖**:
  - KSCrashFilters
- **主要模块**:
  - **HTTP通信**: `KSHTTPRequestSender.m`, `KSHTTPMultipartPostBody.m`
  - **GZip压缩**: `KSGZipHelper.m`
  - **JSON编码**: `KSJSONCodecObjC.m`
  - **网络可达性**: `KSReachabilityKSCrash.m`
  - **字符串工具**: `KSCString.m`, `KSNSDictionaryHelper.m`

### 4. KSCrashRecording (记录公共API层)
- **功能**: 崩溃记录的公共API，提供高级接口和配置
- **依赖**:
  - KSCrashRecordingCore
  - KSCrashCore
- **被依赖**:
  - KSCrashFilters
  - KSCrashSinks
  - KSCrashInstallations
  - KSCrashDemangleFilter
  - KSCrashProfiler
- **主要模块**:
  - **主入口**: `KSCrash.m`, `KSCrashC.c`
  - **配置**: `KSCrashConfiguration.m`
  - **报告存储**: `KSCrashReportStore.m`
  - **报告模型**: `KSCrashReport.m`
  - **监控器实现**:
    - `KSCrashMonitor_MachException.c` - Mach异常监控
    - `KSCrashMonitor_Signal.c` - 信号监控
    - `KSCrashMonitor_NSException.m` - NSException监控
    - `KSCrashMonitor_CPPException.cpp` - C++异常监控
    - `KSCrashMonitor_User.c` - 用户自定义异常
    - `KSCrashMonitor_Deadlock.c` - 死锁检测
    - `KSCrashMonitor_Watchdog.c` - 看门狗监控
    - `KSCrashMonitor_Zombie.c` - 僵尸对象检测
    - `KSCrashMonitor_AppState.m` - 应用状态监控
    - `KSCrashMonitor_Memory.c` - 内存监控
    - `KSCrashMonitor_System.m` - 系统信息监控

### 5. KSCrashFilters (过滤器层)
- **功能**: 处理崩溃报告，包括格式转换、压缩、符号反混淆等
- **依赖**:
  - KSCrashRecording
  - KSCrashRecordingCore
  - KSCrashReportingCore
- **被依赖**:
  - KSCrashSinks
  - KSCrashInstallations
- **主要过滤器**:
  - `KSCrashReportFilterJSON.m` - JSON编码/解码
  - `KSCrashReportFilterGZip.m` - GZip压缩/解压
  - `KSCrashReportFilterAppleFmt.m` - Apple格式转换
  - `KSCrashReportFilterBasic.m` - 基础过滤器（管道、组合等）
  - `KSCrashReportFilterDoctor.m` - 崩溃诊断
  - `KSCrashReportFilterStringify.m` - 字符串化
  - `KSCrashReportFilterAlert.m` - 警报过滤器
  - `KSCrashReportFilterSets.m` - 过滤器集合

### 6. KSCrashSinks (报告输出层)
- **功能**: 将处理后的报告发送到不同目标
- **依赖**:
  - KSCrashRecording
  - KSCrashFilters
- **被依赖**:
  - KSCrashInstallations
- **主要Sink**:
  - `KSCrashReportSinkStandard.m` - 标准HTTP发送
  - `KSCrashReportSinkConsole.m` - 控制台输出
  - `KSCrashReportSinkEMail.m` - 邮件发送

### 7. KSCrashInstallations (安装配置层)
- **功能**: 提供易于使用的安装配置，组合过滤器和Sink
- **依赖**:
  - KSCrashFilters
  - KSCrashSinks
  - KSCrashRecording
  - KSCrashDemangleFilter
- **被依赖**: 无（顶层）
- **主要安装类**:
  - `KSCrashInstallation.m` - 基类
  - `KSCrashInstallationStandard.m` - 标准安装（HTTP发送）
  - `KSCrashInstallationConsole.m` - 控制台安装
  - `KSCrashInstallationEmail.m` - 邮件安装

### 8. 可选模块

#### KSCrashDemangleFilter (符号反混淆过滤器)
- **功能**: 反混淆C++和Swift符号
- **依赖**:
  - KSCrashRecording
- **被依赖**:
  - KSCrashInstallations
- **主要文件**:
  - `KSCrashReportFilterDemangle.m`
  - `KSDemangle_CPP.cpp` - C++符号反混淆
  - `KSDemangle_Swift.cpp` - Swift符号反混淆

#### KSCrashDiscSpaceMonitor (磁盘空间监控)
- **功能**: 监控可用磁盘空间
- **依赖**:
  - KSCrashRecordingCore
- **被依赖**: 无
- **主要文件**:
  - `KSCrashMonitor_DiscSpace.m`

#### KSCrashBootTimeMonitor (启动时间监控)
- **功能**: 监控设备启动时间
- **依赖**:
  - KSCrashRecordingCore
- **被依赖**: 无
- **主要文件**:
  - `KSCrashMonitor_BootTime.m`

#### KSCrashProfiler (性能分析器)
- **功能**: 采样性能分析
- **依赖**:
  - KSCrashRecordingCore
  - KSCrashRecording
- **被依赖**: 无
- **主要文件**:
  - `Profiler.swift`
  - `Profile.swift`
  - `Sample.swift`

### 9. Report (报告模型层)
- **功能**: Swift实现的崩溃报告数据模型
- **依赖**: 无（独立模块）
- **被依赖**: 无
- **主要文件**:
  - Swift文件，定义崩溃报告的数据结构

## 调用流程示例

### 崩溃捕获流程
```
应用崩溃
    ↓
KSCrashRecording (KSCrash.m)
    ↓
KSCrashC.c (C接口)
    ↓
KSCrashRecordingCore (KSCrashMonitor.c)
    ↓
具体监控器 (如 KSCrashMonitor_MachException.c)
    ↓
KSCrashReportWriter (写入报告)
    ↓
KSCrashReportStore (存储报告)
```

### 报告处理流程
```
KSCrashInstallation (安装配置)
    ↓
KSCrashReportStore (读取报告)
    ↓
KSCrashFilters (处理报告)
    ├─ KSCrashReportFilterDemangle (符号反混淆)
    ├─ KSCrashReportFilterDoctor (崩溃诊断)
    ├─ KSCrashReportFilterJSON (JSON编码)
    ├─ KSCrashReportFilterGZip (压缩)
    └─ KSCrashReportFilterAppleFmt (格式转换)
    ↓
KSCrashSinks (发送报告)
    ├─ KSCrashReportSinkStandard (HTTP发送)
    ├─ KSCrashReportSinkConsole (控制台输出)
    └─ KSCrashReportSinkEMail (邮件发送)
```

## 模块间接口

### KSCrashRecordingCore → KSCrashCore
- 使用: `KSSpinLock`, `KSUnfairLock`, `KSNSErrorHelper`

### KSCrashRecording → KSCrashRecordingCore
- 使用: `KSCrashMonitor`, `KSBacktrace`, `KSCrashReportWriter`, `KSJSONCodec`

### KSCrashFilters → KSCrashRecording
- 使用: `KSCrashReport`, `KSCrashReportFilter`协议

### KSCrashFilters → KSCrashReportingCore
- 使用: `KSJSONCodecObjC`, `KSGZipHelper`, `KSHTTPRequestSender`

### KSCrashSinks → KSCrashFilters
- 使用: `KSCrashReportFilter`协议

### KSCrashInstallations → KSCrashFilters + KSCrashSinks
- 使用: 组合过滤器和Sink创建完整的报告处理管道

## 关键设计模式

1. **分层架构**: 清晰的层次结构，从基础核心到高级API
2. **依赖倒置**: 上层模块依赖下层模块的抽象接口
3. **策略模式**: 过滤器、Sink、监控器都使用策略模式
4. **管道模式**: 过滤器可以组合成处理管道
5. **单例模式**: KSCrash使用单例模式
6. **工厂模式**: Installation类提供工厂方法创建配置好的实例

## 数据流向

```
崩溃事件 → 监控器捕获 → 上下文收集 → 报告生成 → 报告存储
                                                      ↓
报告读取 → 过滤器处理 → 格式转换 → Sink发送 → 目标服务器/控制台
```
