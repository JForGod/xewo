import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../llm_service.dart';
import 'claude_config.dart';

/// Claude提供者
/// 
/// 使用Anthropic Claude API实现LLM服务接口
class ClaudeProvider implements LLMService {
  /// 配置
  final ClaudeConfig config;
  
  /// HTTP客户端
  final http.Client _client = http.Client();
  
  /// API版本
  static const String _apiVersion = 'v1';
  
  /// 构造函数
  ClaudeProvider({Map<String, dynamic>? config})
      : config = ClaudeConfig.fromMap(config ?? {});
  
  @override
  Future<String> processInput(
    String input, {
    Map<String, dynamic>? context,
    Map<String, dynamic>? options,
  }) async {
    final processingOptions = options != null
        ? LLMProcessingOptions(
            temperature: options['temperature'] ?? 0.7,
            maxTokens: options['maxTokens'] ?? config.maxTokens,
            streaming: options['streaming'] ?? false,
            stopSequences: options['stopSequences'] ?? [],
          )
        : LLMProcessingOptions(maxTokens: config.maxTokens);
    
    final Map<String, dynamic> requestBody = {
      'model': config.model,
      'messages': _buildMessages(input, context),
      'temperature': processingOptions.temperature,
      'max_tokens': processingOptions.maxTokens,
    };
    
    if (config.systemPrompt.isNotEmpty) {
      requestBody['system'] = config.systemPrompt;
    }
    
    if (processingOptions.stopSequences.isNotEmpty) {
      requestBody['stop_sequences'] = processingOptions.stopSequences;
    }
    
    final response = await _client.post(
      Uri.parse('${config.apiBaseUrl}/$_apiVersion/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': config.apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode(requestBody),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Claude API错误: ${response.statusCode} - ${response.body}');
    }
    
    final responseData = jsonDecode(response.body);
    return responseData['content'][0]['text'] as String;
  }
  
  @override
  Future<void> learn(
    String context, {
    Map<String, dynamic>? metadata,
  }) async {
    // Anthropic没有直接的学习API
    print('学习请求被忽略: Claude不支持直接学习');
  }
  
  @override
  Future<void> optimize({Map<String, dynamic>? options}) async {
    // Claude不支持本地优化
    print('优化请求被忽略: Claude不支持本地优化');
  }
  
  @override
  Map<String, dynamic> getModelInfo() {
    return LLMModelInfo(
      name: config.model,
      provider: 'Anthropic',
      version: '1.0',
      capabilities: ['chat', 'completion', 'multilingual'],
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
    
    if (parameters.containsKey('systemPrompt')) {
      config.systemPrompt = parameters['systemPrompt'];
    }
    
    if (parameters.containsKey('maxTokens')) {
      config.maxTokens = parameters['maxTokens'];
    }
  }
  
  /// 构建消息列表
  List<Map<String, dynamic>> _buildMessages(
    String input,
    Map<String, dynamic>? context,
  ) {
    final List<Map<String, dynamic>> messages = [];
    
    // 添加上下文消息
    if (context != null && context.containsKey('messages')) {
      final contextMessages = context['messages'] as List<dynamic>;
      for (final message in contextMessages) {
        final role = _convertRole(message['role'] as String);
        messages.add({
          'role': role,
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
  
  /// 转换角色（OpenAI格式转换为Claude格式）
  String _convertRole(String openaiRole) {
    switch (openaiRole) {
      case 'system':
        return 'system';
      case 'assistant':
        return 'assistant';
      case 'user':
      default:
        return 'user';
    }
  }
  
  /// 释放资源
  void dispose() {
    _client.close();
  }
} 