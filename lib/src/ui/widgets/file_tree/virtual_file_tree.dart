import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/providers/file_tree_provider.dart';
import '../../themes/app_theme.dart';
import 'draggable_file_tree_node.dart';
import 'version_control_indicator.dart';
import 'file_filter.dart';

/// 虚拟文件树组件
class VirtualFileTree extends ConsumerStatefulWidget {
  const VirtualFileTree({super.key});

  @override
  ConsumerState<VirtualFileTree> createState() => _VirtualFileTreeState();
}

class _VirtualFileTreeState extends ConsumerState<VirtualFileTree> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  FileFilterType _filterType = FileFilterType.all;
  String? _customFilterPattern;
  
  // 虚拟滚动相关
  final double _itemHeight = 28.0; // 每个节点的高度
  final int _cacheExtent = 10; // 缓存范围
  
  @override
  void initState() {
    super.initState();
    // 初始化时加载项目根目录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fileTreeProvider.notifier).loadDirectory('H:\\AxE\\xewo');
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fileTreeProvider);
    
    // 过滤节点
    final filteredNodes = _filterNodes(state.nodes);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // 工具栏
          _buildToolbar(),
          
          // 过滤器
          if (_isSearching) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索文件...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacingXs,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.search, size: 16),
                ),
                onChanged: _searchFiles,
              ),
            ),
          ],
          
          // 文件过滤器
          if (_filterType != FileFilterType.all || _customFilterPattern != null) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
              child: FileFilter(
                initialFilterType: _filterType,
                initialCustomPattern: _customFilterPattern,
                onFilterChanged: (type, pattern) {
                  setState(() {
                    _filterType = type;
                    _customFilterPattern = pattern;
                  });
                },
              ),
            ),
          ],

          // 文件树内容
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text(state.error!))
                    : filteredNodes.isEmpty
                        ? const Center(child: Text('没有文件'))
                        : _buildVirtualTree(filteredNodes, state),
          ),
        ],
      ),
    );
  }

  /// 构建工具栏
  Widget _buildToolbar() {
    return Container(
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
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchFiles('');
                }
              });
            },
            tooltip: _isSearching ? '取消搜索' : '搜索文件',
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _filterType = _filterType == FileFilterType.all
                    ? FileFilterType.dart
                    : FileFilterType.all;
                _customFilterPattern = null;
              });
            },
            tooltip: '过滤文件',
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
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
        ],
      ),
    );
  }

  /// 构建虚拟滚动树
  Widget _buildVirtualTree(List<FileNode> nodes, FileTreeState state) {
    // 计算所有可见节点（包括展开的子节点）
    final visibleNodes = _calculateVisibleNodes(nodes, state.expandedPaths);
    
    // 计算总高度
    final totalHeight = visibleNodes.length * _itemHeight;
    
    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: SizedBox(
          height: totalHeight,
          child: Stack(
            children: _buildVisibleItems(visibleNodes, state),
          ),
        ),
      ),
    );
  }

  /// 计算所有可见节点
  List<_VisibleNode> _calculateVisibleNodes(List<FileNode> nodes, Set<String> expandedPaths, {int level = 0}) {
    final result = <_VisibleNode>[];
    
    for (final node in nodes) {
      // 添加当前节点
      result.add(_VisibleNode(node: node, level: level));
      
      // 如果是展开的文件夹，递归添加子节点
      if (node.isDirectory && expandedPaths.contains(node.path) && node.children.isNotEmpty) {
        result.addAll(_calculateVisibleNodes(node.children, expandedPaths, level: level + 1));
      }
    }
    
    return result;
  }

  /// 构建可见项
  List<Widget> _buildVisibleItems(List<_VisibleNode> visibleNodes, FileTreeState state) {
    final result = <Widget>[];
    
    // 计算可见范围
    final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0;
    final viewportHeight = _scrollController.hasClients ? _scrollController.position.viewportDimension : 0;
    
    final startIndex = (scrollOffset / _itemHeight).floor() - _cacheExtent;
    final endIndex = ((scrollOffset + viewportHeight) / _itemHeight).ceil() + _cacheExtent;
    
    // 只构建可见范围内的节点
    for (int i = 0; i < visibleNodes.length; i++) {
      if (i >= startIndex && i <= endIndex) {
        final visibleNode = visibleNodes[i];
        result.add(
          Positioned(
            top: i * _itemHeight,
            left: 0,
            right: 0,
            height: _itemHeight,
            child: _buildNodeItem(visibleNode, state),
          ),
        );
      }
    }
    
    return result;
  }

  /// 构建节点项
  Widget _buildNodeItem(_VisibleNode visibleNode, FileTreeState state) {
    return Row(
      children: [
        // 缩进
        SizedBox(width: visibleNode.level * 16.0),
        
        // 展开/折叠图标
        if (visibleNode.node.isDirectory)
          IconButton(
            icon: Icon(
              state.expandedPaths.contains(visibleNode.node.path)
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right,
              size: 16,
            ),
            onPressed: () => ref.read(fileTreeProvider.notifier).toggleDirectory(visibleNode.node.path),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
          )
        else
          const SizedBox(width: 24),
        
        // 文件/文件夹图标
        Icon(
          _getIconForNode(visibleNode.node),
          size: 18,
          color: _getColorForNode(context, visibleNode.node),
        ),
        const SizedBox(width: 4),
        
        // 版本控制状态指示器
        VersionControlIndicator(
          filePath: visibleNode.node.path,
          size: 8,
        ),
        const SizedBox(width: 4),
        
        // 文件/文件夹名称
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (visibleNode.node.isDirectory) {
                ref.read(fileTreeProvider.notifier).toggleDirectory(visibleNode.node.path);
              } else {
                ref.read(fileTreeProvider.notifier).selectFile(visibleNode.node.path);
              }
            },
            onSecondaryTap: () {
              // 右键菜单
              ref.read(fileTreeProvider.notifier).selectFile(visibleNode.node.path);
              _showContextMenu(context, visibleNode.node);
            },
            child: Text(
              visibleNode.node.name,
              style: TextStyle(
                color: state.selectedPath == visibleNode.node.path
                    ? Theme.of(context).primaryColor
                    : null,
                fontWeight: state.selectedPath == visibleNode.node.path
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  /// 根据节点类型获取图标
  IconData _getIconForNode(FileNode node) {
    if (node.isDirectory) {
      return Icons.folder;
    }
    
    // 根据文件扩展名获取图标
    final extension = node.name.split('.').last.toLowerCase();
    switch (extension) {
      case 'dart':
        return Icons.code;
      case 'js':
      case 'ts':
        return Icons.javascript;
      case 'html':
        return Icons.html;
      case 'css':
        return Icons.css;
      case 'json':
        return Icons.data_object;
      case 'md':
        return Icons.description;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Icons.audio_file;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'ttf':
      case 'otf':
        return Icons.font_download;
      case 'yml':
      case 'yaml':
        return Icons.settings;
      case 'xml':
        return Icons.code;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// 根据节点类型获取颜色
  Color _getColorForNode(BuildContext context, FileNode node) {
    if (node.isDirectory) {
      return Colors.amber;
    }
    
    // 根据文件扩展名获取颜色
    final extension = node.name.split('.').last.toLowerCase();
    switch (extension) {
      case 'dart':
        return Colors.blue;
      case 'js':
      case 'ts':
        return Colors.yellow.shade800;
      case 'html':
        return Colors.orange;
      case 'css':
        return Colors.blue.shade800;
      case 'json':
        return Colors.green;
      case 'md':
        return Colors.blueGrey;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
        return Colors.purple;
      case 'pdf':
        return Colors.red;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.brown;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Colors.teal;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Colors.pink;
      case 'ttf':
      case 'otf':
        return Colors.indigo;
      case 'yml':
      case 'yaml':
        return Colors.cyan;
      case 'xml':
        return Colors.deepOrange;
      default:
        return Theme.of(context).iconTheme.color ?? Colors.grey;
    }
  }

  /// 过滤节点
  List<FileNode> _filterNodes(List<FileNode> nodes) {
    if (_filterType == FileFilterType.all && (_customFilterPattern == null || _customFilterPattern!.isEmpty) && _searchController.text.isEmpty) {
      return nodes;
    }
    
    // 搜索过滤
    if (_searchController.text.isNotEmpty) {
      return _filterNodesBySearch(nodes, _searchController.text.toLowerCase());
    }
    
    // 类型过滤
    return _filterNodesByType(nodes, _filterType, _customFilterPattern);
  }

  /// 按搜索过滤节点
  List<FileNode> _filterNodesBySearch(List<FileNode> nodes, String query) {
    final result = <FileNode>[];
    
    for (final node in nodes) {
      if (node.name.toLowerCase().contains(query)) {
        // 如果节点匹配，添加到结果中
        result.add(node);
      } else if (node.isDirectory) {
        // 如果是文件夹，递归搜索子节点
        final filteredChildren = _filterNodesBySearch(node.children, query);
        if (filteredChildren.isNotEmpty) {
          // 如果子节点中有匹配的，添加当前文件夹和匹配的子节点
          result.add(
            FileNode(
              path: node.path,
              name: node.name,
              isDirectory: true,
              children: filteredChildren,
              lastModified: node.lastModified,
            ),
          );
        }
      }
    }
    
    return result;
  }

  /// 按类型过滤节点
  List<FileNode> _filterNodesByType(List<FileNode> nodes, FileFilterType filterType, String? customPattern) {
    final result = <FileNode>[];
    
    for (final node in nodes) {
      if (node.isDirectory) {
        // 如果是文件夹，递归过滤子节点
        final filteredChildren = _filterNodesByType(node.children, filterType, customPattern);
        
        // 文件夹始终保留，但子节点可能被过滤
        result.add(
          FileNode(
            path: node.path,
            name: node.name,
            isDirectory: true,
            children: filteredChildren,
            lastModified: node.lastModified,
          ),
        );
      } else if (FileFilterUtils.matchesFilter(node.name, filterType, customPattern)) {
        // 如果文件匹配过滤条件，添加到结果中
        result.add(node);
      }
    }
    
    return result;
  }

  /// 搜索文件
  void _searchFiles(String query) {
    setState(() {
      // 更新搜索查询
    });
  }

  /// 显示上下文菜单
  void _showContextMenu(BuildContext context, FileNode node) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox button = context.findRenderObject() as RenderBox;
    final position = button.localToGlobal(Offset.zero, ancestor: overlay);
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position.translate(button.size.width, button.size.height)),
        Offset.zero & overlay.size,
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
      ],
    ).then((value) {
      if (value == null) return;
      
      switch (value) {
        case 'open':
          // 打开文件
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('添加到收藏夹功能开发中')),
          );
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
}

/// 可见节点
class _VisibleNode {
  final FileNode node;
  final int level;

  _VisibleNode({
    required this.node,
    required this.level,
  });
} 