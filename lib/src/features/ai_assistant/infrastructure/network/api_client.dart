import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/services/logging/logging_service.dart';
import '../../../../core/services/error/error_handling_service.dart';
import '../../../../core/services/network/network_service.dart';
import 'api_config.dart';
import 'api_auth_provider.dart';
import 'api_interceptor.dart';

/// API响应类
class ApiResponse {
  final int statusCode;
  final dynamic data;
  final Map<String, String> headers;
  
  ApiResponse({
    required this.statusCode,
    required this.data,
    required this.headers,
  });
  
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// API客户端
class ApiClient {
  final http.Client _httpClient;
  final ApiConfig _config;
  final LoggingService _loggingService;
  final ErrorHandlingService _errorHandlingService;
  final NetworkService _networkService;
  final ApiAuthProvider _authProvider;
  final List<ApiInterceptor> _interceptors;
  
  /// 构造函数
  ApiClient({
    required http.Client httpClient,
    required ApiConfig config,
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
    required NetworkService networkService,
    required ApiAuthProvider authProvider,
    List<ApiInterceptor>? interceptors,
  })  : _httpClient = httpClient,
        _config = config,
        _loggingService = loggingService,
        _errorHandlingService = errorHandlingService,
        _networkService = networkService,
        _authProvider = authProvider,
        _interceptors = interceptors ?? [];
  
  // 2025-03-16 + GET请求功能
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    Duration? timeout,
  }) async {
    return _sendRequest(
      'GET',
      path,
      headers: headers,
      queryParams: queryParams,
      timeout: timeout,
    );
  }
  
  // 2025-03-16 + POST请求功能
  Future<ApiResponse> post(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    dynamic data,
    Duration? timeout,
  }) async {
    return _sendRequest(
      'POST',
      path,
      headers: headers,
      queryParams: queryParams,
      data: data,
      timeout: timeout,
    );
  }
  
  // 2025-03-16 + PUT请求功能
  Future<ApiResponse> put(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    dynamic data,
    Duration? timeout,
  }) async {
    return _sendRequest(
      'PUT',
      path,
      headers: headers,
      queryParams: queryParams,
      data: data,
      timeout: timeout,
    );
  }
  
  // 2025-03-16 + DELETE请求功能
  Future<ApiResponse> delete(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    dynamic data,
    Duration? timeout,
  }) async {
    return _sendRequest(
      'DELETE',
      path,
      headers: headers,
      queryParams: queryParams,
      data: data,
      timeout: timeout,
    );
  }
  
  // 2025-03-16 + HEAD请求功能
  Future<ApiResponse> head(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    Duration? timeout,
  }) async {
    return _sendRequest(
      'HEAD',
      path,
      headers: headers,
      queryParams: queryParams,
      timeout: timeout,
    );
  }
  
  // 2025-03-16 + 流式请求功能
  Stream<Map<String, dynamic>> getStream(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    dynamic data,
    Duration? timeout,
  }) async* {
    try {
      // 检查网络连接
      if (!await _networkService.isConnected()) {
        throw Exception('没有网络连接');
      }
      
      // 构建URL
      final uri = _buildUri(path, queryParams);
      
      // 构建请求头
      final requestHeaders = await _buildHeaders(headers);
      
      // 准备请求数据
      final requestData = data != null ? json.encode(data) : null;
      
      // 执行请求拦截器
      var requestInfo = {
        'method': 'POST',
        'uri': uri,
        'headers': requestHeaders,
        'data': requestData,
      };
      
      for (final interceptor in _interceptors) {
        requestInfo = await interceptor.onRequest(requestInfo);
      }
      
      // 发送请求
      final request = http.Request('POST', Uri.parse(requestInfo['uri']));
      request.headers.addAll(requestInfo['headers']);
      
      if (requestInfo['data'] != null) {
        request.body = requestInfo['data'];
      }
      
      final streamedResponse = await _httpClient.send(request);
      
      // 解析响应流
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        try {
          // 处理SSE格式的数据
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final dataContent = line.substring(6);
              if (dataContent == '[DONE]') {
                continue;
              }
              
              final jsonData = json.decode(dataContent);
              yield jsonData;
            }
          }
        } catch (e) {
          _loggingService.error('解析流数据失败', tags: {
            'error': e.toString(),
            'chunk': chunk,
          });
        }
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.network,
        severity: ErrorSeverity.high,
        message: '流式请求失败: $path',
      );
      
      rethrow;
    }
  }
  
  // 2025-03-16 + 发送请求功能
  Future<ApiResponse> _sendRequest(
    String method,
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    dynamic data,
    Duration? timeout,
  }) async {
    try {
      // 检查网络连接
      if (!await _networkService.isConnected()) {
        throw Exception('没有网络连接');
      }
      
      // 构建URL
      final uri = _buildUri(path, queryParams);
      
      // 构建请求头
      final requestHeaders = await _buildHeaders(headers);
      
      // 准备请求数据
      final requestData = data != null ? json.encode(data) : null;
      
      // 执行请求拦截器
      var requestInfo = {
        'method': method,
        'uri': uri,
        'headers': requestHeaders,
        'data': requestData,
      };
      
      for (final interceptor in _interceptors) {
        requestInfo = await interceptor.onRequest(requestInfo);
      }
      
      // 发送请求
      http.Response response;
      final effectiveTimeout = timeout ?? _config.defaultTimeout;
      
      switch (requestInfo['method']) {
        case 'GET':
          response = await _httpClient
              .get(Uri.parse(requestInfo['uri']), headers: requestInfo['headers'])
              .timeout(effectiveTimeout);
          break;
        case 'POST':
          response = await _httpClient
              .post(
                Uri.parse(requestInfo['uri']),
                headers: requestInfo['headers'],
                body: requestInfo['data'],
              )
              .timeout(effectiveTimeout);
          break;
        case 'PUT':
          response = await _httpClient
              .put(
                Uri.parse(requestInfo['uri']),
                headers: requestInfo['headers'],
                body: requestInfo['data'],
              )
              .timeout(effectiveTimeout);
          break;
        case 'DELETE':
          response = await _httpClient
              .delete(
                Uri.parse(requestInfo['uri']),
                headers: requestInfo['headers'],
                body: requestInfo['data'],
              )
              .timeout(effectiveTimeout);
          break;
        case 'HEAD':
          response = await _httpClient
              .head(Uri.parse(requestInfo['uri']), headers: requestInfo['headers'])
              .timeout(effectiveTimeout);
          break;
        default:
          throw Exception('不支持的HTTP方法: ${requestInfo['method']}');
      }
      
      // 解析响应数据
      dynamic responseData;
      if (response.body.isNotEmpty) {
        try {
          responseData = json.decode(response.body);
        } catch (e) {
          responseData = response.body;
        }
      }
      
      final apiResponse = ApiResponse(
        statusCode: response.statusCode,
        data: responseData,
        headers: response.headers,
      );
      
      // 执行响应拦截器
      var responseInfo = {
        'statusCode': apiResponse.statusCode,
        'data': apiResponse.data,
        'headers': apiResponse.headers,
      };
      
      for (final interceptor in _interceptors) {
        responseInfo = await interceptor.onResponse(responseInfo);
      }
      
      // 处理令牌刷新
      if (apiResponse.statusCode == 401) {
        if (await _authProvider.refreshToken()) {
          // 重试请求
          return _sendRequest(
            method,
            path,
            headers: headers,
            queryParams: queryParams,
            data: data,
            timeout: timeout,
          );
        }
      }
      
      // 记录请求信息
      _loggingService.info('API请求完成', tags: {
        'method': method,
        'path': path,
        'status_code': apiResponse.statusCode.toString(),
        'response_size': apiResponse.data != null
            ? (apiResponse.data is String 
                ? (apiResponse.data as String).length 
                : json.encode(apiResponse.data).length)
            : 0,
      });
      
      return ApiResponse(
        statusCode: responseInfo['statusCode'],
        data: responseInfo['data'],
        headers: Map<String, String>.from(responseInfo['headers']),
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.network,
        severity: ErrorSeverity.medium,
        message: 'API请求失败: $method $path',
      );
      
      rethrow;
    }
  }
  
  // 2025-03-16 + 构建URI功能
  String _buildUri(String path, Map<String, dynamic>? queryParams) {
    var uri = '${_config.baseUrl}$path';
    
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value.toString())}')
          .join('&');
      
      uri = '$uri?$queryString';
    }
    
    return uri;
  }
  
  // 2025-03-16 + 构建请求头功能
  Future<Map<String, String>> _buildHeaders(Map<String, String>? headers) async {
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // 添加认证头
    final authHeaders = await _authProvider.getAuthHeaders();
    
    // 合并所有头信息
    final mergedHeaders = {
      ...defaultHeaders,
      ...authHeaders,
      ...?headers,
    };
    
    return mergedHeaders;
  }
  
  // 2025-03-16 + 上传文件功能
  Future<ApiResponse> uploadFile(
    String path,
    String filePath,
    String fieldName, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    Duration? timeout,
  }) async {
    try {
      // 检查网络连接
      if (!await _networkService.isConnected()) {
        throw Exception('没有网络连接');
      }
      
      // 构建URL
      final uri = Uri.parse('${_config.baseUrl}$path');
      
      // 构建请求头
      final requestHeaders = await _buildHeaders(headers);
      
      // 创建多部分请求
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(requestHeaders);
      
      // 添加文件
      final file = await http.MultipartFile.fromPath(fieldName, filePath);
      request.files.add(file);
      
      // 添加其他字段
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      // 执行请求拦截器
      var requestInfo = {
        'method': 'POST',
        'uri': uri.toString(),
        'headers': requestHeaders,
        'data': {'file': filePath, 'fields': fields},
      };
      
      for (final interceptor in _interceptors) {
        requestInfo = await interceptor.onRequest(requestInfo);
      }
      
      // 发送请求
      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      // 解析响应数据
      dynamic responseData;
      if (response.body.isNotEmpty) {
        try {
          responseData = json.decode(response.body);
        } catch (e) {
          responseData = response.body;
        }
      }
      
      final apiResponse = ApiResponse(
        statusCode: response.statusCode,
        data: responseData,
        headers: response.headers,
      );
      
      // 执行响应拦截器
      var responseInfo = {
        'statusCode': apiResponse.statusCode,
        'data': apiResponse.data,
        'headers': apiResponse.headers,
      };
      
      for (final interceptor in _interceptors) {
        responseInfo = await interceptor.onResponse(responseInfo);
      }
      
      // 记录请求信息
      _loggingService.info('文件上传完成', tags: {
        'path': path,
        'file_path': filePath,
        'status_code': apiResponse.statusCode.toString(),
      });
      
      return ApiResponse(
        statusCode: responseInfo['statusCode'],
        data: responseInfo['data'],
        headers: Map<String, String>.from(responseInfo['headers']),
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.network,
        severity: ErrorSeverity.medium,
        message: '文件上传失败: $path',
      );
      
      rethrow;
    }
  }
}

/// API客户端提供者
final apiClientProvider = Provider<ApiClient>((ref) {
  final httpClient = http.Client();
  final config = ref.watch(apiConfigProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  final networkService = ref.watch(networkServiceProvider);
  final authProvider = ref.watch(apiAuthProviderProvider);
  final interceptors = ref.watch(apiInterceptorsProvider);
  
  return ApiClient(
    httpClient: httpClient,
    config: config,
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
    networkService: networkService,
    authProvider: authProvider,
    interceptors: interceptors,
  );
});

import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/services/logging/logging_service.dart';
import '../../../../core/services/error/error_handling_service.dart';
import '../../../../core/services/network/network_service.dart';
import 'api_config.dart';
import 'api_auth_provider.dart';
import 'api_interceptor.dart';

/// API响应类
class ApiResponse {
  final int statusCode;
  final dynamic data;
  final Map<String, String> headers;
  
  ApiResponse({
    required this.statusCode,
    required this.data,
    required this.headers,
  });
  
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// API客户端
class ApiClient {
  final http.Client _httpClient;
  final ApiConfig _config;
  final LoggingService _loggingService;
  final ErrorHandlingService _errorHandlingService;
  final NetworkService _networkService;
  final ApiAuthProvider _authProvider;
  final List<ApiInterceptor> _interceptors;
  
  /// 构造函数
  ApiClient({
    required http.Client httpClient,
    required ApiConfig config,
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
    required NetworkService networkService,
    required ApiAuthProvider authProvider,
    List<ApiInterceptor>? interceptors,
  })  : _httpClient = httpClient,
        _config = config,
        _loggingService = loggingService,
        _errorHandlingService = errorHandlingService,
        _networkService = networkService,
        _authProvider = authProvider,
        _interceptors = interceptors ?? [];
  
  // 2025-03-16 + GET请求功能
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    Duration? timeout,
  }) async {
    return _sendRequest(
      'GET',
      path,
      headers: headers,
      queryParams: queryParams,
      timeout: timeout,
    );
  }
  
  // 2025-03-16 + POST请求功能
  Future<ApiResponse> post(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    dynamic data,
    Duration? timeout,
  }) async {
    return _sendRequest(
      'POST',
      path,
      headers: headers,
      queryParams: queryParams,
      data: data,
      timeout: timeout,
    );
  }
  
  // 2025-03-16 + PUT请求功能
  Future<ApiResponse> put(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    dynamic data,
    Duration? timeout,
  }) async {
    return _sendRequest(
      'PUT',
      path,
      headers: headers,
      queryParams: queryParams,
      data: data,
      timeout: timeout,
    );
  }
  
  // 2025-03-16 + DELETE请求功能
  Future<ApiResponse> delete(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    dynamic data,
    Duration? timeout,
  }) async {
    return _sendRequest(
      'DELETE',
      path,
      headers: headers,
      queryParams: queryParams,
      data: data,
      timeout: timeout,
    );
  }
  
  // 2025-03-16 + HEAD请求功能
  Future<ApiResponse> head(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    Duration? timeout,
  }) async {
    return _sendRequest(
      'HEAD',
      path,
      headers: headers,
      queryParams: queryParams,
      timeout: timeout,
    );
  }
  
  // 2025-03-16 + 流式请求功能
  Stream<Map<String, dynamic>> getStream(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    dynamic data,
    Duration? timeout,
  }) async* {
    try {
      // 检查网络连接
      if (!await _networkService.isConnected()) {
        throw Exception('没有网络连接');
      }
      
      // 构建URL
      final uri = _buildUri(path, queryParams);
      
      // 构建请求头
      final requestHeaders = await _buildHeaders(headers);
      
      // 准备请求数据
      final requestData = data != null ? json.encode(data) : null;
      
      // 执行请求拦截器
      var requestInfo = {
        'method': 'POST',
        'uri': uri,
        'headers': requestHeaders,
        'data': requestData,
      };
      
      for (final interceptor in _interceptors) {
        requestInfo = await interceptor.onRequest(requestInfo);
      }
      
      // 发送请求
      final request = http.Request('POST', Uri.parse(requestInfo['uri']));
      request.headers.addAll(requestInfo['headers']);
      
      if (requestInfo['data'] != null) {
        request.body = requestInfo['data'];
      }
      
      final streamedResponse = await _httpClient.send(request);
      
      // 解析响应流
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        try {
          // 处理SSE格式的数据
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final dataContent = line.substring(6);
              if (dataContent == '[DONE]') {
                continue;
              }
              
              final jsonData = json.decode(dataContent);
              yield jsonData;
            }
          }
        } catch (e) {
          _loggingService.error('解析流数据失败', tags: {
            'error': e.toString(),
            'chunk': chunk,
          });
        }
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.network,
        severity: ErrorSeverity.high,
        message: '流式请求失败: $path',
      );
      
      rethrow;
    }
  }
  
  // 2025-03-16 + 发送请求功能
  Future<ApiResponse> _sendRequest(
    String method,
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    dynamic data,
    Duration? timeout,
  }) async {
    try {
      // 检查网络连接
      if (!await _networkService.isConnected()) {
        throw Exception('没有网络连接');
      }
      
      // 构建URL
      final uri = _buildUri(path, queryParams);
      
      // 构建请求头
      final requestHeaders = await _buildHeaders(headers);
      
      // 准备请求数据
      final requestData = data != null ? json.encode(data) : null;
      
      // 执行请求拦截器
      var requestInfo = {
        'method': method,
        'uri': uri,
        'headers': requestHeaders,
        'data': requestData,
      };
      
      for (final interceptor in _interceptors) {
        requestInfo = await interceptor.onRequest(requestInfo);
      }
      
      // 发送请求
      http.Response response;
      final effectiveTimeout = timeout ?? _config.defaultTimeout;
      
      switch (requestInfo['method']) {
        case 'GET':
          response = await _httpClient
              .get(Uri.parse(requestInfo['uri']), headers: requestInfo['headers'])
              .timeout(effectiveTimeout);
          break;
        case 'POST':
          response = await _httpClient
              .post(
                Uri.parse(requestInfo['uri']),
                headers: requestInfo['headers'],
                body: requestInfo['data'],
              )
              .timeout(effectiveTimeout);
          break;
        case 'PUT':
          response = await _httpClient
              .put(
                Uri.parse(requestInfo['uri']),
                headers: requestInfo['headers'],
                body: requestInfo['data'],
              )
              .timeout(effectiveTimeout);
          break;
        case 'DELETE':
          response = await _httpClient
              .delete(
                Uri.parse(requestInfo['uri']),
                headers: requestInfo['headers'],
                body: requestInfo['data'],
              )
              .timeout(effectiveTimeout);
          break;
        case 'HEAD':
          response = await _httpClient
              .head(Uri.parse(requestInfo['uri']), headers: requestInfo['headers'])
              .timeout(effectiveTimeout);
          break;
        default:
          throw Exception('不支持的HTTP方法: ${requestInfo['method']}');
      }
      
      // 解析响应数据
      dynamic responseData;
      if (response.body.isNotEmpty) {
        try {
          responseData = json.decode(response.body);
        } catch (e) {
          responseData = response.body;
        }
      }
      
      final apiResponse = ApiResponse(
        statusCode: response.statusCode,
        data: responseData,
        headers: response.headers,
      );
      
      // 执行响应拦截器
      var responseInfo = {
        'statusCode': apiResponse.statusCode,
        'data': apiResponse.data,
        'headers': apiResponse.headers,
      };
      
      for (final interceptor in _interceptors) {
        responseInfo = await interceptor.onResponse(responseInfo);
      }
      
      // 处理令牌刷新
      if (apiResponse.statusCode == 401) {
        if (await _authProvider.refreshToken()) {
          // 重试请求
          return _sendRequest(
            method,
            path,
            headers: headers,
            queryParams: queryParams,
            data: data,
            timeout: timeout,
          );
        }
      }
      
      // 记录请求信息
      _loggingService.info('API请求完成', tags: {
        'method': method,
        'path': path,
        'status_code': apiResponse.statusCode.toString(),
        'response_size': apiResponse.data != null
            ? (apiResponse.data is String 
                ? (apiResponse.data as String).length 
                : json.encode(apiResponse.data).length)
            : 0,
      });
      
      return ApiResponse(
        statusCode: responseInfo['statusCode'],
        data: responseInfo['data'],
        headers: Map<String, String>.from(responseInfo['headers']),
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.network,
        severity: ErrorSeverity.medium,
        message: 'API请求失败: $method $path',
      );
      
      rethrow;
    }
  }
  
  // 2025-03-16 + 构建URI功能
  String _buildUri(String path, Map<String, dynamic>? queryParams) {
    var uri = '${_config.baseUrl}$path';
    
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value.toString())}')
          .join('&');
      
      uri = '$uri?$queryString';
    }
    
    return uri;
  }
  
  // 2025-03-16 + 构建请求头功能
  Future<Map<String, String>> _buildHeaders(Map<String, String>? headers) async {
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // 添加认证头
    final authHeaders = await _authProvider.getAuthHeaders();
    
    // 合并所有头信息
    final mergedHeaders = {
      ...defaultHeaders,
      ...authHeaders,
      ...?headers,
    };
    
    return mergedHeaders;
  }
  
  // 2025-03-16 + 上传文件功能
  Future<ApiResponse> uploadFile(
    String path,
    String filePath,
    String fieldName, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    Duration? timeout,
  }) async {
    try {
      // 检查网络连接
      if (!await _networkService.isConnected()) {
        throw Exception('没有网络连接');
      }
      
      // 构建URL
      final uri = Uri.parse('${_config.baseUrl}$path');
      
      // 构建请求头
      final requestHeaders = await _buildHeaders(headers);
      
      // 创建多部分请求
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(requestHeaders);
      
      // 添加文件
      final file = await http.MultipartFile.fromPath(fieldName, filePath);
      request.files.add(file);
      
      // 添加其他字段
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      // 执行请求拦截器
      var requestInfo = {
        'method': 'POST',
        'uri': uri.toString(),
        'headers': requestHeaders,
        'data': {'file': filePath, 'fields': fields},
      };
      
      for (final interceptor in _interceptors) {
        requestInfo = await interceptor.onRequest(requestInfo);
      }
      
      // 发送请求
      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      // 解析响应数据
      dynamic responseData;
      if (response.body.isNotEmpty) {
        try {
          responseData = json.decode(response.body);
        } catch (e) {
          responseData = response.body;
        }
      }
      
      final apiResponse = ApiResponse(
        statusCode: response.statusCode,
        data: responseData,
        headers: response.headers,
      );
      
      // 执行响应拦截器
      var responseInfo = {
        'statusCode': apiResponse.statusCode,
        'data': apiResponse.data,
        'headers': apiResponse.headers,
      };
      
      for (final interceptor in _interceptors) {
        responseInfo = await interceptor.onResponse(responseInfo);
      }
      
      // 记录请求信息
      _loggingService.info('文件上传完成', tags: {
        'path': path,
        'file_path': filePath,
        'status_code': apiResponse.statusCode.toString(),
      });
      
      return ApiResponse(
        statusCode: responseInfo['statusCode'],
        data: responseInfo['data'],
        headers: Map<String, String>.from(responseInfo['headers']),
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.network,
        severity: ErrorSeverity.medium,
        message: '文件上传失败: $path',
      );
      
      rethrow;
    }
  }
}

/// API客户端提供者
final apiClientProvider = Provider<ApiClient>((ref) {
  final httpClient = http.Client();
  final config = ref.watch(apiConfigProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  final networkService = ref.watch(networkServiceProvider);
  final authProvider = ref.watch(apiAuthProviderProvider);
  final interceptors = ref.watch(apiInterceptorsProvider);
  
  return ApiClient(
    httpClient: httpClient,
    config: config,
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
    networkService: networkService,
    authProvider: authProvider,
    interceptors: interceptors,
  );
});