import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../suggestion_service.dart';

/// 协作事件类型
enum CollaborationEventType {
  suggestion,    // 建议分享
  codeShare,     // 代码分享
  review,        // 代码审查
  comment,       // 评论
}

/// 协作事件
class CollaborationEvent {
  final String id;
  final CollaborationEventType type;
  final String userId;
  final String content;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const CollaborationEvent({
    required this.id,
    required this.type,
    required this.userId,
    required this.content,
    this.metadata = const {},
    required this.timestamp,
  });
}

/// 协作服务
class CollaborationService {
  final List<CollaborationEvent> _events = [];
  final Map<String, List<SmartSuggestion>> _sharedSuggestions = {};
  
  /// 分享建议
  void shareSuggestion(String userId, SmartSuggestion suggestion) {
    if (!_sharedSuggestions.containsKey(userId)) {
      _sharedSuggestions[userId] = [];
    }
    
    _sharedSuggestions[userId]!.add(suggestion);
    
    _events.add(CollaborationEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: CollaborationEventType.suggestion,
      userId: userId,
      content: suggestion.code,
      metadata: {
        'suggestionId': suggestion.id,
        'title': suggestion.title,
        'description': suggestion.description,
      },
      timestamp: DateTime.now(),
    ));
  }

  /// 获取用户的共享建议
  List<SmartSuggestion> getUserSuggestions(String userId) {
    return _sharedSuggestions[userId] ?? [];
  }

  /// 添加评论
  void addComment(String userId, String content, {Map<String, dynamic> metadata = const {}}) {
    _events.add(CollaborationEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: CollaborationEventType.comment,
      userId: userId,
      content: content,
      metadata: metadata,
      timestamp: DateTime.now(),
    ));
  }

  /// 获取事件历史
  List<CollaborationEvent> getEventHistory() {
    return List.from(_events)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 获取特定类型的事件
  List<CollaborationEvent> getEventsByType(CollaborationEventType type) {
    return _events.where((e) => e.type == type).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 获取用户的事件
  List<CollaborationEvent> getUserEvents(String userId) {
    return _events.where((e) => e.userId == userId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}

/// 协作服务提供者
final collaborationServiceProvider = Provider<CollaborationService>((ref) {
  return CollaborationService();
}); 