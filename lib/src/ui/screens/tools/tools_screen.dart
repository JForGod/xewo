import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_theme.dart';

/// 工具项
class ToolItem {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  
  const ToolItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// 工具屏幕
class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tools = [
      const ToolItem(
        id: 'formatter',
        name: '代码格式化',
        description: '格式化您的代码以提高可读性',
        icon: Icons.format_align_left,
        color: Colors.blue,
      ),
      const ToolItem(
        id: 'database',
        name: '数据库工具',
        description: '管理和查询数据库',
        icon: Icons.storage,
        color: Colors.green,
      ),
      const ToolItem(
        id: 'git',
        name: 'Git工具',
        description: '管理您的Git仓库',
        icon: Icons.merge_type,
        color: Colors.orange,
      ),
      const ToolItem(
        id: 'terminal',
        name: '终端',
        description: '运行命令行工具',
        icon: Icons.terminal,
        color: Colors.purple,
      ),
      const ToolItem(
        id: 'snippets',
        name: '代码片段',
        description: '管理和使用代码片段',
        icon: Icons.code,
        color: Colors.teal,
      ),
      const ToolItem(
        id: 'diff',
        name: '文件比较',
        description: '比较文件差异',
        icon: Icons.compare_arrows,
        color: Colors.red,
      ),
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('工具箱'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.5,
          crossAxisSpacing: AppTheme.spacingLg,
          mainAxisSpacing: AppTheme.spacingLg,
        ),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];
          return _buildToolCard(context, tool);
        },
      ),
    );
  }
  
  Widget _buildToolCard(BuildContext context, ToolItem tool) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // TODO: 打开工具
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${tool.name}功能开发中')),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: tool.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      tool.icon,
                      color: tool.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Flexible(
                    child: Text(
                      tool.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                tool.description,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.neutral600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 