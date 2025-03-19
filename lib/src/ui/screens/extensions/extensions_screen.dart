import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

/// 扩展项
class ExtensionItem {
  final String id;
  final String name;
  final String description;
  final String author;
  final String version;
  final bool isInstalled;
  
  const ExtensionItem({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.version,
    this.isInstalled = false,
  });
}

/// 扩展屏幕
class ExtensionsScreen extends StatelessWidget {
  const ExtensionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '扩展市场',
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