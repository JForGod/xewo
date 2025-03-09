import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/core/shortcut_stats_service.dart';
import '../../../state/providers/shortcut_provider.dart';
import 'package:intl/intl.dart';

class ShortcutStatsScreen extends ConsumerWidget {
  const ShortcutStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsService = ref.watch(shortcutStatsProvider);
    final shortcuts = ref.watch(shortcutProvider).shortcuts;
    final mostUsed = statsService.getMostUsedShortcuts();
    final recentlyUsed = statsService.getRecentlyUsedShortcuts();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('快捷键使用统计'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // TODO: 刷新统计数据
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _showClearStatsDialog(context, ref);
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '使用最多'),
              Tab(text: '最近使用'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMostUsedList(mostUsed, shortcuts),
            _buildRecentlyUsedList(recentlyUsed, shortcuts, dateFormat),
          ],
        ),
      ),
    );
  }

  Widget _buildMostUsedList(
    List<ShortcutStats> stats,
    Map<String, ShortcutConfig> shortcuts,
  ) {
    return ListView.builder(
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        final shortcut = shortcuts[stat.id];
        if (shortcut == null) return const SizedBox();

        return ListTile(
          title: Text(shortcut.name),
          subtitle: Text(shortcut.description),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '使用次数: ${stat.useCount}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatShortcut(shortcut.activator),
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentlyUsedList(
    List<ShortcutStats> stats,
    Map<String, ShortcutConfig> shortcuts,
    DateFormat dateFormat,
  ) {
    return ListView.builder(
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        final shortcut = shortcuts[stat.id];
        if (shortcut == null) return const SizedBox();

        return ListTile(
          title: Text(shortcut.name),
          subtitle: Text(shortcut.description),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateFormat.format(stat.lastUsed),
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
              Text(
                _formatShortcut(shortcut.activator),
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatShortcut(SingleActivator activator) {
    final parts = <String>[];
    if (activator.control) parts.add('Ctrl');
    if (activator.alt) parts.add('Alt');
    if (activator.shift) parts.add('Shift');
    if (activator.meta) parts.add('Meta');
    parts.add(activator.trigger.keyLabel.toUpperCase());
    return parts.join(' + ');
  }

  Future<void> _showClearStatsDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除统计数据'),
        content: const Text('确定要清除所有统计数据吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref.read(shortcutStatsProvider).clearStats();
    }
  }
} 