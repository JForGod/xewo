// 2025-03-17: 新增 - Gemini API服务实现
// 2025-03-18: 修改 - 添加代理支持
// 2025-03-19: 修改 - 更新API URL和请求格式
// 2025-03-21: 修改 - 优化API连接稳定性和错误处理

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'llm_config_service.dart';
import 'llm_service.dart';

/// 自定义超时异常
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}

/// Gemini LLM 服务实现
class GeminiLLMService implements LLMService {
  /// API 密钥
  final String apiKey;
  
  /// 是否使用代理
  final bool useProxy;
  
  /// 默认模型名称
  String model = 'gemini-1.5-pro';
  
  /// 基础 API URL
  final String _baseUrl = 'generativelanguage.googleapis.com';
  
  /// 备用 API URL（如果主URL不可用）
  final String _backupBaseUrl = 'generativelanguage.googleapis.com';
  
  /// 使用备用URL
  bool _useBackupUrl = false;
  
  /// 连接超时（秒）
  final int connectionTimeoutSeconds;
  
  /// 请求超时（秒）
  final int requestTimeoutSeconds;
  
  /// 最大重试次数
  final int maxRetries;
  
  /// 重试延迟（毫秒）
  final int retryDelayMs;
  
  /// HTTP客户端
  final http.Client _httpClient;
  
  /// 代理设置
  final String proxyHost;
  final int proxyPort;
  
  /// 构造函数
  GeminiLLMService({
    required this.apiKey,
    this.model = 'gemini-1.5-pro',
    this.useProxy = false,
    this.proxyHost = '127.0.0.1',
    this.proxyPort = 1080,
    this.connectionTimeoutSeconds = 30,
    this.requestTimeoutSeconds = 60,
    this.maxRetries = 3,
    this.retryDelayMs = 1000,
  }) : _httpClient = _createHttpClient(
        useProxy, 
        proxyHost, 
        proxyPort, 
        connectionTimeoutSeconds
      );
  
  /// 创建HTTP客户端（带可选代理）
  static http.Client _createHttpClient(
    bool useProxy, 
    String proxyHost, 
    int proxyPort,
    int connectionTimeoutSeconds
  ) {
    if (useProxy) {
      if (kDebugMode) {
        print('使用代理: $proxyHost:$proxyPort');
      }
      
      final httpClient = HttpClient();
      httpClient.findProxy = (uri) => 'PROXY $proxyHost:$proxyPort';
      // 如果需要忽略证书错误（不推荐在生产环境使用）
      httpClient.badCertificateCallback = (cert, host, port) => true;
      
      // 增加连接超时设置
      httpClient.connectionTimeout = Duration(seconds: connectionTimeoutSeconds);
      
      return IOClient(httpClient);
    } else {
      // 普通HTTP客户端
      final httpClient = HttpClient();
      httpClient.connectionTimeout = Duration(seconds: connectionTimeoutSeconds);
      return IOClient(httpClient);
    }
  }
  
  @override
  Future<bool> testConnection() async {
    int attempts = 0;
    const maxAttempts = 2;
    
    while (attempts < maxAttempts) {
      attempts++;
      if (kDebugMode) {
        print('测试 Gemini API 连接... (尝试 $attempts/$maxAttempts)');
        print('使用代理: $useProxy');
      }
      
      try {
        final url = _buildUrl('generateContent');
        final headers = _getHeaders();
        
        final body = {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text': '你好'
                }
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 10,
          },
        };
        
        if (kDebugMode) {
          print('发送请求到: $url');
          print('请求头: $headers');
          print('请求体: ${jsonEncode(body)}');
        }
        
        try {
          final response = await _httpClient.post(
            url,
            headers: headers,
            body: jsonEncode(body),
          ).timeout(Duration(seconds: requestTimeoutSeconds), onTimeout: () {
            throw TimeoutException('API请求超时，超过了$requestTimeoutSeconds秒');
          });
          
          if (kDebugMode) {
            print('响应状态码: ${response.statusCode}');
            print('响应内容: ${response.body}');
          }
          
          if (response.statusCode == 200) {
            return true;
          }
          
          // 尝试解析错误消息
          try {
            final errorData = jsonDecode(response.body);
            String errorMessage = '未知错误';
            if (errorData['error'] != null) {
              errorMessage = '${errorData['error']['code'] ?? ''} - ${errorData['error']['message'] ?? ''}';
            }
            throw '请求失败: $errorMessage';
          } catch (parseError) {
            // 如果无法解析JSON，则返回原始响应
            throw '请求失败，状态码: ${response.statusCode}, 响应内容: ${response.body}';
          }
        } on SocketException catch (e) {
          if (kDebugMode) {
            print('网络连接错误: $e');
            if (useProxy) {
              print('代理可能配置错误或无法连接，尝试禁用代理或检查代理设置');
            } else {
              print('直接连接失败，尝试启用代理或检查网络连接');
            }
          }
          
          if (attempts < maxAttempts) {
            // 如果使用代理失败，尝试切换URL
            _switchToBackupUrl();
            await Future.delayed(Duration(milliseconds: retryDelayMs));
            continue;
          }
          
          throw '网络连接错误: $e. ${useProxy ? "代理可能配置错误，尝试禁用代理" : "尝试启用代理或检查网络连接"}';
        } on TimeoutException catch (e) {
          if (kDebugMode) {
            print('请求超时: $e');
            if (useProxy) {
              print('使用代理时连接超时，尝试禁用代理或使用不同的代理');
            } else {
              print('直接连接超时，尝试启用代理');
            }
          }
          
          if (attempts < maxAttempts) {
            // 如果超时，尝试切换URL
            _switchToBackupUrl();
            await Future.delayed(Duration(milliseconds: retryDelayMs));
            continue;
          }
          
          throw '请求超时: $e. ${useProxy ? "尝试禁用代理" : "尝试启用代理或检查网络连接"}';
        }
      } catch (e) {
        if (attempts < maxAttempts) {
          await Future.delayed(Duration(milliseconds: retryDelayMs));
          continue;
        }
        
        if (kDebugMode) {
          print('测试连接失败: $e');
        }
        rethrow;
      }
    }
    
    throw '测试连接失败，已尝试$maxAttempts次';
  }
  
  @override
  Future<String> processRequest(String userPrompt) async {
    int attempts = 0;
    const maxAttempts = 2;
    
    while (attempts < maxAttempts) {
      attempts++;
      if (kDebugMode) {
        print('发送消息请求... (尝试 $attempts/$maxAttempts)');
      }
      
      try {
        final url = _buildUrl('generateContent');
        final headers = _getHeaders();
        
        final body = {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text': userPrompt
                }
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 8192,
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_NONE'
            }
          ],
        };
        
        if (kDebugMode) {
          print('请求体: ${jsonEncode(body)}');
        }
        
        try {
          final response = await _httpClient.post(
            url,
            headers: headers,
            body: jsonEncode(body),
          ).timeout(Duration(seconds: requestTimeoutSeconds), onTimeout: () {
            throw TimeoutException('API请求超时，超过了$requestTimeoutSeconds秒');
          });
          
          if (kDebugMode) {
            if (response.body.isNotEmpty) {
              print('响应状态码: ${response.statusCode}');
              print('响应内容摘要: ${response.body.substring(0, math.min(200, response.body.length))}...');
            } else {
              print('响应内容为空');
            }
          }
          
          if (response.statusCode == 200) {
            try {
              final Map<String, dynamic> data = jsonDecode(response.body);
              
              if (data.containsKey('candidates') && 
                  data['candidates'] is List && 
                  (data['candidates'] as List).isNotEmpty) {
                final candidate = data['candidates'][0];
                
                if (candidate.containsKey('content') && 
                    candidate['content'] is Map && 
                    candidate['content'].containsKey('parts') && 
                    candidate['content']['parts'] is List && 
                    (candidate['content']['parts'] as List).isNotEmpty) {
                  final part = candidate['content']['parts'][0];
                  
                  if (part.containsKey('text')) {
                    return part['text'];
                  }
                }
              }
              
              throw '响应格式异常: $data';
            } catch (parseError) {
              throw '无法解析响应内容: $parseError. 响应内容: ${response.body}';
            }
          } else {
            if (kDebugMode) {
              print('请求失败，状态码: ${response.statusCode}');
              print('响应内容: ${response.body}');
            }
            
            if (attempts < maxAttempts) {
              // 尝试切换URL
              _switchToBackupUrl();
              if (kDebugMode) {
                print('尝试使用${_useBackupUrl ? '备用' : '主要'}URL重新发送请求...');
              }
              await Future.delayed(Duration(milliseconds: retryDelayMs));
              continue;
            }
            
            try {
              final errorData = jsonDecode(response.body);
              String errorMessage = '未知错误';
              if (errorData['error'] != null) {
                errorMessage = '${errorData['error']['code'] ?? ''} - ${errorData['error']['message'] ?? ''}';
              }
              throw '请求失败: $errorMessage';
            } catch (parseError) {
              throw '请求失败，状态码: ${response.statusCode}, 响应内容: ${response.body}';
            }
          }
        } on SocketException catch (e) {
          if (kDebugMode) {
            print('网络连接错误: $e');
          }
          
          if (attempts < maxAttempts) {
            // 尝试切换URL
            _switchToBackupUrl();
            if (kDebugMode) {
              print('尝试使用${_useBackupUrl ? '备用' : '主要'}URL重新发送请求...');
            }
            await Future.delayed(Duration(milliseconds: retryDelayMs));
            continue;
          }
          
          throw '网络连接错误: ${e.message}. 请检查您的网络连接${useProxy ? "或代理设置" : ""}。';
        } on TimeoutException catch (e) {
          if (kDebugMode) {
            print('请求超时: $e');
          }
          
          if (attempts < maxAttempts) {
            // 尝试切换URL
            _switchToBackupUrl();
            if (kDebugMode) {
              print('尝试使用${_useBackupUrl ? '备用' : '主要'}URL重新发送请求...');
            }
            await Future.delayed(Duration(milliseconds: retryDelayMs));
            continue;
          }
          
          throw '请求超时: ${e.message}. 请检查您的网络连接${useProxy ? "或代理设置" : ""}，或稍后再试。';
        } catch (e) {
          if (kDebugMode) {
            print('发送消息失败: $e');
          }
          
          if (attempts < maxAttempts) {
            await Future.delayed(Duration(milliseconds: retryDelayMs));
            continue;
          }
          
          throw '处理请求失败: $e';
        }
      } catch (e) {
        if (attempts < maxAttempts) {
          await Future.delayed(Duration(milliseconds: retryDelayMs));
          continue;
        }
        
        if (kDebugMode) {
          print('处理LLM请求失败: $e');
        }
        throw '处理请求失败: $e';
      }
    }
    
    throw '处理请求失败，已尝试$maxAttempts次';
  }

  @override
  Future<String> sessionTest() async {
    try {
      final url = _buildUrl('generateContent');
      final headers = _getHeaders();
      
      final body = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text': '请用一句话介绍自己'
              }
            ]
          }
        ],
        'generationConfig': {
          'maxOutputTokens': 100,
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_NONE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_NONE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_NONE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_NONE'
          }
        ]
      };
      
      if (kDebugMode) {
        print('发送会话测试请求...');
        print('请求体: ${jsonEncode(body)}');
      }
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('API请求超时');
      });
      
      if (kDebugMode) {
        print('响应状态码: ${response.statusCode}');
        print('响应内容: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['candidates'][0]['content']['parts'][0]['text'];
      }
      
      final errorData = jsonDecode(response.body);
      throw '${errorData['error']['code']} - ${errorData['error']['message']}';
    } catch (e) {
      if (kDebugMode) {
        print('会话测试失败: $e');
      }
      rethrow;
    }
  }
  
  @override
  Future<String> sendMessage(String message, List<Map<String, String>> history) async {
    // 尝试次数
    int attempts = 0;
    const maxAttempts = 2;
    
    while (attempts < maxAttempts) {
      attempts++;
      try {
        final url = _buildUrl('generateContent');
        final headers = _getHeaders();
        
        // 构建会话历史
        final contents = _buildContents(message, history);
        
        final body = {
          'contents': contents,
          'generationConfig': {
            'maxOutputTokens': 8192,
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_NONE'
            }
          ]
        };
        
        if (kDebugMode) {
          print('发送消息请求... (尝试 $attempts/$maxAttempts)');
          print('请求体: ${jsonEncode(body)}');
        }
        
        // 增加超时时间
        final response = await _httpClient.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 120), onTimeout: () {
          throw TimeoutException('API请求超时');
        });
        
        if (kDebugMode) {
          print('响应状态码: ${response.statusCode}');
          if (response.body.isNotEmpty) {
            print('响应内容摘要: ${response.body.substring(0, math.min(200, response.body.length))}...');
          } else {
            print('响应内容为空');
          }
        }
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          
          if (data.containsKey('candidates') && 
              data['candidates'] is List && 
              (data['candidates'] as List).isNotEmpty) {
            final candidate = data['candidates'][0];
            
            if (candidate.containsKey('content') && 
                candidate['content'] is Map && 
                candidate['content'].containsKey('parts') && 
                candidate['content']['parts'] is List && 
                (candidate['content']['parts'] as List).isNotEmpty) {
              final part = candidate['content']['parts'][0];
              
              if (part.containsKey('text')) {
                return part['text'];
              }
            }
          }
          
          if (kDebugMode) {
            print('响应格式异常: $data');
          }
          return '无法解析响应内容。请检查API是否正常工作。响应内容: ${response.body}';
        } else {
          if (kDebugMode) {
            print('请求失败，状态码: ${response.statusCode}');
            print('响应内容: ${response.body}');
          }
          
          if (attempts < maxAttempts) {
            // 如果有备用URL，尝试切换
            _switchToBackupUrl();
            if (kDebugMode) {
              print('尝试使用${_useBackupUrl ? '备用' : '主要'}URL重新发送请求...');
            }
            // 等待一秒后重试
            await Future.delayed(const Duration(seconds: 1));
            continue;
          }
          
          try {
            final errorData = jsonDecode(response.body);
            throw '${errorData['error']['code']} - ${errorData['error']['message']}';
          } catch (e) {
            throw '请求失败，状态码: ${response.statusCode}, 响应内容: ${response.body}';
          }
        }
      } on SocketException catch (e) {
        if (kDebugMode) {
          print('网络连接错误: $e');
        }
        
        if (attempts < maxAttempts) {
          // 尝试切换URL
          _switchToBackupUrl();
          if (kDebugMode) {
            print('尝试使用${_useBackupUrl ? '备用' : '主要'}URL重新发送请求...');
          }
          // 等待一秒后重试
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        
        throw '处理LLM请求失败: $e';
      } on TimeoutException catch (e) {
        if (kDebugMode) {
          print('请求超时: $e');
        }
        
        if (attempts < maxAttempts) {
          // 尝试切换URL
          _switchToBackupUrl();
          if (kDebugMode) {
            print('尝试使用${_useBackupUrl ? '备用' : '主要'}URL重新发送请求...');
          }
          // 等待一秒后重试
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        
        throw '处理LLM请求失败: $e';
      } catch (e) {
        if (kDebugMode) {
          print('发送消息失败: $e');
        }
        
        if (attempts < maxAttempts) {
          // 等待一秒后重试
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        
        throw '处理LLM请求失败: $e';
      }
    }
    
    // 所有尝试都失败
    throw '在 $maxAttempts 次尝试后发送消息失败';
  }

  @override
  Future<String> analyzeImage(String base64Image, String prompt) async {
    try {
      final url = _buildUrl('generateContent');
      final headers = _getHeaders();
      
      final body = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text': prompt
              },
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': base64Image
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'maxOutputTokens': 4096,
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_NONE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_NONE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_NONE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_NONE'
          }
        ]
      };
      
      if (kDebugMode) {
        print('发送图像分析请求...');
        print('提示: $prompt');
      }
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60), onTimeout: () {
        throw TimeoutException('API请求超时');
      });
      
      if (kDebugMode) {
        print('响应状态码: ${response.statusCode}');
        print('响应内容摘要: ${response.body.substring(0, math.min(200, response.body.length))}...');
      }
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['candidates'][0]['content']['parts'][0]['text'];
      }
      
      final errorData = jsonDecode(response.body);
      throw '${errorData['error']['code']} - ${errorData['error']['message']}';
    } catch (e) {
      if (kDebugMode) {
        print('图像分析失败: $e');
      }
      rethrow;
    }
  }
  
  /// 构建 API URL
  Uri _buildUrl(String endpoint) {
    final String domain = _useBackupUrl ? _backupBaseUrl : _baseUrl;
    final String apiPath = '/v1beta/models/$model:$endpoint';
    
    return Uri.https(
      domain,
      apiPath,
      {'key': apiKey},
    );
  }
  
  /// 获取 HTTP 请求头
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
    };
  }
  
  /// 构建会话内容
  List<dynamic> _buildContents(String message, List<Map<String, String>> history) {
    final contents = <dynamic>[];
    
    // 添加历史记录
    for (int i = 0; i < history.length; i += 2) {
      if (i + 1 < history.length) {
        // 用户消息
        contents.add({
          'role': 'user',
          'parts': [{'text': history[i]['content']}]
        });
        
        // 助手响应
        contents.add({
          'role': 'model',
          'parts': [{'text': history[i+1]['content']}]
        });
      }
    }
    
    // 添加当前消息
    contents.add({
      'role': 'user',
      'parts': [{'text': message}]
    });
    
    return contents;
  }

  /// 处理用户输入并返回响应
  @override
  Future<String> processInput(
    String input, {
    Map<String, dynamic>? context,
    Map<String, dynamic>? options,
  }) async {
    // 转发到sendMessage方法
    final List<Map<String, String>> history = [];
    if (context != null && context['history'] != null) {
      final historyList = context['history'] as List<dynamic>;
      for (final item in historyList) {
        history.add(Map<String, String>.from(item as Map));
      }
    }
    return sendMessage(input, history);
  }
  
  /// 从上下文中学习
  @override
  Future<void> learn(
    String context, {
    Map<String, dynamic>? metadata,
  }) async {
    // Gemini API不支持此功能
    if (kDebugMode) {
      print('Gemini API不支持直接学习功能');
    }
  }
  
  /// 优化模型性能
  @override
  Future<void> optimize({Map<String, dynamic>? options}) async {
    // Gemini API不支持此功能
    if (kDebugMode) {
      print('Gemini API不支持直接优化功能');
    }
  }
  
  /// 获取模型信息
  @override
  Map<String, dynamic> getModelInfo() {
    return {
      'name': model,
      'provider': 'Google',
      'version': '1.5',
      'capabilities': ['text-generation', 'image-analysis'],
    };
  }
  
  /// 设置模型参数
  @override
  Future<void> setParameters(Map<String, dynamic> parameters) async {
    if (parameters.containsKey('model')) {
      model = parameters['model'] as String;
    }
  }
  
  /// 创建带API密钥的服务实例
  static Future<GeminiLLMService> create(String apiKey, {bool useProxy = false}) async {
    return GeminiLLMService(
      apiKey: apiKey,
      useProxy: useProxy,
      proxyHost: '127.0.0.1',
      proxyPort: 1080,
    );
  }
  
  /// 切换到备用URL
  void _switchToBackupUrl() {
    _useBackupUrl = !_useBackupUrl;
    if (kDebugMode) {
      print('切换到${_useBackupUrl ? '备用' : '主要'} API URL');
    }
  }
} 