# TTS系统第三轮修复计划

## 问题分类

根据编译错误，我们可以将剩余问题分为以下几类:

### 1. 类型导出冲突
- `TTSVoice` 从多个文件导出
- `TTSEngineConfig` 从多个文件导出
- `TTSConfigException` 从多个文件导出
- `AudioPlaybackController` 从多个文件导出

### 2. 缺失类型定义
- `PlaybackProgress` 类型未定义
- `TTSConfigurationException` 不是类型

### 3. 枚举值缺失
- `PlaybackState` 缺少 `started` 和 `completed` 静态成员
- `TTSEngineType` 缺少 `appleTTS`, `edgeTTS`, `azureTTS`, `googleTTS` 等值
- `IosTextToSpeechAudioCategoryOptions` 缺少 `soloAmbient`, `record` 等值

### 4. 属性和方法缺失
- `TTSConfig` 缺少 `voiceSettings` getter
- `TTSVoiceSettings` 类中的 `call` 方法缺失
- `TTSEngine` 缺少 `voiceSettings` 属性
- 各种错误类需要构造函数参数

### 5. 依赖注入和提供者问题
- `getIt` 方法未找到
- `TTSModule` 缺少 `cleanup` 方法
- 多个提供者找不到或参数不匹配

### 6. 语音处理相关问题
- `VoiceProcessor` 类缺少多个方法和属性
- `VoiceProcessingState` 类缺少多个属性
- 处理状态枚举缺少 `listening`, `speaking`, `idle` 等值

### 7. 导入路径错误
- 多个文件导入路径错误，如 `tts_exceptions.dart` 不存在

## 修复策略

### 1. 第一阶段：解决类型导出冲突
- 创建统一的类型导出文件，确保每个类型只从一个地方导出
- 删除重复导出，只保留一个导出源
- 更新所有导入，使用统一的导入路径

### 2. 第二阶段：添加缺失的类型和枚举
- 创建 `PlaybackProgress` 类
- 添加缺失的枚举值到相应的枚举类型
- 确保所有需要的枚举类型完整定义

### 3. 第三阶段：添加缺失的属性和方法
- 为 `TTSConfig` 添加 `voiceSettings` getter
- 为 `TTSVoiceSettings` 添加 `call` 方法
- 修复其他缺失的属性和方法

### 4. 第四阶段：解决依赖注入问题
- 确保 `getIt` 正确导入
- 为 `TTSModule` 添加 `cleanup` 方法
- 修复提供者的参数问题

### 5. 第五阶段：语音处理模块修复
- 完善 `VoiceProcessor` 类的实现
- 添加缺失的状态枚举值
- 确保所有事件处理逻辑完整

### 6. 最后阶段：修复导入路径和其他错误
- 修复所有错误的导入路径
- 解决剩余的编译错误

## 优先级排序

以下是按照严重性和依赖关系排序的修复优先级：

1. 解决类型导出冲突 (阻止了大部分代码的编译)
2. 添加缺失的类型定义 (这些类型被多处引用)
3. 完善枚举值 (这影响了状态处理)
4. 添加缺失的属性和方法 (这些是功能实现的基础)
5. 解决依赖注入问题 (这影响了系统的组装)
6. 语音处理模块修复 (单独的功能模块)
7. 修复导入路径和其他错误 (清理工作)

## 工作计划

1. 首先分析每个报错，确定它属于哪个类别
2. 按照优先级顺序修复问题
3. 每修复一类问题后，进行一次编译测试
4. 记录修复过程，为后续维护提供参考

## 预计挑战

1. 类型冲突解决可能会影响现有的代码逻辑
2. 添加缺失的枚举值可能需要同时更新多处使用这些枚举的代码
3. 依赖注入问题可能涉及到整个应用的结构
4. 语音处理模块的修复可能需要深入理解该功能的设计意图

通过这个系统性的修复计划，我们将逐步解决TTS系统的剩余问题，提高代码质量和系统稳定性。 