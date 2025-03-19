import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 项目屏幕
class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('ProjectScreen initialized');
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('ProjectScreen disposed');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('Building ProjectScreen');
    }

    try {
      final theme = Theme.of(context);

      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '项目管理',
                  style: theme.textTheme.headlineLarge,
                ),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        // TODO: 实现新建项目功能
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('新建项目功能开发中')),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('新建项目'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        // TODO: 实现筛选功能
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('筛选功能开发中')),
                        );
                      },
                      icon: const Icon(Icons.filter_list),
                      tooltip: '筛选',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 项目列表
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 根据可用宽度动态计算列数
                  final crossAxisCount = (constraints.maxWidth / 400).floor().clamp(1, 3);
                  
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: _mockProjects.length,
                    itemBuilder: (context, index) {
                      final project = _mockProjects[index];
                      return _ProjectCard(
                        key: ValueKey(project.path),
                        project: project,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in ProjectScreen build: $e\n$stackTrace');
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              '加载项目列表失败',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // 强制重建组件
                setState(() {});
              },
              child: const Text('点击重试'),
            ),
          ],
        ),
      );
    }
  }
}

class _Project {
  final String name;
  final String description;
  final String path;
  final DateTime lastModified;
  final double progress;
  final String language;

  const _Project({
    required this.name,
    required this.description,
    required this.path,
    required this.lastModified,
    required this.progress,
    required this.language,
  });
}

// 模拟数据
final _mockProjects = [
  _Project(
    name: 'Flutter App',
    description: '一个使用Flutter开发的跨平台应用',
    path: '/projects/flutter_app',
    lastModified: DateTime.now().subtract(const Duration(days: 1)),
    progress: 0.75,
    language: 'Dart',
  ),
  _Project(
    name: 'Python Backend',
    description: 'Python FastAPI后端服务',
    path: '/projects/python_backend',
    lastModified: DateTime.now().subtract(const Duration(days: 3)),
    progress: 0.45,
    language: 'Python',
  ),
  _Project(
    name: 'React Website',
    description: '使用React开发的公司官网',
    path: '/projects/react_website',
    lastModified: DateTime.now().subtract(const Duration(days: 5)),
    progress: 0.90,
    language: 'TypeScript',
  ),
];

class _ProjectCard extends StatelessWidget {
  final _Project project;

  const _ProjectCard({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: () {
          // TODO: 打开项目
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('打开项目: ${project.name}')),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 项目名称和语言
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: theme.textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      project.language,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 项目描述
              Text(
                project.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // 进度条
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '完成进度',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        '${(project.progress * 100).toInt()}%',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: project.progress,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 最后修改时间
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '最后修改: ${_formatDate(project.lastModified)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}天前';
    } else {
      return '${date.year}-${date.month}-${date.day}';
    }
  }
} 