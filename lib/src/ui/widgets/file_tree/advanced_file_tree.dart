import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/providers/file_tree_provider.dart';
import '../../themes/app_theme.dart';
import 'draggable_file_tree_node.dart';
import 'file_filter.dart';
import 'favorites_panel.dart';
import 'version_control_indicator.dart';
import 'virtual_file_tree.dart';

/// 高级文件树视图类型
enum AdvancedFileTreeViewType {
  standard,  // 标准视图
  virtual,   // 虚拟滚动视图
  favorites, // 收藏夹视图
}

/// 高级文件树组件
class AdvancedFileTree extends ConsumerStatefulWidget {
  const AdvancedFileTree({super.key});

  @override
  ConsumerState<AdvancedFileTree> createState() => _AdvancedFileTreeState();
}

class _AdvancedFileTreeState extends ConsumerState<AdvancedFileTree> with SingleTickerProviderStateMixin {
  AdvancedFileTreeViewType _currentView = AdvancedFileTreeViewType.standard;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentView = AdvancedFileTreeViewType.values[_tabController.index];
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 视图切换选项卡
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(
              icon: Icon(Icons.folder, size: 20),
              text: '文件',
            ),
            Tab(
              icon: Icon(Icons.star, size: 20),
              text: '收藏',
            ),
            Tab(
              icon: Icon(Icons.history, size: 20),
              text: '历史',
            ),
          ],
        ),
        
        // 视图内容
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 文件树视图
              _buildFileTreeView(),
              
              // 收藏夹视图
              _buildFavoritesView(),
              
              // 历史视图
              _buildHistoryView(),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建文件树视图
  Widget _buildFileTreeView() {
    // 根据项目大小选择合适的视图
    // 这里可以根据文件数量动态选择标准视图或虚拟滚动视图
    final state = ref.watch(fileTreeProvider);
    final nodeCount = _countNodes(state.nodes);
    
    // 如果节点数量超过1000，使用虚拟滚动视图
    if (nodeCount > 1000) {
      return const VirtualFileTree();
    }
    
    // 否则使用标准视图
    return _buildStandardFileTree();
  }

  /// 构建标准文件树视图
  Widget _buildStandardFileTree() {
    final state = ref.watch(fileTreeProvider);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // 工具栏
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text('文件', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.read(fileTreeProvider.notifier).refresh(),
                  tooltip: '刷新',
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.create_new_folder),
                  onPressed: _showCreateFolderDialog,
                  tooltip: '新建文件夹',
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.note_add),
                  onPressed: _showCreateFileDialog,
                  tooltip: '新建文件',
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                  tooltip: '过滤',
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),

          // 文件树内容
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text(state.error!))
                    : state.nodes.isEmpty
                        ? const Center(child: Text('没有文件'))
                        : ListView.builder(
                            itemCount: state.nodes.length,
                            itemBuilder: (context, index) {
                              return DraggableFileTreeNode(
                                node: state.nodes[index],
                                level: 0,
                                isExpanded: state.expandedPaths.contains(state.nodes[index].path),
                                isSelected: state.selectedPath == state.nodes[index].path,
                                onNodeTap: (node) {
                                  if (node.isDirectory) {
                                    ref.read(fileTreeProvider.notifier).toggleDirectory(node.path);
                                  } else {
                                    ref.read(fileTreeProvider.notifier).selectFile(node.path);
                                    ref.read(editorProvider.notifier).openFile(node.path);
                                  }
                                },
                                onNodeRightClick: (node, position) {
                                  ref.read(fileTreeProvider.notifier).selectFile(node.path);
                                  _showContextMenu(context, node, position);
                                },
                                onNodeDrop: (sourceNode, targetNode) {
                                  _handleNodeDrop(sourceNode, targetNode);
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  /// 构建收藏夹视图
  Widget _buildFavoritesView() {
    return FavoritesPanel(
      onItemSelected: (path) {
        // 处理收藏项选择
        if (path.endsWith('/') || path.endsWith('\\')) {
          // 如果是目录，加载目录
          ref.read(fileTreeProvider.notifier).loadDirectory(path);
          _tabController.animateTo(0); // 切换到文件树视图
        } else {
          // 如果是文件，打开文件
          ref.read(fileTreeProvider.notifier).selectFile(path);
          ref.read(editorProvider.notifier).openFile(path);
        }
      },
    );
  }

  /// 构建历史视图
  Widget _buildHistoryView() {
    // 这里可以实现文件历史记录视图
    return const Center(
      child: Text('文件历史记录功能开发中'),
    );
  }

  /// 计算节点数量
  int _countNodes(List<FileNode> nodes) {
    int count = nodes.length;
    
    for (final node in nodes) {
      if (node.isDirectory && node.children.isNotEmpty) {
        count += _countNodes(node.children);
      }
    }
    
    return count;
  }

  /// 显示过滤对话框
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('过滤文件'),
        content: SizedBox(
          width: 400,
          child: FileFilter(
            onFilterChanged: (type, pattern) {
              Navigator.pop(context);
              // 这里应该实现过滤逻辑
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('过滤类型: $type, 模式: $pattern')),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 显示上下文菜单
  void _showContextMenu(BuildContext context, FileNode node, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        if (!node.isDirectory)
          PopupMenuItem(
            value: 'open',
            child: _buildMenuItem(Icons.open_in_new, '打开'),
          ),
        if (node.isDirectory)
          PopupMenuItem(
            value: 'create_file',
            child: _buildMenuItem(Icons.note_add, '新建文件'),
          ),
        if (node.isDirectory)
          PopupMenuItem(
            value: 'create_folder',
            child: _buildMenuItem(Icons.create_new_folder, '新建文件夹'),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'rename',
          child: _buildMenuItem(Icons.edit, '重命名'),
        ),
        PopupMenuItem(
          value: 'delete',
          child: _buildMenuItem(Icons.delete, '删除', color: Colors.red),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'add_to_favorites',
          child: _buildMenuItem(Icons.star, '添加到收藏夹'),
        ),
        PopupMenuItem(
          value: 'view_version_control',
          child: _buildMenuItem(Icons.history, '版本控制信息'),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      
      switch (value) {
        case 'open':
          // 打开文件
          ref.read(editorProvider.notifier).openFile(node.path);
          break;
        case 'create_file':
          _showCreateFileInDirectoryDialog(node);
          break;
        case 'create_folder':
          _showCreateFolderInDirectoryDialog(node);
          break;
        case 'rename':
          _showRenameDialog(node);
          break;
        case 'delete':
          _showDeleteConfirmation(node);
          break;
        case 'add_to_favorites':
          // 添加到收藏夹
          ref.read(favoritesProvider.notifier).addFavorite(node);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已添加 ${node.name} 到收藏夹')),
          );
          break;
        case 'view_version_control':
          // 查看版本控制信息
          _showVersionControlDetails(node);
          break;
      }
    });
  }

  /// 构建菜单项
  Widget _buildMenuItem(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }

  /// 创建新文件夹对话框
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
      await ref.read(fileTreeProvider.notifier).createFolder(result);
    }
  }

  /// 创建新文件对话框
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
      await ref.read(fileTreeProvider.notifier).createFile(result);
    }
  }

  /// 在指定目录中创建文件对话框
  Future<void> _showCreateFileInDirectoryDialog(FileNode directory) async {
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
      await ref.read(fileTreeProvider.notifier).createFileInDirectory(directory.path, result);
    }
  }

  /// 在指定目录中创建文件夹对话框
  Future<void> _showCreateFolderInDirectoryDialog(FileNode directory) async {
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
      await ref.read(fileTreeProvider.notifier).createFolderInDirectory(directory.path, result);
    }
  }

  /// 重命名对话框
  Future<void> _showRenameDialog(FileNode node) async {
    final controller = TextEditingController(text: node.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('重命名${node.isDirectory ? '文件夹' : '文件'}'),
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
      await ref.read(fileTreeProvider.notifier).renameNode(node.path, result);
    }
  }

  /// 删除确认对话框
  Future<void> _showDeleteConfirmation(FileNode node) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除${node.isDirectory ? '文件夹' : '文件'}'),
        content: Text('确定要删除 ${node.name} 吗？${node.isDirectory ? '这将删除文件夹中的所有内容。' : ''}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(fileTreeProvider.notifier).deleteNode(node.path);
    }
  }

  /// 显示版本控制详情
  void _showVersionControlDetails(FileNode node) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('版本控制信息'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: VersionControlDetailsPanel(filePath: node.path),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 处理节点拖放
  Future<void> _handleNodeDrop(FileNode sourceNode, FileNode targetNode) async {
    // 如果目标是文件，使用其父目录作为目标
    String targetPath = targetNode.isDirectory
        ? targetNode.path
        : targetNode.path.substring(0, targetNode.path.lastIndexOf('\\'));
    
    // 构建新路径
    String newPath = '$targetPath\\${sourceNode.name}';
    
    // 检查是否是移动到相同位置
    if (sourceNode.path == newPath) {
      return;
    }
    
    // 确认移动
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移动文件'),
        content: Text('确定要将 ${sourceNode.name} 移动到 $targetPath 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移动'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        // 移动文件或文件夹
        if (sourceNode.isDirectory) {
          // 移动文件夹
          await ref.read(fileTreeProvider.notifier).moveDirectory(sourceNode.path, newPath);
        } else {
          // 移动文件
          await ref.read(fileTreeProvider.notifier).moveFile(sourceNode.path, newPath);
        }
        
        // 刷新文件树
        await ref.read(fileTreeProvider.notifier).refresh();
        
        // 显示成功消息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已移动 ${sourceNode.name} 到 $targetPath')),
          );
        }
      } catch (e) {
        // 显示错误消息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('移动失败: $e')),
          );
        }
      }
    }
  }
} 