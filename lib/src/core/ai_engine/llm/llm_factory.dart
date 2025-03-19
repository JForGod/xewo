import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'llm_service.dart';
import 'providers/openai/openai_provider.dart';
import 'providers/anthropic/claude_provider.dart';
import 'providers/local/local_provider.dart';

/// LLM提供者类型
enum LLMProviderType {
  /// OpenAI提供者
  openAI,
  
  /// Anthropic提供者
  claude,
  
  /// 本地模型提供者
  local,
  
  /// 自定义提供者
  custom,
}

/// LLM工厂类
/// 
/// 负责创建和管理不同的LLM服务实例
class LLMFactory {
  /// 缓存的LLM服务实例
  final Map<String, LLMService> _serviceInstances = {};
  
  /// 根据提供者类型创建LLM服务
  /// 
  /// [type] 提供者类型
  /// [config] 配置参数
  Future<LLMService> createService(
    LLMProviderType type, {
    Map<String, dynamic>? config,
  }) async {
    final configKey = '${type.name}_${config.hashCode}';
    
    // 如果已经创建过该配置的实例，直接返回
    if (_serviceInstances.containsKey(configKey)) {
      return _serviceInstances[configKey]!;
    }
    
    // 根据类型创建对应的服务
    late LLMService service;
    
    switch (type) {
      case LLMProviderType.openAI:
        service = OpenAIProvider(config: config ?? {});
        break;
      case LLMProviderType.claude:
        service = ClaudeProvider(config: config ?? {});
        break;
      case LLMProviderType.local:
        service = LocalProvider(config: config ?? {});
        break;
      case LLMProviderType.custom:
        throw UnimplementedError('自定义LLM提供者尚未实现');
    }
    
    // 缓存实例
    _serviceInstances[configKey] = service;
    
    return service;
  }
  
  /// 根据名称获取LLM服务
  /// 
  /// [name] 提供者名称
  /// [config] 配置参数
  Future<LLMService> getServiceByName(
    String name, {
    Map<String, dynamic>? config,
  }) async {
    // 解析名称对应的类型
    LLMProviderType? type;
    
    if (name.toLowerCase().contains('openai') || 
        name.toLowerCase().contains('gpt')) {
      type = LLMProviderType.openAI;
    } else if (name.toLowerCase().contains('claude') || 
               name.toLowerCase().contains('anthropic')) {
      type = LLMProviderType.claude;
    } else if (name.toLowerCase().contains('local') || 
               name.toLowerCase().contains('offline')) {
      type = LLMProviderType.local;
    } else {
      throw ArgumentError('不支持的LLM提供者名称: $name');
    }
    
    return createService(type, config: config);
  }
  
  /// 释放服务实例
  void disposeService(String key) {
    _serviceInstances.remove(key);
  }
  
  /// 释放所有服务实例
  void disposeAll() {
    _serviceInstances.clear();
  }
}

/// LLM工厂提供者
final llmFactoryProvider = Provider<LLMFactory>((ref) {
  return LLMFactory();
}); 