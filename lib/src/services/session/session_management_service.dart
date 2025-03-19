import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/logging_service.dart';
import '../error/error_handling_service.dart';
import '../user/user_management_service.dart';

/// 会话状态
enum SessionState {
  /// 活跃
  active,
  
  /// 空闲
  idle,
  
  /// 过期
  expired,
  
  /// 已注销
  loggedOut,
}

/// 会话
class Session {
  /// 会话ID
  final String id;
  
  /// 用户ID
  final String userId;
  
  /// 状态
  final SessionState state;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间
  final DateTime updatedAt;
  
  /// 过期时间
  final DateTime expiresAt;
  
  /// 最后活动时间
  final DateTime lastActivityAt;
  
  /// IP地址
  final String? ipAddress;
  
  /// 设备信息
  final Map<String, dynamic> deviceInfo;
  
  /// 浏览器信息
  final Map<String, dynamic> browserInfo;
  
  /// 位置信息
  final Map<String, dynamic> locationInfo;
  
  /// 访问令牌
  final String accessToken;
  
  /// 刷新令牌
  final String refreshToken;
  
  /// 权限列表
  final List<String> permissions;
  
  /// 标签
  final List<String> tags;
  
  /// 详细信息
  final Map<String, dynamic> details;
  
  /// 构造函数
  Session({
    required this.id,
    required this.userId,
    this.state = SessionState.active,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.expiresAt,
    DateTime? lastActivityAt,
    this.ipAddress,
    this.deviceInfo = const {},
    this.browserInfo = const {},
    this.locationInfo = const {},
    required this.accessToken,
    required this.refreshToken,
    this.permissions = const [],
    this.tags = const [],
    this.details = const {},
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        lastActivityAt = lastActivityAt ?? DateTime.now();
  
  /// 从Map创建会话
  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as String,
      userId: map['userId'] as String,
      state: SessionState.values.byName(map['state'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      lastActivityAt: DateTime.parse(map['lastActivityAt'] as String),
      ipAddress: map['ipAddress'] as String?,
      deviceInfo: Map<String, dynamic>.from(map['deviceInfo'] ?? {}),
      browserInfo: Map<String, dynamic>.from(map['browserInfo'] ?? {}),
      locationInfo: Map<String, dynamic>.from(map['locationInfo'] ?? {}),
      accessToken: map['accessToken'] as String,
      refreshToken: map['refreshToken'] as String,
      permissions: List<String>.from(map['permissions'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      details: Map<String, dynamic>.from(map['details'] ?? {}),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'state': state.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'lastActivityAt': lastActivityAt.toIso8601String(),
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
      'browserInfo': browserInfo,
      'locationInfo': locationInfo,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'permissions': permissions,
      'tags': tags,
      'details': details,
    };
  }
  
  /// 检查是否过期
  bool isExpired() {
    return DateTime.now().isAfter(expiresAt);
  }
  
  /// 检查是否空闲
  bool isIdle(Duration idleTimeout) {
    return DateTime.now().difference(lastActivityAt) > idleTimeout;
  }
}

/// 会话配置
class SessionConfig {
  /// 会话超时时间（毫秒）
  final int sessionTimeout;
  
  /// 空闲超时时间（毫秒）
  final int idleTimeout;
  
  /// 访问令牌有效期（毫秒）
  final int accessTokenTtl;
  
  /// 刷新令牌有效期（毫秒）
  final int refreshTokenTtl;
  
  /// 最大会话数
  final int maxSessions;
  
  /// 是否允许多会话
  final bool allowMultipleSessions;
  
  /// 是否启用会话监控
  final bool enableSessionMonitoring;
  
  /// 监控间隔（毫秒）
  final int monitoringInterval;
  
  /// 构造函数
  SessionConfig({
    this.sessionTimeout = 24 * 60 * 60 * 1000, // 24小时
    this.idleTimeout = 30 * 60 * 1000, // 30分钟
    this.accessTokenTtl = 15 * 60 * 1000, // 15分钟
    this.refreshTokenTtl = 7 * 24 * 60 * 60 * 1000, // 7天
    this.maxSessions = 5,
    this.allowMultipleSessions = true,
    this.enableSessionMonitoring = true,
    this.monitoringInterval = 60000, // 1分钟
  });
  
  /// 从Map创建配置
  factory SessionConfig.fromMap(Map<String, dynamic> map) {
    return SessionConfig(
      sessionTimeout: map['sessionTimeout'] ?? 24 * 60 * 60 * 1000,
      idleTimeout: map['idleTimeout'] ?? 30 * 60 * 1000,
      accessTokenTtl: map['accessTokenTtl'] ?? 15 * 60 * 1000,
      refreshTokenTtl: map['refreshTokenTtl'] ?? 7 * 24 * 60 * 60 * 1000,
      maxSessions: map['maxSessions'] ?? 5,
      allowMultipleSessions: map['allowMultipleSessions'] ?? true,
      enableSessionMonitoring: map['enableSessionMonitoring'] ?? true,
      monitoringInterval: map['monitoringInterval'] ?? 60000,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'sessionTimeout': sessionTimeout,
      'idleTimeout': idleTimeout,
      'accessTokenTtl': accessTokenTtl,
      'refreshTokenTtl': refreshTokenTtl,
      'maxSessions': maxSessions,
      'allowMultipleSessions': allowMultipleSessions,
      'enableSessionMonitoring': enableSessionMonitoring,
      'monitoringInterval': monitoringInterval,
    };
  }
}

/// 会话管理服务
class SessionManagementService {
  /// 配置
  SessionConfig _config;
  
  /// 日志服务
  final LoggingService _loggingService;
  
  /// 错误处理服务
  final ErrorHandlingService _errorHandlingService;
  
  /// 用户管理服务
  final UserManagementService _userManagementService;
  
  /// 会话映射
  final Map<String, Session> _sessions = {};
  
  /// 用户会话映射
  final Map<String, List<String>> _userSessions = {};
  
  /// 会话变更流控制器
  final StreamController<Session> _sessionController =
      StreamController<Session>.broadcast();
  
  /// 会话变更流
  Stream<Session> get sessionStream => _sessionController.stream;
  
  /// 定时器
  Timer? _timer;
  
  /// 构造函数
  SessionManagementService({
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
    required UserManagementService userManagementService,
    SessionConfig? config,
  })  : _loggingService = loggingService,
        _errorHandlingService = errorHandlingService,
        _userManagementService = userManagementService,
        _config = config ?? SessionConfig() {
    _initializeService();
  }
  
  /// 初始化服务
  void _initializeService() {
    // 启动会话监控
    if (_config.enableSessionMonitoring) {
      _timer = Timer.periodic(
        Duration(milliseconds: _config.monitoringInterval),
        (_) => _monitorSessions(),
      );
    }
  }
  
  /// 监控会话
  Future<void> _monitorSessions() async {
    try {
      final now = DateTime.now();
      final idleTimeout = Duration(milliseconds: _config.idleTimeout);
      
      for (final session in _sessions.values.toList()) {
        if (session.isExpired()) {
          await invalidateSession(session.id);
          continue;
        }
        
        if (session.isIdle(idleTimeout)) {
          await updateSessionState(session.id, SessionState.idle);
        }
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '会话监控失败',
      );
    }
  }
  
  /// 创建会话
  Future<Session> createSession({
    required String userId,
    String? ipAddress,
    Map<String, dynamic> deviceInfo = const {},
    Map<String, dynamic> browserInfo = const {},
    Map<String, dynamic> locationInfo = const {},
    List<String> permissions = const [],
    List<String> tags = const [],
    Map<String, dynamic> details = const {},
  }) async {
    try {
      final user = _userManagementService.getUser(userId);
      if (user == null) {
        throw Exception('用户不存在');
      }
      
      // 检查会话数量限制
      if (!_config.allowMultipleSessions) {
        await invalidateUserSessions(userId);
      } else {
        final sessions = _userSessions[userId] ?? [];
        if (sessions.length >= _config.maxSessions) {
          throw Exception('超出最大会话数限制');
        }
      }
      
      // 生成会话ID
      final id = _generateId();
      
      // 生成令牌
      final accessToken = _generateToken();
      final refreshToken = _generateToken();
      
      // 创建会话
      final session = Session(
        id: id,
        userId: userId,
        expiresAt: DateTime.now().add(
          Duration(milliseconds: _config.sessionTimeout),
        ),
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
        browserInfo: browserInfo,
        locationInfo: locationInfo,
        accessToken: accessToken,
        refreshToken: refreshToken,
        permissions: permissions,
        tags: tags,
        details: details,
      );
      
      // 保存会话
      _sessions[id] = session;
      _userSessions.putIfAbsent(userId, () => []).add(id);
      
      // 发送到流
      _sessionController.add(session);
      
      // 更新用户最后登录时间
      await _userManagementService.updateLastLoginAt(userId);
      
      _loggingService.info(
        '创建会话',
        tags: {
          'session_id': session.id,
          'user_id': session.userId,
          'ip_address': session.ipAddress ?? 'unknown',
        },
      );
      
      return session;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '创建会话失败',
      );
      rethrow;
    }
  }
  
  /// 更新会话状态
  Future<void> updateSessionState(
    String sessionId,
    SessionState state,
  ) async {
    try {
      final session = _sessions[sessionId];
      if (session == null) {
        return;
      }
      
      // 更新会话
      final updatedSession = Session(
        id: session.id,
        userId: session.userId,
        state: state,
        createdAt: session.createdAt,
        updatedAt: DateTime.now(),
        expiresAt: session.expiresAt,
        lastActivityAt: session.lastActivityAt,
        ipAddress: session.ipAddress,
        deviceInfo: session.deviceInfo,
        browserInfo: session.browserInfo,
        locationInfo: session.locationInfo,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        permissions: session.permissions,
        tags: session.tags,
        details: session.details,
      );
      
      // 保存会话
      _sessions[sessionId] = updatedSession;
      
      // 发送到流
      _sessionController.add(updatedSession);
      
      _loggingService.info(
        '更新会话状态',
        tags: {
          'session_id': sessionId,
          'state': state.name,
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '更新会话状态失败',
      );
      rethrow;
    }
  }
  
  /// 更新会话活动时间
  Future<void> updateSessionActivity(String sessionId) async {
    try {
      final session = _sessions[sessionId];
      if (session == null) {
        return;
      }
      
      // 更新会话
      final updatedSession = Session(
        id: session.id,
        userId: session.userId,
        state: session.state,
        createdAt: session.createdAt,
        updatedAt: DateTime.now(),
        expiresAt: session.expiresAt,
        lastActivityAt: DateTime.now(),
        ipAddress: session.ipAddress,
        deviceInfo: session.deviceInfo,
        browserInfo: session.browserInfo,
        locationInfo: session.locationInfo,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        permissions: session.permissions,
        tags: session.tags,
        details: session.details,
      );
      
      // 保存会话
      _sessions[sessionId] = updatedSession;
      
      // 发送到流
      _sessionController.add(updatedSession);
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.low,
        message: '更新会话活动时间失败',
      );
    }
  }
  
  /// 刷新会话
  Future<Session> refreshSession(
    String sessionId,
    String refreshToken,
  ) async {
    try {
      final session = _sessions[sessionId];
      if (session == null) {
        throw Exception('会话不存在');
      }
      
      if (session.refreshToken != refreshToken) {
        throw Exception('刷新令牌无效');
      }
      
      if (session.isExpired()) {
        throw Exception('会话已过期');
      }
      
      // 生成新令牌
      final accessToken = _generateToken();
      final newRefreshToken = _generateToken();
      
      // 更新会话
      final updatedSession = Session(
        id: session.id,
        userId: session.userId,
        state: SessionState.active,
        createdAt: session.createdAt,
        updatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(
          Duration(milliseconds: _config.sessionTimeout),
        ),
        lastActivityAt: DateTime.now(),
        ipAddress: session.ipAddress,
        deviceInfo: session.deviceInfo,
        browserInfo: session.browserInfo,
        locationInfo: session.locationInfo,
        accessToken: accessToken,
        refreshToken: newRefreshToken,
        permissions: session.permissions,
        tags: session.tags,
        details: session.details,
      );
      
      // 保存会话
      _sessions[sessionId] = updatedSession;
      
      // 发送到流
      _sessionController.add(updatedSession);
      
      _loggingService.info(
        '刷新会话',
        tags: {
          'session_id': sessionId,
        },
      );
      
      return updatedSession;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '刷新会话失败',
      );
      rethrow;
    }
  }
  
  /// 使会话无效
  Future<void> invalidateSession(String sessionId) async {
    try {
      final session = _sessions[sessionId];
      if (session == null) {
        return;
      }
      
      // 更新会话状态
      await updateSessionState(sessionId, SessionState.loggedOut);
      
      // 移除会话
      _sessions.remove(sessionId);
      _userSessions[session.userId]?.remove(sessionId);
      
      _loggingService.info(
        '使会话无效',
        tags: {
          'session_id': sessionId,
          'user_id': session.userId,
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '使会话无效失败',
      );
      rethrow;
    }
  }
  
  /// 使用户所有会话无效
  Future<void> invalidateUserSessions(String userId) async {
    try {
      final sessions = _userSessions[userId] ?? [];
      for (final sessionId in sessions.toList()) {
        await invalidateSession(sessionId);
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '使用户所有会话无效失败',
      );
      rethrow;
    }
  }
  
  /// 获取会话
  Session? getSession(String sessionId) {
    return _sessions[sessionId];
  }
  
  /// 获取用户会话
  List<Session> getUserSessions(String userId) {
    final sessions = _userSessions[userId] ?? [];
    return sessions.map((id) => _sessions[id]!).toList();
  }
  
  /// 获取所有会话
  List<Session> getAllSessions() {
    return List.unmodifiable(_sessions.values);
  }
  
  /// 验证访问令牌
  bool verifyAccessToken(String sessionId, String accessToken) {
    final session = _sessions[sessionId];
    if (session == null) {
      return false;
    }
    
    return session.accessToken == accessToken && !session.isExpired();
  }
  
  /// 生成会话ID
  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    final data = utf8.encode('$now$random');
    final hash = sha256.convert(data);
    return hash.toString().substring(0, 16);
  }
  
  /// 生成令牌
  String _generateToken() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    final data = utf8.encode('$now$random');
    final hash = sha256.convert(data);
    return hash.toString();
  }
  
  /// 更新配置
  void updateConfig(SessionConfig config) {
    _config = config;
    _initializeService();
  }
  
  /// 获取当前配置
  SessionConfig getConfig() {
    return _config;
  }
  
  /// 关闭服务
  Future<void> dispose() async {
    _timer?.cancel();
    await _sessionController.close();
  }
}

/// 会话管理服务提供者
final sessionManagementServiceProvider = Provider<SessionManagementService>((ref) {
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  final userManagementService = ref.watch(userManagementServiceProvider);
  
  final service = SessionManagementService(
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
    userManagementService: userManagementService,
  );
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// 会话变更流提供者
final sessionStreamProvider = StreamProvider<Session>((ref) {
  final service = ref.watch(sessionManagementServiceProvider);
  return service.sessionStream;
}); 