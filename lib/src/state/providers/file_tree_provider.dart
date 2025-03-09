import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../services/core/file_system_service.dart';

/// 文件树节点模型
class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  final List<FileNode> children;

  const FileNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.children = const [],
  });

  // 从FileSystemEntity创建FileNode
  static FileNode fromEntity(FileSystemEntity entity) {
    return FileNode(
      name: path.basename(entity.path),
      path: entity.path,
      isDirectory: entity is Directory,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileNode && other.path == path;
  }
  
  @override
  int get hashCode => path.hashCode;
}

/// 文件树状态
class FileTreeState {
  final List<FileNode> nodes;
  final String? selectedPath;
  final bool isLoading;
  final String? error;
  final String? currentDirectory;
  final Set<String> expandedPaths;
  final Set<String> selectedPaths; // 多选路径集合
  final bool isMultiSelectMode; // 是否处于多选模式

  const FileTreeState({
    this.nodes = const [],
    this.selectedPath,
    this.isLoading = false,
    this.error,
    this.currentDirectory,
    this.expandedPaths = const {},
    this.selectedPaths = const {},
    this.isMultiSelectMode = false,
  });

  FileTreeState copyWith({
    List<FileNode>? nodes,
    String? selectedPath,
    bool? isLoading,
    String? error,
    String? currentDirectory,
    Set<String>? expandedPaths,
    Set<String>? selectedPaths,
    bool? isMultiSelectMode,
  }) {
    return FileTreeState(
      nodes: nodes ?? this.nodes,
      selectedPath: selectedPath ?? this.selectedPath,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentDirectory: currentDirectory ?? this.currentDirectory,
      expandedPaths: expandedPaths ?? this.expandedPaths,
      selectedPaths: selectedPaths ?? this.selectedPaths,
      isMultiSelectMode: isMultiSelectMode ?? this.isMultiSelectMode,
    );
  }
}

/// 文件树状态管理
class FileTreeNotifier extends StateNotifier<FileTreeState> {
  final FileSystemService _fileSystemService;

  FileTreeNotifier(this._fileSystemService) : super(const FileTreeState());

  // 加载目录
  Future<void> loadDirectory(String directoryPath) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final entities = await _fileSystemService.listDirectory(directoryPath);
      final nodes = entities
          .map((entity) => FileNode.fromEntity(entity))
          .toList()
          ..sort((a, b) {
            // 目录排在文件前面
            if (a.isDirectory && !b.isDirectory) return -1;
            if (!a.isDirectory && b.isDirectory) return 1;
            // 同类型按名称排序
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
      
      state = state.copyWith(
        nodes: nodes,
        isLoading: false,
        currentDirectory: directoryPath,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '加载目录失败: $e',
      );
    }
  }

  // 选择节点
  void selectNode(String path) {
    if (state.isMultiSelectMode) {
      // 多选模式下，切换选择状态
      final selectedPaths = Set<String>.from(state.selectedPaths);
      if (selectedPaths.contains(path)) {
        selectedPaths.remove(path);
      } else {
        selectedPaths.add(path);
      }
      state = state.copyWith(selectedPaths: selectedPaths);
    } else {
      // 单选模式
      state = state.copyWith(selectedPath: path);
    }
  }
  
  // 切换多选模式
  void toggleMultiSelectMode() {
    final isMultiSelectMode = !state.isMultiSelectMode;
    
    // 进入多选模式时，将当前选中项添加到多选集合
    Set<String> selectedPaths = {};
    if (isMultiSelectMode && state.selectedPath != null) {
      selectedPaths = {state.selectedPath!};
    }
    
    state = state.copyWith(
      isMultiSelectMode: isMultiSelectMode,
      selectedPaths: selectedPaths,
    );
  }
  
  // 清除所有选择
  void clearSelection() {
    state = state.copyWith(
      selectedPath: null,
      selectedPaths: {},
    );
  }
  
  // 获取所有选中的节点
  List<FileNode> getSelectedNodes() {
    if (state.isMultiSelectMode) {
      return _findNodesByPaths(state.nodes, state.selectedPaths);
    } else if (state.selectedPath != null) {
      return _findNodesByPaths(state.nodes, {state.selectedPath!});
    }
    return [];
  }
  
  // 根据路径查找节点
  List<FileNode> _findNodesByPaths(List<FileNode> nodes, Set<String> paths) {
    final result = <FileNode>[];
    
    for (final node in nodes) {
      if (paths.contains(node.path)) {
        result.add(node);
      }
      
      if (node.isDirectory && node.children.isNotEmpty) {
        result.addAll(_findNodesByPaths(node.children, paths));
      }
    }
    
    return result;
  }

  // 展开/折叠节点
  void toggleNodeExpansion(String path) {
    final expandedPaths = Set<String>.from(state.expandedPaths);
    if (expandedPaths.contains(path)) {
      expandedPaths.remove(path);
    } else {
      expandedPaths.add(path);
      _loadNodeChildren(path);
    }
    state = state.copyWith(expandedPaths: expandedPaths);
  }

  // 加载节点的子节点
  Future<void> _loadNodeChildren(String nodePath) async {
    try {
      final entities = await _fileSystemService.listDirectory(nodePath);
      final children = entities
          .map((entity) => FileNode.fromEntity(entity))
          .toList()
          ..sort((a, b) {
            if (a.isDirectory && !b.isDirectory) return -1;
            if (!a.isDirectory && b.isDirectory) return 1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
      
      // 更新节点的子节点
      final updatedNodes = _updateNodeChildren(state.nodes, nodePath, children);
      state = state.copyWith(nodes: updatedNodes);
    } catch (e) {
      // 加载子节点失败，不更新状态
    }
  }

  // 更新节点的子节点
  List<FileNode> _updateNodeChildren(
    List<FileNode> nodes,
    String nodePath,
    List<FileNode> children,
  ) {
    return nodes.map((node) {
      if (node.path == nodePath) {
        return FileNode(
          name: node.name,
          path: node.path,
          isDirectory: node.isDirectory,
          children: children,
        );
      } else if (node.isDirectory && node.children.isNotEmpty) {
        return FileNode(
          name: node.name,
          path: node.path,
          isDirectory: node.isDirectory,
          children: _updateNodeChildren(node.children, nodePath, children),
        );
      } else {
        return node;
      }
    }).toList();
  }
  
  // 移动文件/文件夹
  Future<void> moveNodes(List<FileNode> sourceNodes, FileNode targetNode) async {
    if (!targetNode.isDirectory) return;
    
    try {
      state = state.copyWith(isLoading: true);
      
      for (final sourceNode in sourceNodes) {
        final targetPath = path.join(targetNode.path, sourceNode.name);
        
        // 检查是否是移动到自身或子目录
        if (sourceNode.isDirectory && targetPath.startsWith(sourceNode.path)) {
          continue; // 跳过无效的移动
        }
        
        await _fileSystemService.moveFileOrDirectory(sourceNode.path, targetPath);
      }
      
      // 重新加载目录
      await loadDirectory(state.currentDirectory!);
      
      // 清除选择
      if (state.isMultiSelectMode) {
        state = state.copyWith(selectedPaths: {});
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '移动文件失败: $e',
      );
    }
  }
}

/// 文件树提供者
final fileTreeProvider = StateNotifierProvider<FileTreeNotifier, FileTreeState>((ref) {
  final fileSystemService = FileSystemService();
  return FileTreeNotifier(fileSystemService);
}); 