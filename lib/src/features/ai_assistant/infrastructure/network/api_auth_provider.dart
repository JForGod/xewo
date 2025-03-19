import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/logging/logging_service.dart';
import '../../../../core/services/security/security_service.dart';
import '../../../../core/services/session/session_management_service.dart';

/// API认证提供者
class ApiAuthProvider {
  final SecurityService _securityService;
  final SessionManagementService _sessionService;
  final LoggingService _loggingService;
  
  /// 构造函数
  ApiAuthProvider({
    required SecurityService securityService,
    required SessionManagementService sessionService,
    required LoggingService loggingService,
  })  : _securityService = securityService,
        _sessionService = sessionService,
        _loggingService = loggingService;
  
  // 2025-03-16 + 获取认证头功能
  Future<Map<String, String>> getAuthHeaders() async {
    try {
      // 获取当前会话
      final session = await _sessionService.getCurrentSession();
      
      if (session != null && session.accessToken != null) {
        return {
          'Authorization': 'Bearer ${session.accessToken}',
        };
      }
      
      return {};
    } catch (e) {
      _loggingService.error('获取认证头失败', tags: {'error': e.toString()});
      return {};
    }
  }
  
  // 2025-03-16 + 刷新令牌功能
  Future<bool> refreshToken() async {
    try {
      final session = await _sessionService.getCurrentSession();
      
      if (session == null || session.refreshToken == null) {
        _loggingService.warning('无法刷新令牌，没有可用的刷新令牌');
        return false;
      }
      
      // 尝试使用刷新令牌获取新的访问令牌
      final result = await _sessionService.refreshTokens(session.refreshToken!);
      
      return result;
    } catch (e) {
      _loggingService.error('刷新令牌失败', tags: {'error': e.toString()});
      return false;
    }
  }
}

/// API认证提供者 Provider
final apiAuthProviderProvider = Provider<ApiAuthProvider>((ref) {
  final securityService = ref.watch(securityServiceProvider);
  final sessionService = ref.watch(sessionManagementServiceProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  
  return ApiAuthProvider(
    securityService: securityService,
    sessionService: sessionService,
    loggingService: loggingService,
  );
});
