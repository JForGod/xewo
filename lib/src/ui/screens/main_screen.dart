import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../themes/app_theme.dart';
import '../widgets/navigation/nav_bar.dart';
import '../widgets/common/toolbar_button.dart';
import '../../state/providers/navigation_provider.dart';
import 'home/home_screen.dart';
import 'project/project_screen.dart';
import 'coding/coding_screen.dart';
import '../widgets/common/navigation_rail.dart';
import '../widgets/editor/editor_toolbar.dart';
import '../widgets/editor/code_editor.dart';
import '../../services/app_config.dart';
import '../../state/providers/editor_state.dart';
import '../../features/ai_assistant/presentation/pages/ai_assistant_entry.dart';
import 'learning/learning_screen.dart';
import 'settings/settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  // 添加状态变量
  final List<String> openFiles = [];
  int _activeFileIndex = -1;
  
  // 添加文件操作方法
  void _switchToFile(int index) {
    setState(() {
      _activeFileIndex = index;
    });
  }

  void _closeFile(int index) {
    setState(() {
      openFiles.removeAt(index);
      if (_activeFileIndex >= openFiles.length) {
        _activeFileIndex = openFiles.length - 1;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('MainScreen initialized');
    }
    _restoreAppState();
  }

  Future<void> _restoreAppState() async {
    final config = ref.read(appConfigProvider);
    // TODO: 恢复上次的状态
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('MainScreen disposed');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('Building MainScreen');
    }

    try {
      final selectedNavItem = ref.watch(selectedNavItemProvider);
      
      return Scaffold(
        body: Column(
          children: [
            // 主菜单栏 - 暂时简化以确保可以启动
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, size: 16),
                    onPressed: () {
                      // 切换导航栏显示
                      ref.read(navigationRailVisibilityProvider.notifier).state = 
                        !ref.read(navigationRailVisibilityProvider);
                    },
                  ),
                  // 暂时移除 EditorTabs，等程序能启动后再添加
                  const Spacer(),
                ],
              ),
            ),
            
            // 主体内容区域
            Expanded(
              child: Row(
                children: [
                  // 导航栏
                  if (ref.watch(navigationRailVisibilityProvider))
                    const NavigationRailWidget(),
                  
                  // 编辑器区域
                  Expanded(
                    child: _buildContent(selectedNavItem),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in MainScreen build: $e\n$stackTrace');
      }
      return const Scaffold(
        body: Center(
          child: Text('发生错误，请重试'),
        ),
      );
    }
  }

  Widget _buildContent(String navItem) {
    if (kDebugMode) {
      print('Building content for: $navItem');
    }

    try {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _getContentWidget(navItem),
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in _buildContent: $e\n$stackTrace');
      }
      return Center(
        key: ValueKey('error-$navItem'),
        child: Text(
          '加载页面失败: $navItem',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }
  }

  Widget _getContentWidget(String navItem) {
    if (kDebugMode) {
      print('Getting content widget for: $navItem');
    }

    try {
      switch (navItem) {
        case 'home':
          return const HomeScreen(key: ValueKey('home'));
        case 'projects':
          return const ProjectScreen(key: ValueKey('projects'));
        case 'editor':
          return const CodingScreen(key: ValueKey('editor'));
        case 'ai':
          return const AIAssistantEntry(key: ValueKey('ai'));
        case 'learning':
          return const LearningScreen(key: ValueKey('learning'));
        case 'database':
          // 临时返回占位页面
          return _buildPlaceholderScreen('数据库', navItem);
        case 'settings':
          // 2025-03-17: 修改-将设置导航项指向实际的设置屏幕而非占位符
          return const SettingsScreen(key: ValueKey('settings'));
        default:
          return _buildPlaceholderScreen('未知页面', navItem);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in _getContentWidget: $e\n$stackTrace');
      }
      return Center(
        key: ValueKey('error-$navItem'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '页面加载错误: $navItem',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {});
              },
              child: const Text('点击重试'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPlaceholderScreen(String title, String navItem) {
    return Center(
      key: ValueKey('placeholder-$navItem'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '$title - 开发中',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '该功能正在开发中，敬请期待',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _handleFormat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('格式化功能开发中')),
    );
  }

  void _handleFindReplace() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('查找替换功能开发中')),
    );
  }

  void _handleSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设置功能开发中')),
    );
  }

  void _handleToggleLineNumbers() {
    ref.read(editorStateProvider.notifier).toggleLineNumbers();
  }

  void _handleToggleMinimap() {
    ref.read(editorStateProvider.notifier).toggleMinimap();
  }
} 