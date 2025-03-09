import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';
import '../common/logo_placeholder.dart';
import 'nav_item.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppTheme.navBarWidth,
      color: AppTheme.neutral50,
      child: Column(
        children: [
          // Logo区域 (APP-NAV-LOG-001)
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                const LogoPlaceholder(size: 24, color: Colors.blue),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'xEwo IDE',
                  style: AppTheme.titleLarge,
                ),
              ],
            ),
          ),
          
          // 导航项列表
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.spacingXs,
              ),
              children: const [
                NavItem(
                  icon: Icons.home,
                  label: '主页',
                  id: 'home',
                ),
                NavItem(
                  icon: Icons.folder,
                  label: '项目管理',
                  id: 'projects',
                ),
                NavItem(
                  icon: Icons.analytics,
                  label: '代码分析',
                  id: 'analysis',
                ),
                NavItem(
                  icon: Icons.build,
                  label: '工具箱',
                  id: 'tools',
                ),
                NavItem(
                  icon: Icons.bug_report,
                  label: '调试控制台',
                  id: 'debug',
                ),
                NavItem(
                  icon: Icons.smart_toy,
                  label: 'AI助手',
                  id: 'ai',
                ),
                NavItem(
                  icon: Icons.extension,
                  label: '扩展市场',
                  id: 'extensions',
                ),
                NavItem(
                  icon: Icons.school,
                  label: '学习系统',
                  id: 'learning',
                ),
                NavItem(
                  icon: Icons.help,
                  label: '帮助文档',
                  id: 'help',
                ),
                NavItem(
                  icon: Icons.settings,
                  label: '设置',
                  id: 'settings',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 