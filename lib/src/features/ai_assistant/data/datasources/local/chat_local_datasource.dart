// lib/src/features/ai_assistant/data/datasources/local/chat_local_datasource.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/chat_message.dart';
import '../../../domain/models/conversation.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../../../core/services/logging/logging_service.dart';

/// 聊天本地数据源
class ChatLocalDataSource {
  final StorageService _storageService;
  final LoggingService _loggingService;
  
  /// 构造函数
  ChatLocalDataSource({
    required StorageService storageService,
    required LoggingService loggingService,
  })  : _storageService = storageService,
        _loggingService = loggingService;
  
  // 2025-03-16 + 获取特定会话功能
  Future<Conversation?> getConversation(String id) async {
    try {
      final data = await _storageService.read<Map<String, dynamic>>(
        'conversations/$id',
      );
      
      if (data == null) {
        return null;
      }
      
      return Conversation.fromMap(data);
    } catch (e) {
      _loggingService.error('获取会话失败', tags: {
        'error': e.toString(),
        'conversation_id': id,
      });
      return null;
    }
  }
  
  // 2025-03-16 + 获取所有会话功能
  Future<List<Conversation>> getAllConversations() async {
    try {
      final keys = await _storageService.getKeys('conversations/');
      final List<Conversation> conversations = [];
      
      for (final key in keys) {
        final id = key.split('/').last;
        final conversation = await getConversation(id);
        if (conversation != null) {
          conversations.add(conversation);
        }
      }
      
      // 按更新时间排序，最新的在前面
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return conversations;
    } catch (e) {
      _loggingService.error('获取所有会话失败', tags: {'error': e.toString()});
      return [];
    }
  }
  
  // 2025-03-16 + 保存会话功能
  Future<void> saveConversation(Conversation conversation) async {
    try {
      await _storageService.write(
        'conversations/${conversation.id}',
        conversation.toMap(),
      );
    } catch (e) {
      _loggingService.error('保存会话失败', tags: {
        'error': e.toString(),
        'conversation_id': conversation.id,
      });
      rethrow;
    }
  }
  
  // 2025-03-16 + 删除会话功能
  Future<void> deleteConversation(String id) async {
    try {
      // 删除会话
      await _storageService.delete('conversations/$id');
      
      // 删除会话的所有消息
      final messageKeys = await _storageService.getKeys('messages/$id/');
      for (final key in messageKeys) {
        await _storageService.delete(key);
      }
    } catch (e) {
      _loggingService.error('删除会话失败', tags: {
        'error': e.toString(),
        'conversation_id': id,
      });
      rethrow;
    }
  }
  
  // 2025-03-16 + 保存消息功能
  Future<void> saveMessage(String conversationId, ChatMessage message) async {
    try {
      await _storageService.write(
        'messages/$conversationId/${message.id}',
        message.toMap(),
      );
    } catch (e) {
      _loggingService.error('保存消息失败', tags: {
        'error': e.toString(),
        'conversation_id': conversationId,
        'message_id': message.id,
      });
      rethrow;
    }
  }
  
  // 2025-03-16 + 删除消息功能
  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      await _storageService.delete('messages/$conversationId/$messageId');
    } catch (e) {
      _loggingService.error('删除消息失败', tags: {
        'error': e.toString(),
        'conversation_id': conversationId,
        'message_id': messageId,
      });
      rethrow;
    }
  }
  
  // 2025-03-16 + 获取消息功能
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int? limit,
    int? offset,
    DateTime? before,
    DateTime? after,
  }) async {
    try {
      final keys = await _storageService.getKeys('messages/$conversationId/');
      final List<ChatMessage> messages = [];
      
      for (final key in keys) {
        final data = await _storageService.read<Map<String, dynamic>>(key);
        if (data != null) {
          final message = ChatMessage.fromMap(data);
          
          // 应用过滤条件
          if ((before == null || message.timestamp.isBefore(before)) &&
              (after == null || message.timestamp.isAfter(after))) {
            messages.add(message);
          }
        }
      }
      
      // 按时间排序，最新的在前面
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // 应用分页
      if (offset != null || limit != null) {
        final start = offset ?? 0;
        final end = limit != null ? (start + limit) : null;
        
        if (start < messages.length) {
          return messages.sublist(start, end != null && end < messages.length ? end : messages.length);
        } else {
          return [];
        }
      }
      
      return messages;
    } catch (e) {
      _loggingService.error('获取消息失败', tags: {
        'error': e.toString(),
        'conversation_id': conversationId,
      });
      return [];
    }
  }
  
  // 2025-03-16 + 搜索消息功能
  Future<List<ChatMessage>> searchMessages(
    String query, {
    String? conversationId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final List<ChatMessage> results = [];
      
      // 决定搜索范围
      List<String> conversationIds;
      if (conversationId != null) {
        conversationIds = [conversationId];
      } else {
        final conversations = await getAllConversations();
        conversationIds = conversations.map((c) => c.id).toList();
      }
      
      // 在每个会话中搜索
      for (final id in conversationIds) {
        final messages = await getMessages(
          id,
          after: startDate,
          before: endDate,
        );
        
        // 筛选包含查询词的消息
        final matchingMessages = messages.where((message) {
          final content = message.content.toLowerCase();
          return content.contains(query.toLowerCase());
        }).toList();
        
        results.addAll(matchingMessages);
      }
      
      // 按时间排序，最新的在前面
      results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return results;
    } catch (e) {
      _loggingService.error('搜索消息失败', tags: {
        'error': e.toString(),
        'query': query,
      });
      return [];
    }
  }
}

/// 聊天本地数据源提供者
final chatLocalDataSourceProvider = Provider<ChatLocalDataSource>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  
  return ChatLocalDataSource(
    storageService: storageService,
    loggingService: loggingService,
  );
});