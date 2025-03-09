import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../state/providers/shortcut_provider.dart';
import '../../../../state/models/shortcut_model.dart';

/// 快捷键设置对话框
class ShortcutSettingsDialog extends ConsumerWidget {
  const ShortcutSettingsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortcuts = ref.watch(shortcutProvider);
    final notifier = ref.read(shortcutProvider.notifier);
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('快捷键设置'),
      content: SizedBox(
        width: 500,
        height: 500,
        child: Column(
          children: [
            // 搜索框
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: '搜索快捷键',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  // 搜索功能
                },
              ),
            ),
            
            // 快捷键列表
            Expanded(
              child: ListView(
                children: [
                  _buildShortcutCategory(
                    context,
                    title: '文件操作',
                    shortcuts: [
                      _buildShortcutItem(
                        context,
                        label: '新建文件',
                        shortcut: 'Ctrl+N',
                        onPressed: () {
                          _showShortcutEditDialog(context, '新建文件', 'Ctrl+N');
                        },
                      ),
                      _buildShortcutItem(
                        context,
                        label: '打开文件',
                        shortcut: 'Ctrl+O',
                        onPressed: () {
                          _showShortcutEditDialog(context, '打开文件', 'Ctrl+O');
                        },
                      ),
                      _buildShortcutItem(
                        context,
                        label: '保存文件',
                        shortcut: 'Ctrl+S',
                        onPressed: () {
                          _showShortcutEditDialog(context, '保存文件', 'Ctrl+S');
                        },
                      ),
                      _buildShortcutItem(
                        context,
                        label: '另存为',
                        shortcut: 'Ctrl+Shift+S',
                        onPressed: () {
                          _showShortcutEditDialog(context, '另存为', 'Ctrl+Shift+S');
                        },
                      ),
                      _buildShortcutItem(
                        context,
                        label: '关闭文件',
                        shortcut: 'Ctrl+W',
                        onPressed: () {
                          _showShortcutEditDialog(context, '关闭文件', 'Ctrl+W');
                        },
                      ),
                    ],
                  ),
                  
                  _buildShortcutCategory(
                    context,
                    title: '编辑操作',
                    shortcuts: [
                      _buildShortcutItem(
                        context,
                        label: '撤销',
                        shortcut: 'Ctrl+Z',
                        onPressed: () {
                          _showShortcutEditDialog(context, '撤销', 'Ctrl+Z');
                        },
                      ),
                      _buildShortcutItem(
                        context,
                        label: '重做',
                        shortcut: 'Ctrl+Y',
                        onPressed: () {
                          _showShortcutEditDialog(context, '重做', 'Ctrl+Y');
                        },
                      ),
                      _buildShortcutItem(
                        context,
                        label: '剪切',
                        shortcut: 'Ctrl+X',
                        onPressed: () {
                          _showShortcutEditDialog(context, '剪切', 'Ctrl+X');
                        },
                      ),
                      _buildShortcutItem(
                        context,
                        label: '复制',
                        shortcut: 'Ctrl+C',
                        onPressed: () {
                          _showShortcutEditDialog(context, '复制', 'Ctrl+C');
                        },
                      ),
                      _buildShortcutItem(
                        context,
                        label: '粘贴',
                        shortcut: 'Ctrl+V',
                        onPressed: () {
                          _showShortcutEditDialog(context, '粘贴', 'Ctrl+V');
                        },
                      ),
                      _buildShortcutItem(
                        context,
                        label: '查找',
                        shortcut: 'Ctrl+F',
                        onPressed: () {
                          _showShortcutEditDialog(context, '查找', 'Ctrl+F');
                        },
                      ),
                      _buildShortcutItem(
                        context,
                        label: '替换',
                        shortcut: 'Ctrl+H',
                        onPressed: () {
                          _showShortcutEditDialog(context, '替换', 'Ctrl+H');
                        },
                      ),
                    ],
                  ),
                  
                  _buildShortcutCategory(
                    context,
                    title: '代码操作',
                    shortcuts: [
                      _buildShortcutItem(
                        context,
                        label: '格式化代码',
                        shortcut: 'Ctrl+Shift+F',
                        onPressed: () {
                          _showShortcutEditDialog(context, '格式化代码', 'Ctrl+Shift+F');
                        },
                      ),
                      _buildShortcutItem(
                        context,
                        label: '注释/取消注释',
                        shortcut: 'Ctrl+/',
                        onPressed: () {
                          _showShortcutEditDialog(context, '注释/取消注释', 'Ctrl+/');
                        },
                      ),
                      _buildShortcutItem(
                        context,
                        label: '缩进',
                        shortcut: 'Tab',
                        onPressed: () {
                          _showShortcutEditDialog(context, '缩进', 'Tab');
                        },
                      ),
                      _buildShortcutItem(
                        context,
                        label: '取消缩进',
                        shortcut: 'Shift+Tab',
                        onPressed: () {
                          _showShortcutEditDialog(context, '取消缩进', 'Shift+Tab');
                        },
                      ),
                    ],
                  ),
                  
                  _buildShortcutCategory(
                    context,
                    title: '视图操作',
                    shortcuts: [
                      _buildShortcutItem(
                        context,
                        label: '放大',
                        shortcut: 'Ctrl++',
                        onPressed: () {
                          _showShortcutEditDialog(context, '放大', 'Ctrl++');
                        },
                      ),
                      _buildShortcutItem(
                        context,
                        label: '缩小',
                        shortcut: 'Ctrl+-',
                        onPressed: () {
                          _showShortcutEditDialog(context, '缩小', 'Ctrl+-');
                        },
                      ),
                      _buildShortcutItem(
                        context,
                        label: '重置缩放',
                        shortcut: 'Ctrl+0',
                        onPressed: () {
                          _showShortcutEditDialog(context, '重置缩放', 'Ctrl+0');
                        },
                      ),
                      _buildShortcutItem(
                        context,
                        label: '切换全屏',
                        shortcut: 'F11',
                        onPressed: () {
                          _showShortcutEditDialog(context, '切换全屏', 'F11');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // 重置所有快捷键
            _showResetConfirmDialog(context);
          },
          child: const Text('重置所有快捷键'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
  
  // 构建快捷键分类
  Widget _buildShortcutCategory(
    BuildContext context, {
    required String title,
    required List<Widget> shortcuts,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const Divider(),
        ...shortcuts,
      ],
    );
  }
  
  // 构建快捷键项
  Widget _buildShortcutItem(
    BuildContext context, {
    required String label,
    required String shortcut,
    required VoidCallback onPressed,
  }) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 16),
            onPressed: onPressed,
            tooltip: '编辑快捷键',
          ),
        ],
      ),
      dense: true,
      onTap: onPressed,
    );
  }
  
  // 显示快捷键编辑对话框
  void _showShortcutEditDialog(BuildContext context, String action, String currentShortcut) {
    showDialog(
      context: context,
      builder: (context) => _ShortcutEditDialog(
        action: action,
        currentShortcut: currentShortcut,
        onSave: (newShortcut) {
          // 保存新的快捷键
          Navigator.pop(context);
        },
      ),
    );
  }
  
  // 显示重置确认对话框
  void _showResetConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置所有快捷键'),
        content: const Text('确定要将所有快捷键重置为默认值吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 重置所有快捷键
              Navigator.pop(context);
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }
}

/// 快捷键编辑对话框
class _ShortcutEditDialog extends StatefulWidget {
  final String action;
  final String currentShortcut;
  final Function(String) onSave;

  const _ShortcutEditDialog({
    Key? key,
    required this.action,
    required this.currentShortcut,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_ShortcutEditDialog> createState() => _ShortcutEditDialogState();
}

class _ShortcutEditDialogState extends State<_ShortcutEditDialog> {
  String _newShortcut = '';
  bool _isRecording = false;
  
  @override
  void initState() {
    super.initState();
    _newShortcut = widget.currentShortcut;
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('编辑快捷键: ${widget.action}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('当前快捷键: ${widget.currentShortcut}'),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                _isRecording = true;
              });
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isRecording
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isRecording ? '按下快捷键组合...' : (_newShortcut.isEmpty ? '点击此处录制新快捷键' : _newShortcut),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isRecording
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ),
          ),
          if (_isRecording)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                '按下键盘上的按键组合，完成后点击保存',
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // 清除快捷键
            setState(() {
              _newShortcut = '';
              _isRecording = false;
            });
          },
          child: const Text('清除'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            widget.onSave(_newShortcut);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    super.dispose();
  }
} 