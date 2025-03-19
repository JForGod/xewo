import 'package:flutter/material.dart';

/// 文件树节点类型
enum FileNodeType {
  /// 文件
  file,
  
  /// 文件夹
  folder,
}

/// 文件树节点
class FileNode {
  /// 节点名称
  final String name;
  
  /// 节点路径
  final String path;
  
  /// 节点类型
  final FileNodeType type;
  
  /// 子节点
  final List<FileNode> children;
  
  /// 是否展开
  bool isExpanded;
  
  /// 构造函数
  FileNode({
    required this.name,
    required this.path,
    required this.type,
    this.children = const [],
    this.isExpanded = false,
  });
  
  /// 添加子节点
  void addChild(FileNode child) {
    if (type == FileNodeType.folder) {
      children.add(child);
    }
  }
  
  /// 移除子节点
  void removeChild(String path) {
    if (type == FileNodeType.folder) {
      children.removeWhere((node) => node.path == path);
    }
  }
  
  /// 查找子节点
  FileNode? findChild(String path) {
    if (this.path == path) {
      return this;
    }
    
    if (type == FileNodeType.folder) {
      for (final child in children) {
        final result = child.findChild(path);
        if (result != null) {
          return result;
        }
      }
    }
    
    return null;
  }
  
  /// 切换展开状态
  void toggleExpanded() {
    if (type == FileNodeType.folder) {
      isExpanded = !isExpanded;
    }
  }
}

/// 文件树状态管理类
class FileTreeState extends ChangeNotifier {
  /// 根节点
  FileNode? _root;
  
  /// 是否显示文件树
  final ValueNotifier<bool> showFileTree = ValueNotifier<bool>(true);
  
  /// 当前选中节点路径
  String? _selectedPath;
  
  /// 获取根节点
  FileNode? get root => _root;
  
  /// 获取当前选中节点路径
  String? get selectedPath => _selectedPath;
  
  /// 设置根节点
  set root(FileNode? node) {
    _root = node;
    notifyListeners();
  }
  
  /// 设置当前选中节点路径
  set selectedPath(String? path) {
    _selectedPath = path;
    notifyListeners();
  }
  
  /// 切换文件树显示
  void toggleFileTree() {
    showFileTree.value = !showFileTree.value;
    notifyListeners();
  }
  
  /// 展开节点
  void expandNode(String path) {
    final node = _root?.findChild(path);
    if (node != null && node.type == FileNodeType.folder) {
      node.isExpanded = true;
      notifyListeners();
    }
  }
  
  /// 折叠节点
  void collapseNode(String path) {
    final node = _root?.findChild(path);
    if (node != null && node.type == FileNodeType.folder) {
      node.isExpanded = false;
      notifyListeners();
    }
  }
  
  /// 切换节点展开状态
  void toggleNodeExpanded(String path) {
    final node = _root?.findChild(path);
    if (node != null && node.type == FileNodeType.folder) {
      node.isExpanded = !node.isExpanded;
      notifyListeners();
    }
  }
  
  /// 全部展开
  void expandAll() {
    _expandAll(_root);
    notifyListeners();
  }
  
  /// 全部折叠
  void collapseAll() {
    _collapseAll(_root);
    notifyListeners();
  }
  
  /// 递归展开所有节点
  void _expandAll(FileNode? node) {
    if (node == null) {
      return;
    }
    
    if (node.type == FileNodeType.folder) {
      node.isExpanded = true;
      for (final child in node.children) {
        _expandAll(child);
      }
    }
  }
  
  /// 递归折叠所有节点
  void _collapseAll(FileNode? node) {
    if (node == null) {
      return;
    }
    
    if (node.type == FileNodeType.folder) {
      node.isExpanded = false;
      for (final child in node.children) {
        _collapseAll(child);
      }
    }
  }
} 