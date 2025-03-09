import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/providers/shortcut_provider.dart';

class ShortcutEditorScreen extends ConsumerWidget {
  const ShortcutEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortcutState = ref.watch(shortcutProvider);
    final shortcuts = shortcutState.filteredShortcuts;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('快捷键设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ShortcutSearchDelegate(ref),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () {
              ref.read(shortcutProvider.notifier).resetShortcuts();
            },
          ),
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: () {
              _showImportExportDialog(context, ref);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: shortcuts.length,
        itemBuilder: (context, index) {
          final shortcut = shortcuts[index];
          return ListTile(
            title: Text(shortcut.name),
            subtitle: Text(shortcut.description),
            trailing: _buildShortcutButton(
              context,
              shortcut.id,
              shortcut.activator,
              ref,
            ),
          );
        },
      ),
    );
  }

  Widget _buildShortcutButton(
    BuildContext context,
    String id,
    SingleActivator activator,
    WidgetRef ref,
  ) {
    return TextButton(
      onPressed: () {
        _showShortcutDialog(context, id, activator, ref);
      },
      child: Text(_formatShortcut(activator)),
    );
  }

  String _formatShortcut(SingleActivator activator) {
    final parts = <String>[];
    if (activator.control) parts.add('Ctrl');
    if (activator.alt) parts.add('Alt');
    if (activator.shift) parts.add('Shift');
    if (activator.meta) parts.add('Meta');
    parts.add(_getKeyLabel(activator.trigger));
    return parts.join(' + ');
  }

  String _getKeyLabel(LogicalKeyboardKey key) {
    // 特殊按键映射
    const specialKeys = {
      LogicalKeyboardKey.enter: 'Enter',
      LogicalKeyboardKey.tab: 'Tab',
      LogicalKeyboardKey.space: 'Space',
      LogicalKeyboardKey.escape: 'Esc',
      LogicalKeyboardKey.backspace: 'Backspace',
      LogicalKeyboardKey.delete: 'Delete',
      LogicalKeyboardKey.home: 'Home',
      LogicalKeyboardKey.end: 'End',
      LogicalKeyboardKey.pageUp: 'Page Up',
      LogicalKeyboardKey.pageDown: 'Page Down',
      LogicalKeyboardKey.arrowLeft: '←',
      LogicalKeyboardKey.arrowRight: '→',
      LogicalKeyboardKey.arrowUp: '↑',
      LogicalKeyboardKey.arrowDown: '↓',
    };

    return specialKeys[key] ?? key.keyLabel.toUpperCase();
  }

  Future<void> _showShortcutDialog(
    BuildContext context,
    String id,
    SingleActivator currentActivator,
    WidgetRef ref,
  ) async {
    SingleActivator? newActivator = await showDialog<SingleActivator>(
      context: context,
      builder: (context) => ShortcutRecorderDialog(
        currentActivator: currentActivator,
      ),
    );

    if (newActivator != null) {
      await ref.read(shortcutProvider.notifier).updateShortcut(id, newActivator);
    }
  }

  Future<void> _showImportExportDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ImportExportDialog(),
    );

    if (result == true) {
      // 导出
      final data = ref.read(shortcutProvider.notifier).exportShortcuts();
      // TODO: 保存到文件或剪贴板
    } else if (result == false) {
      // 导入
      // TODO: 从文件或剪贴板读取
      const data = '';
      await ref.read(shortcutProvider.notifier).importShortcuts(data);
    }
  }
}

class ShortcutSearchDelegate extends SearchDelegate<void> {
  final WidgetRef ref;

  ShortcutSearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    ref.read(shortcutProvider.notifier).searchShortcuts(query);
    return const ShortcutList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    ref.read(shortcutProvider.notifier).searchShortcuts(query);
    return const ShortcutList();
  }
}

class ShortcutList extends ConsumerWidget {
  const ShortcutList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortcuts = ref.watch(shortcutProvider).filteredShortcuts;
    return ListView.builder(
      itemCount: shortcuts.length,
      itemBuilder: (context, index) {
        final shortcut = shortcuts[index];
        return ListTile(
          title: Text(shortcut.name),
          subtitle: Text(shortcut.description),
          trailing: Text(_formatShortcut(shortcut.activator)),
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
}

class ShortcutRecorderDialog extends StatefulWidget {
  final SingleActivator currentActivator;

  const ShortcutRecorderDialog({
    super.key,
    required this.currentActivator,
  });

  @override
  State<ShortcutRecorderDialog> createState() => _ShortcutRecorderDialogState();
}

class _ShortcutRecorderDialogState extends State<ShortcutRecorderDialog> {
  late SingleActivator _activator;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _activator = widget.currentActivator;
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKey: _isRecording ? _handleKeyEvent : null,
      child: AlertDialog(
        title: const Text('设置快捷键'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_isRecording ? '请按下快捷键组合...' : '点击开始录制'),
            const SizedBox(height: 16),
            Text(
              _formatShortcut(_activator),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: _isRecording
                ? null
                : () {
                    setState(() {
                      _isRecording = true;
                    });
                  },
            child: const Text('开始录制'),
          ),
          TextButton(
            onPressed: _isRecording
                ? null
                : () {
                    Navigator.of(context).pop(_activator);
                  },
            child: const Text('确定'),
          ),
        ],
      ),
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

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      setState(() {
        _activator = SingleActivator(
          event.logicalKey,
          control: event.isControlPressed,
          shift: event.isShiftPressed,
          alt: event.isAltPressed,
          meta: event.isMetaPressed,
        );
        _isRecording = false;
      });
    }
  }
}

class ImportExportDialog extends StatelessWidget {
  const ImportExportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导入/导出快捷键配置'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('导出配置'),
            onTap: () {
              Navigator.of(context).pop(true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导入配置'),
            onTap: () {
              Navigator.of(context).pop(false);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
      ],
    );
  }
} 