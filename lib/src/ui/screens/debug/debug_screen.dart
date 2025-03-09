import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_theme.dart';

/// 调试屏幕
class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('调试控制台'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bug_report,
              size: 64,
              color: AppTheme.primary,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              '调试控制台',
              style: AppTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              '调试您的应用程序',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.neutral600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始调试'),
              onPressed: () {
                // TODO: 开始调试
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('调试功能开发中')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 