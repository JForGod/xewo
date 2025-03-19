import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../themes/app_theme.dart';
import '../../../../state/providers/navigation_provider.dart';

/// 2025-03-15: 新增 - AI助手页面底部导航按钮组件
class NavigationButtons extends ConsumerWidget {
  final List<NavigationButtonItem> items;
  final bool showLabels;
  final double spacing;
  final double buttonSize;
  final double iconSize;
  final double borderRadius;
  final EdgeInsets padding;

  const NavigationButtons({
    Key? key,
    required this.items,
    this.showLabels = true,
    this.spacing = 8.0,
    this.buttonSize = 48.0,
    this.iconSize = 20.0,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentNavItem = ref.watch(selectedNavItemProvider);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AIAssistantTheme.glassShadow(),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: spacing,
        runSpacing: spacing,
        children: items.map((item) {
          final isSelected = currentNavItem == item.route;
          
          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                ref.read(selectedNavItemProvider.notifier).state = item.route;
                
                // 2025-03-15: 修改 - 添加实际导航功能
                _navigateToRoute(context, item.route);
                
                if (item.onTap != null) {
                  item.onTap!();
                }
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AIAssistantTheme.getPrimaryColorByMode(item.mode).withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: AIAssistantTheme.getPrimaryColorByMode(item.mode).withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: -2,
                      )
                    ] : null,
                    border: Border.all(
                      color: isSelected 
                          ? AIAssistantTheme.getPrimaryColorByMode(item.mode).withOpacity(0.5)
                          : Colors.white.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      item.icon,
                      size: iconSize,
                      color: isSelected 
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
                if (showLabels && item.label != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      item.label!,
                      style: TextStyle(
                        color: isSelected 
                            ? Colors.white
                            : Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  // 2025-03-15: 新增 - 导航到指定路由
  void _navigateToRoute(BuildContext context, String route) {
    // 关闭AI助手面板
    Navigator.of(context).pop();
    
    // 导航到指定页面
    switch (route) {
      case 'home':
        Navigator.of(context).pushReplacementNamed('/');
        break;
      case 'coding':
        Navigator.of(context).pushReplacementNamed('/coding');
        break;
      case 'settings':
        Navigator.of(context).pushReplacementNamed('/settings');
        break;
      case 'tools':
        Navigator.of(context).pushReplacementNamed('/tools');
        break;
      case 'projects':
        Navigator.of(context).pushReplacementNamed('/projects');
        break;
      case 'learning':
        Navigator.of(context).pushReplacementNamed('/learning');
        break;
      default:
        // 对于自定义路由，尝试直接导航
        Navigator.of(context).pushReplacementNamed('/$route');
        break;
    }
  }
}

/// 导航按钮项
class NavigationButtonItem {
  final IconData icon;
  final String? label;
  final String route;
  final VoidCallback? onTap;
  final dynamic mode;

  const NavigationButtonItem({
    required this.icon,
    this.label,
    required this.route,
    this.onTap,
    this.mode,
  });
}

/// 2025-03-15: 新增 - 自定义导航按钮设置提供者
final customNavigationButtonsProvider = StateProvider<List<NavigationButtonItem>>((ref) {
  // 默认导航按钮
  return [
    const NavigationButtonItem(
      icon: Icons.home,
      label: '主页',
      route: 'home',
      mode: null,
    ),
    const NavigationButtonItem(
      icon: Icons.code,
      label: '智能编程',
      route: 'coding',
      mode: null,
    ),
    const NavigationButtonItem(
      icon: Icons.settings,
      label: '设置',
      route: 'settings',
      mode: null,
    ),
  ];
}); 