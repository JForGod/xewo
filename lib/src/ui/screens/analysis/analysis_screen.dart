import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

/// 分析屏幕
class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '代码分析',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              '正在开发中...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 