import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../themes/app_theme.dart';
import '../widgets/navigation/nav_bar.dart';
import '../widgets/ai_assistant/ai_assistant_panel.dart';
import 'database/database_screen.dart';
import 'editor/editor_screen.dart';
import 'home/home_screen.dart';
import 'settings/settings_screen.dart';
import 'project/project_screen.dart';
import 'analysis/analysis_screen.dart';
import 'tools/tools_screen.dart';
import 'debug/debug_screen.dart';
import 'ai/ai_screen.dart';
import 'extensions/extensions_screen.dart';
import 'learning/learning_screen.dart';
import 'help/help_screen.dart';
import '../widgets/common/toolbar_button.dart';

/// 当前选中的导航项
final selectedNavItemProvider = StateProvider<String>((ref) => 'home');

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedNavItem = ref.watch(selectedNavItemProvider);
    
    return Scaffold(
      body: Row(
        children: [
          // 导航栏 (APP-NAV-BAR-001)
          const NavBar(),

          // 主内容区域 (APP-CNT-ARE-001)
          Expanded(
            child: Container(
              color: AppTheme.neutral100,
              child: Column(
                children: [
                  // 工具栏 (APP-TLB-MAN-001)
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                    ),
                    child: Row(
                      children: [
                        ToolbarButton(
                          icon: Icons.menu,
                          tooltip: '菜单',
                          onPressed: () {},
                        ),
                        const SizedBox(width: 4),
                        ToolbarButton(
                          icon: Icons.add,
                          tooltip: '新建',
                          onPressed: () {},
                        ),
                        const SizedBox(width: 4),
                        ToolbarButton(
                          icon: Icons.chat,
                          tooltip: '聊天',
                          onPressed: () {
                            ref.read(selectedNavItemProvider.notifier).state = 'ai';
                          },
                          isActive: selectedNavItem == 'ai',
                        ),
                        const SizedBox(width: 4),
                        ToolbarButton(
                          icon: Icons.code,
                          tooltip: '编辑器',
                          onPressed: () {
                            ref.read(selectedNavItemProvider.notifier).state = 'editor';
                          },
                          isActive: selectedNavItem == 'editor',
                        ),
                        const SizedBox(width: 4),
                        ToolbarButton(
                          icon: Icons.storage,
                          tooltip: '数据库',
                          onPressed: () {
                            ref.read(selectedNavItemProvider.notifier).state = 'database';
                          },
                          isActive: selectedNavItem == 'database',
                        ),
                        const SizedBox(width: 4),
                        ToolbarButton(
                          icon: Icons.settings,
                          tooltip: '设置',
                          onPressed: () {
                            ref.read(selectedNavItemProvider.notifier).state = 'settings';
                          },
                          isActive: selectedNavItem == 'settings',
                        ),
                      ],
                    ),
                  ),

                  // 内容区域
                  Expanded(
                    child: _buildContent(selectedNavItem),
                  ),
                ],
              ),
            ),
          ),

          // AI助手面板 (GLB-AST-MAN-001)
          const AiAssistantPanel(),
        ],
      ),
    );
  }
  
  /// 根据选中的导航项构建内容
  Widget _buildContent(String navItem) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _getContentWidget(navItem),
    );
  }

  /// 获取内容widget
  Widget _getContentWidget(String navItem) {
    switch (navItem) {
      case 'home':
        return const HomeScreen(key: ValueKey('home'));
      case 'projects':
        return const ProjectScreen(key: ValueKey('projects'));
      case 'analysis':
        return const AnalysisScreen(key: ValueKey('analysis'));
      case 'tools':
        return const ToolsScreen(key: ValueKey('tools'));
      case 'debug':
        return const DebugScreen(key: ValueKey('debug'));
      case 'ai':
        return const AiScreen(key: ValueKey('ai'));
      case 'extensions':
        return const ExtensionsScreen(key: ValueKey('extensions'));
      case 'learning':
        return const LearningScreen(key: ValueKey('learning'));
      case 'help':
        return const HelpScreen(key: ValueKey('help'));
      case 'settings':
        return const SettingsScreen(key: ValueKey('settings'));
      case 'editor':
        return const EditorScreen(key: ValueKey('editor'));
      case 'database':
        return const DatabaseScreen(key: ValueKey('database'));
      default:
        return Container(
          key: const ValueKey('default'),
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Center(
            child: Text(
              '选择了: $navItem',
              style: AppTheme.titleLarge,
            ),
          ),
        );
    }
  }
} 