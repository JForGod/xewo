import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/assistant_service.dart';
import '../../models/interaction.dart';
import '../../models/assistant_response.dart';

/// 处理语音输入用例
class ProcessVoiceInputUseCase {
  final AssistantService _assistantService;
  
  /// 构造函数
  ProcessVoiceInputUseCase({
    required AssistantService assistantService,
  }) : _assistantService = assistantService;
  
  /// 执行用例
  // 2025-03-16 + 执行语音输入处理功能
  Future<AssistantResponse> execute({
    required List<int> audioData,
    required String audioFormat,
    double? confidence,
    Map<String, dynamic>? metadata,
  }) async {
    // 创建语音交互对象
    final interaction = Interaction(
      type: InteractionType.voice,
      content: '', // 语音内容将由助手服务解析
      attachments: [
        {
          'type': 'audio',
          'data': audioData,
          'format': audioFormat,
          'confidence': confidence ?? 1.0,
        },
      ],
      metadata: metadata ?? {},
    );
    
    // 处理交互并获取响应
    return await _assistantService.handleInteraction(interaction);
  }
}

/// 处理语音输入用例提供者
final processVoiceInputUseCaseProvider = Provider<ProcessVoiceInputUseCase>((ref) {
  final assistantService = ref.watch(assistantServiceProvider);
  
  return ProcessVoiceInputUseCase(
    assistantService: assistantService,
  );
});
