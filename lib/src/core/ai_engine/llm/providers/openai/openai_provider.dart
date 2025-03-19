import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../llm_service.dart';
import 'openai_config.dart';

/// OpenAI提供者
/// 
/// 使用OpenAI API实现LLM服务接口
class OpenAIProvider implements LLMService {
  /// 配置
  final OpenAIConfig config;
  
  /// 默认API基础URL
  static const String _defaultApiBaseUrl = 'https://api.openai.com/v1';
  
  /// 默认模型
  static const String _defaultModel = 'gpt-4';

  /// HTTP客户端
  final http.Client _client = http.Client();
  
  /// 构造函数
  OpenAIProvider({Map<String, dynamic>? config})
      : config = OpenAIConfig.fromMap(config ?? {});
  
  @override
  Future<String> processInput(
    String input, {
    Map<String, dynamic>? context,
    Map<String, dynamic>? options,
  }) async {
    final processingOptions = options != null
        ? LLMProcessingOptions(
            temperature: options['temperature'] ?? 0.7,
            maxTokens: options['maxTokens'] ?? 1000,
            streaming: options['streaming'] ?? false,
            stopSequences: options['stopSequences'] ?? [],
          )
        : const LLMProcessingOptions();
    
    final Map<String, dynamic> requestBody = {
      'model': config.model,
      'messages': _buildMessages(input, context),
      'temperature': processingOptions.temperature,
      'max_tokens': processingOptions.maxTokens,
      'stream': processingOptions.streaming,
    };
    
    if (processingOptions.stopSequences.isNotEmpty) {
      requestBody['stop'] = processingOptions.stopSequences;
    }
    
    final response = await _client.post(
      Uri.parse('${config.apiBaseUrl}/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.apiKey}',
      },
      body: jsonEncode(requestBody),
    );
    
    if (response.statusCode != 200) {
      throw Exception('OpenAI API错误: ${response.statusCode} - ${response.body}');
    }
    
    final responseData = jsonDecode(response.body);
    return responseData['choices'][0]['message']['content'];
  }
  
  @override
  Future<void> learn(
    String context, {
    Map<String, dynamic>? metadata,
  }) async {
    // OpenAI不直接支持学习，这可以通过微调API实现
    // 此处为简化版实现
    print('学习上下文: $context');
    print('元数据: $metadata');
  }
  
  @override
  Future<void> optimize({Map<String, dynamic>? options}) async {
    // OpenAI不直接支持本地优化
    print('优化选项: $options');
  }
  
  @override
  Map<String, dynamic> getModelInfo() {
    return LLMModelInfo(
      name: config.model,
      provider: 'OpenAI',
      version: '1.0',
      capabilities: ['chat', 'completion', 'function_calling'],
    ).toMap();
  }
  
  @override
  Future<void> setParameters(Map<String, dynamic> parameters) async {
    // 更新配置
    if (parameters.containsKey('model')) {
      config.model = parameters['model'];
    }
    
    if (parameters.containsKey('apiKey')) {
      config.apiKey = parameters['apiKey'];
    }
    
    if (parameters.containsKey('apiBaseUrl')) {
      config.apiBaseUrl = parameters['apiBaseUrl'];
    }
    
    if (parameters.containsKey('organization')) {
      config.organization = parameters['organization'];
    }
  }
  
  /// 构建消息列表
  List<Map<String, dynamic>> _buildMessages(
    String input,
    Map<String, dynamic>? context,
  ) {
    final List<Map<String, dynamic>> messages = [];
    
    // 添加系统消息
    if (config.systemMessage.isNotEmpty) {
      messages.add({
        'role': 'system',
        'content': config.systemMessage,
      });
    }
    
    // 添加上下文消息
    if (context != null && context.containsKey('messages')) {
      final contextMessages = context['messages'] as List<dynamic>;
      for (final message in contextMessages) {
        messages.add({
          'role': message['role'],
          'content': message['content'],
        });
      }
    }
    
    // 添加用户输入
    messages.add({
      'role': 'user',
      'content': input,
    });
    
    return messages;
  }
  
  /// 释放资源
  void dispose() {
    _client.close();
  }
} 