import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/chat_repository.dart';
import '../../models/chat_message.dart';
import '../../services/assistant_service.dart';
import '../../models/interaction.dart';

/// 发送消息用例
class SendMessageUseCase {
  final ChatRepository _chatRepository;
  final AssistantService _assistantService;
  
  /// 构造函数
  SendMessageUseCase({
    required ChatRepository chatRepository,
    required AssistantService assistantService,
  })  : _chatRepository = chatRepository,
        _assistantService = assistantService;
  
  /// 执行用例
  // 2025-03-16 + 执行发送消息功能
  Future<ChatMessage> execute({
    required String conversationId,
    required String content,
    List<Attachment>? attachments,
    Map<String, dynamic>? metadata,
  }) async {
    // 创建用户消息
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
      attachments: attachments ?? [],
      metadata: metadata ?? {},
    );
    
    // 保存用户消息
    await _chatRepository.addMessage(conversationId, userMessage);
    
    // 创建交互对象
    final interaction = Interaction(
      type: InteractionType.text,
      content: content,
      attachments: attachments?.map((a) => a.toMap()).toList() ?? [],
      metadata: metadata ?? {},
    );
    
    // 处理交互并获取响应
    final response = await _assistantService.handleInteraction(interaction);
    
    // 创建助手消息
    final assistantMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: response.content,
      sender: MessageSender.assistant,
      timestamp: DateTime.now(),
      attachments: [],
      metadata: response.additionalData ?? {},
    );
    
    // 保存助手消息
    await _chatRepository.addMessage(conversationId, assistantMessage);
    
    return assistantMessage;
  }
}

/// 发送消息用例提供者
final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  final assistantService = ref.watch(assistantServiceProvider);
  
  return SendMessageUseCase(
    chatRepository: chatRepository,
    assistantService: assistantService,
  );
});
