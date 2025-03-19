import 'package:flutter/material.dart';
import '../../../state/models/file_node.dart';

/// 显示文件树上下文菜单
void showFileTreeContextMenu({
  required BuildContext context,
  required Offset position,
  required FileNode node,
  required Set<String> selectedPaths,
  required VoidCallback onRename,
  required VoidCallback onDelete,
  required VoidCallback onCreateFile,
  required VoidCallback onCreateFolder,
  required VoidCallback onCopy,
  required VoidCallback onCut,
  required VoidCallback onPaste,
}) {
  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final menuPosition = RelativeRect.fromLTRB(
    position.dx,
    position.dy,
    overlay.size.width - position.dx,
    overlay.size.height - position.dy,
  );

  final isDirectory = node.type == FileNodeType.directory;
  final multipleSelected = selectedPaths.length > 1;

  showMenu<String>(
    context: context,
    position: menuPosition,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: BorderSide(
        color: Theme.of(context).dividerColor,
        width: 1,
      ),
    ),
    elevation: 4,
    items: [
      // 新建菜单项
      if (isDirectory) ...[
        _buildMenuItem(
          context: context,
          icon: Icons.note_add,
          text: '新建文件',
          shortcut: 'Ctrl+N',
          onTap: onCreateFile,
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.create_new_folder,
          text: '新建文件夹',
          shortcut: 'Ctrl+Shift+N',
          onTap: onCreateFolder,
        ),
        const PopupMenuDivider(height: 1),
      ],
      
      // 剪切、复制、粘贴
      _buildMenuItem(
        context: context,
        icon: Icons.content_cut,
        text: multipleSelected ? '剪切 ${selectedPaths.length} 个项目' : '剪切',
        shortcut: 'Ctrl+X',
        onTap: onCut,
      ),
      _buildMenuItem(
        context: context,
        icon: Icons.content_copy,
        text: multipleSelected ? '复制 ${selectedPaths.length} 个项目' : '复制',
        shortcut: 'Ctrl+C',
        onTap: onCopy,
      ),
      if (isDirectory)
        _buildMenuItem(
          context: context,
          icon: Icons.content_paste,
          text: '粘贴',
          shortcut: 'Ctrl+V',
          onTap: onPaste,
        ),
      const PopupMenuDivider(height: 1),
      
      // 重命名和删除
      _buildMenuItem(
        context: context,
        icon: Icons.drive_file_rename_outline,
        text: multipleSelected ? '重命名 ${selectedPaths.length} 个项目' : '重命名',
        shortcut: 'F2',
        onTap: onRename,
      ),
      _buildMenuItem(
        context: context,
        icon: Icons.delete_outline,
        text: multipleSelected ? '删除 ${selectedPaths.length} 个项目' : '删除',
        shortcut: 'Del',
        onTap: onDelete,
        isDestructive: true,
      ),
    ],
  );
}

/// 构建菜单项
PopupMenuItem<String> _buildMenuItem({
  required BuildContext context,
  required IconData icon,
  required String text,
  required String shortcut,
  required VoidCallback onTap,
  bool isDestructive = false,
}) {
  return PopupMenuItem<String>(
    height: 32,
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDestructive
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.onSurface,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDestructive
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          shortcut,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    ),
  );
}

// 实现文件树上下文菜单
class FileTreeContextMenu extends StatelessWidget {
  final String path;
  final bool isDirectory;
  final Function(String) onOpen;
  final Function(String) onRename;
  final Function(String) onDelete;
  final Function(String) onCopy;
  final Function(String) onCut;
  final Function(String, String) onPaste;
  final Function(String) onNewFile;
  final Function(String) onNewFolder;
  
  const FileTreeContextMenu({
    Key? key,
    required this.path,
    required this.isDirectory,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
    required this.onCopy,
    required this.onCut,
    required this.onPaste,
    required this.onNewFile,
    required this.onNewFolder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      itemBuilder: (context) => [
        if (!isDirectory)
          PopupMenuItem(
            value: 'open',
            child: ListTile(
              leading: Icon(Icons.open_in_new),
              title: Text('打开'),
            ),
          ),
        PopupMenuItem(
          value: 'rename',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('重命名'),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete),
            title: Text('删除'),
          ),
        ),
        PopupMenuItem(
          value: 'copy',
          child: ListTile(
            leading: Icon(Icons.content_copy),
            title: Text('复制'),
          ),
        ),
        PopupMenuItem(
          value: 'cut',
          child: ListTile(
            leading: Icon(Icons.content_cut),
            title: Text('剪切'),
          ),
        ),
        if (isDirectory) ...[
          PopupMenuItem(
            value: 'paste',
            child: ListTile(
              leading: Icon(Icons.content_paste),
              title: Text('粘贴'),
            ),
          ),
          PopupMenuItem(
            value: 'new_file',
            child: ListTile(
              leading: Icon(Icons.insert_drive_file),
              title: Text('新建文件'),
            ),
          ),
          PopupMenuItem(
            value: 'new_folder',
            child: ListTile(
              leading: Icon(Icons.create_new_folder),
              title: Text('新建文件夹'),
            ),
          ),
        ],
      ],
      onSelected: (value) {
        switch (value) {
          case 'open':
            onOpen(path);
            break;
          case 'rename':
            onRename(path);
            break;
          case 'delete':
            onDelete(path);
            break;
          case 'copy':
            onCopy(path);
            break;
          case 'cut':
            onCut(path);
            break;
          case 'paste':
            // 需要实现粘贴逻辑
            break;
          case 'new_file':
            onNewFile(path);
            break;
          case 'new_folder':
            onNewFolder(path);
            break;
        }
      },
    );
  }
} 