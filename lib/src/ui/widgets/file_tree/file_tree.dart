import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/providers/file_tree_provider.dart';
import '../../../state/providers/editor_provider.dart';
import 'draggable_file_tree_node.dart';
import '../../../services/file/file_service.dart';

/// 文件树组件
class FileTree extends ConsumerStatefulWidget {
  const FileTree({super.key});

  @override
  ConsumerState<FileTree> createState() => _FileTreeState();
}

class _FileTreeState extends ConsumerState<FileTree> {
  final FileService _fileService = FileService();
  
  @override
  void initState() {
    super.initState();
    // 初始化时加载项目根目录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fileTreeProvider.notifier).loadDirectory('H:\\AxE\\xewo');
    });
  }

  // 创建新文件夹对话框
  Future<void> _showCreateFolderDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文件夹'),
        content: Container(
          width: 300,
          constraints: const BoxConstraints(maxWidth: 300),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '文件夹名称',
              isDense: true,
            ),
            maxLines: 1,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final state = ref.read(fileTreeProvider);
      if (state.currentDirectory != null) {
        final newPath = '${state.currentDirectory}\\$result';
        try {
          await _fileService.createDirectory(newPath);
          // 重新加载当前目录
          ref.read(fileTreeProvider.notifier).loadDirectory(state.currentDirectory!);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('创建文件夹失败: $e')),
            );
          }
        }
      }
    }
  }

  // 创建新文件对话框
  Future<void> _showCreateFileDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文件'),
        content: Container(
          width: 300,
          constraints: const BoxConstraints(maxWidth: 300),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '文件名',
              isDense: true,
            ),
            maxLines: 1,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final state = ref.read(fileTreeProvider);
      if (state.currentDirectory != null) {
        final newPath = '${state.currentDirectory}\\$result';
        try {
          await _fileService.createFile(newPath, '');
          // 重新加载当前目录
          ref.read(fileTreeProvider.notifier).loadDirectory(state.currentDirectory!);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('创建文件失败: $e')),
            );
          }
        }
      }
    }
  }

  // 处理节点点击
  void _handleNodeTap(FileNode node) {
    final fileTreeNotifier = ref.read(fileTreeProvider.notifier);
    
    if (node.isDirectory) {
      // 如果是目录，切换展开/折叠状态
      fileTreeNotifier.toggleNodeExpansion(node.path);
    } else {
      // 如果是文件，选择该文件
      fileTreeNotifier.selectNode(node.path);
      
      // 如果不是多选模式，打开文件
      if (!ref.read(fileTreeProvider).isMultiSelectMode) {
        _openFile(node.path);
      }
    }
  }
  
  // 处理节点键盘事件
  void _handleNodeKeyDown(FileNode node, RawKeyEvent event, bool isMultiSelectMode) {
    // 处理Ctrl+A全选
    if (event.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyA) {
      // 实现全选逻辑
    }
    
    // 处理Shift+方向键多选
    if (event.isShiftPressed) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // 实现Shift+方向键多选逻辑
      }
    }
    
    // 处理空格键切换选择状态
    if (event.logicalKey == LogicalKeyboardKey.space) {
      ref.read(fileTreeProvider.notifier).selectNode(node.path);
    }
    
    // 处理Delete键删除文件/文件夹
    if (event.logicalKey == LogicalKeyboardKey.delete) {
      _showDeleteConfirmDialog([node]);
    }
  }

  // 处理节点右键点击
  void _handleNodeRightClick(FileNode node, Offset position) {
    final fileTreeState = ref.read(fileTreeProvider);
    final fileTreeNotifier = ref.read(fileTreeProvider.notifier);
    
    // 如果右键点击的节点不在选中状态，先选中它
    if (!fileTreeState.isMultiSelectMode || !fileTreeState.selectedPaths.contains(node.path)) {
      fileTreeNotifier.selectNode(node.path);
    }
    
    // 显示上下文菜单
    _showContextMenu(position, fileTreeNotifier.getSelectedNodes());
  }

  // 处理节点拖放
  void _handleNodeDrop(FileNode sourceNode, FileNode targetNode) {
    final fileTreeState = ref.read(fileTreeProvider);
    final fileTreeNotifier = ref.read(fileTreeProvider.notifier);
    
    // 如果是多选模式且源节点在选中集合中，移动所有选中的节点
    if (fileTreeState.isMultiSelectMode && fileTreeState.selectedPaths.contains(sourceNode.path)) {
      final selectedNodes = fileTreeNotifier.getSelectedNodes();
      fileTreeNotifier.moveNodes(selectedNodes, targetNode);
    } else {
      // 否则只移动单个节点
      fileTreeNotifier.moveNodes([sourceNode], targetNode);
    }
  }

  // 打开文件
  Future<void> _openFile(String filePath) async {
    try {
      final content = await _fileService.readFile(filePath);
      ref.read(editorProvider.notifier).updateCurrentFile(filePath, content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开文件失败: $e')),
        );
      }
    }
  }
  
  // 显示上下文菜单
  void _showContextMenu(Offset position, List<FileNode> selectedNodes) {
    if (selectedNodes.isEmpty) return;
    
    final fileTreeNotifier = ref.read(fileTreeProvider.notifier);
    final isMultiSelect = selectedNodes.length > 1;
    final firstNode = selectedNodes.first;
    
    final items = <PopupMenuEntry<String>>[];
    
    // 打开文件选项（仅单选且为文件时显示）
    if (!isMultiSelect && !firstNode.isDirectory) {
      items.add(
        const PopupMenuItem<String>(
          value: 'open',
          child: ListTile(
            leading: Icon(Icons.open_in_new),
            title: Text('打开'),
            dense: true,
          ),
        ),
      );
      items.add(const PopupMenuDivider());
    }
    
    // 新建选项（仅单选且为目录时显示）
    if (!isMultiSelect && firstNode.isDirectory) {
      items.add(
        const PopupMenuItem<String>(
          value: 'new_file',
          child: ListTile(
            leading: Icon(Icons.insert_drive_file),
            title: Text('新建文件'),
            dense: true,
          ),
        ),
      );
      items.add(
        const PopupMenuItem<String>(
          value: 'new_folder',
          child: ListTile(
            leading: Icon(Icons.create_new_folder),
            title: Text('新建文件夹'),
            dense: true,
          ),
        ),
      );
      items.add(const PopupMenuDivider());
    }
    
    // 复制、剪切、粘贴选项
    items.add(
      const PopupMenuItem<String>(
        value: 'copy',
        child: ListTile(
          leading: Icon(Icons.content_copy),
          title: Text('复制'),
          dense: true,
        ),
      ),
    );
    items.add(
      const PopupMenuItem<String>(
        value: 'cut',
        child: ListTile(
          leading: Icon(Icons.content_cut),
          title: Text('剪切'),
          dense: true,
        ),
      ),
    );
    
    // 删除选项
    items.add(
      const PopupMenuItem<String>(
        value: 'delete',
        child: ListTile(
          leading: Icon(Icons.delete),
          title: Text('删除'),
          dense: true,
        ),
      ),
    );
    
    // 重命名选项（仅单选时显示）
    if (!isMultiSelect) {
      items.add(
        const PopupMenuItem<String>(
          value: 'rename',
          child: ListTile(
            leading: Icon(Icons.drive_file_rename_outline),
            title: Text('重命名'),
            dense: true,
          ),
        ),
      );
    }
    
    // 显示菜单
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: items,
    ).then((value) {
      if (value == null) return;
      
      switch (value) {
        case 'open':
          if (!isMultiSelect && !firstNode.isDirectory) {
            _openFile(firstNode.path);
          }
          break;
        case 'new_file':
          if (!isMultiSelect && firstNode.isDirectory) {
            _showCreateFileDialog();
          }
          break;
        case 'new_folder':
          if (!isMultiSelect && firstNode.isDirectory) {
            _showCreateFolderDialog();
          }
          break;
        case 'copy':
          // 实现复制功能
          break;
        case 'cut':
          // 实现剪切功能
          break;
        case 'delete':
          _showDeleteConfirmDialog(selectedNodes);
          break;
        case 'rename':
          if (!isMultiSelect) {
            _showRenameDialog(firstNode);
          }
          break;
      }
    });
  }
  
  // 显示重命名对话框
  Future<void> _showRenameDialog(FileNode node) async {
    final controller = TextEditingController(text: node.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名'),
        content: Container(
          width: 300,
          constraints: const BoxConstraints(maxWidth: 300),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '新名称',
              isDense: true,
            ),
            maxLines: 1,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('重命名'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != node.name) {
      final state = ref.read(fileTreeProvider);
      if (state.currentDirectory != null) {
        final newPath = '${state.currentDirectory}\\$result';
        try {
          if (node.isDirectory) {
            await _fileService.moveDirectory(node.path, newPath);
          } else {
            await _fileService.moveFile(node.path, newPath);
          }
          // 重新加载当前目录
          ref.read(fileTreeProvider.notifier).loadDirectory(state.currentDirectory!);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('重命名失败: $e')),
            );
          }
        }
      }
    }
  }
  
  // 显示删除确认对话框
  Future<void> _showDeleteConfirmDialog(List<FileNode> nodes) async {
    if (nodes.isEmpty) return;
    
    final isMultiple = nodes.length > 1;
    final message = isMultiple
        ? '确定要删除这 ${nodes.length} 个项目吗？此操作无法撤销。'
        : '确定要删除 "${nodes.first.name}" 吗？此操作无法撤销。';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isMultiple ? '删除多个项目' : '删除'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final state = ref.read(fileTreeProvider);
      if (state.currentDirectory != null) {
        try {
          for (final node in nodes) {
            if (node.isDirectory) {
              await _fileService.deleteDirectory(node.path, recursive: true);
            } else {
              await _fileService.deleteFile(node.path);
            }
          }
          // 重新加载当前目录
          ref.read(fileTreeProvider.notifier).loadDirectory(state.currentDirectory!);
          // 清除选择
          ref.read(fileTreeProvider.notifier).clearSelection();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('删除失败: $e')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileTreeState = ref.watch(fileTreeProvider);
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // 工具栏
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
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
              // 新建文件按钮
              IconButton(
                icon: const Icon(Icons.insert_drive_file, size: 18),
                tooltip: '新建文件',
                onPressed: _showCreateFileDialog,
                splashRadius: 20,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: const EdgeInsets.all(6),
              ),
              
              // 新建文件夹按钮
              IconButton(
                icon: const Icon(Icons.create_new_folder, size: 18),
                tooltip: '新建文件夹',
                onPressed: _showCreateFolderDialog,
                splashRadius: 20,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: const EdgeInsets.all(6),
              ),
              
              // 刷新按钮
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: '刷新',
                onPressed: () {
                  if (fileTreeState.currentDirectory != null) {
                    ref.read(fileTreeProvider.notifier).loadDirectory(fileTreeState.currentDirectory!);
                  }
                },
                splashRadius: 20,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: const EdgeInsets.all(6),
              ),
              
              const Spacer(),
              
              // 多选模式切换按钮
              IconButton(
                icon: Icon(
                  fileTreeState.isMultiSelectMode ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18,
                ),
                tooltip: fileTreeState.isMultiSelectMode ? '退出多选模式' : '进入多选模式',
                onPressed: () {
                  ref.read(fileTreeProvider.notifier).toggleMultiSelectMode();
                },
                splashRadius: 20,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: const EdgeInsets.all(6),
              ),
            ],
          ),
        ),
        
        // 文件树
        Expanded(
          child: fileTreeState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : fileTreeState.error != null
                  ? Center(child: Text('加载失败: ${fileTreeState.error}'))
                  : fileTreeState.nodes.isEmpty
                      ? const Center(child: Text('目录为空'))
                      : ListView.builder(
                          itemCount: fileTreeState.nodes.length,
                          itemBuilder: (context, index) {
                            final node = fileTreeState.nodes[index];
                            return DraggableFileTreeNode(
                              node: node,
                              level: 0,
                              isExpanded: fileTreeState.expandedPaths.contains(node.path),
                              isSelected: fileTreeState.selectedPath == node.path,
                              isMultiSelected: fileTreeState.selectedPaths.contains(node.path),
                              isMultiSelectMode: fileTreeState.isMultiSelectMode,
                              onNodeTap: _handleNodeTap,
                              onNodeKeyDown: _handleNodeKeyDown,
                              onNodeRightClick: _handleNodeRightClick,
                              onNodeDrop: _handleNodeDrop,
                            );
                          },
                        ),
        ),
      ],
    );
  }
} 