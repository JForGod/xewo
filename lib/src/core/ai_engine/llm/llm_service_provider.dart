// 2025-03-17: 新增 - LLM服务提供者

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'llm_service.dart';
import 'llm_config_service.dart';

/// LLM服务状态
enum LLMServiceStatus {
  /// 未初始化
  uninitialized,
  
  /// 初始化中
  initializing,
  
  /// 就绪
  ready,
  
  /// 出错
  error,
}

/// LLM服务状态提供者
class LLMServiceNotifier extends StateNotifier<AsyncValue<LLMService>> {
  /// 配置服务
  final LLMConfigService _configService;
  
  /// 服务状态
  LLMServiceStatus _status = LLMServiceStatus.uninitialized;
  
  /// 错误信息
  String? _errorMessage;
  
  /// 会话历史
  List<Map<String, String>> _conversationHistory = [];
  
  /// 构造函数
  LLMServiceNotifier(this._configService) : super(const AsyncValue.loading()) {
    _initService();
  }
  
  /// 获取服务状态
  LLMServiceStatus get status => _status;
  
  /// 获取错误信息
  String? get errorMessage => _errorMessage;
  
  /// 获取会话历史
  List<Map<String, String>> get conversationHistory => List.unmodifiable(_conversationHistory);
  
  /// 初始化服务
  Future<void> _initService() async {
    if (_status == LLMServiceStatus.initializing) {
      return;
    }
    
    _status = LLMServiceStatus.initializing;
    _errorMessage = null;
    
    state = const AsyncValue.loading();
    
    try {
      // 检查是否配置了API密钥
      if (!_configService.hasConfiguredApiKey()) {
        _status = LLMServiceStatus.error;
        _errorMessage = '未配置API密钥，请前往设置配置LLM服务';
        state = AsyncValue.error(_errorMessage!, StackTrace.current);
        return;
      }
      
      // 初始化LLM服务
      final llmService = await _configService.getActiveLLMService();
      _status = LLMServiceStatus.ready;
      state = AsyncValue.data(llmService);
      
      if (kDebugMode) {
        print('LLM服务初始化成功');
      }
    } catch (e, stackTrace) {
      _status = LLMServiceStatus.error;
      _errorMessage = '初始化LLM服务失败: $e';
      state = AsyncValue.error(_errorMessage!, stackTrace);
      
      if (kDebugMode) {
        print('LLM服务初始化失败: $e');
        print(stackTrace);
      }
    }
  }
  
  /// 重新初始化服务
  Future<void> reinitialize() async {
    await _configService.resetActiveService();
    await _initService();
  }
  
  /// 执行LLM请求
  Future<String> processRequest(String input) async {
    try {
      // 如果服务未就绪，尝试初始化
      if (_status != LLMServiceStatus.ready) {
        await _initService();
        // 二次检查
        if (_status != LLMServiceStatus.ready) {
          throw Exception('LLM服务未就绪: $_errorMessage');
        }
      }
      
      final llmService = state.value;
      if (llmService == null) {
        throw Exception('LLM服务未初始化');
      }
      
      // 添加用户消息到历史
      _conversationHistory.add({
        'role': 'user',
        'content': input,
      });
      
      // 处理请求
      final response = await llmService.sendMessage(input, _conversationHistory);
      
      // 添加助手回复到历史
      _conversationHistory.add({
        'role': 'assistant',
        'content': response,
      });
      
      // 限制历史长度
      _trimHistory();
      
      return response;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('处理LLM请求失败: $e');
        print(stackTrace);
      }
      
      final errorMessage = '处理请求失败: $e';
      
      // 添加错误消息到历史
      _conversationHistory.add({
        'role': 'assistant',
        'content': errorMessage,
      });
      
      throw Exception(errorMessage);
    }
  }
  
  /// 分析图像
  Future<String> analyzeImage(String base64Image, String prompt) async {
    try {
      // 如果服务未就绪，尝试初始化
      if (_status != LLMServiceStatus.ready) {
        await _initService();
        // 二次检查
        if (_status != LLMServiceStatus.ready) {
          throw Exception('LLM服务未就绪: $_errorMessage');
        }
      }
      
      final llmService = state.value;
      if (llmService == null) {
        throw Exception('LLM服务未初始化');
      }
      
      // 添加用户消息到历史（不包含图像数据）
      _conversationHistory.add({
        'role': 'user',
        'content': '[图像分析] $prompt',
      });
      
      // 处理请求
      final response = await llmService.analyzeImage(base64Image, prompt);
      
      // 添加助手回复到历史
      _conversationHistory.add({
        'role': 'assistant',
        'content': response,
      });
      
      // 限制历史长度
      _trimHistory();
      
      return response;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('图像分析失败: $e');
        print(stackTrace);
      }
      
      final errorMessage = '图像分析失败: $e';
      
      // 添加错误消息到历史
      _conversationHistory.add({
        'role': 'assistant',
        'content': errorMessage,
      });
      
      throw Exception(errorMessage);
    }
  }
  
  /// 清除会话历史
  void clearHistory() {
    _conversationHistory.clear();
  }
  
  /// 限制历史长度
  void _trimHistory() {
    // 保留最近的20轮对话（40条消息）
    if (_conversationHistory.length > 40) {
      _conversationHistory = _conversationHistory.sublist(_conversationHistory.length - 40);
    }
  }
}

/// LLM配置服务提供者
final llmConfigServiceProvider = Provider<LLMConfigService>((ref) {
  throw UnimplementedError('请在主应用中初始化');
});

/// LLM服务提供者
final llmServiceProvider = StateNotifierProvider<LLMServiceNotifier, AsyncValue<LLMService>>((ref) {
  final configService = ref.watch(llmConfigServiceProvider);
  return LLMServiceNotifier(configService);
});

/// LLM服务状态提供者
final llmServiceStatusProvider = Provider<LLMServiceStatus>((ref) {
  final notifier = ref.watch(llmServiceProvider.notifier);
  return notifier.status;
});

/// LLM错误消息提供者
final llmErrorMessageProvider = Provider<String?>((ref) {
  final notifier = ref.watch(llmServiceProvider.notifier);
  return notifier.errorMessage;
});

/// 会话历史提供者
final conversationHistoryProvider = Provider<List<Map<String, String>>>((ref) {
  final notifier = ref.watch(llmServiceProvider.notifier);
  return notifier.conversationHistory;
}); 