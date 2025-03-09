/// 快捷键类别
enum ShortcutCategory {
  file,    // 文件操作
  edit,    // 编辑操作
  view,    // 视图操作
  search,  // 搜索操作
  debug,   // 调试操作
  tool,    // 工具操作
  other,   // 其他操作
}

/// 快捷键模型
class ShortcutModel {
  final String id;
  final String name;
  final String description;
  final String defaultKeys;
  final String? customKeys;
  final ShortcutCategory category;
  
  const ShortcutModel({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultKeys,
    this.customKeys,
    required this.category,
  });
  
  /// 复制并更新
  ShortcutModel copyWith({
    String? id,
    String? name,
    String? description,
    String? defaultKeys,
    String? customKeys,
    ShortcutCategory? category,
  }) {
    return ShortcutModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      defaultKeys: defaultKeys ?? this.defaultKeys,
      customKeys: customKeys,
      category: category ?? this.category,
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'defaultKeys': defaultKeys,
      'customKeys': customKeys,
      'category': category.toString(),
    };
  }
  
  /// 从JSON创建
  factory ShortcutModel.fromJson(Map<String, dynamic> json) {
    return ShortcutModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      defaultKeys: json['defaultKeys'] as String,
      customKeys: json['customKeys'] as String?,
      category: _categoryFromString(json['category'] as String),
    );
  }
  
  /// 从字符串解析类别
  static ShortcutCategory _categoryFromString(String category) {
    switch (category) {
      case 'ShortcutCategory.file':
        return ShortcutCategory.file;
      case 'ShortcutCategory.edit':
        return ShortcutCategory.edit;
      case 'ShortcutCategory.view':
        return ShortcutCategory.view;
      case 'ShortcutCategory.search':
        return ShortcutCategory.search;
      case 'ShortcutCategory.debug':
        return ShortcutCategory.debug;
      case 'ShortcutCategory.tool':
        return ShortcutCategory.tool;
      default:
        return ShortcutCategory.other;
    }
  }
} 