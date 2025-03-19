import 'package:flutter_riverpod/flutter_riverpod.dart';

/// API配置
class ApiConfig {
  final String baseUrl;
  final Duration defaultTimeout;
  final int maxRetries;
  final bool enableLogging;
  
  /// 构造函数
  ApiConfig({
    required this.baseUrl,
    this.defaultTimeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.enableLogging = true,
  });
  
  /// 是否有有效配置
  bool get hasValidConfig => baseUrl.isNotEmpty;
}

/// API配置提供者
final apiConfigProvider = Provider<ApiConfig>((ref) {
  return ApiConfig(
    baseUrl: 'https://api.xewo.example.com/v1',  // 实际项目中应该从配置文件或环境变量中获取
  );
});
