// 2025-03-17: 新增 - LLM配置服务
// 2025-03-18: 修改 - 添加代理配置支持

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'llm_service.dart';
import 'gemini_llm_service.dart';

/// LLM提供者枚举
enum LLMProvider {
  /// 谷歌Gemini
  gemini,
  
  /// OpenAI
  openAI,
  
  /// 模拟/本地 
  mock,
  
  /// 其他 - 自定义配置
  custom,
}

/// LLM配置服务
/// 
/// 管理不同的LLM提供者配置和服务实例
class LLMConfigService {
  /// SharedPreferences实例
  final SharedPreferences _prefs;
  
  /// 存储密钥的键
  static const String _apiKeysKey = 'llm_api_keys';
  
  /// 当前提供者的键
  static const String _currentProviderKey = 'llm_current_provider';
  
  /// 配置的键
  static const String _configKey = 'llm_config';
  
  /// 代理配置的键
  static const String _proxyConfigKey = 'llm_proxy_config';
  
  /// 当前活动的LLM服务
  LLMService? _activeLLMService;
  
  /// 构造函数
  LLMConfigService(this._prefs);
  
  /// 获取当前提供者
  LLMProvider getCurrentProvider() {
    final providerString = _prefs.getString(_currentProviderKey);
    if (providerString == null) {
      return LLMProvider.gemini; // 默认使用Gemini
    }
    
    return LLMProvider.values.firstWhere(
      (e) => e.toString() == 'LLMProvider.$providerString',
      orElse: () => LLMProvider.gemini,
    );
  }
  
  /// 设置当前提供者
  Future<void> setCurrentProvider(LLMProvider provider) async {
    await _prefs.setString(
      _currentProviderKey, 
      provider.toString().split('.').last,
    );
    
    // 清除当前活动服务，以便下次懒加载
    _activeLLMService = null;
  }
  
  /// 获取API密钥
  String? getApiKey(LLMProvider provider) {
    final keys = _getApiKeys();
    return keys[provider.toString().split('.').last];
  }
  
  /// 保存API密钥
  Future<void> saveApiKey(LLMProvider provider, String apiKey) async {
    final keys = _getApiKeys();
    keys[provider.toString().split('.').last] = apiKey;
    await _prefs.setString(_apiKeysKey, jsonEncode(keys));
  }
  
  /// 获取配置
  Map<String, dynamic> getConfig(LLMProvider provider) {
    final configsString = _prefs.getString(_configKey);
    if (configsString == null) {
      return {};
    }
    
    try {
      final configs = jsonDecode(configsString) as Map<String, dynamic>;
      final providerKey = provider.toString().split('.').last;
      return configs[providerKey] as Map<String, dynamic>? ?? {};
    } catch (e) {
      if (kDebugMode) {
        print('解析LLM配置失败: $e');
      }
      return {};
    }
  }
  
  /// 保存配置
  Future<void> saveConfig(LLMProvider provider, Map<String, dynamic> config) async {
    final configsString = _prefs.getString(_configKey);
    Map<String, dynamic> configs = {};
    
    if (configsString != null) {
      try {
        configs = jsonDecode(configsString) as Map<String, dynamic>;
      } catch (e) {
        if (kDebugMode) {
          print('解析LLM配置失败: $e');
        }
      }
    }
    
    final providerKey = provider.toString().split('.').last;
    configs[providerKey] = config;
    
    await _prefs.setString(_configKey, jsonEncode(configs));
  }

  /// 获取代理配置
  Map<String, dynamic> getProxyConfig() {
    final proxyConfigString = _prefs.getString(_proxyConfigKey);
    if (proxyConfigString == null) {
      return {
        'useProxy': false,  // 默认不启用代理
        'proxyHost': '127.0.0.1',
        'proxyPort': 1080,
      };
    }
    
    try {
      return jsonDecode(proxyConfigString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('解析代理配置失败: $e');
      }
      return {
        'useProxy': false,  // 默认不启用代理
        'proxyHost': '127.0.0.1',
        'proxyPort': 1080,
      };
    }
  }
  
  /// 保存代理配置
  Future<void> saveProxyConfig({
    required bool useProxy,
    required String proxyHost,
    required int proxyPort,
  }) async {
    final config = {
      'useProxy': useProxy,
      'proxyHost': proxyHost,
      'proxyPort': proxyPort,
    };
    
    await _prefs.setString(_proxyConfigKey, jsonEncode(config));
    
    // 清除当前活动服务，以便下次使用新代理配置
    _activeLLMService = null;
  }
  
  /// 获取可用的模型列表
  List<String> getAvailableModels(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.gemini:
        return ['gemini-1.5-pro', 'gemini-1.5-flash', 'gemini-1.0-pro'];
      case LLMProvider.openAI:
        return ['gpt-3.5-turbo', 'gpt-4', 'gpt-4-turbo'];
      case LLMProvider.mock:
        return ['mock-basic', 'mock-advanced'];
      case LLMProvider.custom:
        return [];
    }
  }
  
  /// 获取当前活动的LLM服务
  Future<LLMService> getActiveLLMService() async {
    if (_activeLLMService != null) {
      return _activeLLMService!;
    }
    
    final provider = getCurrentProvider();
    final apiKey = getApiKey(provider);
    final config = getConfig(provider);
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API密钥未配置');
    }
    
    // 获取代理配置
    final proxyConfig = getProxyConfig();
    
    try {
      switch (provider) {
        case LLMProvider.gemini:
          _activeLLMService = await GeminiLLMService.create(
            apiKey,
            useProxy: proxyConfig['useProxy'] as bool? ?? true,
          );
          if (kDebugMode) {
            print('已创建Gemini LLM服务，代理状态: ${proxyConfig['useProxy']}');
          }
          break;
        case LLMProvider.openAI:
          // 待实现
          throw UnimplementedError('OpenAI服务尚未实现');
        case LLMProvider.mock:
          // 待实现
          throw UnimplementedError('模拟服务尚未实现');
        case LLMProvider.custom:
          // 待实现
          throw UnimplementedError('自定义服务尚未实现');
      }
    } catch (e) {
      if (kDebugMode) {
        print('初始化LLM服务失败: $e');
      }
      throw Exception('初始化LLM服务失败: $e');
    }
    
    return _activeLLMService!;
  }
  
  /// 获取所有API密钥
  Map<String, String> _getApiKeys() {
    final keysString = _prefs.getString(_apiKeysKey);
    if (keysString == null) {
      return {};
    }
    
    try {
      final dynamic keysJson = jsonDecode(keysString);
      return Map<String, String>.from(keysJson as Map);
    } catch (e) {
      if (kDebugMode) {
        print('解析API密钥失败: $e');
      }
      return {};
    }
  }
  
  /// 清除配置
  Future<void> clearConfig() async {
    await _prefs.remove(_apiKeysKey);
    await _prefs.remove(_currentProviderKey);
    await _prefs.remove(_configKey);
    await _prefs.remove(_proxyConfigKey);
    _activeLLMService = null;
  }
  
  /// 检查是否已配置API密钥
  bool hasConfiguredApiKey() {
    final provider = getCurrentProvider();
    final apiKey = getApiKey(provider);
    return apiKey != null && apiKey.isNotEmpty;
  }
  
  /// 获取提供者显示名称
  static String getProviderDisplayName(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.gemini:
        return '谷歌 Gemini';
      case LLMProvider.openAI:
        return 'OpenAI';
      case LLMProvider.mock:
        return '模拟服务';
      case LLMProvider.custom:
        return '自定义服务';
    }
  }
  
  /// 工厂方法：创建实例
  static Future<LLMConfigService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LLMConfigService(prefs);
  }
  
  /// 重置活动LLM服务
  Future<void> resetActiveService() async {
    _activeLLMService = null;
  }
} 