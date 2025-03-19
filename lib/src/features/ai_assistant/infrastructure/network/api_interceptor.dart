import 'package:flutter_riverpod/flutter_riverpod.dart';

/// API拦截器接口
abstract class ApiInterceptor {
  /// 请求拦截
  Future<Map<String, dynamic>> onRequest(Map<String, dynamic> request);
  
  /// 响应拦截
  Future<Map<String, dynamic>> onResponse(Map<String, dynamic> response);
}

/// 日志拦截器
class LoggingInterceptor implements ApiInterceptor {
  @override
  Future<Map<String, dynamic>> onRequest(Map<String, dynamic> request) async {
    // 可以在这里记录请求信息
    return request;
  }
  
  @override
  Future<Map<String, dynamic>> onResponse(Map<String, dynamic> response) async {
    // 可以在这里记录响应信息
    return response;
  }
}

/// 安全拦截器
class SecurityInterceptor implements ApiInterceptor {
  @override
  Future<Map<String, dynamic>> onRequest(Map<String, dynamic> request) async {
    // 可以在这里添加安全头或处理敏感信息
    return request;
  }
  
  @override
  Future<Map<String, dynamic>> onResponse(Map<String, dynamic> response) async {
    // 可以在这里处理响应中的敏感信息
    return response;
  }
}

/// API拦截器提供者
final apiInterceptorsProvider = Provider<List<ApiInterceptor>>((ref) {
  return [
    LoggingInterceptor(),
    SecurityInterceptor(),
  ];
});
