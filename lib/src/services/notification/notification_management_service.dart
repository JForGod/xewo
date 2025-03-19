import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/logging_service.dart';
import '../error/error_handling_service.dart';

/// 通知类型
enum NotificationType {
  /// 系统通知
  system,
  
  /// 安全通知
  security,
  
  /// 更新通知
  update,
  
  /// 警告通知
  warning,
  
  /// 错误通知
  error,
  
  /// 任务通知
  task,
  
  /// 消息通知
  message,
  
  /// 其他通知
  other,
}

/// 通知优先级
enum NotificationPriority {
  /// 低
  low,
  
  /// 正常
  normal,
  
  /// 高
  high,
  
  /// 紧急
  urgent,
}

/// 通知状态
enum NotificationState {
  /// 未读
  unread,
  
  /// 已读
  read,
  
  /// 已处理
  handled,
  
  /// 已归档
  archived,
  
  /// 已删除
  deleted,
}

/// 通知
class Notification {
  /// 通知ID
  final String id;
  
  /// 通知类型
  final NotificationType type;
  
  /// 优先级
  final NotificationPriority priority;
  
  /// 状态
  final NotificationState state;
  
  /// 时间戳
  final DateTime timestamp;
  
  /// 标题
  final String title;
  
  /// 内容
  final String content;
  
  /// 图标
  final String? icon;
  
  /// 链接
  final String? link;
  
  /// 发送者ID
  final String? senderId;
  
  /// 接收者ID
  final String? receiverId;
  
  /// 分组ID
  final String? groupId;
  
  /// 标签
  final List<String> tags;
  
  /// 详细信息
  final Map<String, dynamic> details;
  
  /// 构造函数
  Notification({
    String? id,
    required this.type,
    required this.priority,
    this.state = NotificationState.unread,
    DateTime? timestamp,
    required this.title,
    required this.content,
    this.icon,
    this.link,
    this.senderId,
    this.receiverId,
    this.groupId,
    this.tags = const [],
    this.details = const {},
  })  : id = id ?? _generateId(),
        timestamp = timestamp ?? DateTime.now();
  
  /// 生成通知ID
  static String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    final data = utf8.encode('$now$random');
    final hash = sha256.convert(data);
    return hash.toString().substring(0, 16);
  }
  
  /// 从Map创建通知
  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] as String,
      type: NotificationType.values.byName(map['type'] as String),
      priority: NotificationPriority.values.byName(map['priority'] as String),
      state: NotificationState.values.byName(map['state'] as String),
      timestamp: DateTime.parse(map['timestamp'] as String),
      title: map['title'] as String,
      content: map['content'] as String,
      icon: map['icon'] as String?,
      link: map['link'] as String?,
      senderId: map['senderId'] as String?,
      receiverId: map['receiverId'] as String?,
      groupId: map['groupId'] as String?,
      tags: List<String>.from(map['tags'] ?? []),
      details: Map<String, dynamic>.from(map['details'] ?? {}),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'priority': priority.name,
      'state': state.name,
      'timestamp': timestamp.toIso8601String(),
      'title': title,
      'content': content,
      'icon': icon,
      'link': link,
      'senderId': senderId,
      'receiverId': receiverId,
      'groupId': groupId,
      'tags': tags,
      'details': details,
    };
  }
}

/// 通知配置
class NotificationConfig {
  /// 是否启用通知
  final bool enableNotifications;
  
  /// 是否启用声音
  final bool enableSound;
  
  /// 是否启用震动
  final bool enableVibration;
  
  /// 是否启用桌面通知
  final bool enableDesktopNotifications;
  
  /// 是否启用通知分组
  final bool enableGrouping;
  
  /// 是否启用自动归档
  final bool enableAutoArchive;
  
  /// 通知保留时间（毫秒）
  final int retentionTime;
  
  /// 最大通知数量
  final int maxNotifications;
  
  /// 每页通知数量
  final int pageSize;
  
  /// 构造函数
  NotificationConfig({
    this.enableNotifications = true,
    this.enableSound = true,
    this.enableVibration = true,
    this.enableDesktopNotifications = true,
    this.enableGrouping = true,
    this.enableAutoArchive = true,
    this.retentionTime = 30 * 24 * 60 * 60 * 1000, // 30天
    this.maxNotifications = 1000,
    this.pageSize = 20,
  });
  
  /// 从Map创建配置
  factory NotificationConfig.fromMap(Map<String, dynamic> map) {
    return NotificationConfig(
      enableNotifications: map['enableNotifications'] ?? true,
      enableSound: map['enableSound'] ?? true,
      enableVibration: map['enableVibration'] ?? true,
      enableDesktopNotifications: map['enableDesktopNotifications'] ?? true,
      enableGrouping: map['enableGrouping'] ?? true,
      enableAutoArchive: map['enableAutoArchive'] ?? true,
      retentionTime: map['retentionTime'] ?? 30 * 24 * 60 * 60 * 1000,
      maxNotifications: map['maxNotifications'] ?? 1000,
      pageSize: map['pageSize'] ?? 20,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'enableNotifications': enableNotifications,
      'enableSound': enableSound,
      'enableVibration': enableVibration,
      'enableDesktopNotifications': enableDesktopNotifications,
      'enableGrouping': enableGrouping,
      'enableAutoArchive': enableAutoArchive,
      'retentionTime': retentionTime,
      'maxNotifications': maxNotifications,
      'pageSize': pageSize,
    };
  }
}

/// 通知管理服务
class NotificationManagementService {
  /// 配置
  NotificationConfig _config;
  
  /// 日志服务
  final LoggingService _loggingService;
  
  /// 错误处理服务
  final ErrorHandlingService _errorHandlingService;
  
  /// 通知流控制器
  final StreamController<Notification> _notificationController =
      StreamController<Notification>.broadcast();
  
  /// 通知流
  Stream<Notification> get notificationStream => _notificationController.stream;
  
  /// 通知列表
  final List<Notification> _notifications = [];
  
  /// 通知分组
  final Map<String, List<Notification>> _groups = {};
  
  /// 构造函数
  NotificationManagementService({
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
    NotificationConfig? config,
  })  : _loggingService = loggingService,
        _errorHandlingService = errorHandlingService,
        _config = config ?? NotificationConfig() {
    _initializeService();
  }
  
  /// 初始化服务
  void _initializeService() {
    // 清理过期通知
    _cleanupNotifications();
  }
  
  /// 清理过期通知
  void _cleanupNotifications() {
    final now = DateTime.now();
    final cutoff = now.subtract(
      Duration(milliseconds: _config.retentionTime),
    );
    
    _notifications.removeWhere((notification) =>
        notification.timestamp.isBefore(cutoff) ||
        notification.state == NotificationState.deleted);
    
    // 限制通知数量
    if (_notifications.length > _config.maxNotifications) {
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _notifications.removeRange(_config.maxNotifications, _notifications.length);
    }
    
    // 更新分组
    if (_config.enableGrouping) {
      _updateGroups();
    }
  }
  
  /// 更新分组
  void _updateGroups() {
    _groups.clear();
    
    for (final notification in _notifications) {
      if (notification.groupId != null) {
        _groups.putIfAbsent(notification.groupId!, () => []).add(notification);
      }
    }
    
    // 对每个分组进行排序
    for (final group in _groups.values) {
      group.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
  }
  
  /// 发送通知
  Future<void> sendNotification(Notification notification) async {
    try {
      if (!_config.enableNotifications) {
        return;
      }
      
      // 添加通知
      _notifications.add(notification);
      
      // 更新分组
      if (_config.enableGrouping && notification.groupId != null) {
        _groups.putIfAbsent(notification.groupId!, () => []).add(notification);
      }
      
      // 发送到流
      _notificationController.add(notification);
      
      // 显示桌面通知
      if (_config.enableDesktopNotifications) {
        await _showDesktopNotification(notification);
      }
      
      // 播放声音
      if (_config.enableSound) {
        await _playSound(notification);
      }
      
      // 震动
      if (_config.enableVibration) {
        await _vibrate(notification);
      }
      
      // 记录日志
      _loggingService.info(
        '发送通知',
        tags: {
          'notification_id': notification.id,
          'type': notification.type.name,
          'priority': notification.priority.name,
          'title': notification.title,
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '发送通知失败',
      );
    }
  }
  
  /// 显示桌面通知
  Future<void> _showDesktopNotification(Notification notification) async {
    try {
      // TODO: 实现桌面通知
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.low,
        message: '显示桌面通知失败',
      );
    }
  }
  
  /// 播放声音
  Future<void> _playSound(Notification notification) async {
    try {
      // TODO: 实现声音播放
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.low,
        message: '播放通知声音失败',
      );
    }
  }
  
  /// 震动
  Future<void> _vibrate(Notification notification) async {
    try {
      // TODO: 实现震动
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.low,
        message: '通知震动失败',
      );
    }
  }
  
  /// 标记通知为已读
  void markAsRead(String notificationId) {
    final notification = _notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => null,
    );
    
    if (notification != null) {
      final updatedNotification = Notification(
        id: notification.id,
        type: notification.type,
        priority: notification.priority,
        state: NotificationState.read,
        timestamp: notification.timestamp,
        title: notification.title,
        content: notification.content,
        icon: notification.icon,
        link: notification.link,
        senderId: notification.senderId,
        receiverId: notification.receiverId,
        groupId: notification.groupId,
        tags: notification.tags,
        details: notification.details,
      );
      
      final index = _notifications.indexOf(notification);
      _notifications[index] = updatedNotification;
      
      if (_config.enableGrouping && notification.groupId != null) {
        final group = _groups[notification.groupId!];
        if (group != null) {
          final groupIndex = group.indexOf(notification);
          if (groupIndex != -1) {
            group[groupIndex] = updatedNotification;
          }
        }
      }
    }
  }
  
  /// 标记所有通知为已读
  void markAllAsRead() {
    for (final notification in _notifications) {
      if (notification.state == NotificationState.unread) {
        markAsRead(notification.id);
      }
    }
  }
  
  /// 归档通知
  void archiveNotification(String notificationId) {
    final notification = _notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => null,
    );
    
    if (notification != null) {
      final updatedNotification = Notification(
        id: notification.id,
        type: notification.type,
        priority: notification.priority,
        state: NotificationState.archived,
        timestamp: notification.timestamp,
        title: notification.title,
        content: notification.content,
        icon: notification.icon,
        link: notification.link,
        senderId: notification.senderId,
        receiverId: notification.receiverId,
        groupId: notification.groupId,
        tags: notification.tags,
        details: notification.details,
      );
      
      final index = _notifications.indexOf(notification);
      _notifications[index] = updatedNotification;
      
      if (_config.enableGrouping && notification.groupId != null) {
        final group = _groups[notification.groupId!];
        if (group != null) {
          final groupIndex = group.indexOf(notification);
          if (groupIndex != -1) {
            group[groupIndex] = updatedNotification;
          }
        }
      }
    }
  }
  
  /// 删除通知
  void deleteNotification(String notificationId) {
    final notification = _notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => null,
    );
    
    if (notification != null) {
      final updatedNotification = Notification(
        id: notification.id,
        type: notification.type,
        priority: notification.priority,
        state: NotificationState.deleted,
        timestamp: notification.timestamp,
        title: notification.title,
        content: notification.content,
        icon: notification.icon,
        link: notification.link,
        senderId: notification.senderId,
        receiverId: notification.receiverId,
        groupId: notification.groupId,
        tags: notification.tags,
        details: notification.details,
      );
      
      final index = _notifications.indexOf(notification);
      _notifications[index] = updatedNotification;
      
      if (_config.enableGrouping && notification.groupId != null) {
        final group = _groups[notification.groupId!];
        if (group != null) {
          final groupIndex = group.indexOf(notification);
          if (groupIndex != -1) {
            group[groupIndex] = updatedNotification;
          }
        }
      }
    }
  }
  
  /// 获取通知
  Notification? getNotification(String notificationId) {
    return _notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => null,
    );
  }
  
  /// 获取所有通知
  List<Notification> getAllNotifications() {
    return List.unmodifiable(_notifications);
  }
  
  /// 获取未读通知
  List<Notification> getUnreadNotifications() {
    return _notifications
        .where((n) => n.state == NotificationState.unread)
        .toList();
  }
  
  /// 获取分组通知
  List<Notification>? getGroupNotifications(String groupId) {
    return _groups[groupId]?.toList();
  }
  
  /// 获取所有分组
  Map<String, List<Notification>> getAllGroups() {
    return Map.unmodifiable(_groups);
  }
  
  /// 更新配置
  void updateConfig(NotificationConfig config) {
    _config = config;
  }
  
  /// 获取当前配置
  NotificationConfig getConfig() {
    return _config;
  }
  
  /// 关闭服务
  Future<void> dispose() async {
    await _notificationController.close();
  }
}

/// 通知管理服务提供者
final notificationManagementServiceProvider =
    Provider<NotificationManagementService>((ref) {
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  
  final service = NotificationManagementService(
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
  );
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// 通知流提供者
final notificationStreamProvider = StreamProvider<Notification>((ref) {
  final service = ref.watch(notificationManagementServiceProvider);
  return service.notificationStream;
}); 