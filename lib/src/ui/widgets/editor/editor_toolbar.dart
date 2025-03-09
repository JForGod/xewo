import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/providers/editor_provider.dart';
import 'dialogs/find_replace_dialog.dart';
import 'dialogs/editor_settings_dialog.dart';
import 'shortcuts/editor_shortcuts.dart';
import 'dialogs/shortcut_settings_dialog.dart';
import '../../themes/app_theme.dart';

/// 编辑器工具栏
class EditorToolbar extends ConsumerWidget {
  final VoidCallback? onFormatPressed;
  final VoidCallback? onFindReplacePressed;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onShortcutsPressed;
  final VoidCallback? onSavePressed;
  final VoidCallback? onSaveAsPressed;

  const EditorToolbar({
    Key? key,
    this.onFormatPressed,
    this.onFindReplacePressed,
    this.onSettingsPressed,
    this.onShortcutsPressed,
    this.onSavePressed,
    this.onSaveAsPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorProvider);
    final notifier = ref.read(editorProvider.notifier);
    final theme = Theme.of(context);
    
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildToolbarButton(
            context,
            icon: Icons.save,
            tooltip: '保存',
            onPressed: onSavePressed,
          ),
          _buildToolbarButton(
            context,
            icon: Icons.save_as,
            tooltip: '另存为',
            onPressed: onSaveAsPressed,
          ),
          const VerticalDivider(width: 1, indent: 8, endIndent: 8),
          _buildToolbarButton(
            context,
            icon: Icons.format_align_left,
            tooltip: '格式化代码',
            onPressed: onFormatPressed,
          ),
          _buildToolbarButton(
            context,
            icon: Icons.search,
            tooltip: '查找/替换',
            onPressed: onFindReplacePressed,
          ),
          const VerticalDivider(width: 1, indent: 8, endIndent: 8),
          _buildToolbarButton(
            context,
            icon: Icons.settings,
            tooltip: '编辑器设置',
            onPressed: onSettingsPressed,
          ),
          _buildToolbarButton(
            context,
            icon: Icons.keyboard,
            tooltip: '快捷键设置',
            onPressed: onShortcutsPressed,
          ),
          const Spacer(),
          if (state.currentFilePath.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Text(
                    '${state.language} | ',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    state.currentFilePath.split('/').last,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: state.isModified ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (state.isModified)
                    Text(
                      ' *',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        splashRadius: 20,
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}

/// 显示查找替换对话框
void showFindReplaceDialog(
  BuildContext context,
  EditorState state,
  EditorNotifier notifier, {
  bool showReplace = false,
}) {
  showDialog(
    context: context,
    builder: (context) => FindReplaceDialog(
      initialText: state.currentFileContent,
      showReplace: showReplace,
      onReplace: (newText) {
        notifier.updateCurrentFileContent(newText);
        Navigator.of(context).pop();
      },
    ),
  );
}

/// 显示编辑器设置对话框
void showEditorSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const EditorSettingsDialog(),
  );
}

/// 显示快捷键设置对话框
void showShortcutSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const ShortcutSettingsDialog(),
  );
} 