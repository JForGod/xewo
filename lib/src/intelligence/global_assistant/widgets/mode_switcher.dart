import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/assistant_controller.dart';
import '../models/assistant_mode.dart';

/// AI助手模式切换器
class ModeSwitcher extends ConsumerWidget {
  const ModeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assistantProvider);
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getModeColor(state.mode, theme).withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: _getModeColor(state.mode, theme),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 模式标题
          Row(
            children: [
              Image.asset(
                state.mode.icon,
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              Text(
                state.mode.name,
                style: TextStyle(
                  color: _getModeColor(state.mode, theme),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: () => _showModeSwitchDialog(context, ref),
                tooltip: '切换模式',
              ),
            ],
          ),
          
          // 模式描述
          Text(
            state.mode.description,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
  
  /// 获取模式颜色
  Color _getModeColor(AssistantMode mode, ThemeData theme) {
    switch (mode) {
      case AssistantMode.standard:
        return theme.colorScheme.primary;
      case AssistantMode.professional:
        return theme.colorScheme.secondary;
      case AssistantMode.guardian:
        return theme.colorScheme.tertiary;
    }
  }
  
  /// 显示模式切换对话框
  void _showModeSwitchDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AssistantMode.values.map((mode) {
            return ListTile(
              leading: Image.asset(
                mode.icon,
                width: 24,
                height: 24,
              ),
              title: Text(mode.name),
              subtitle: Text(mode.description),
              onTap: () {
                ref.read(assistantProvider.notifier).setMode(mode);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }
} 