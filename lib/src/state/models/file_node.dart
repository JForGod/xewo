import 'dart:io';
import 'package:path/path.dart' as p;

/// 文件节点类型
enum FileNodeType {
  /// 文件
  file,
  
  /// 目录
  directory,
}

/// 文件节点模型
class FileNode {
  /// 节点路径
  final String path;
  
  /// 节点名称
  final String name;
  
  /// 节点类型
  final FileNodeType type;
  
  /// 子节点列表
  final List<FileNode> children;
  
  /// 最后修改时间
  final DateTime? lastModified;
  
  /// 文件大小（字节）
  final int? size;
  
  /// 是否正在加载
  final bool isLoading;
  
  /// 错误信息
  final String? error;
  
  /// 文件扩展名
  final String? extension;
  
  /// 构造函数
  const FileNode({
    required this.path,
    required this.name,
    required this.type,
    this.children = const [],
    this.lastModified,
    this.size,
    this.isLoading = false,
    this.error,
    this.extension,
  });
  
  /// 从文件系统实体创建节点
  static Future<FileNode> fromEntity(FileSystemEntity entity) async {
    final stat = await entity.stat();
    final name = p.basename(entity.path);
    
    if (entity is Directory) {
      return FileNode(
        path: entity.path,
        name: name,
        type: FileNodeType.directory,
        lastModified: stat.modified,
      );
    } else {
      return FileNode(
        path: entity.path,
        name: name,
        type: FileNodeType.file,
        lastModified: stat.modified,
        size: stat.size,
      );
    }
  }
  
  /// 从目录创建节点（包括子节点）
  static Future<FileNode> fromDirectory(Directory directory, {bool recursive = true}) async {
    final node = await fromEntity(directory);
    
    if (recursive) {
      try {
        final List<FileNode> children = [];
        final entities = await directory.list().toList();
        
        // 先处理目录
        for (var entity in entities.where((e) => e is Directory)) {
          try {
            children.add(await fromDirectory(entity as Directory));
          } catch (e) {
            // 忽略无法访问的目录
            print('无法访问目录: ${entity.path}, 错误: $e');
          }
        }
        
        // 再处理文件
        for (var entity in entities.where((e) => e is File)) {
          try {
            children.add(await fromEntity(entity));
          } catch (e) {
            // 忽略无法访问的文件
            print('无法访问文件: ${entity.path}, 错误: $e');
          }
        }
        
        // 按名称排序
        children.sort((a, b) {
          // 目录优先
          if (a.type != b.type) {
            return a.type == FileNodeType.directory ? -1 : 1;
          }
          // 按名称排序
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        
        return FileNode(
          path: node.path,
          name: node.name,
          type: node.type,
          children: children,
          lastModified: node.lastModified,
        );
      } catch (e) {
        // 如果无法访问目录内容，返回没有子节点的目录节点
        print('无法访问目录内容: ${directory.path}, 错误: $e');
        return node;
      }
    }
    
    return node;
  }
  
  /// 复制节点
  FileNode copyWith({
    String? path,
    String? name,
    FileNodeType? type,
    List<FileNode>? children,
    DateTime? lastModified,
    int? size,
    bool? isLoading,
    String? error,
    String? extension,
  }) {
    return FileNode(
      path: path ?? this.path,
      name: name ?? this.name,
      type: type ?? this.type,
      children: children ?? this.children,
      lastModified: lastModified ?? this.lastModified,
      size: size ?? this.size,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      extension: extension ?? this.extension,
    );
  }
  
  /// 添加子节点
  FileNode addChild(FileNode child) {
    if (type != FileNodeType.directory) {
      return this;
    }
    
    final newChildren = List<FileNode>.from(children);
    newChildren.add(child);
    
    return copyWith(children: newChildren);
  }
  
  /// 移除子节点
  FileNode removeChild(String childPath) {
    if (type != FileNodeType.directory) {
      return this;
    }
    
    final newChildren = children.where((child) => child.path != childPath).toList();
    
    return copyWith(children: newChildren);
  }
  
  /// 更新子节点
  FileNode updateChild(String childPath, FileNode newChild) {
    if (type != FileNodeType.directory) {
      return this;
    }
    
    final newChildren = List<FileNode>.from(children);
    final index = newChildren.indexWhere((child) => child.path == childPath);
    
    if (index != -1) {
      newChildren[index] = newChild;
    }
    
    return copyWith(children: newChildren);
  }
  
  /// 查找节点
  FileNode? findNode(String nodePath) {
    if (path == nodePath) {
      return this;
    }
    
    if (type != FileNodeType.directory) {
      return null;
    }
    
    for (final child in children) {
      final found = child.findNode(nodePath);
      if (found != null) {
        return found;
      }
    }
    
    return null;
  }
  
  /// 获取所有节点（扁平列表）
  List<FileNode> getAllNodes() {
    final List<FileNode> result = [this];
    
    if (type == FileNodeType.directory) {
      for (final child in children) {
        result.addAll(child.getAllNodes());
      }
    }
    
    return result;
  }
  
  /// 从JSON创建文件节点
  factory FileNode.fromJson(Map<String, dynamic> json) {
    return FileNode(
      name: json['name'] as String,
      path: json['path'] as String,
      type: FileNodeType.values[json['type'] as int],
      children: (json['children'] as List<dynamic>)
          .map((e) => FileNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastModified: json['lastModified'] != null ? DateTime.parse(json['lastModified'] as String) : null,
      size: json['size'] as int?,
      isLoading: json['isLoading'] as bool? ?? false,
      error: json['error'] as String?,
      extension: json['extension'] as String?,
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'type': type.index,
      'children': children.map((e) => e.toJson()).toList(),
      'lastModified': lastModified?.toIso8601String(),
      'size': size,
      'isLoading': isLoading,
      'error': error,
      'extension': extension,
    };
  }
  
  @override
  String toString() {
    return 'FileNode(path: $path, name: $name, type: $type, children: ${children.length}, isLoading: $isLoading)';
  }
} 