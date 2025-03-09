import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_theme.dart';

/// 项目屏幕
class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('项目管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: 创建新项目
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('创建新项目功能开发中')),
              );
            },
            tooltip: '创建新项目',
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () {
              // TODO: 打开项目
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('打开项目功能开发中')),
              );
            },
            tooltip: '打开项目',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.folder,
              size: 64,
              color: AppTheme.primary,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              '项目管理',
              style: AppTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              '创建或打开项目以开始编码',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.neutral600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('创建新项目'),
              onPressed: () {
                // TODO: 创建新项目
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('创建新项目功能开发中')),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),
            OutlinedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('打开项目'),
              onPressed: () {
                // TODO: 打开项目
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('打开项目功能开发中')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 