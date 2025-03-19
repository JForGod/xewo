import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_theme.dart';
import '../../../state/providers/navigation_provider.dart';

class NavBar extends ConsumerWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedNavItem = ref.watch(selectedNavItemProvider);

    return Container(
      width: AppTheme.navBarWidth,
      color: AppTheme.neutral50,
      child: Column(
        children: [
          // Logo区域 (APP-NAV-LOG-001)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.neutral50,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.neutral600.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'xEwo IDE',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeBase,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutral800,
                  ),
                ),
              ],
            ),
          ),

          // 导航项目列表
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.spacingXs,
                horizontal: AppTheme.spacingMd,
              ),
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.home,
                  label: '主页',
                  isSelected: selectedNavItem == 'home',
                  onTap: () => ref.read(selectedNavItemProvider.notifier).state = 'home',
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.folder,
                  label: '项目管理',
                  isSelected: selectedNavItem == 'projects',
                  onTap: () => ref.read(selectedNavItemProvider.notifier).state = 'projects',
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.analytics,
                  label: '代码分析',
                  isSelected: selectedNavItem == 'analysis',
                  onTap: () => ref.read(selectedNavItemProvider.notifier).state = 'analysis',
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.build,
                  label: '工具箱',
                  isSelected: selectedNavItem == 'tools',
                  onTap: () => ref.read(selectedNavItemProvider.notifier).state = 'tools',
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.bug_report,
                  label: '调试控制台',
                  isSelected: selectedNavItem == 'debug',
                  onTap: () => ref.read(selectedNavItemProvider.notifier).state = 'debug',
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.chat,
                  label: 'AI助手',
                  isSelected: selectedNavItem == 'ai',
                  onTap: () => ref.read(selectedNavItemProvider.notifier).state = 'ai',
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.extension,
                  label: '扩展市场',
                  isSelected: selectedNavItem == 'extensions',
                  onTap: () => ref.read(selectedNavItemProvider.notifier).state = 'extensions',
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.school,
                  label: '学习系统',
                  isSelected: selectedNavItem == 'learn',
                  onTap: () => ref.read(selectedNavItemProvider.notifier).state = 'learn',
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.help,
                  label: '帮助文档',
                  isSelected: selectedNavItem == 'help',
                  onTap: () => ref.read(selectedNavItemProvider.notifier).state = 'help',
                ),
              ],
            ),
          ),

          // 底部设置按钮
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTheme.neutral600.withOpacity(0.1),
                ),
              ),
            ),
            child: _buildNavItem(
              context: context,
              icon: Icons.settings,
              label: '设置',
              isSelected: selectedNavItem == 'settings',
              onTap: () => ref.read(selectedNavItemProvider.notifier).state = 'settings',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          height: AppTheme.navItemHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingXs,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary100 : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppTheme.primary700 : AppTheme.neutral600,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSm,
                  color: isSelected ? AppTheme.primary700 : AppTheme.neutral600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 