import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/chat_repository.dart';
import '../../models/conversation.dart';

/// 获取会话用例
class GetConversationsUseCase {
  final ChatRepository _chatRepository;
  
  /// 构造函数
  GetConversationsUseCase({
    required ChatRepository chatRepository,
  }) : _chatRepository = chatRepository;
  
  /// 执行用例
  // 2025-03-16 + 执行获取会话功能
  Future<List<Conversation>> execute() async {
    return await _chatRepository.getAllConversations();
  }
  
  /// 获取单个会话
  // 2025-03-16 + 获取单个会话功能
  Future<Conversation?> getConversation(String id) async {
    return await _chatRepository.getConversation(id);
  }
  
  /// 获取会话消息
  // 2025-03-16 + 获取会话消息功能
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int? limit,
    int? offset,
  }) async {
    return await _chatRepository.getMessages(
      conversationId,
      limit: limit,
      offset: offset,
    );
  }
}

/// 获取会话用例提供者
final getConversationsUseCaseProvider = Provider<GetConversationsUseCase>((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  
  return GetConversationsUseCase(
    chatRepository: chatRepository,
  );
});
