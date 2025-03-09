import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_theme.dart';

/// 学习系统屏幕
class LearningScreen extends ConsumerWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学习系统'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.school,
                size: 64,
                color: AppTheme.primary,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                '学习系统',
                style: AppTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                '学习系统功能正在开发中...',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.neutral600,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('学习系统功能开发中')),
                  );
                },
                child: const Text('开始学习'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 