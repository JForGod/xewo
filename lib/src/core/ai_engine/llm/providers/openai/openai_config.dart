/// OpenAI配置类
/// 
/// 管理OpenAI服务的配置参数
class OpenAIConfig {
  /// API密钥
  String apiKey;
  
  /// API基础URL
  String apiBaseUrl;
  
  /// 模型名称
  String model;
  
  /// 组织ID
  String? organization;
  
  /// 系统消息
  String systemMessage;
  
  /// 重试次数
  int maxRetries;
  
  /// 超时时间（毫秒）
  int timeoutMs;
  
  /// 构造函数
  OpenAIConfig({
    required this.apiKey,
    this.apiBaseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4',
    this.organization,
    this.systemMessage = '',
    this.maxRetries = 3,
    this.timeoutMs = 30000,
  });
  
  /// 从Map创建配置
  factory OpenAIConfig.fromMap(Map<String, dynamic> map) {
    return OpenAIConfig(
      apiKey: map['apiKey'] ?? '',
      apiBaseUrl: map['apiBaseUrl'] ?? 'https://api.openai.com/v1',
      model: map['model'] ?? 'gpt-4',
      organization: map['organization'],
      systemMessage: map['systemMessage'] ?? '',
      maxRetries: map['maxRetries'] ?? 3,
      timeoutMs: map['timeoutMs'] ?? 30000,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'apiKey': apiKey,
      'apiBaseUrl': apiBaseUrl,
      'model': model,
      'organization': organization,
      'systemMessage': systemMessage,
      'maxRetries': maxRetries,
      'timeoutMs': timeoutMs,
    };
  }
  
  /// 克隆配置
  OpenAIConfig clone() {
    return OpenAIConfig.fromMap(toMap());
  }
  
  /// 合并配置
  void merge(OpenAIConfig other) {
    if (other.apiKey.isNotEmpty) {
      apiKey = other.apiKey;
    }
    
    if (other.apiBaseUrl.isNotEmpty) {
      apiBaseUrl = other.apiBaseUrl;
    }
    
    if (other.model.isNotEmpty) {
      model = other.model;
    }
    
    if (other.organization != null) {
      organization = other.organization;
    }
    
    if (other.systemMessage.isNotEmpty) {
      systemMessage = other.systemMessage;
    }
    
    maxRetries = other.maxRetries;
    timeoutMs = other.timeoutMs;
  }
} 