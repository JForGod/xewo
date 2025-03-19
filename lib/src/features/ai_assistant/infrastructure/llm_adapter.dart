import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ai_engine/llm/llm_service.dart';
import '../../core/services/logging/logging_service.dart';
import '../../core/services/error/error_handling_service.dart';
import '../domain/models/chat_message.dart';

/// LLM适配器类型
enum LLMAdapterType {
  chat,    // 聊天
  completion, // 补全
  embedding, // 嵌入
  image,    // 图像
  audio,    // 音频
}

/// LLM适配器
class LLMAdapter {
  final LLMService _llmService;
  final LoggingService _loggingService;
  final ErrorHandlingService _errorHandlingService;
  
  /// 构造函数
  LLMAdapter({
    required LLMService llmService,
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
  })  : _llmService = llmService,
        _loggingService = loggingService,
        _errorHandlingService = errorHandlingService;
  
  // 2025-03-16 + 处理聊天功能
  Future<ChatMessage> processChatMessage(
    List<ChatMessage> history, 
    String prompt, {
    Map<String, dynamic>? options,
  }) async {
    try {
      _loggingService.info('处理聊天消息', tags: {'prompt_length': prompt.length});
      
      // 构建上下文历史
      final formattedHistory = _formatChatHistory(history);
      
      // 发送到LLM服务
      final result = await _llmService.processChatCompletion(
        formattedHistory,
        prompt,
        options: options,
      );
      
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: result.content,
        role: 'assistant',
        timestamp: DateTime.now(),
        metadata: {
          'model': result.model,
          'tokens': result.tokens,
          'finish_reason': result.finishReason,
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.network,
        severity: ErrorSeverity.high,
        message: '处理聊天消息失败',
      );
      
      // 返回错误消息
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '抱歉，我无法处理您的请求。请稍后再试。',
        role: 'assistant',
        timestamp: DateTime.now(),
        metadata: {
          'error': true,
          'error_message': e.toString(),
        },
      );
    }
  }
  
  // 2025-03-16 + 流式处理聊天功能
  Stream<ChatMessage> streamChatMessage(
    List<ChatMessage> history, 
    String prompt, {
    Map<String, dynamic>? options,
  }) async* {
    try {
      _loggingService.info('流式处理聊天消息', tags: {'prompt_length': prompt.length});
      
      // 构建上下文历史
      final formattedHistory = _formatChatHistory(history);
      
      // 创建初始消息
      final baseMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '',
        role: 'assistant',
        timestamp: DateTime.now(),
        metadata: {},
      );
      
      yield baseMessage;
      
      // 获取流式响应
      final stream = _llmService.streamChatCompletion(
        formattedHistory,
        prompt,
        options: options,
      );
      
      String contentBuffer = '';
      
      await for (final chunk in stream) {
        contentBuffer += chunk.content;
        
        yield baseMessage.copyWith(
          content: contentBuffer,
          metadata: {
            'model': chunk.model,
            'streaming': true,
            'finish_reason': chunk.finishReason,
          },
        );
      }
      
      // 最终消息
      yield baseMessage.copyWith(
        content: contentBuffer,
        metadata: {
          'model': _llmService.getDefaultModel(),
          'streaming': false,
          'finish_reason': 'stop',
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.network,
        severity: ErrorSeverity.high,
        message: '流式处理聊天消息失败',
      );
      
      // 返回错误消息
      yield ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '抱歉，我无法处理您的请求。请稍后再试。',
        role: 'assistant',
        timestamp: DateTime.now(),
        metadata: {
          'error': true,
          'error_message': e.toString(),
        },
      );
    }
  }
  
  // 2025-03-16 + 处理文本补全功能
  Future<String> processTextCompletion(
    String prompt, {
    Map<String, dynamic>? options,
  }) async {
    try {
      _loggingService.info('处理文本补全', tags: {'prompt_length': prompt.length});
      
      // 发送到LLM服务
      final result = await _llmService.processTextCompletion(
        prompt,
        options: options,
      );
      
      return result.content;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.network,
        severity: ErrorSeverity.medium,
        message: '处理文本补全失败',
      );
      
      // 返回错误消息
      return '抱歉，我无法完成文本补全。请稍后再试。';
    }
  }
  
  // 2025-03-16 + 处理嵌入功能
  Future<List<double>> processEmbedding(String text) async {
    try {
      _loggingService.info('处理嵌入', tags: {'text_length': text.length});
      
      // 发送到LLM服务
      final result = await _llmService.processEmbedding(text);
      
      return result;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.network,
        severity: ErrorSeverity.medium,
        message: '处理嵌入失败',
      );
      
      // 返回空数组
      return [];
    }
  }
  
  // 2025-03-16 + 处理图像生成功能
  Future<String> processImageGeneration(
    String prompt, {
    Map<String, dynamic>? options,
  }) async {
    try {
      _loggingService.info('处理图像生成', tags: {'prompt_length': prompt.length});
      
      // 发送到LLM服务
      final result = await _llmService.processImageGeneration(
        prompt,
        options: options,
      );
      
      return result.url;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.network,
        severity: ErrorSeverity.medium,
        message: '处理图像生成失败',
      );
      
      // 返回错误消息
      return '';
    }
  }
  
  // 2025-03-16 + 处理音频转文本功能
  Future<String> processAudioTranscription(
    String audioPath, {
    String? language,
  }) async {
    try {
      _loggingService.info('处理音频转文本', tags: {'audio_path': audioPath});
      
      // 发送到LLM服务
      final result = await _llmService.processAudioTranscription(
        audioPath,
        language: language,
      );
      
      return result.text;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.network,
        severity: ErrorSeverity.medium,
        message: '处理音频转文本失败',
      );
      
      // 返回错误消息
      return '抱歉，我无法转录音频。请稍后再试。';
    }
  }
  
  // 2025-03-16 + 处理文本到语音功能
  Future<String> processTextToSpeech(
    String text, {
    String? voice,
  }) async {
    try {
      _loggingService.info('处理文本到语音', tags: {'text_length': text.length});
      
      // 发送到LLM服务
      final result = await _llmService.processTextToSpeech(
        text,
        voice: voice,
      );
      
      return result.audioPath;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.network,
        severity: ErrorSeverity.medium,
        message: '处理文本到语音失败',
      );
      
      // 返回错误消息
      return '';
    }
  }
  
  // 2025-03-16 + 工具调用功能
  Future<Map<String, dynamic>> processToolCall(
    String toolName,
    Map<String, dynamic> params,
  ) async {
    try {
      _loggingService.info('处理工具调用', tags: {'tool_name': toolName});
      
      // 发送到LLM服务
      final result = await _llmService.processToolCall(
        toolName,
        params,
      );
      
      return result;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.network,
        severity: ErrorSeverity.high,
        message: '处理工具调用失败',
      );
      
      // 返回错误消息
      return {'error': true, 'message': '工具调用失败：${e.toString()}'};
    }
  }
  
  // 2025-03-16 + 格式化聊天历史功能
  List<Map<String, String>> _formatChatHistory(List<ChatMessage> messages) {
    return messages.map((message) => {
      'role': message.role,
      'content': message.content,
    }).toList();
  }
}

/// LLM适配器提供者
final llmAdapterProvider = Provider<LLMAdapter>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  
  return LLMAdapter(
    llmService: llmService,
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
  );
});
