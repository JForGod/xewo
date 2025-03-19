/// 应用常量
class AppConstants {
  // 应用信息
  static const String appName = 'Xewo AI助手';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // 路由
  static const String homeRoute = '/';
  static const String chatRoute = '/chat';
  static const String settingsRoute = '/settings';
  static const String profileRoute = '/profile';
  static const String helpRoute = '/help';
  static const String aboutRoute = '/about';
  
  // 资源路径
  static const String assetsPath = 'assets';
  static const String imagesPath = '$assetsPath/images';
  static const String iconsPath = '$assetsPath/icons';
  static const String soundsPath = '$assetsPath/sounds';
  
  // API相关
  static const int apiTimeout = 30; // 秒
  static const int maxRetries = 3;
  
  // 缓存相关
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int cacheDuration = 7; // 天
  
  // 聊天相关
  static const int maxMessageLength = 4000;
  static const int maxConversations = 100;
  static const int messagesPerPage = 20;
  
  // 文件相关
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> supportedAudioFormats = ['mp3', 'wav', 'aac', 'm4a'];
  static const List<String> supportedVideoFormats = ['mp4', 'mov', 'avi', 'webm'];
  static const int maxFileSize = 20 * 1024 * 1024; // 20MB
  
  // 安全相关
  static const int passwordMinLength = 8;
  static const int sessionTimeout = 30; // 分钟
  static const int tokenExpiryDays = 7;
  
  // 默认设置
  static const String defaultLanguage = 'zh_CN';
  static const String defaultTheme = 'system';
  static const bool defaultNotifications = true;
  
  AppConstants._(); // 私有构造函数，防止实例化
}
