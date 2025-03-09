import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_theme.dart';

/// 帮助文档屏幕
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('帮助文档'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'xEwo IDE 帮助文档',
              style: AppTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              '欢迎使用xEwo IDE，您的智能编码伙伴',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.neutral600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Expanded(
              child: ListView(
                children: [
                  _buildHelpSection(
                    title: '开始使用',
                    items: [
                      '创建新项目',
                      '打开现有项目',
                      '导入项目',
                      '设置工作区',
                    ],
                  ),
                  _buildHelpSection(
                    title: '编辑器功能',
                    items: [
                      '代码编辑',
                      '智能补全',
                      '代码格式化',
                      '查找替换',
                    ],
                  ),
                  _buildHelpSection(
                    title: 'AI助手',
                    items: [
                      '使用AI助手',
                      '代码生成',
                      '代码解释',
                      '问题解答',
                    ],
                  ),
                  _buildHelpSection(
                    title: '数据库工具',
                    items: [
                      '连接数据库',
                      '执行SQL查询',
                      '查看数据库结构',
                      'SQL优化建议',
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHelpSection({
    required String title,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
          child: Text(
            title,
            style: AppTheme.titleLarge,
          ),
        ),
        ...items.map((item) => _buildHelpItem(item)),
        const Divider(height: AppTheme.spacingLg),
      ],
    );
  }
  
  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.spacingSm,
        horizontal: AppTheme.spacingMd,
      ),
      child: Row(
        children: [
          const Icon(Icons.arrow_right, color: AppTheme.primary),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            text,
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
} 