import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'file_tree_toolbar_controller.dart';
import '../../themes/app_theme.dart';
import 'views/search_view.dart';
import 'views/source_control_view.dart';
import 'views/run_debug_view.dart';
import 'views/extensions_view.dart';

class FileTreeToolbar extends ConsumerWidget {
  const FileTreeToolbar({super.key});

  void _handleKeyboard(BuildContext context, WidgetRef ref) {
    // 注册快捷键
    ServicesBinding.instance.keyboard.addHandler((event) {
      if (event is! KeyDownEvent) return false;

      final bool isModifierPressed = HardwareKeyboard.instance.isControlPressed ||
                                   HardwareKeyboard.instance.isMetaPressed;
      final bool isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

      // Ctrl+Shift+E
      if (event.logicalKey == LogicalKeyboardKey.keyE &&
          isModifierPressed &&
          isShiftPressed) {
        ref.read(fileTreeToolbarProvider.notifier).setActiveView(FileTreeView.fileBrowser);
        return true;
      }

      // Ctrl+Shift+F
      if (event.logicalKey == LogicalKeyboardKey.keyF &&
          isModifierPressed &&
          isShiftPressed) {
        ref.read(fileTreeToolbarProvider.notifier).setActiveView(FileTreeView.search);
        return true;
      }

      // Ctrl+Shift+G
      if (event.logicalKey == LogicalKeyboardKey.keyG &&
          isModifierPressed &&
          isShiftPressed) {
        ref.read(fileTreeToolbarProvider.notifier).setActiveView(FileTreeView.sourceControl);
        return true;
      }

      // Ctrl+Shift+D
      if (event.logicalKey == LogicalKeyboardKey.keyD &&
          isModifierPressed &&
          isShiftPressed) {
        ref.read(fileTreeToolbarProvider.notifier).setActiveView(FileTreeView.runDebug);
        return true;
      }

      // Ctrl+Shift+X
      if (event.logicalKey == LogicalKeyboardKey.keyX &&
          isModifierPressed &&
          isShiftPressed) {
        ref.read(fileTreeToolbarProvider.notifier).setActiveView(FileTreeView.extensions);
        return true;
      }

      return false;
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentView = ref.watch(fileTreeViewProvider);
    
    // 注册快捷键处理
    _handleKeyboard(context, ref);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ToolbarItem(
                  icon: Icons.folder_outlined,
                  label: '文件浏览器',
                  shortcut: 'Ctrl+Shift+E',
                  isActive: currentView == FileTreeView.fileBrowser,
                  onPressed: () {
                    try {
                      ref.read(fileTreeViewProvider.notifier).state = FileTreeView.fileBrowser;
                    } catch (e) {
                      debugPrint('Error switching to file browser view: $e');
                    }
                  },
                ),
                ToolbarItem(
                  icon: Icons.search,
                  label: '搜索',
                  shortcut: 'Ctrl+Shift+F',
                  isActive: currentView == FileTreeView.search,
                  onPressed: () {
                    try {
                      ref.read(fileTreeViewProvider.notifier).state = FileTreeView.search;
                    } catch (e) {
                      debugPrint('Error switching to search view: $e');
                    }
                  },
                ),
                ToolbarItem(
                  icon: Icons.source_outlined,
                  label: '源代码管理',
                  shortcut: 'Ctrl+Shift+G',
                  isActive: currentView == FileTreeView.sourceControl,
                  onPressed: () {
                    try {
                      ref.read(fileTreeViewProvider.notifier).state = FileTreeView.sourceControl;
                    } catch (e) {
                      debugPrint('Error switching to source control view: $e');
                    }
                  },
                ),
                ToolbarItem(
                  icon: Icons.bug_report_outlined,
                  label: '运行和调试',
                  shortcut: 'Ctrl+Shift+D',
                  isActive: currentView == FileTreeView.runDebug,
                  onPressed: () {
                    try {
                      ref.read(fileTreeViewProvider.notifier).state = FileTreeView.runDebug;
                    } catch (e) {
                      debugPrint('Error switching to run debug view: $e');
                    }
                  },
                ),
                ToolbarItem(
                  icon: Icons.extension_outlined,
                  label: '扩展',
                  shortcut: 'Ctrl+Shift+X',
                  isActive: currentView == FileTreeView.extensions,
                  onPressed: () {
                    try {
                      ref.read(fileTreeViewProvider.notifier).state = FileTreeView.extensions;
                    } catch (e) {
                      debugPrint('Error switching to extensions view: $e');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                ToolbarItem(
                  icon: Icons.refresh,
                  label: '刷新',
                  shortcut: 'F5',
                  onPressed: () => ref.read(fileTreeToolbarProvider.notifier).refresh(),
                ),
                ToolbarItem(
                  icon: Icons.create_new_folder,
                  label: '新建文件夹',
                  shortcut: 'Ctrl+Shift+N',
                  onPressed: () => ref.read(fileTreeToolbarProvider.notifier).createNewFolder(),
                ),
                ToolbarItem(
                  icon: Icons.note_add,
                  label: '新建文件',
                  shortcut: 'Ctrl+N',
                  onPressed: () => ref.read(fileTreeToolbarProvider.notifier).createNewFile(),
                ),
                ToolbarItem(
                  icon: Icons.filter_list,
                  label: '过滤器',
                  onPressed: () => ref.read(fileTreeToolbarProvider.notifier).toggleFilter(),
                ),
                ToolbarItem(
                  icon: Icons.more_vert,
                  label: '更多选项',
                  onPressed: () => _showMoreOptions(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 200,
        50,
        MediaQuery.of(context).size.width - 10,
        100,
      ),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.sort, color: theme.colorScheme.onSurface),
            title: Text('排序方式'),
            trailing: Icon(Icons.arrow_right, color: theme.colorScheme.onSurface),
            dense: true,
            onTap: () {
              Navigator.pop(context);
              _showSortOptions(context, ref);
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.visibility, color: theme.colorScheme.onSurface),
            title: Text('显示选项'),
            trailing: Icon(Icons.arrow_right, color: theme.colorScheme.onSurface),
            dense: true,
            onTap: () {
              Navigator.pop(context);
              _showViewOptions(context, ref);
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.folder_zip, color: theme.colorScheme.onSurface),
            title: Text('折叠所有文件夹'),
            dense: true,
            onTap: () {
              Navigator.pop(context);
              ref.read(fileTreeToolbarProvider.notifier).collapseAll();
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.settings, color: theme.colorScheme.onSurface),
            title: Text('文件树设置'),
            dense: true,
            onTap: () {
              Navigator.pop(context);
              ref.read(fileTreeToolbarProvider.notifier).openSettings();
            },
          ),
        ),
      ],
    );
  }

  void _showSortOptions(BuildContext context, WidgetRef ref) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 400,
        50,
        MediaQuery.of(context).size.width - 200,
        100,
      ),
      items: [
        CheckedPopupMenuItem(
          checked: true,
          child: Text('按名称'),
          onTap: () => ref.read(fileTreeToolbarProvider.notifier).setSortBy(SortBy.name),
        ),
        CheckedPopupMenuItem(
          checked: false,
          child: Text('按修改时间'),
          onTap: () => ref.read(fileTreeToolbarProvider.notifier).setSortBy(SortBy.modified),
        ),
        CheckedPopupMenuItem(
          checked: false,
          child: Text('按类型'),
          onTap: () => ref.read(fileTreeToolbarProvider.notifier).setSortBy(SortBy.type),
        ),
        CheckedPopupMenuItem(
          checked: false,
          child: Text('按大小'),
          onTap: () => ref.read(fileTreeToolbarProvider.notifier).setSortBy(SortBy.size),
        ),
      ],
    );
  }

  void _showViewOptions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 400,
        50,
        MediaQuery.of(context).size.width - 200,
        100,
      ),
      items: [
        CheckedPopupMenuItem(
          checked: true,
          child: Text('显示隐藏文件'),
          onTap: () => ref.read(fileTreeToolbarProvider.notifier).toggleHiddenFiles(),
        ),
        CheckedPopupMenuItem(
          checked: true,
          child: Text('显示文件图标'),
          onTap: () => ref.read(fileTreeToolbarProvider.notifier).toggleFileIcons(),
        ),
        CheckedPopupMenuItem(
          checked: false,
          child: Text('紧凑视图'),
          onTap: () => ref.read(fileTreeToolbarProvider.notifier).toggleCompactView(),
        ),
      ],
    );
  }
}

class ToolbarItem extends StatefulWidget {
  const ToolbarItem({
    super.key,
    required this.icon,
    required this.label,
    this.shortcut,
    this.isActive = false,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final String? shortcut;
  final bool isActive;
  final VoidCallback? onPressed;

  @override
  State<ToolbarItem> createState() => _ToolbarItemState();
}

class _ToolbarItemState extends State<ToolbarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.shortcut != null 
            ? '${widget.label} (${widget.shortcut})'
            : widget.label,
        child: Material(
          color: widget.isActive || _isHovered 
              ? theme.colorScheme.primaryContainer.withOpacity(0.1)
              : Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            child: Container(
              height: 36,
              width: 32,
              padding: const EdgeInsets.all(6),
              child: Icon(
                widget.icon,
                size: 20,
                color: widget.isActive 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
