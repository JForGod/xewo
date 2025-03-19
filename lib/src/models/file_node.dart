enum FileNodeType {
  file,
  directory,
}

class FileNode {
  final String name;
  final String path;
  final FileNodeType type;
  final DateTime? modifiedTime;
  final int? size;
  final List<FileNode> children;
  final bool isExpanded;

  FileNode({
    required this.name,
    required this.path,
    required this.type,
    this.modifiedTime,
    this.size,
    this.children = const [],
    this.isExpanded = false,
  });

  FileNode copyWith({
    String? name,
    String? path,
    FileNodeType? type,
    DateTime? modifiedTime,
    int? size,
    List<FileNode>? children,
    bool? isExpanded,
  }) {
    return FileNode(
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      size: size ?? this.size,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  List<FileNode> getAllNodes() {
    final nodes = <FileNode>[this];
    for (final child in children) {
      nodes.addAll(child.getAllNodes());
    }
    return nodes;
  }

  FileNode? findNode(String nodePath) {
    if (path == nodePath) {
      return this;
    }
    for (final child in children) {
      final found = child.findNode(nodePath);
      if (found != null) {
        return found;
      }
    }
    return null;
  }
} 