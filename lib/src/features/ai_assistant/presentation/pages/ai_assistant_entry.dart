import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/floating_assistant.dart';
import '../widgets/mode_switcher.dart';
import '../widgets/multimodal_controls.dart';
import '../widgets/activation_widgets.dart';
import '../themes/app_theme.dart';
import '../../domain/models/assistant_mode.dart';
import '../../domain/models/assistant_state.dart';
import '../../providers/assistant_state_provider.dart';
import 'guardian_mode_page.dart';
import 'standard_mode_page.dart';
import 'pro_mode_page.dart';
import '../../../../ui/screens/home/home_screen.dart';
import '../../../../ui/screens/coding/coding_screen.dart';
import '../../../../ui/screens/learning/learning_screen.dart';
import '../../../../ui/screens/settings/settings_screen.dart';

/// 导航按钮数据模型
class NavButton {
  final String label;
  final IconData icon;
  final Widget destination;

  const NavButton({
    required this.label,
    required this.icon,
    required this.destination,
  });
}

class AIAssistantEntry extends ConsumerStatefulWidget {
  const AIAssistantEntry({Key? key}) : super(key: key);

  @override
  ConsumerState<AIAssistantEntry> createState() => _AIAssistantEntryState();
}

class _AIAssistantEntryState extends ConsumerState<AIAssistantEntry> with SingleTickerProviderStateMixin {
  // 使用TransitionController管理动画
  late AnimationController _transitionController;
  
  // 仅保留本地状态：助手显示状态
  FloatingAssistantState _currentAssistantState = FloatingAssistantState.collapsed;
  
  // 2025-03-16: 添加导航按钮列表
  final List<NavButton> _navButtons = [
    NavButton(
      label: '主页',
      icon: Icons.home_rounded,
      destination: const HomeScreen(),
    ),
    NavButton(
      label: '智能编程',
      icon: Icons.code_rounded,
      destination: const CodingScreen(),
    ),
    NavButton(
      label: '学习',
      icon: Icons.school_rounded,
      destination: const LearningScreen(),
    ),
    NavButton(
      label: '设置',
      icon: Icons.settings_rounded,
      destination: const SettingsScreen(),
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  // 2025-03-17: 修改-使用状态提供者管理模式切换
  void _handleModeChange(AssistantMode newMode) {
    // 获取状态提供者
    final notifier = ref.read(assistantStateProvider.notifier);
    
    // 触发动画
    _transitionController.reset();
    _transitionController.forward();
    
    // 更新模式
    final result = notifier.setAssistantMode(newMode);
    
    // 如果有错误，显示提示
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? '切换模式失败')),
      );
    }
  }

  void _handleAssistantStateChange(FloatingAssistantState newState) {
    setState(() {
      _currentAssistantState = newState;
    });
    
    // 2025-03-17: 修改-当助手展开/折叠时，更新状态提供者中的可见性
    final notifier = ref.read(assistantStateProvider.notifier);
    final isVisible = newState != FloatingAssistantState.collapsed;
    notifier.setAssistantVisibility(isVisible);
  }

  // 2025-03-17: 修改-使用状态提供者管理语音激活
  void _toggleVoiceActivation() {
    // 创建一个记录操作的函数
    final notifier = ref.read(assistantStateProvider.notifier);
    notifier.logAssistantAction(
      'toggle_voice_activation',
      {'timestamp': DateTime.now().toIso8601String()},
    );
    
    // 这里仅记录操作，具体的语音激活逻辑稍后实现
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('语音激活功能正在开发中...')),
    );
  }

  // 2025-03-17: 修改-使用状态提供者管理手势激活
  void _toggleGestureActivation() {
    // 创建一个记录操作的函数
    final notifier = ref.read(assistantStateProvider.notifier);
    notifier.logAssistantAction(
      'toggle_gesture_activation',
      {'timestamp': DateTime.now().toIso8601String()},
    );
    
    // 这里仅记录操作，具体的手势激活逻辑稍后实现
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('手势激活功能正在开发中...')),
    );
  }

  // 2025-03-17: 修改-导航到指定页面的方法，针对主页特殊处理
  void _navigateToPage(BuildContext context, Widget page, {bool isHome = false}) {
    // 如果是主页，则使用Navigator.popUntil回到根页面
    if (isHome) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      // 其他页面正常导航
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => page,
        ),
      );
    }
    
    // 2025-03-17: 修改-记录导航操作
    final notifier = ref.read(assistantStateProvider.notifier);
    notifier.logAssistantAction(
      'navigate_to_page',
      {
        'timestamp': DateTime.now().toIso8601String(),
        'destination': page.runtimeType.toString(),
        'isHome': isHome,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 2025-03-17: 修改-从状态提供者获取当前模式和错误信息
    final assistantState = ref.watch(assistantStateProvider);
    final currentMode = assistantState.currentMode;
    final hasError = assistantState.hasError;
    
    return Stack(
      children: [
        // 边缘触发器
        Positioned(
          left: 0,
          top: MediaQuery.of(context).size.height / 3,
          child: EdgeTrigger(
            position: EdgePosition.left,
            onTap: () {
              // 展开助手
              _handleAssistantStateChange(FloatingAssistantState.semiExpanded);
            },
          ),
        ),
        
        // 2025-03-17: 修改-语音唤醒指示器
        Positioned(
          right: 24,
          bottom: 24,
          child: VoiceActivationIndicator(
            isListening: false, // 暂时固定为false，后续实现
            onTap: _toggleVoiceActivation,
          ),
        ),
        
        // 全局悬浮助手
        FloatingAssistant(
          initialState: _currentAssistantState,
          onStateChanged: _handleAssistantStateChange,
          collapsedChild: _buildCollapsedChild(currentMode),
          semiExpandedChild: _buildSemiExpandedChild(currentMode),
          fullyExpandedChild: _buildFullyExpandedChild(currentMode),
        ),
        
        // 2025-03-17: 修改-手势唤醒区域 (仅在调试模式显示)
        if (assistantState.contextAwarenessLevel == ContextAwarenessLevel.high)
          Positioned(
            right: 100,
            bottom: 100,
            child: GestureActivationZone(
              isActive: true,
              onTap: _toggleGestureActivation,
            ),
          ),
          
        // 快捷键提示 (仅在特定条件下显示)
        Positioned(
          top: 20,
          right: 20,
          child: AnimatedOpacity(
            opacity: 0.8,
            duration: const Duration(milliseconds: 300),
            child: HotkeyOverlay(
              hotkey: currentMode == AssistantMode.guardian
                  ? 'Ctrl+G'
                  : currentMode == AssistantMode.pro
                      ? 'Ctrl+Alt+A'
                      : 'Ctrl+Shift+A',
              onTap: () {
                // 展开助手
                _handleAssistantStateChange(FloatingAssistantState.fullyExpanded);
              },
            ),
          ),
        ),
        
        // 2025-03-16: 添加圆形导航按钮
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: _buildNavigationButtons(),
        ),
        
        // 2025-03-17: 新增-如果有错误，显示错误提示
        if (hasError)
          Positioned(
            top: 50,
            right: 20,
            child: ErrorIndicator(
              error: assistantState.lastError!,
              timestamp: assistantState.lastErrorTime,
            ),
          ),
      ],
    );
  }

  // 2025-03-17: 修改-根据当前模式构建折叠状态UI
  Widget _buildCollapsedChild(AssistantMode currentMode) {
    final color = currentMode == AssistantMode.guardian
        ? Colors.purple
        : currentMode == AssistantMode.pro
            ? Colors.green
            : Colors.blue;
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.smart_toy,
          color: Colors.white,
        ),
      ),
    );
  }

  // 半展开状态UI
  Widget _buildSemiExpandedChild(AssistantMode currentMode) {
    return Container(
      width: 240,
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      // 使用SingleChildScrollView包装Column以修复布局溢出问题
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 模式切换器
            ModeSwitcher(
              currentMode: currentMode,
              onModeChanged: _handleModeChange,
            ),
            const SizedBox(height: 16),
            const Text(
              '提示',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // 移除Expanded，因为在SingleChildScrollView中不需要
            ListView(
              // 通过shrinkWrap使ListView根据子元素大小调整尺寸
              shrinkWrap: true,
              // 禁用滚动，因为外层已有SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                QuickActionCard(
                  title: '编写代码',
                  description: '帮助你快速编写高质量代码',
                  icon: Icons.code,
                ),
                SizedBox(height: 8),
                QuickActionCard(
                  title: '解释代码',
                  description: '分析并解释复杂的代码片段',
                  icon: Icons.lightbulb,
                ),
                SizedBox(height: 8),
                QuickActionCard(
                  title: '提供建议',
                  description: '根据当前上下文提供智能建议',
                  icon: Icons.tips_and_updates,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 展开按钮
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _handleAssistantStateChange(FloatingAssistantState.fullyExpanded);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('展开助手'),
              ),
            ),
            // 额外的空间，确保底部有足够的间距
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // 完全展开状态UI
  Widget _buildFullyExpandedChild(AssistantMode currentMode) {
    // 根据模式返回不同的页面
    switch (currentMode) {
      case AssistantMode.guardian:
        return const GuardianModePage();
      case AssistantMode.pro:
        return const ProModePage();
      case AssistantMode.standard:
      default:
        return const StandardModePage();
    }
  }
  
  // 构建导航按钮
  Widget _buildNavigationButtons() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _navButtons.map((button) => _buildNavButton(button)).toList(),
      ),
    );
  }
  
  // 2025-03-17: 修改-构建单个导航按钮
  Widget _buildNavButton(NavButton button) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: GestureDetector(
        onTap: () {
          _navigateToPage(
            context,
            button.destination,
            isHome: button.label == '主页',
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
              child: Icon(
                button.icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              button.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 2025-03-17: 新增-快速操作卡片组件
class QuickActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  
  const QuickActionCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 2025-03-17: 新增-错误指示器组件
class ErrorIndicator extends StatelessWidget {
  final String error;
  final DateTime? timestamp;
  
  const ErrorIndicator({
    Key? key,
    required this.error,
    this.timestamp,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '错误: ${error.length > 20 ? '${error.substring(0, 20)}...' : error}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
