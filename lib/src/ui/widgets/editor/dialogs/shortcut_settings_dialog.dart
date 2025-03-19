import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../state/providers/shortcut_provider.dart';
import '../../../../state/models/shortcut_model.dart';

/// 快捷键设置对话框
class ShortcutSettingsDialog extends ConsumerStatefulWidget {
  const ShortcutSettingsDialog({super.key});

  @override
  ConsumerState<ShortcutSettingsDialog> createState() => _ShortcutSettingsDialogState();
}

class _ShortcutSettingsDialogState extends ConsumerState<ShortcutSettingsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedShortcutId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: ShortcutCategory.values.length, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final shortcutState = ref.watch(shortcutProvider);
    
    return AlertDialog(
      title: const Text('快捷键设置'),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: '搜索',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: ShortcutCategory.values.map((category) {
                return Tab(text: _getCategoryName(category));
              }).toList(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: ShortcutCategory.values.map((category) {
                  return _buildShortcutList(
                    shortcutState.shortcuts.where((s) {
                      if (_searchQuery.isEmpty) {
                        return s.category == category;
                      } else {
                        return s.category == category && 
                               (s.name.toLowerCase().contains(_searchQuery) || 
                                s.description.toLowerCase().contains(_searchQuery));
                      }
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(shortcutProvider.notifier).resetAllShortcuts();
          },
          child: const Text('重置所有'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
  
  Widget _buildShortcutList(List<ShortcutModel> shortcuts) {
    if (shortcuts.isEmpty) {
      return const Center(
        child: Text('没有找到快捷键'),
      );
    }
    
    return ListView.builder(
      itemCount: shortcuts.length,
      itemBuilder: (context, index) {
        final shortcut = shortcuts[index];
        return ListTile(
          title: Text(shortcut.name),
          subtitle: Text(shortcut.description),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedShortcutId = shortcut.id;
                  });
                  _showKeyRecordDialog(shortcut);
                },
                child: Text(
                  shortcut.customKeys ?? shortcut.defaultKeys,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: shortcut.customKeys != null ? Colors.blue : null,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: '重置为默认',
                onPressed: () {
                  ref.read(shortcutProvider.notifier).resetShortcut(shortcut.id);
                },
              ),
            ],
          ),
          selected: _selectedShortcutId == shortcut.id,
          onTap: () {
            setState(() {
              _selectedShortcutId = shortcut.id;
            });
          },
        );
      },
    );
  }
  
  void _showKeyRecordDialog(ShortcutModel shortcut) {
    showDialog(
      context: context,
      builder: (context) => KeyRecordDialog(
        shortcut: shortcut,
        onSave: (keys) {
          ref.read(shortcutProvider.notifier).updateShortcut(shortcut.id, keys);
          Navigator.pop(context);
        },
      ),
    );
  }
  
  String _getCategoryName(ShortcutCategory category) {
    switch (category) {
      case ShortcutCategory.file:
        return '文件';
      case ShortcutCategory.edit:
        return '编辑';
      case ShortcutCategory.view:
        return '视图';
      case ShortcutCategory.search:
        return '搜索';
      case ShortcutCategory.debug:
        return '调试';
      case ShortcutCategory.tool:
        return '工具';
      case ShortcutCategory.other:
        return '其他';
    }
  }

  String _getKeyboardEventDescription(KeyDownEvent event) {
    final List<String> modifiers = [];
    
    if (event.logicalKey == LogicalKeyboardKey.control || 
        event.logicalKey == LogicalKeyboardKey.controlLeft || 
        event.logicalKey == LogicalKeyboardKey.controlRight) {
      modifiers.add('Ctrl');
    }
    if (event.logicalKey == LogicalKeyboardKey.alt || 
        event.logicalKey == LogicalKeyboardKey.altLeft || 
        event.logicalKey == LogicalKeyboardKey.altRight) {
      modifiers.add('Alt');
    }
    if (event.logicalKey == LogicalKeyboardKey.shift || 
        event.logicalKey == LogicalKeyboardKey.shiftLeft || 
        event.logicalKey == LogicalKeyboardKey.shiftRight) {
      modifiers.add('Shift');
    }
    if (event.logicalKey == LogicalKeyboardKey.meta || 
        event.logicalKey == LogicalKeyboardKey.metaLeft || 
        event.logicalKey == LogicalKeyboardKey.metaRight) {
      modifiers.add('Meta');
    }
    
    // 获取按键名称
    final keyLabel = event.logicalKey.keyLabel.toLowerCase();
    if (!['control', 'alt', 'shift', 'meta', 'command', 'windows'].contains(keyLabel)) {
      modifiers.add(keyLabel);
    }
    
    return modifiers.join('+');
  }
}

/// 按键记录对话框
class KeyRecordDialog extends StatefulWidget {
  final ShortcutModel shortcut;
  final Function(String) onSave;
  
  const KeyRecordDialog({
    super.key,
    required this.shortcut,
    required this.onSave,
  });
  
  @override
  State<KeyRecordDialog> createState() => _KeyRecordDialogState();
}

class _KeyRecordDialogState extends State<KeyRecordDialog> {
  bool _ctrl = false;
  bool _alt = false;
  bool _shift = false;
  bool _meta = false;
  String _key = '';
  
  @override
  void initState() {
    super.initState();
    _parseShortcut(widget.shortcut.customKeys ?? widget.shortcut.defaultKeys);
  }
  
  void _parseShortcut(String shortcut) {
    final parts = shortcut.toLowerCase().split('+');
    
    setState(() {
      _ctrl = parts.contains('ctrl');
      _alt = parts.contains('alt');
      _shift = parts.contains('shift');
      _meta = parts.contains('meta') || parts.contains('cmd') || parts.contains('win');
      
      // 获取最后一个部分作为键
      for (final part in parts) {
        if (!['ctrl', 'alt', 'shift', 'meta', 'cmd', 'win'].contains(part)) {
          _key = part;
          break;
        }
      }
    });
  }
  
  String _buildShortcutString() {
    final parts = <String>[];
    
    if (_ctrl) parts.add('ctrl');
    if (_alt) parts.add('alt');
    if (_shift) parts.add('shift');
    if (_meta) parts.add('meta');
    
    if (_key.isNotEmpty) {
      parts.add(_key);
    }
    
    return parts.join('+');
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('设置快捷键: ${widget.shortcut.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('当前快捷键: ${_buildShortcutString()}'),
          const SizedBox(height: 16),
          const Text('按下新的快捷键组合'),
          const SizedBox(height: 16),
          Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                setState(() {
                  _ctrl = event.logicalKey == LogicalKeyboardKey.control || 
                          event.logicalKey == LogicalKeyboardKey.controlLeft || 
                          event.logicalKey == LogicalKeyboardKey.controlRight;
                  _alt = event.logicalKey == LogicalKeyboardKey.alt || 
                         event.logicalKey == LogicalKeyboardKey.altLeft || 
                         event.logicalKey == LogicalKeyboardKey.altRight;
                  _shift = event.logicalKey == LogicalKeyboardKey.shift || 
                           event.logicalKey == LogicalKeyboardKey.shiftLeft || 
                           event.logicalKey == LogicalKeyboardKey.shiftRight;
                  _meta = event.logicalKey == LogicalKeyboardKey.meta || 
                          event.logicalKey == LogicalKeyboardKey.metaLeft || 
                          event.logicalKey == LogicalKeyboardKey.metaRight;
                  
                  // 获取按键名称
                  final keyLabel = event.logicalKey.keyLabel.toLowerCase();
                  if (!['control', 'alt', 'shift', 'meta', 'command', 'windows'].contains(keyLabel)) {
                    _key = keyLabel;
                  }
                });
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Container(
              width: 300,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '按下键盘快捷键',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            widget.onSave(_buildShortcutString());
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
} 