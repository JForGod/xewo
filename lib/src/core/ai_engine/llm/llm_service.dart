import 'package:flutter/foundation.dart';

/// LLM服务接口
/// 
/// 定义与大语言模型交互的核心方法
abstract class LLMService {
  /// 处理用户输入并返回响应
  /// 
  /// [input] 用户输入的文本
  /// [context] 上下文信息
  /// [options] 处理选项
  Future<String> processInput(
    String input, {
    Map<String, dynamic>? context,
    Map<String, dynamic>? options,
  });
  
  /// 从上下文中学习
  /// 
  /// [context] 学习的上下文信息
  /// [metadata] 元数据
  Future<void> learn(
    String context, {
    Map<String, dynamic>? metadata,
  });
  
  /// 优化模型性能
  /// 
  /// [options] 优化选项
  Future<void> optimize({Map<String, dynamic>? options});
  
  /// 获取模型信息
  /// 
  /// 返回当前使用的模型信息
  Map<String, dynamic> getModelInfo();
  
  /// 设置模型参数
  /// 
  /// [parameters] 要设置的参数
  Future<void> setParameters(Map<String, dynamic> parameters);
  
  /// 测试连接
  Future<bool> testConnection();
  
  /// 会话测试
  Future<String> sessionTest();
  
  /// 发送消息并获取响应
  Future<String> sendMessage(String message, List<Map<String, String>> history);
  
  /// 分析图像
  Future<String> analyzeImage(String base64Image, String prompt);
}

/// LLM服务结果
class LLMResult {
  /// 响应文本
  final String text;
  
  /// 置信度 (0.0-1.0)
  final double confidence;
  
  /// 额外元数据
  final Map<String, dynamic> metadata;
  
  /// 生成时间
  final DateTime timestamp;
  
  /// 构造函数
  const LLMResult({
    required this.text,
    this.confidence = 1.0,
    this.metadata = const {},
    required this.timestamp,
  });
}

/// LLM处理选项
class LLMProcessingOptions {
  /// 温度 (0.0-1.0)
  final double temperature;
  
  /// 最大标记数
  final int maxTokens;
  
  /// 是否流式处理
  final bool streaming;
  
  /// 停止序列
  final List<String> stopSequences;
  
  /// 其他选项
  final Map<String, dynamic> additionalOptions;
  
  /// 构造函数
  const LLMProcessingOptions({
    this.temperature = 0.7,
    this.maxTokens = 1000,
    this.streaming = false,
    this.stopSequences = const [],
    this.additionalOptions = const {},
  });
}

/// LLM模型信息
class LLMModelInfo {
  /// 模型名称
  final String name;
  
  /// 模型提供者
  final String provider;
  
  /// 模型版本
  final String version;
  
  /// 模型能力
  final List<String> capabilities;
  
  /// 模型参数数量
  final int? parameterCount;
  
  /// 构造函数
  const LLMModelInfo({
    required this.name,
    required this.provider,
    required this.version,
    this.capabilities = const [],
    this.parameterCount,
  });
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'provider': provider,
      'version': version,
      'capabilities': capabilities,
      'parameterCount': parameterCount,
    };
  }
} 