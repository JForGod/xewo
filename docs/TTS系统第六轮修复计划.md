# TTS系统第六轮修复计划

## 当前状态分析

通过运行 `flutter analyze` 命令，我们发现以下主要问题类型：

1. **TTS测试用例错误**：
   - `test/features/ai_assistant/domain/tts/tts_exception_test.dart` 中的URI不存在和未定义标识符问题
   - `test/features/ai_assistant/tts_models_test.dart` 中的参数不匹配和未定义函数错误
   - `test/features/ai_assistant/tts_service_test.dart` 中的类型不兼容错误
   - `test/src/features/ai_assistant/domain/tts/tts_module_test.dart` 中的模拟对象错误

2. **UI组件中的弃用API**：
   - 大量使用已弃用的 `withOpacity` 方法，应该使用 `.withValues()` 代替
   - 使用了已弃用的 `RawKeyboard`、`RawKeyEvent` 等API，应该使用 `HardwareKeyboard`、`KeyEvent` 等替代
   - 使用了已弃用的 `onWillAccept` 和 `onAccept`，应该使用 `onWillAcceptWithDetails` 和 `onAcceptWithDetails`

3. **文件树组件错误**：
   - `FileNode` 类相关的未定义类和方法错误
   - `FileTreeState` 的 `nodes`、`isMultiSelectMode` 和 `selectedPaths` getter未定义
   - 文件操作方法如 `createFolder`、`deleteNode` 等未定义

4. **编辑器组件错误**：
   - `multi_cursor_editor.dart` 中存在不兼容的API使用，如 `DragDownDetails.kind` 和 `DragDownDetails.buttons`
   - 缺少必要的导入和类定义

## 修复优先级

根据错误的严重性和影响范围，我们建议按以下优先级进行修复：

1. **优先级A（第六轮主要目标）**：
   - 更新测试用例，确保与新的TTS系统实现兼容（主要是导入路径和类型定义）
   - 实现 `FileNode` 类及相关接口，解决文件树组件的大量错误

2. **优先级B（后续轮次）**：
   - 替换弃用的UI API，特别是 `withOpacity` 和键盘相关API
   - 更新文件操作方法，确保文件树功能正常
   - 修复编辑器组件不兼容API问题

3. **优先级C（最后处理）**：
   - 解决次要的警告，如未使用的导入和变量
   - 优化代码结构，消除重复导入
   - 完善测试覆盖范围

## 第六轮修复计划

### 1. 更新TTS测试用例

1. 修复测试导入路径：
   - 检查所有测试文件中的导入语句，确保它们指向正确的文件位置
   - 如果导入文件不存在，创建必要的存根文件或调整测试用例

2. 更新测试断言：
   - 更新测试中使用的API和类型，确保与最新实现一致
   - 修复构造函数参数不匹配问题（如`TTSConfig`构造函数）
   - 确保枚举使用与实现一致

3. 创建必要的模拟对象：
   - 实现或更新`MockTTSService`、`MockSharedPreferences`等测试所需的模拟类

### 2. 实现FileNode类及相关接口

1. 创建基础文件节点模型：
   - 定义`FileNode`类，包含必要的属性和方法
   - 实现文件树状态管理相关的接口

2. 更新文件树状态：
   - 为`FileTreeState`添加缺失的`nodes`、`isMultiSelectMode`和`selectedPaths` getter
   - 确保状态与视图组件正确连接

3. 实现文件操作方法：
   - 添加`createFolder`、`deleteNode`、`renameNode`等方法
   - 确保所有文件操作与实际文件系统交互正确

### 3. 修复其他编译错误

1. 添加丢失的导入：
   - 解决"undefined identifier"错误
   - 确保所有必要的包和类都被正确导入

2. 修复类型错误：
   - 解决类型不兼容和转换问题
   - 确保泛型使用正确

## 测试计划

1. **单元测试**：
   - 为每个修复的类和方法编写单元测试
   - 确保测试覆盖所有主要功能和边界情况

2. **集成测试**：
   - 测试文件树组件的完整功能
   - 验证TTS系统的端到端功能

3. **UI测试**：
   - 验证UI组件的外观和行为是否正确
   - 测试用户交互流程

## 时间估计

- **TTS测试用例更新**：2天
- **FileNode实现**：3天
- **其他编译错误修复**：2天
- **测试和验证**：3天

**总计**：10个工作日

## 责任分配

1. **TTS测试更新**：张工
2. **FileNode实现**：李工
3. **编译错误修复**：王工
4. **测试和验证**：周工
5. **文档更新**：赵工

## 风险评估

1. **高风险**：
   - 文件树组件的改变可能影响整个应用的文件操作
   - 测试用例修改可能引入新的错误

2. **中风险**：
   - API弃用替换可能引入新的兼容性问题
   - 文件操作逻辑更改可能影响数据安全

3. **低风险**：
   - 代码结构优化可能暂时增加复杂性
   - 测试覆盖可能不完整

## 结论

第六轮修复将主要聚焦于测试用例更新和文件树组件错误修复，这是恢复项目功能的关键步骤。通过系统性地解决这些问题，我们将能够大幅减少编译错误数量，为后续的优化工作打下基础。

计划在10个工作日内完成主要修复工作，并在之后的迭代中解决次要问题和优化代码结构。 