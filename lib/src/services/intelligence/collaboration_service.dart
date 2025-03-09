import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../core/config/app_config.dart';

/// 协作会话信息
class CollaborationSession {
  final String id;
  final String userId;
  final String projectId;
  final DateTime startTime;
  final Map<String, dynamic> metadata;

  const CollaborationSession({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.startTime,
    this.metadata = const {},
  });
}

/// 协作建议
class CollaborativeSuggestion {
  final String id;
  final String sessionId;
  final String content;
  final double confidence;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const CollaborativeSuggestion({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.confidence,
    required this.createdAt,
    this.metadata = const {},
  });
}

/// 协作服务
class CollaborationService {
  final Map<String, CollaborationSession> _activeSessions = {};
  final Map<String, StreamController<CollaborativeSuggestion>> _suggestionControllers = {};
  
  /// 创建协作会话
  Future<CollaborationSession> createSession(String userId, String projectId) async {
    final session = CollaborationSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      projectId: projectId,
      startTime: DateTime.now(),
    );
    
    _activeSessions[session.id] = session;
    _suggestionControllers[session.id] = StreamController<CollaborativeSuggestion>.broadcast();
    
    return session;
  }

  /// 获取建议流
  Stream<CollaborativeSuggestion> getSuggestionStream(String sessionId) {
    return _suggestionControllers[sessionId]?.stream ?? const Stream.empty();
  }

  /// 添加协作建议
  Future<void> addSuggestion(CollaborativeSuggestion suggestion) async {
    final controller = _suggestionControllers[suggestion.sessionId];
    if (controller != null) {
      controller.add(suggestion);
    }
  }

  /// 结束会话
  Future<void> endSession(String sessionId) async {
    _activeSessions.remove(sessionId);
    await _suggestionControllers[sessionId]?.close();
    _suggestionControllers.remove(sessionId);
  }

  /// 获取活跃会话
  CollaborationSession? getActiveSession(String sessionId) {
    return _activeSessions[sessionId];
  }

  /// 清理资源
  void dispose() {
    for (final controller in _suggestionControllers.values) {
      controller.close();
    }
    _suggestionControllers.clear();
    _activeSessions.clear();
  }
}

/// 协作服务提供者
final collaborationServiceProvider = Provider<CollaborationService>((ref) {
  final service = CollaborationService();
  ref.onDispose(() => service.dispose());
  return service;
}); 