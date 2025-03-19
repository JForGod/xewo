我将根据UI设计指南生成AI助手的Flutter UI代码。我会严格按照设计文档中的Glassmorphism风格和组件规范，先创建基础组件、主题和样式，再实现各种交互界面。
让我们从项目结构和基础设置开始：
1. 项目结构设置
首先，我们需要在lib/src/features/ai_assistant/目录下建立UI相关结构：
2. 核心主题和样式文件
首先创建以下文件：
lib/src/features/ai_assistant/presentation/themes/app_theme.dart
3. 用户模式主题定义
创建三种模式的主题文件：
lib/src/features/ai_assistant/presentation/themes/guardian_theme.dart
lib/src/features/ai_assistant/presentation/themes/standard_theme.dart
lib/src/features/ai_assistant/presentation/themes/pro_theme.dart
4. 动画定义文件
lib/src/features/ai_assistant/presentation/animations/assistant_animations.dart
5. 核心组件 - 助手容器
lib/src/features/ai_assistant/presentation/widgets/assistant_container.dart
6. 模式切换器组件
lib/src/features/ai_assistant/presentation/widgets/mode_switcher.dart
7. 多模态交互控件
lib/src/features/ai_assistant/presentation/widgets/multimodal_controls.dart
8. 全局悬浮助手组件
lib/src/features/ai_assistant/presentation/widgets/floating_assistant.dart

继续实现全局悬浮助手组件
lib/src/features/ai_assistant/presentation/widgets/floating_assistant.dart（继续）
9. 唤醒机制相关UI
lib/src/features/ai_assistant/presentation/widgets/activation_widgets.dart
10. 监护模式UI页面
lib/src/features/ai_assistant/presentation/pages/guardian_mode_page.dart
11. 标准模式UI页面
lib/src/features/ai_assistant/presentation/pages/standard_mode_page.dart
12. 专业模式UI页面
lib/src/features/ai_assistant/presentation/pages/pro_mode_page.dart
13. 完成专业模式UI页面
lib/src/features/ai_assistant/presentation/pages/pro_mode_page.dart（继续）
14. 创建主应用入口组件
lib/src/features/ai_assistant/presentation/pages/ai_assistant_entry.dart
15. 创建模式特定设置页面
lib/src/features/ai_assistant/presentation/pages/mode_settings_page.dart
16. 创建统一入口点
lib/src/features/ai_assistant/presentation/ai_assistant.dart
17. 创建导出文件
lib/src/features/ai_assistant/ai_assistant_export.dart
18. 实现主题文件
lib/src/features/ai_assistant/presentation/themes/app_theme.dart
lib/src/features/ai_assistant/presentation/themes/guardian_theme.dart
lib/src/features/ai_assistant/presentation/themes/standard_theme.dart
lib/src/features/ai_assistant/presentation/themes/pro_theme.dart
19. 助手容器组件
lib/src/features/ai_assistant/presentation/widgets/assistant_container.dart
20. 多模态控制组件
lib/src/features/ai_assistant/presentation/widgets/multimodal_controls.dart
21. 模式切换器组件
lib/src/features/ai_assistant/presentation/widgets/mode_switcher.dart
22. 助手动画样式
lib/src/features/ai_assistant/presentation/themes/animations.dart
23. 助手导出文件（完成）
lib/src/features/ai_assistant/ai_assistant_export.dart
24. 全局状态管理UI组件
lib/src/features/ai_assistant/presentation/widgets/global_state_manager.dart
25. 上下文感知卡片组件
lib/src/features/ai_assistant/presentation/widgets/context_aware_card.dart
26. 语音波形组件
lib/src/features/ai_assistant/presentation/widgets/voice_wave_form.dart
27. 手势轨迹组件
lib/src/features/ai_assistant/presentation/widgets/gesture_trail.dart
28. 视线追踪反馈组件
lib/src/features/ai_assistant/presentation/widgets/gaze_feedback.dart
29. 视频互动组件
lib/src/features/ai_assistant/presentation/widgets/video_interaction.dart
30. 助手消息气泡组件
lib/src/features/ai_assistant/presentation/widgets/message_bubble.dart
31. 创建主应用入口点
lib/main_ai_assistant.dart
32. 完成所有组件
至此，我们已经完成了所有必要的UI组件代码，包括：
全局助手结构：
主应用入口点
AI助手容器
浮动助手组件
交互界面：
监护模式页面
标准模式页面
专业模式页面
模式设置页面
交互组件：
多模态控制组件
模式切换器
激活组件（语音、手势等）
视觉反馈组件：
全局状态管理UI
上下文感知卡片
语音波形组件
手势轨迹组件
视线追踪反馈组件
视频互动组件
消息气泡组件
主题和样式：
全局主题
各模式特定主题
动画样式
这些UI组件严格遵循了0030全局AI助手的UI界面生成指南2025-03-14.md和0029全局AI助手设计与实现2025-03-14.md中定义的设计规范，采用了Glassmorphism风格，实现了多种状态转换和交互效果。同时，代码结构也按照0029全局AI助手设计与实现2025-03-14.md中提出的架构设计进行了组织。

根据设计指南，我已经为AI助手创建了所有缺少的UI组件，采用了Glassmorphism磨砂玻璃风格。以下是完成的组件列表：

### 状态管理UI组件
1. **状态指示器** (state_indicator.dart)
   - 展示AI助手的运行状态（活跃、协作、休眠）
   - 使用磨砂玻璃效果和状态特定颜色

2. **任务切换面板** (task_switcher.dart)
   - 网格式任务卡片布局
   - 实时资源占用波形图
   - 支持多任务切换和关闭

3. **资源仪表盘** (resource_dashboard.dart)
   - 卡片式网格布局
   - 实时资源使用指标
   - 系统健康度指示

4. **性能监视器** (performance_monitor.dart)
   - 响应时间和操作延迟显示
   - 优化建议
   - 可折叠设计

### 知识系统UI组件
1. **知识图谱可视化** (knowledge_graph.dart)
   - 交互式知识节点展示
   - 磨砂玻璃气泡节点
   - 支持缩放和平移
   - 节点之间的关联可视化

2. **学习进度展示** (learning_progress.dart)
   - 渐变玻璃环进度条
   - 多维数据雷达图
   - 最近学习活动列表

### 沙盒系统UI组件
1. **沙盒状态组件** (sandbox_status.dart)
   - 活跃沙盒环境展示
   - 资源使用监控
   - 安全事件列表

2. **安全策略配置** (security_config.dart)
   - 安全级别滑动调节器
   - 权限管理矩阵
   - 网络规则配置
   - 预设安全配置切换

### 索引文件
创建了一个索引文件(index.dart)，方便统一导入所有UI组件。

这些组件严格遵循了设计文档中的Glassmorphism风格规范：
- 模糊度：16px-32px
- 透明度：0.1-0.9
- 圆角：12px-24px
- 多层阴影叠加
- 设计文档指定的色彩方案

所有UI组件都已实现，但尚未连接到实际功能逻辑。这些组件为后续功能实现提供了完整的UI基础，遵循了"先UI后逻辑"的开发方式。



所有的UI组件都只包含界面呈现代码，没有实际的功能逻辑实现，这与您的要求一致，即"不用管功能实现，等所有UI代码都生成完毕，我们再开始功能逻辑的具体实现和测试"。
接下来，我们可以开始功能逻辑的具体实现和测试。