import 'dart:async';
import '../models/chat_message.dart';
import '../models/conversation.dart';

/// 聊天仓库接口
abstract class ChatRepository {
  /// 获取指定ID的会话
  // 2025-03-16 + 获取特定会话功能
  Future<Conversation?> getConversation(String id);
  
  /// 获取所有会话
  // 2025-03-16 + 获取所有会话功能
  Future<List<Conversation>> getAllConversations();
  
  /// 创建新会话
  // 2025-03-16 + 创建新会话功能
  Future<Conversation> createConversation({
    required String title,
    String? description,
    Map<String, dynamic>? metadata,
  });
  
  /// 更新会话信息
  // 2025-03-16 + 更新会话信息功能
  Future<void> updateConversation(Conversation conversation);
  
  /// 删除会话
  // 2025-03-16 + 删除会话功能
  Future<void> deleteConversation(String id);
  
  /// 添加消息到会话
  // 2025-03-16 + 添加消息功能
  Future<void> addMessage(String conversationId, ChatMessage message);
  
  /// 更新消息
  // 2025-03-16 + 更新消息功能
  Future<void> updateMessage(String conversationId, ChatMessage message);
  
  /// 删除消息
  // 2025-03-16 + 删除消息功能
  Future<void> deleteMessage(String conversationId, String messageId);
  
  /// 获取会话的所有消息
  // 2025-03-16 + 获取会话消息功能
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int? limit,
    int? offset,
    DateTime? before,
    DateTime? after,
  });
  
  /// 搜索消息
  // 2025-03-16 + 搜索消息功能
  Future<List<ChatMessage>> searchMessages(
    String query, {
    String? conversationId,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// 获取会话消息流
  // 2025-03-16 + 获取消息流功能
  Stream<ChatMessage> getMessageStream(String conversationId);
  
  /// 设置会话标签
  // 2025-03-16 + 设置会话标签功能
  Future<void> setConversationTags(String conversationId, List<String> tags);
  
  /// 设置消息标记状态
  // 2025-03-16 + 设置消息标记功能
  Future<void> markMessage(
    String conversationId,
    String messageId,
    MessageMarkType type,
    bool value,
  );
}

/// 消息标记类型
enum MessageMarkType {
  favorite,
  read,
  important,
  flagged,
}
