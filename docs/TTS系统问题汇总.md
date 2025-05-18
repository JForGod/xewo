# TTS系统问题汇总

## 已解决问题

### 第一轮修复 (2025-06-25)

1. **类型系统问题**：
   - 添加了 `TTSVoiceSettings.defaultSettings` 静态方法
   - 将 `TTSEngineType` 从字符串类型改为枚举类型
   - 修复了 `TTSEvent` 和 `PlaybackState` 中的类型错误

2. **导出冲突问题**：
   - 解决了 `TTSConfigException` 重复导出问题
   - 优化了异常类的结构，清理了多余代码

3. **方法和属性问题**：
   - 修正了 `BaseTTSEngine` 中的 `broadcastProgressEvent` 使用的事件类型
   - 将 `TTSVoiceSettings.copyWith` 中的参数名从 `speed` 改为 `rate`

### 第二轮修复 (2025-06-26)

1. **类型导出冲突**：
   - 规范化了 `TTSVoice` 和 `TTSEngineConfig` 的导出
   - 优化了文件结构，避免重复导出

2. **缺失方法和属性**：
   - 为 `PlaybackState` 添加了 `started` 和 `completed` 静态工厂方法
   - 为 `TTSConfig` 添加了 `engineType` getter

3. **缺失类型定义**：
   - 创建了 `PlaybackProgress` 类，包含进度和文本属性
   - 更新了相关引用

4. **枚举不完整问题**：
   - 修复了 `IosTextToSpeechAudioCategoryOptions` 枚举在 switch 中的不完整匹配
   - 完善了 `TTSEventType` 在事件处理中的匹配

5. **声明冲突**：
   - 合并了 `TTSModule` 类定义，解决了依赖注入问题

6. **其他编译错误**：
   - 添加了缺失的导入
   - 规范化了导入路径

## 未解决问题

1. **测试用例失败**：
   - `tts_exception_test.dart` 中的测试用例找不到相关类型
   - `tts_models_test.dart` 中的类型不匹配
   - `tts_service_test.dart` 中的方法未定义

2. **接口实现不完整**：
   - 部分接口方法缺少实现
   - 一些依赖注入未正确配置

3. **编译警告**：
   - 大量 `withOpacity` 已弃用警告
   - UI 组件中的弃用 API 使用

4. **文件树组件错误**：
   - `FileNode` 类未定义
   - 文件树状态和节点管理存在问题

5. **多光标编辑器问题**：
   - `DragDownDetails` 和 `DragUpdateDetails` 属性未定义
   - 鼠标按键常量未定义

## 下一步计划

1. **测试修复**：
   - 更新测试用例以适应新的类型系统
   - 修复模拟对象创建

2. **接口完善**：
   - 实现缺失的方法
   - 完善依赖注入配置

3. **类型系统清理**：
   - 统一类型导出
   - 简化类型层次结构

4. **文档更新**：
   - 更新 API 文档
   - 添加使用示例

5. **UI 组件升级**：
   - 替换弃用 API
   - 修复文件树组件

## 优先级排序

1. **高优先级**：
   - 修复测试用例
   - 完成接口实现
   - 解决类型系统问题

2. **中优先级**：
   - 更新 UI 组件
   - 改进文档

3. **低优先级**：
   - 性能优化
   - 代码重构

## 常见错误模式

1. **类型不匹配**：
   - 返回类型不兼容（例如 `List<dynamic>` 不能转换为 `List<String>`）
   - 参数类型错误

2. **缺失属性**：
   - 类中缺少必要属性
   - getter 未实现

3. **枚举不完整**：
   - switch 语句中未包含所有枚举值
   - 缺少枚举类型处理

4. **导入冲突**：
   - 多个文件导出同一个类
   - 导入路径不一致 