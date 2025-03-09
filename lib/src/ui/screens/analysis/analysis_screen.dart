import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_theme.dart';

/// 分析屏幕
class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('代码分析'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.analytics,
              size: 64,
              color: AppTheme.primary,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              '代码分析',
              style: AppTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              '分析您的代码以提高质量',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.neutral600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始分析'),
              onPressed: () {
                // TODO: 开始分析
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('代码分析功能开发中')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 