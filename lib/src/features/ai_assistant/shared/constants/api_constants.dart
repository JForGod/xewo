/// API常量
class ApiConstants {
  // API端点
  static const String baseUrl = 'https://api.xewo.example.com/v1';
  static const String authEndpoint = '/auth';
  static const String userEndpoint = '/users';
  static const String chatEndpoint = '/conversations';
  static const String assistantEndpoint = '/assistant';
  static const String settingsEndpoint = '/settings';
  
  // API错误码
  static const int errorUnauthorized = 401;
  static const int errorForbidden = 403;
  static const int errorNotFound = 404;
  static const int errorServerError = 500;
  
  // API参数
  static const String paramApiKey = 'api_key';
  static const String paramRefreshToken = 'refresh_token';
  static const String paramLimit = 'limit';
  static const String paramOffset = 'offset';
  static const String paramQuery = 'query';
  
  // API头
  static const String headerAuthorization = 'Authorization';
  static const String headerContentType = 'Content-Type';
  static const String headerAccept = 'Accept';
  static const String headerUserAgent = 'User-Agent';
  
  // API内容类型
  static const String contentTypeJson = 'application/json';
  static const String contentTypeFormUrlencoded = 'application/x-www-form-urlencoded';
  static const String contentTypeMultipart = 'multipart/form-data';
  
  // API状态
  static const String statusSuccess = 'success';
  static const String statusError = 'error';
  static const String statusPending = 'pending';
  
  ApiConstants._(); // 私有构造函数，防止实例化
}
