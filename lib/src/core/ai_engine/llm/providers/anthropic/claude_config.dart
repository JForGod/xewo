/// Claude配置类
/// 
/// 管理Anthropic Claude服务的配置参数
class ClaudeConfig {
  /// API密钥
  String apiKey;
  
  /// API基础URL
  String apiBaseUrl;
  
  /// 模型名称
  String model;
  
  /// 系统提示信息
  String systemPrompt;
  
  /// 重试次数
  int maxRetries;
  
  /// 超时时间（毫秒）
  int timeoutMs;
  
  /// 最大令牌数
  int maxTokens;
  
  /// 构造函数
  ClaudeConfig({
    required this.apiKey,
    this.apiBaseUrl = 'https://api.anthropic.com',
    this.model = 'claude-3-opus-20240229',
    this.systemPrompt = '',
    this.maxRetries = 3,
    this.timeoutMs = 60000,
    this.maxTokens = 4000,
  });
  
  /// 从Map创建配置
  factory ClaudeConfig.fromMap(Map<String, dynamic> map) {
    return ClaudeConfig(
      apiKey: map['apiKey'] ?? '',
      apiBaseUrl: map['apiBaseUrl'] ?? 'https://api.anthropic.com',
      model: map['model'] ?? 'claude-3-opus-20240229',
      systemPrompt: map['systemPrompt'] ?? '',
      maxRetries: map['maxRetries'] ?? 3,
      timeoutMs: map['timeoutMs'] ?? 60000,
      maxTokens: map['maxTokens'] ?? 4000,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'apiKey': apiKey,
      'apiBaseUrl': apiBaseUrl,
      'model': model,
      'systemPrompt': systemPrompt,
      'maxRetries': maxRetries,
      'timeoutMs': timeoutMs,
      'maxTokens': maxTokens,
    };
  }
  
  /// 克隆配置
  ClaudeConfig clone() {
    return ClaudeConfig.fromMap(toMap());
  }
  
  /// 合并配置
  void merge(ClaudeConfig other) {
    if (other.apiKey.isNotEmpty) {
      apiKey = other.apiKey;
    }
    
    if (other.apiBaseUrl.isNotEmpty) {
      apiBaseUrl = other.apiBaseUrl;
    }
    
    if (other.model.isNotEmpty) {
      model = other.model;
    }
    
    if (other.systemPrompt.isNotEmpty) {
      systemPrompt = other.systemPrompt;
    }
    
    maxRetries = other.maxRetries;
    timeoutMs = other.timeoutMs;
    maxTokens = other.maxTokens;
  }
} 