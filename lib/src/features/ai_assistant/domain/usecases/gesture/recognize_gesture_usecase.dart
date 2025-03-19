import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/assistant_service.dart';
import '../../models/interaction.dart';
import '../../models/assistant_response.dart';
import '../../models/gesture_data.dart';

/// 识别手势用例
class RecognizeGestureUseCase {
  final AssistantService _assistantService;
  
  /// 构造函数
  RecognizeGestureUseCase({
    required AssistantService assistantService,
  }) : _assistantService = assistantService;
  
  /// 执行用例
  // 2025-03-16 + 执行手势识别功能
  Future<AssistantResponse> execute({
    required GestureData gestureData,
    double? confidence,
    Map<String, dynamic>? metadata,
  }) async {
    // 创建手势交互对象
    final interaction = Interaction(
      type: InteractionType.gesture,
      content: gestureData.type.name,
      attachments: [
        {
          'type': 'gesture',
          'gesture_type': gestureData.type.name,
          'points': gestureData.points.map((p) => p.toMap()).toList(),
          'duration': gestureData.duration.inMilliseconds,
          'confidence': confidence ?? gestureData.confidence,
        },
      ],
      metadata: metadata ?? {},
    );
    
    // 处理交互并获取响应
    return await _assistantService.handleInteraction(interaction);
  }
}

/// 识别手势用例提供者
final recognizeGestureUseCaseProvider = Provider<RecognizeGestureUseCase>((ref) {
  final assistantService = ref.watch(assistantServiceProvider);
  
  return RecognizeGestureUseCase(
    assistantService: assistantService,
  );
});
