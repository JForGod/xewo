import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/chat_message.dart';
import '../../../domain/models/conversation.dart';
import '../../../../core/services/network/api_client.dart';
import '../../../../core/services/logging/logging_service.dart';

/// 聊天远程数据源
class ChatRemoteDataSource {
  final ApiClient _apiClient;
  final LoggingService _loggingService;
  
  /// 构造函数
  ChatRemoteDataSource({
    required ApiClient apiClient,
    required LoggingService loggingService,
  })  : _apiClient = apiClient,
        _loggingService = loggingService;
  
  // 2025-03-16 + 获取会话功能
  Future<Conversation?> getConversation(String id) async {
    try {
      final response = await _apiClient.get('/conversations/$id');
      
      if (response.statusCode == 200) {
        return Conversation.fromMap(response.data);
      }
      
      return null;
    } catch (e) {
      _loggingService.error('获取远程会话失败', tags: {
        'error': e.toString(),
        'conversation_id': id,
      });
      return null;
    }
  }
  
  // 2025-03-16 + 获取用户所有会话功能
  Future<List<Conversation>> getUserConversations() async {
    try {
      final response = await _apiClient.get('/conversations');
      
      if (response.statusCode == 200) {
        final List<dynamic> conversationsData = response.data;
        return conversationsData
            .map((data) => Conversation.fromMap(data))
            .toList();
      }
      
      return [];
    } catch (e) {
      _loggingService.error('获取远程用户会话失败', tags: {'error': e.toString()});
      return [];
    }
  }
  
  // 2025-03-16 + 创建或更新会话功能
  Future<bool> saveConversation(Conversation conversation) async {
    try {
      final response = await _apiClient.post(
        '/conversations',
        data: conversation.toMap(),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      _loggingService.error('保存远程会话失败', tags: {
        'error': e.toString(),
        'conversation_id': conversation.id,
      });
      return false;
    }
  }
  
  // 2025-03-16 + 删除会话功能
  Future<bool> deleteConversation(String id) async {
    try {
      final response = await _apiClient.delete('/conversations/$id');
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _loggingService.error('删除远程会话失败', tags: {
        'error': e.toString(),
        'conversation_id': id,
      });
      return false;
    }
  }
  
  // 2025-03-16 + 获取会话消息功能
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int? limit,
    int? offset,
    DateTime? before,
    DateTime? after,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (before != null) queryParams['before'] = before.toIso8601String();
      if (after != null) queryParams['after'] = after.toIso8601String();
      
      final response = await _apiClient.get(
        '/conversations/$conversationId/messages',
        queryParams: queryParams,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> messagesData = response.data;
        return messagesData
            .map((data) => ChatMessage.fromMap(data))
            .toList();
      }
      
      return [];
    } catch (e) {
      _loggingService.error('获取远程消息失败', tags: {
        'error': e.toString(),
        'conversation_id': conversationId,
      });
      return [];
    }
  }
  
  // 2025-03-16 + 发送消息功能
  Future<bool> sendMessage(String conversationId, ChatMessage message) async {
    try {
      final response = await _apiClient.post(
        '/conversations/$conversationId/messages',
        data: message.toMap(),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      _loggingService.error('发送远程消息失败', tags: {
        'error': e.toString(),
        'conversation_id': conversationId,
        'message_id': message.id,
      });
      return false;
    }
  }
  
  // 2025-03-16 + 删除消息功能
  Future<bool> deleteMessage(String conversationId, String messageId) async {
    try {
      final response = await _apiClient.delete(
        '/conversations/$conversationId/messages/$messageId',
      );
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _loggingService.error('删除远程消息失败', tags: {
        'error': e.toString(),
        'conversation_id': conversationId,
        'message_id': messageId,
      });
      return false;
    }
  }
  
  // 2025-03-16 + 流式发送消息功能
  Stream<ChatMessage> streamMessage(String conversationId, String prompt) async* {
    try {
      final streamResponse = _apiClient.getStream(
        '/conversations/$conversationId/stream',
        data: {'prompt': prompt},
      );
      
      await for (final chunk in streamResponse) {
        if (chunk.containsKey('delta')) {
          final messageChunk = ChatMessage.fromMap(chunk);
          yield messageChunk;
        }
      }
    } catch (e) {
      _loggingService.error('流式发送远程消息失败', tags: {
        'error': e.toString(),
        'conversation_id': conversationId,
      });
    }
  }
}

/// 聊天远程数据源提供者
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource?>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  
  // 检查是否配置了API端点
  final hasApiConfig = ref.watch(apiConfigProvider).hasValidConfig;
  
  if (!hasApiConfig) {
    return null;
  }
  
  return ChatRemoteDataSource(
    apiClient: apiClient,
    loggingService: loggingService,
  );
});
