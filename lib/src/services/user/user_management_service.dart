import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/logging_service.dart';
import '../error/error_handling_service.dart';

/// 用户角色
enum UserRole {
  /// 管理员
  admin,
  
  /// 普通用户
  user,
  
  /// 访客
  guest,
}

/// 用户状态
enum UserState {
  /// 正常
  active,
  
  /// 禁用
  disabled,
  
  /// 锁定
  locked,
  
  /// 过期
  expired,
}

/// 用户权限
class UserPermission {
  /// 权限ID
  final String id;
  
  /// 权限名称
  final String name;
  
  /// 权限描述
  final String description;
  
  /// 资源类型
  final String resourceType;
  
  /// 操作类型
  final String action;
  
  /// 条件
  final Map<String, dynamic> conditions;
  
  /// 构造函数
  UserPermission({
    required this.id,
    required this.name,
    required this.description,
    required this.resourceType,
    required this.action,
    this.conditions = const {},
  });
  
  /// 从Map创建权限
  factory UserPermission.fromMap(Map<String, dynamic> map) {
    return UserPermission(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      resourceType: map['resourceType'] as String,
      action: map['action'] as String,
      conditions: Map<String, dynamic>.from(map['conditions'] ?? {}),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'resourceType': resourceType,
      'action': action,
      'conditions': conditions,
    };
  }
}

/// 用户
class User {
  /// 用户ID
  final String id;
  
  /// 用户名
  final String username;
  
  /// 密码哈希
  final String passwordHash;
  
  /// 电子邮件
  final String email;
  
  /// 角色
  final UserRole role;
  
  /// 状态
  final UserState state;
  
  /// 权限列表
  final List<UserPermission> permissions;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间
  final DateTime updatedAt;
  
  /// 最后登录时间
  final DateTime? lastLoginAt;
  
  /// 过期时间
  final DateTime? expiresAt;
  
  /// 个人信息
  final Map<String, dynamic> profile;
  
  /// 设置
  final Map<String, dynamic> settings;
  
  /// 标签
  final List<String> tags;
  
  /// 详细信息
  final Map<String, dynamic> details;
  
  /// 构造函数
  User({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.email,
    required this.role,
    this.state = UserState.active,
    this.permissions = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastLoginAt,
    this.expiresAt,
    this.profile = const {},
    this.settings = const {},
    this.tags = const [],
    this.details = const {},
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
  
  /// 从Map创建用户
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      username: map['username'] as String,
      passwordHash: map['passwordHash'] as String,
      email: map['email'] as String,
      role: UserRole.values.byName(map['role'] as String),
      state: UserState.values.byName(map['state'] as String),
      permissions: (map['permissions'] as List<dynamic>?)
          ?.map((e) => UserPermission.fromMap(e as Map<String, dynamic>))
          .toList() ??
          [],
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.parse(map['lastLoginAt'] as String)
          : null,
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'] as String)
          : null,
      profile: Map<String, dynamic>.from(map['profile'] ?? {}),
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
      tags: List<String>.from(map['tags'] ?? []),
      details: Map<String, dynamic>.from(map['details'] ?? {}),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'passwordHash': passwordHash,
      'email': email,
      'role': role.name,
      'state': state.name,
      'permissions': permissions.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'profile': profile,
      'settings': settings,
      'tags': tags,
      'details': details,
    };
  }
  
  /// 检查权限
  bool hasPermission(String resourceType, String action) {
    return permissions.any((p) =>
        p.resourceType == resourceType &&
        p.action == action);
  }
  
  /// 检查是否过期
  bool isExpired() {
    if (expiresAt == null) {
      return false;
    }
    return DateTime.now().isAfter(expiresAt!);
  }
}

/// 用户管理服务
class UserManagementService {
  /// 日志服务
  final LoggingService _loggingService;
  
  /// 错误处理服务
  final ErrorHandlingService _errorHandlingService;
  
  /// 用户映射
  final Map<String, User> _users = {};
  
  /// 用户变更流控制器
  final StreamController<User> _userController =
      StreamController<User>.broadcast();
  
  /// 用户变更流
  Stream<User> get userStream => _userController.stream;
  
  /// 构造函数
  UserManagementService({
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
  })  : _loggingService = loggingService,
        _errorHandlingService = errorHandlingService;
  
  /// 创建用户
  Future<User> createUser({
    required String username,
    required String password,
    required String email,
    required UserRole role,
    List<UserPermission> permissions = const [],
    DateTime? expiresAt,
    Map<String, dynamic> profile = const {},
    Map<String, dynamic> settings = const {},
    List<String> tags = const [],
    Map<String, dynamic> details = const {},
  }) async {
    try {
      // 检查用户名是否已存在
      if (_users.values.any((u) => u.username == username)) {
        throw Exception('用户名已存在');
      }
      
      // 检查邮箱是否已存在
      if (_users.values.any((u) => u.email == email)) {
        throw Exception('邮箱已存在');
      }
      
      // 生成用户ID
      final id = _generateId();
      
      // 生成密码哈希
      final passwordHash = _hashPassword(password);
      
      // 创建用户
      final user = User(
        id: id,
        username: username,
        passwordHash: passwordHash,
        email: email,
        role: role,
        permissions: permissions,
        expiresAt: expiresAt,
        profile: profile,
        settings: settings,
        tags: tags,
        details: details,
      );
      
      // 保存用户
      _users[id] = user;
      
      // 发送到流
      _userController.add(user);
      
      _loggingService.info(
        '创建用户',
        tags: {
          'user_id': user.id,
          'username': user.username,
          'role': user.role.name,
        },
      );
      
      return user;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '创建用户失败',
      );
      rethrow;
    }
  }
  
  /// 更新用户
  Future<User> updateUser(
    String userId, {
    String? username,
    String? password,
    String? email,
    UserRole? role,
    UserState? state,
    List<UserPermission>? permissions,
    DateTime? expiresAt,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? settings,
    List<String>? tags,
    Map<String, dynamic>? details,
  }) async {
    try {
      final user = _users[userId];
      if (user == null) {
        throw Exception('用户不存在');
      }
      
      // 检查用户名是否已存在
      if (username != null &&
          username != user.username &&
          _users.values.any((u) => u.username == username)) {
        throw Exception('用户名已存在');
      }
      
      // 检查邮箱是否已存在
      if (email != null &&
          email != user.email &&
          _users.values.any((u) => u.email == email)) {
        throw Exception('邮箱已存在');
      }
      
      // 更新用户
      final updatedUser = User(
        id: user.id,
        username: username ?? user.username,
        passwordHash: password != null ? _hashPassword(password) : user.passwordHash,
        email: email ?? user.email,
        role: role ?? user.role,
        state: state ?? user.state,
        permissions: permissions ?? user.permissions,
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
        lastLoginAt: user.lastLoginAt,
        expiresAt: expiresAt ?? user.expiresAt,
        profile: profile ?? user.profile,
        settings: settings ?? user.settings,
        tags: tags ?? user.tags,
        details: details ?? user.details,
      );
      
      // 保存用户
      _users[userId] = updatedUser;
      
      // 发送到流
      _userController.add(updatedUser);
      
      _loggingService.info(
        '更新用户',
        tags: {
          'user_id': updatedUser.id,
          'username': updatedUser.username,
          'role': updatedUser.role.name,
        },
      );
      
      return updatedUser;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '更新用户失败',
      );
      rethrow;
    }
  }
  
  /// 删除用户
  Future<void> deleteUser(String userId) async {
    try {
      final user = _users[userId];
      if (user == null) {
        return;
      }
      
      // 删除用户
      _users.remove(userId);
      
      _loggingService.info(
        '删除用户',
        tags: {
          'user_id': user.id,
          'username': user.username,
          'role': user.role.name,
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '删除用户失败',
      );
      rethrow;
    }
  }
  
  /// 获取用户
  User? getUser(String userId) {
    return _users[userId];
  }
  
  /// 获取所有用户
  List<User> getAllUsers() {
    return List.unmodifiable(_users.values);
  }
  
  /// 根据用户名获取用户
  User? getUserByUsername(String username) {
    return _users.values.firstWhere(
      (u) => u.username == username,
      orElse: () => null,
    );
  }
  
  /// 根据邮箱获取用户
  User? getUserByEmail(String email) {
    return _users.values.firstWhere(
      (u) => u.email == email,
      orElse: () => null,
    );
  }
  
  /// 验证密码
  bool verifyPassword(String userId, String password) {
    final user = _users[userId];
    if (user == null) {
      return false;
    }
    
    final hash = _hashPassword(password);
    return hash == user.passwordHash;
  }
  
  /// 更新密码
  Future<void> updatePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final user = _users[userId];
      if (user == null) {
        throw Exception('用户不存在');
      }
      
      // 验证旧密码
      if (!verifyPassword(userId, oldPassword)) {
        throw Exception('旧密码错误');
      }
      
      // 更新密码
      await updateUser(
        userId,
        password: newPassword,
      );
      
      _loggingService.info(
        '更新密码',
        tags: {
          'user_id': user.id,
          'username': user.username,
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '更新密码失败',
      );
      rethrow;
    }
  }
  
  /// 重置密码
  Future<String> resetPassword(String userId) async {
    try {
      final user = _users[userId];
      if (user == null) {
        throw Exception('用户不存在');
      }
      
      // 生成随机密码
      final password = _generatePassword();
      
      // 更新密码
      await updateUser(
        userId,
        password: password,
      );
      
      _loggingService.info(
        '重置密码',
        tags: {
          'user_id': user.id,
          'username': user.username,
        },
      );
      
      return password;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '重置密码失败',
      );
      rethrow;
    }
  }
  
  /// 更新最后登录时间
  Future<void> updateLastLoginAt(String userId) async {
    try {
      final user = _users[userId];
      if (user == null) {
        return;
      }
      
      // 更新最后登录时间
      await updateUser(
        userId,
        details: {
          ...user.details,
          'lastLoginAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.low,
        message: '更新最后登录时间失败',
      );
    }
  }
  
  /// 生成用户ID
  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    final data = utf8.encode('$now$random');
    final hash = sha256.convert(data);
    return hash.toString().substring(0, 16);
  }
  
  /// 生成随机密码
  String _generatePassword() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    final data = utf8.encode('$now$random');
    final hash = sha256.convert(data);
    return hash.toString().substring(0, 8);
  }
  
  /// 哈希密码
  String _hashPassword(String password) {
    final data = utf8.encode(password);
    final hash = sha256.convert(data);
    return hash.toString();
  }
  
  /// 关闭服务
  Future<void> dispose() async {
    await _userController.close();
  }
}

/// 用户管理服务提供者
final userManagementServiceProvider = Provider<UserManagementService>((ref) {
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  
  final service = UserManagementService(
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
  );
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// 用户变更流提供者
final userStreamProvider = StreamProvider<User>((ref) {
  final service = ref.watch(userManagementServiceProvider);
  return service.userStream;
}); 