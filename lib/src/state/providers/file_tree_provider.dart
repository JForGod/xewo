import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../models/file_node.dart';
import '../../services/file/file_tree_service.dart';

/// 文件树状态
class FileTreeState {
  /// 是否正在加载
  final bool isLoading;
  
  /// 错误信息
  final String? error;
  
  /// 根节点
  final FileNode? rootNode;
  
  /// 展开的路径集合
  final Set<String> expandedPaths;
  
  /// 搜索查询
  final String? searchQuery;
  
  /// 搜索结果
  final List<FileNode> searchResults;
  
  /// 选择的路径
  final String? selectedPath;
  
  /// 构造函数
  const FileTreeState({
    this.isLoading = false,
    this.error,
    this.rootNode,
    this.expandedPaths = const {},
    this.searchQuery,
    this.searchResults = const [],
    this.selectedPath,
  });
  
  /// 创建副本
  FileTreeState copyWith({
    bool? isLoading,
    String? error,
    FileNode? rootNode,
    Set<String>? expandedPaths,
    String? searchQuery,
    List<FileNode>? searchResults,
    String? selectedPath,
    bool clearError = false,
    bool clearRootNode = false,
  }) {
    return FileTreeState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      rootNode: clearRootNode ? null : (rootNode ?? this.rootNode),
      expandedPaths: expandedPaths ?? this.expandedPaths,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      selectedPath: selectedPath ?? this.selectedPath,
    );
  }
  
  /// 获取所有节点（扁平列表）
  List<FileNode> getAllNodes() {
    if (rootNode == null) return [];
    return rootNode!.getAllNodes();
  }
  
  /// 根据路径获取节点
  FileNode? getNodeByPath(String nodePath) {
    if (rootNode == null) return null;
    return rootNode!.findNode(nodePath);
  }
}

/// 文件树状态提供者
final fileTreeProvider = StateNotifierProvider<FileTreeNotifier, FileTreeState>((ref) {
  final fileTreeService = ref.watch(fileTreeServiceProvider);
  return FileTreeNotifier(fileTreeService);
});

class FileTreeNotifier extends StateNotifier<FileTreeState> {
  final FileTreeService _fileTreeService;
  
  FileTreeNotifier(this._fileTreeService) : super(const FileTreeState());
  
  /// 加载目录
  Future<void> loadDirectory(String path) async {
    if (state.rootNode?.path == path) return; // 如果是同一个目录，不重新加载
    
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );
    
    try {
      final rootNode = await _fileTreeService.loadDirectory(path);
      state = state.copyWith(
        isLoading: false,
        rootNode: rootNode,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// 刷新当前目录
  Future<void> refresh() async {
    if (state.rootNode == null) return;
    
    final currentPath = state.rootNode!.path;
    final expandedPaths = state.expandedPaths;
    
    await loadDirectory(currentPath);
    
    // 恢复展开状态
    state = state.copyWith(
      expandedPaths: expandedPaths,
    );
  }
  
  /// 切换节点展开状态
  void toggleNodeExpansion(String path) {
    if (state.rootNode == null) return;
    
    final node = state.rootNode!.findNode(path);
    if (node == null) return;
    
    final expandedPaths = Set<String>.from(state.expandedPaths);
    if (expandedPaths.contains(path)) {
      expandedPaths.remove(path);
    } else {
      expandedPaths.add(path);
    }
    
    state = state.copyWith(expandedPaths: expandedPaths);
  }
  
  /// 检查节点是否展开
  bool isNodeExpanded(String nodePath) {
    return state.expandedPaths.contains(nodePath);
  }
  
  /// 搜索文件
  void searchFiles(String query) {
    if (state.rootNode == null || query.isEmpty) {
      state = state.copyWith(
        searchQuery: null,
        searchResults: [],
        isLoading: false,
      );
      return;
    }
    
    final results = <FileNode>[];
    final allNodes = state.getAllNodes();
    
    for (final node in allNodes) {
      if (node.name.toLowerCase().contains(query.toLowerCase())) {
        results.add(node);
      }
    }
    
    state = state.copyWith(
      searchQuery: query,
      searchResults: results,
      isLoading: false,
    );
  }
  
  /// 清除搜索
  void clearSearch() {
    state = state.copyWith(
      searchQuery: null,
      searchResults: [],
    );
  }
  
  /// 创建文件
  Future<void> createFile(String parentPath, String fileName) async {
    try {
      final filePath = path.join(parentPath, fileName);
      final file = File(filePath);
      await file.create(recursive: true);
      await refresh();
    } catch (e) {
      state = state.copyWith(
        error: '创建文件失败: $e',
      );
    }
  }
  
  /// 创建目录
  Future<void> createDirectory(String parentPath, String dirName) async {
    try {
      final dirPath = path.join(parentPath, dirName);
      final directory = Directory(dirPath);
      await directory.create(recursive: true);
      await refresh();
    } catch (e) {
      state = state.copyWith(
        error: '创建目录失败: $e',
      );
    }
  }
  
  /// 重命名文件或目录
  Future<void> renameFileOrDirectory(String oldPath, String newName) async {
    try {
      await _fileTreeService.rename(oldPath, newName);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  /// 移动文件或目录
  Future<void> moveFileOrDirectory(String sourcePath, String targetPath) async {
    try {
      await _fileTreeService.move(sourcePath, targetPath);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  /// 展开所有节点
  void expandAll() {
    if (state.rootNode == null) return;
    
    final expandedPaths = Set<String>.from(state.expandedPaths);
    _expandAllNodes(state.rootNode!, expandedPaths);
    
    state = state.copyWith(expandedPaths: expandedPaths);
  }
  
  /// 递归展开所有节点
  void _expandAllNodes(FileNode node, Set<String> expandedPaths) {
    if (node.type == FileNodeType.directory) {
      expandedPaths.add(node.path);
      for (final child in node.children) {
        _expandAllNodes(child, expandedPaths);
      }
    }
  }
  
  /// 折叠所有节点
  void collapseAll() {
    if (state.rootNode == null) return;
    
    // 保留根节点的展开状态
    final expandedPaths = {state.rootNode!.path};
    
    state = state.copyWith(expandedPaths: expandedPaths);
  }
  
  /// 复制文件或目录
  Future<void> copyFileOrDirectory(String sourcePath, String targetPath) async {
    try {
      await _fileTreeService.copy(sourcePath, targetPath);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  /// 删除文件或目录
  Future<void> deleteFileOrDirectory(String path) async {
    try {
      await _fileTreeService.delete(path);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  void selectFile(String path) {
    state = state.copyWith(selectedPath: path);
  }
} 