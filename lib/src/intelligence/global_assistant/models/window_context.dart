/// 窗口上下文操作枚举
enum WindowContextAction {
  /// 打开项目
  openProject,
  
  /// 在新窗口打开
  openNewWindow,
  
  /// 切换文件树显示
  toggleFileTree,
  
  /// 格式化代码
  formatCode,
  
  /// 搜索
  search,
  
  /// 替换
  replace,
  
  /// 切换行号显示
  toggleLineNumbers,
  
  /// 切换小地图显示
  toggleMinimap,
  
  /// 全部折叠
  foldAll,
  
  /// 全部展开
  expandAll,
  
  /// 保存文件
  saveFile,
  
  /// 窗口创建
  windowCreate,
  
  /// 窗口关闭
  windowClose,
  
  /// 窗口切换
  windowSwitch,
  
  /// 窗口布局变更
  windowLayoutChange,
}

/// 窗口上下文数据类
class WindowContext {
  /// 窗口ID
  final String windowId;
  
  /// 窗口标题
  final String title;
  
  /// 窗口类型
  final String type;
  
  /// 窗口状态
  final Map<String, dynamic> state;
  
  /// 窗口关联
  final List<String> relatedWindowIds;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 最后活动时间
  final DateTime lastActiveAt;
  
  /// 窗口上下文构造函数
  WindowContext({
    required this.windowId,
    required this.title,
    required this.type,
    required this.state,
    required this.relatedWindowIds,
    required this.createdAt,
    DateTime? lastActiveAt,
  }) : lastActiveAt = lastActiveAt ?? createdAt;
  
  /// 从JSON创建窗口上下文
  factory WindowContext.fromJson(Map<String, dynamic> json) {
    return WindowContext(
      windowId: json['windowId'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      state: json['state'] as Map<String, dynamic>,
      relatedWindowIds: (json['relatedWindowIds'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActiveAt: json['lastActiveAt'] != null 
          ? DateTime.parse(json['lastActiveAt'] as String) 
          : null,
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'windowId': windowId,
      'title': title,
      'type': type,
      'state': state,
      'relatedWindowIds': relatedWindowIds,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
    };
  }
  
  /// 创建更新后的窗口上下文
  WindowContext copyWith({
    String? windowId,
    String? title,
    String? type,
    Map<String, dynamic>? state,
    List<String>? relatedWindowIds,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return WindowContext(
      windowId: windowId ?? this.windowId,
      title: title ?? this.title,
      type: type ?? this.type,
      state: state ?? this.state,
      relatedWindowIds: relatedWindowIds ?? this.relatedWindowIds,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
  
  /// 更新状态
  WindowContext updateState(Map<String, dynamic> newState) {
    return copyWith(
      state: {...state, ...newState},
      lastActiveAt: DateTime.now(),
    );
  }
  
  /// 添加关联窗口
  WindowContext addRelatedWindow(String windowId) {
    if (relatedWindowIds.contains(windowId)) {
      return this;
    }
    return copyWith(
      relatedWindowIds: [...relatedWindowIds, windowId],
      lastActiveAt: DateTime.now(),
    );
  }
  
  /// 移除关联窗口
  WindowContext removeRelatedWindow(String windowId) {
    if (!relatedWindowIds.contains(windowId)) {
      return this;
    }
    return copyWith(
      relatedWindowIds: relatedWindowIds.where((id) => id != windowId).toList(),
      lastActiveAt: DateTime.now(),
    );
  }
} 