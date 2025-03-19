/// 存储键常量
class StorageKeys {
  // 用户相关
  static const String currentUserId = 'current_user_id';
  static const String userProfile = 'users/{userId}/profile';
  static const String userPreferences = 'users/{userId}/preferences';
  static const String userHistory = 'users/{userId}/history';
  static const String userLearningData = 'users/{userId}/learning_data';
  
  // 会话相关
  static const String conversations = 'conversations';
  static const String conversation = 'conversations/{conversationId}';
  static const String messages = 'messages/{conversationId}';
  static const String message = 'messages/{conversationId}/{messageId}';
  
  // 设置相关
  static const String settings = 'settings';
  static const String setting = 'settings/{key}';
  static const String languageSetting = 'settings/language';
  static const String themeSetting = 'settings/theme';
  static const String notificationSetting = 'settings/notifications';
  
  // 认证相关
  static const String authToken = 'auth/token';
  static const String refreshToken = 'auth/refresh_token';
  static const String authState = 'auth/state';
  
  // 缓存相关
  static const String cache = 'cache/{key}';
  static const String responseCache = 'cache/responses/{endpoint}';
  static const String imageCache = 'cache/images/{url}';
  
  // 应用状态相关
  static const String lastActive = 'app/last_active';
  static const String onboardingComplete = 'app/onboarding_complete';
  static const String appVersion = 'app/version';
  
  // 安全相关
  static const String encryptionKey = 'security/encryption_key';
  static const String biometricEnabled = 'security/biometric_enabled';
  static const String securityLevel = 'security/level';
  
  /// 获取包含用户ID的键
  static String getUserKey(String key, String userId) {
    return key.replaceAll('{userId}', userId);
  }
  
  /// 获取包含会话ID的键
  static String getConversationKey(String key, String conversationId) {
    return key.replaceAll('{conversationId}', conversationId);
  }
  
  /// 获取包含消息ID的键
  static String getMessageKey(String key, String conversationId, String messageId) {
    return key
        .replaceAll('{conversationId}', conversationId)
        .replaceAll('{messageId}', messageId);
  }
  
  /// 获取设置键
  static String getSettingKey(String key, String settingKey) {
    return key.replaceAll('{key}', settingKey);
  }
  
  /// 获取缓存键
  static String getCacheKey(String key, String cacheKey) {
    return key.replaceAll('{key}', cacheKey);
  }
  
  StorageKeys._(); // 私有构造函数，防止实例化
}
