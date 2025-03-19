import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/providers/navigation_provider.dart';

final navigationRailVisibilityProvider = StateProvider<bool>((ref) => false);

class NavigationRailWidget extends ConsumerWidget {
  const NavigationRailWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedItem = ref.watch(selectedNavItemProvider);
    
    int selectedIndex = _getIndexFromNavItem(selectedItem);
    
    return Container(
      width: 120, // 设置固定宽度为120像素
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          final navItem = _getNavItemFromIndex(index);
          ref.read(selectedNavItemProvider.notifier).state = navItem;
        },
        labelType: NavigationRailLabelType.all, // 显示所有标签
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: Text('主页'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: Text('项目管理'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.code_outlined),
            selectedIcon: Icon(Icons.code),
            label: Text('代码分析'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: Text('工具箱'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.terminal_outlined),
            selectedIcon: Icon(Icons.terminal),
            label: Text('调试控制台'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: Text('AI助手'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.extension_outlined),
            selectedIcon: Icon(Icons.extension),
            label: Text('扩展市场'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: Text('学习系统'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help),
            label: Text('帮助文档'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: Text('设置'),
          ),
        ],
      ),
    );
  }
  
  int _getIndexFromNavItem(String navItem) {
    switch (navItem) {
      case 'home': return 0;
      case 'projects': return 1;
      case 'editor': return 2;
      case 'tools': return 3;
      case 'debug': return 4;
      case 'ai': return 5;
      case 'extensions': return 6;
      case 'learning': return 7;
      case 'help': return 8;
      case 'settings': return 9;
      default: return 0;
    }
  }
  
  String _getNavItemFromIndex(int index) {
    switch (index) {
      case 0: return 'home';
      case 1: return 'projects';
      case 2: return 'editor';
      case 3: return 'tools';
      case 4: return 'debug';
      case 5: return 'ai';
      case 6: return 'extensions';
      case 7: return 'learning';
      case 8: return 'help';
      case 9: return 'settings';
      default: return 'home';
    }
  }
} 