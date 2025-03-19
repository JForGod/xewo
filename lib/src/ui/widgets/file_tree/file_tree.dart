import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import '../../../state/providers/file_tree_provider.dart';
import '../../../services/file/file_service.dart';
import '../../../state/models/file_node.dart';
import '../../themes/app_theme.dart';
import 'file_tree_context_menu.dart';
import 'file_tree_node.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'dart:async';
import '../../../services/file/file_tree_service.dart';
import '../../../services/settings/settings_service.dart';
import 'file_tree_toolbar.dart';
import 'views/file_explorer_view.dart';
import 'views/search_view.dart';
import 'file_tree_toolbar_controller.dart';
import 'package:flutter/foundation.dart';
import 'views/source_control_view.dart';
import 'views/run_debug_view.dart';
import 'views/extensions_view.dart';

/// 简化版文件树组件
class FileTree extends ConsumerStatefulWidget {
  const FileTree({
    super.key,
    this.onFileSelected,
    this.onToggleVisibility,
    this.enableSmartHide = true,
    this.hideDelay = const Duration(seconds: 3),
  });

  final Function(String)? onFileSelected;
  final VoidCallback? onToggleVisibility;
  final bool enableSmartHide;
  final Duration hideDelay;

  @override
  ConsumerState<FileTree> createState() => _FileTreeState();
}

class _FileTreeState extends ConsumerState<FileTree> with SingleTickerProviderStateMixin {
  final FocusNode _treeFocusNode = FocusNode();
  Set<String> _selectedPaths = {};
  String? _lastSelectedPath;
  bool _isCtrlPressed = false;
  bool _isShiftPressed = false;
  String? _clipboardPath;
  bool _isCut = false;
  late AnimationController _animationController;
  Timer? _hideTimer;
  final _isVisible = ValueNotifier<bool>(true);
  bool _isHovered = false;
  bool _isMouseNearEdge = false;
  final double _edgeThreshold = 20.0;
  DateTime _lastActivityTime = DateTime.now();
  bool _isEditorFocused = false;
  bool _isFullScreen = false;
  bool _isSystemLowMemory = false;
  String _currentRootPath = '';
  bool _hasLoadedProject = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.value = 1.0;
    _setupKeyboardShortcuts();
    _setupSystemMonitor();
    
    // 在初始化时加载上次打开的项目
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLastOpenedProject();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _animationController.dispose();
    _isVisible.dispose();
    super.dispose();
  }

  void _setupKeyboardShortcuts() {
    RawKeyboard.instance.addListener(_handleKeyPress);
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // Ctrl/Cmd + B 切换文件树显示
      if ((event.isControlPressed || event.isMetaPressed) &&
          event.logicalKey == LogicalKeyboardKey.keyB) {
        _toggleVisibility();
      }
    }
  }

  void _setupSystemMonitor() {
    // 监控系统资源
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _checkSystemResources();
    });
  }

  void _checkSystemResources() async {
    try {
      // 这里可以添加更多系统资源检查
      final memoryInfo = await Process.run('wmic', ['OS', 'get', 'FreePhysicalMemory']);
      if (memoryInfo.exitCode == 0 && memoryInfo.stdout is String) {
        final freeMemory = int.tryParse(
          (memoryInfo.stdout as String)
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .last
              .trim()
        );
        if (freeMemory != null && mounted) {
          setState(() {
            _isSystemLowMemory = freeMemory < 1024 * 1024; // 小于1GB时认为内存不足
          });
        }
      }
    } catch (e) {
      debugPrint('检查系统资源失败: $e');
    }
  }

  void _startHideTimer() {
    if (!widget.enableSmartHide) return;
    
    _hideTimer?.cancel();
    _hideTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final fileTreeState = ref.read(fileTreeProvider);
      // 只有在文件树加载完成且有根节点时才开始计时
      if (!fileTreeState.isLoading && fileTreeState.rootNode != null) {
        final now = DateTime.now();
        final timeSinceActivity = now.difference(_lastActivityTime);
        
        // 检查自动隐藏条件
        if (_shouldHideFileTree(timeSinceActivity)) {
          setState(() => _isVisible.value = false);
          widget.onToggleVisibility?.call();
        }
      }
    });
  }

  bool _shouldHideFileTree(Duration timeSinceActivity) {
    if (!_isVisible.value || _isMouseNearEdge) return false;
    
    return timeSinceActivity >= widget.hideDelay || // 超过无操作时间
           _isEditorFocused || // 编辑器获得焦点
           _isFullScreen || // 全屏模式
           _isSystemLowMemory; // 系统资源紧张
  }

  void _handleEditorFocusChanged(bool focused) {
    if (!mounted) return;
    setState(() => _isEditorFocused = focused);
    _updateActivityTime();
  }

  void _handleFullScreenChanged(bool isFullScreen) {
    if (!mounted) return;
    setState(() => _isFullScreen = isFullScreen);
    if (isFullScreen) {
      setState(() => _isVisible.value = false);
    }
  }

  void _updateActivityTime() {
    if (!mounted) return;
    _lastActivityTime = DateTime.now();
    if (!_isVisible.value && (_isMouseNearEdge || !_shouldHideFileTree(Duration.zero))) {
      setState(() => _isVisible.value = true);
      widget.onToggleVisibility?.call();
    }
  }

  void _handleMouseMovement(PointerEvent event) {
    if (!mounted) return;
    final isNearEdge = event.position.dx <= _edgeThreshold;
    if (isNearEdge != _isMouseNearEdge) {
      setState(() => _isMouseNearEdge = isNearEdge);
      if (isNearEdge && !_isVisible.value) {
        setState(() => _isVisible.value = true);
        widget.onToggleVisibility?.call();
      }
    }
    _updateActivityTime();
  }

  void _toggleVisibility() {
    if (!mounted) return;
    
    final bool newVisibility = !_isVisible.value;
    if (newVisibility == _isVisible.value) return;
    
    // 保存当前状态，但不触发重建
    final currentState = ref.read(fileTreeProvider);
    
    _isVisible.value = newVisibility;
    
    if (newVisibility) {
      // 只有在文件树加载完成且有根节点时才启动定时器
      if (!currentState.isLoading && currentState.rootNode != null) {
        _startHideTimer();
      }
    } else {
      _hideTimer?.cancel();
    }
    
    // 通知父组件状态变化，但不重新加载文件树
    if (mounted && widget.onToggleVisibility != null) {
      widget.onToggleVisibility!();
    }
  }

  // 选择目录
  Future<void> _selectDirectory() async {
    final directory = await FilePicker.platform.getDirectoryPath();
    if (directory != null) {
      await ref.read(fileTreeProvider.notifier).loadDirectory(directory);
      setState(() {
        _currentRootPath = directory;
      });
      
      // 保存当前项目路径
      await _saveCurrentProjectPath(directory);
    }
  }

  // 创建新文件夹
  Future<void> _createNewFolder() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入文件夹名称',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final controller = TextEditingController();
              Navigator.of(context).pop(controller.text);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final state = ref.read(fileTreeProvider);
      if (state.rootNode == null) return;

      final parentPath = state.rootNode!.path;
      final newFolderPath = path.join(parentPath, result);

      try {
        await Directory(newFolderPath).create();
        await ref.read(fileTreeProvider.notifier).refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建文件夹失败: $e')),
          );
        }
      }
    }
  }

  // 创建新文件
  Future<void> _createNewFile() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文件'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入文件名',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final controller = TextEditingController();
              Navigator.of(context).pop(controller.text);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final state = ref.read(fileTreeProvider);
      if (state.rootNode == null) return;

      final parentPath = state.rootNode!.path;
      final newFilePath = path.join(parentPath, result);

      try {
        await File(newFilePath).create();
        await ref.read(fileTreeProvider.notifier).refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建文件失败: $e')),
          );
        }
      }
    }
  }

  // 获取选中的目录路径
  String _getSelectedDirectoryPath() {
    final fileTreeState = ref.read(fileTreeProvider);
    if (fileTreeState.rootNode == null) {
      return 'H:\\AxE\\xewo';
    }
    
    if (_selectedPaths.isEmpty) {
      return fileTreeState.rootNode!.path;
    }
    
    final selectedPath = _selectedPaths.first;
    final selectedNode = fileTreeState.getNodeByPath(selectedPath);
    
    if (selectedNode == null) {
      return fileTreeState.rootNode!.path;
    }
    
    return selectedNode.type == FileNodeType.directory
        ? selectedNode.path
        : path.dirname(selectedNode.path);
  }

  // 处理键盘事件
  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      setState(() {
        _isCtrlPressed = event.isControlPressed;
        _isShiftPressed = event.isShiftPressed;
      });
      
      // 处理方向键导航
      if (_handleArrowKeys(event)) {
        return;
      }
    } else if (event is RawKeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.control) {
        setState(() {
          _isCtrlPressed = false;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.shift) {
        setState(() {
          _isShiftPressed = false;
        });
      }
    }
  }
  
  // 处理方向键导航
  bool _handleArrowKeys(RawKeyDownEvent event) {
    final fileTreeState = ref.read(fileTreeProvider);
    if (fileTreeState.rootNode == null) return false;
    
    // 获取所有可见节点
    List<FileNode> visibleNodes = _getVisibleNodes(fileTreeState.rootNode!);
    if (visibleNodes.isEmpty) return false;
    
    // 查找当前选中节点的索引
    int currentIndex = -1;
    if (_selectedPaths.isNotEmpty) {
      String currentPath = _selectedPaths.first;
      currentIndex = visibleNodes.indexWhere((node) => node.path == currentPath);
    }
    
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      // 向上移动选择
      if (currentIndex > 0) {
        _selectSingleNode(visibleNodes[currentIndex - 1]);
      } else if (currentIndex == -1 && visibleNodes.isNotEmpty) {
        // 如果之前没有选中，则选择第一个节点
        _selectSingleNode(visibleNodes.first);
      }
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      // 向下移动选择
      if (currentIndex < visibleNodes.length - 1 && currentIndex != -1) {
        _selectSingleNode(visibleNodes[currentIndex + 1]);
      } else if (currentIndex == -1 && visibleNodes.isNotEmpty) {
        // 如果之前没有选中，则选择第一个节点
        _selectSingleNode(visibleNodes.first);
      }
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      // 向右展开目录
      if (currentIndex != -1 && visibleNodes[currentIndex].type == FileNodeType.directory) {
        FileNode currentNode = visibleNodes[currentIndex];
        if (!ref.read(fileTreeProvider.notifier).isNodeExpanded(currentNode.path)) {
          _toggleNodeExpansion(currentNode);
        }
      }
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      // 向左折叠目录或者移动到父目录
      if (currentIndex != -1) {
        FileNode currentNode = visibleNodes[currentIndex];
        if (currentNode.type == FileNodeType.directory && 
            ref.read(fileTreeProvider.notifier).isNodeExpanded(currentNode.path)) {
          // 如果是展开的目录，则折叠它
          _toggleNodeExpansion(currentNode);
        } else {
          // 如果是文件或折叠的目录，则选择父目录
          String parentPath = path.dirname(currentNode.path);
          FileNode? parentNode = fileTreeState.getNodeByPath(parentPath);
          if (parentNode != null) {
            _selectSingleNode(parentNode);
          }
        }
      }
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      // Enter键打开文件或切换目录展开状态
      if (currentIndex != -1) {
        FileNode currentNode = visibleNodes[currentIndex];
        if (currentNode.type == FileNodeType.directory) {
          _toggleNodeExpansion(currentNode);
        } else if (currentNode.type == FileNodeType.file && widget.onFileSelected != null) {
          widget.onFileSelected!(currentNode.path);
        }
      }
      return true;
    }
    
    return false;
  }
  
  // 获取所有可见节点（按照显示顺序）
  List<FileNode> _getVisibleNodes(FileNode rootNode) {
    List<FileNode> result = [];
    _addVisibleNodes(rootNode, result, true);
    return result;
  }
  
  // 递归添加可见节点
  void _addVisibleNodes(FileNode node, List<FileNode> result, bool isRoot) {
    // 根节点不添加到结果中，因为文件树UI中不显示根节点
    if (!isRoot) {
      result.add(node);
    }
    
    // 如果是目录且已展开，则添加其子节点
    if (node.type == FileNodeType.directory && 
        (isRoot || ref.read(fileTreeProvider.notifier).isNodeExpanded(node.path))) {
      for (var child in node.children) {
        _addVisibleNodes(child, result, false);
      }
    }
  }
  
  // 选择单个节点
  void _selectSingleNode(FileNode node) {
    setState(() {
      _selectedPaths = {node.path};
      _lastSelectedPath = node.path;
    });
    
    // 如果是文件，则调用选择回调
    if (node.type == FileNodeType.file && widget.onFileSelected != null) {
      widget.onFileSelected!(node.path);
    }
  }

  // 处理右键菜单
  void _handleContextMenu(BuildContext context, Offset position, FileNode node) {
    showFileTreeContextMenu(
      context: context,
      position: position,
      node: node,
      selectedPaths: _selectedPaths,
      onRename: () => _renameNode(node),
      onDelete: () => _deleteNode(node),
      onCreateFile: () => _createNewFile(),
      onCreateFolder: () => _createNewFolder(),
      onCopy: () => _copyNode(node),
      onCut: () => _cutNode(node),
      onPaste: () => _pasteNode(node),
    );
  }
  
  // 重命名节点
  void _renameNode(FileNode node) {
    final TextEditingController controller = TextEditingController(text: node.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入新名称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != node.name) {
                ref.read(fileTreeProvider.notifier).renameFileOrDirectory(node.path, newName);
              }
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  // 删除节点
  void _deleteNode(FileNode node) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${node.name}" 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(fileTreeProvider.notifier).deleteFileOrDirectory(node.path);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
  
  // 复制节点
  void _copyNode(FileNode node) {
    setState(() {
      _clipboardPath = node.path;
      _isCut = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制: ${node.name}')),
    );
  }
  
  // 剪切节点
  void _cutNode(FileNode node) {
    setState(() {
      _clipboardPath = node.path;
      _isCut = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已剪切: ${node.path}')),
    );
  }
  
  // 粘贴节点
  void _pasteNode(FileNode targetNode) {
    if (_clipboardPath == null) return;
    
    if (targetNode.type != FileNodeType.directory) return;
    
    if (_isCut) {
      ref.read(fileTreeProvider.notifier).moveFileOrDirectory(_clipboardPath!, targetNode.path);
      setState(() {
        _clipboardPath = null;
      });
    } else {
      ref.read(fileTreeProvider.notifier).copyFileOrDirectory(_clipboardPath!, targetNode.path);
    }
  }
  
  // 处理拖放完成
  void _handleDragCompleted(String sourcePath, String targetPath) {
    if (sourcePath == targetPath) return;
    
    ref.read(fileTreeProvider.notifier).moveFileOrDirectory(sourcePath, targetPath);
  }

  // 切换节点展开状态
  void _toggleNodeExpansion(FileNode node) {
    if (node.type == FileNodeType.directory) {
      ref.read(fileTreeProvider.notifier).toggleNodeExpansion(node.path);
    }
  }

  // 处理外部文件拖放
  Future<void> _handleExternalDrop(dynamic event) async {
    try {
      final List<XFile> files = event.files.map<XFile>((file) => XFile(file.path)).toList();
      if (files.isEmpty) return;
      
      final fileService = ref.read(fileServiceProvider);
      final targetPath = _getSelectedDirectoryPath();
      
      for (final file in files) {
        if (file.path == null) continue;
        
        // 检查文件类型
        if (!await _isValidFile(file.path)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('不支持的文件类型: ${file.name}')),
            );
          }
          continue;
        }
        
        // 复制文件到目标目录
        final newPath = path.join(targetPath, file.name);
        await fileService.copyFile(file.path, newPath);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已导入文件: ${file.name}')),
          );
        }
      }
      
      // 刷新文件树
      ref.read(fileTreeProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入文件失败: $e')),
        );
      }
    }
  }
  
  Future<bool> _isValidFile(String filePath) async {
    // 检查文件大小
    final file = File(filePath);
    final size = await file.length();
    if (size > 100 * 1024 * 1024) { // 100MB
      return false;
    }
    
    // 检查文件类型
    final extension = path.extension(filePath).toLowerCase();
    final validExtensions = [
      '.txt', '.md', '.json', '.yaml', '.yml',
      '.dart', '.js', '.ts', '.html', '.css',
      '.py', '.java', '.kt', '.cpp', '.h',
      '.go', '.rs', '.rb', '.php', '.sql',
      '.xml', '.toml', '.ini', '.conf', '.sh',
      '.bat', '.ps1', '.log', '.csv', '.properties',
    ];
    
    return validExtensions.contains(extension);
  }

  // 加载上次打开的项目
  Future<void> _loadLastOpenedProject() async {
    try {
      // 如果已经加载过项目且当前有根路径，则不需要重新加载
      if (_hasLoadedProject && _currentRootPath.isNotEmpty) {
        final fileTreeState = ref.read(fileTreeProvider);
        if (fileTreeState.rootNode != null) {
          return; // 已经有加载的项目，不需要重新加载
        }
      }
      
      final settingsService = ref.read(settingsServiceProvider);
      await settingsService.initialize();
      final lastProjectPath = await settingsService.getLastOpenedProjectPath();
      
      if (lastProjectPath != null && lastProjectPath.isNotEmpty) {
        // 检查目录是否存在
        final directory = Directory(lastProjectPath);
        if (await directory.exists()) {
          // 加载上次打开的项目
          await ref.read(fileTreeProvider.notifier).loadDirectory(lastProjectPath);
          if (mounted) {
            setState(() {
              _currentRootPath = lastProjectPath;
              _hasLoadedProject = true;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('加载上次打开的项目失败: $e');
    }
  }

  // 保存当前项目路径
  Future<void> _saveCurrentProjectPath(String path) async {
    try {
      final settingsService = ref.read(settingsServiceProvider);
      await settingsService.initialize();
      await settingsService.saveLastOpenedProjectPath(path);
      // 同时添加到最近项目列表
      await settingsService.addToRecentProjects(path);
    } catch (e) {
      debugPrint('保存项目路径失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentView = ref.watch(fileTreeViewProvider);
    
    return Column(
      children: [
        const FileTreeToolbar(),
        Expanded(
          child: MouseRegion(
            onHover: _handleMouseMovement,
            child: Stack(
              children: [
                // 内容区域 - 根据当前视图显示不同的内容
                SizedBox(
                  width: 280,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: RepaintBoundary(
                      child: _buildContent(currentView),
                    ),
                  ),
                ),
                // 遮罩层 - 只处理显示/隐藏动画
                ValueListenableBuilder<bool>(
                  valueListenable: _isVisible,
                  builder: (context, isVisible, child) {
                    return AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: isVisible ? 280 : 0,
                      top: 0,
                      bottom: 0,
                      width: 280,
                      child: Container(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 根据当前视图构建内容
  Widget _buildContent(FileTreeView currentView) {
    try {
      switch (currentView) {
        case FileTreeView.fileBrowser:
          return _buildFileTree(context);
        case FileTreeView.search:
          return const SearchView();
        case FileTreeView.sourceControl:
          return const SourceControlView();
        case FileTreeView.runDebug:
          return const RunDebugView();
        case FileTreeView.extensions:
          return const ExtensionsView();
        default:
          return _buildFileTree(context);
      }
    } catch (e, stackTrace) {
      debugPrint('Error building content for view $currentView: $e\n$stackTrace');
      // 返回一个错误视图，而不是让整个应用崩溃
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '加载视图时出错',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFileTree(BuildContext context) {
    // 使用 select 只监听必要的状态
    final isLoading = ref.watch(fileTreeProvider.select((state) => state.isLoading));
    final rootNode = ref.watch(fileTreeProvider.select((state) => state.rootNode));
    
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (rootNode == null) {
      return _buildEmptyState();
    }
    
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // 防止滚动事件冒泡
        return true;
      },
      child: KeyedSubtree(
        key: ValueKey(rootNode.path),
        child: _buildFileTreeContent(rootNode),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '没有打开的项目',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _selectDirectory,
            icon: const Icon(Icons.folder_open, size: 16),
            label: const Text('选择文件夹'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTreeContent(FileNode rootNode) {
    // 使用 select 只监听展开状态
    final expandedPaths = ref.watch(fileTreeProvider.select((state) => state.expandedPaths));
    
    return ListView.builder(
      itemCount: rootNode.children.length,
      itemBuilder: (context, index) {
        final node = rootNode.children[index];
        return FileTreeNodeWidget(
          key: ValueKey(node.path), // 添加 key 以优化重建
          node: node,
          depth: 0,
          isSelected: _selectedPaths.contains(node.path),
          isExpanded: expandedPaths.contains(node.path),
          onTap: () => _handleNodeTap(node),
          onDoubleTap: () => _handleNodeDoubleTap(node),
          onExpand: () => _toggleNodeExpansion(node),
          onRightClick: (offset) => _handleContextMenu(context, offset, node),
        );
      },
    );
  }

  // 处理节点点击
  void _handleNodeTap(FileNode node) {
    setState(() {
      if (_isCtrlPressed) {
        // Ctrl + 点击：切换选择
        if (_selectedPaths.contains(node.path)) {
          _selectedPaths.remove(node.path);
          if (node.path == _lastSelectedPath) {
            _lastSelectedPath = _selectedPaths.isEmpty ? null : _selectedPaths.last;
          }
        } else {
          _selectedPaths.add(node.path);
          _lastSelectedPath = node.path;
        }
      } else if (_isShiftPressed && _lastSelectedPath != null) {
        // Shift + 点击：范围选择
        final allNodes = ref.read(fileTreeProvider).getAllNodes();
        final lastIndex = allNodes.indexWhere((n) => n.path == _lastSelectedPath);
        final currentIndex = allNodes.indexWhere((n) => n.path == node.path);
        
        if (lastIndex != -1 && currentIndex != -1) {
          final start = lastIndex < currentIndex ? lastIndex : currentIndex;
          final end = lastIndex < currentIndex ? currentIndex : lastIndex;
          
          _selectedPaths = allNodes
              .sublist(start, end + 1)
              .map((n) => n.path)
              .toSet();
        }
      } else {
        // 普通点击：单选
        _selectedPaths = {node.path};
        _lastSelectedPath = node.path;
      }
    });
  }
  
  // 处理节点双击
  void _handleNodeDoubleTap(FileNode node) {
    if (node.type == FileNodeType.file) {
      widget.onFileSelected?.call(node.path);
    } else {
      _toggleNodeExpansion(node);
    }
  }
} 