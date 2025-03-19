import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../knowledge_base.dart';
import '../storage_interface.dart';
import '../memory/memory_storage.dart';

/// 云存储配置
class CloudStorageConfig {
  /// API基础URL
  final String apiBaseUrl;
  
  /// API密钥
  final String apiKey;
  
  /// 知识库ID
  final String knowledgeBaseId;
  
  /// 构造函数
  CloudStorageConfig({
    required this.apiBaseUrl,
    required this.apiKey,
    required this.knowledgeBaseId,
  });
}

/// 云存储实现
class CloudStorage implements StorageInterface {
  /// 内存存储实例（作为缓存）
  final MemoryStorage _memoryStorage = MemoryStorage();
  
  /// 配置
  final CloudStorageConfig _config;
  
  /// HTTP客户端
  final http.Client _client = http.Client();
  
  /// 初始化状态
  bool _isInitialized = false;
  
  /// 构造函数
  CloudStorage(this._config);
  
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // 从云端加载知识库
      await _loadFromCloud();
      _isInitialized = true;
    } catch (e) {
      print('初始化云存储时出错: $e');
      rethrow;
    }
  }
  
  /// 从云端加载知识
  Future<void> _loadFromCloud() async {
    try {
      // 获取知识索引
      final indexResponse = await _client.get(
        Uri.parse('${_config.apiBaseUrl}/knowledge/${_config.knowledgeBaseId}/index'),
        headers: _getHeaders(),
      );
      
      if (indexResponse.statusCode != 200) {
        throw Exception('获取知识索引失败: ${indexResponse.statusCode}');
      }
      
      final indexData = jsonDecode(indexResponse.body) as List<dynamic>;
      
      // 批量获取知识条目
      if (indexData.isNotEmpty) {
        final batchResponse = await _client.post(
          Uri.parse('${_config.apiBaseUrl}/knowledge/${_config.knowledgeBaseId}/batch'),
          headers: _getHeaders(),
          body: jsonEncode({'ids': indexData}),
        );
        
        if (batchResponse.statusCode != 200) {
          throw Exception('批量获取知识条目失败: ${batchResponse.statusCode}');
        }
        
        final batchData = jsonDecode(batchResponse.body) as List<dynamic>;
        
        // 将知识条目加载到内存存储
        for (final item in batchData) {
          final knowledgeData = item as Map<String, dynamic>;
          final knowledge = Knowledge.fromMap(knowledgeData);
          await _memoryStorage.store(knowledge);
        }
      }
    } catch (e) {
      print('从云端加载知识时出错: $e');
      rethrow;
    }
  }
  
  /// 获取HTTP请求头
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_config.apiKey}',
    };
  }
  
  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  @override
  Future<String> store(Knowledge knowledge) async {
    await _ensureInitialized();
    
    // 先存储到内存
    final id = await _memoryStorage.store(knowledge);
    final updatedKnowledge = knowledge.copyWith(id: id);
    
    try {
      // 保存到云端
      final response = await _client.post(
        Uri.parse('${_config.apiBaseUrl}/knowledge/${_config.knowledgeBaseId}/entries'),
        headers: _getHeaders(),
        body: jsonEncode(updatedKnowledge.toMap()),
      );
      
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('存储知识条目到云端失败: ${response.statusCode}');
      }
    } catch (e) {
      print('存储知识条目到云端时出错: $e');
      // 仍然返回ID，因为已经存储到内存中
    }
    
    return id;
  }
  
  @override
  Future<Knowledge?> retrieve(String id) async {
    await _ensureInitialized();
    
    // 先从内存检索
    final knowledge = await _memoryStorage.retrieve(id);
    if (knowledge != null) {
      return knowledge;
    }
    
    try {
      // 从云端检索
      final response = await _client.get(
        Uri.parse('${_config.apiBaseUrl}/knowledge/${_config.knowledgeBaseId}/entries/$id'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 404) {
        return null;
      }
      
      if (response.statusCode != 200) {
        throw Exception('从云端检索知识条目失败: ${response.statusCode}');
      }
      
      final knowledgeData = jsonDecode(response.body) as Map<String, dynamic>;
      final retrievedKnowledge = Knowledge.fromMap(knowledgeData);
      
      // 存储到内存
      await _memoryStorage.store(retrievedKnowledge);
      
      return retrievedKnowledge;
    } catch (e) {
      print('从云端检索知识条目时出错: $e');
      return null;
    }
  }
  
  @override
  Future<List<Knowledge>> retrieveByTags(List<String> tags, {int limit = 10}) async {
    await _ensureInitialized();
    
    // 优先使用内存存储
    final memoryResults = await _memoryStorage.retrieveByTags(tags, limit: limit);
    if (memoryResults.isNotEmpty) {
      return memoryResults;
    }
    
    try {
      // 从云端检索
      final response = await _client.post(
        Uri.parse('${_config.apiBaseUrl}/knowledge/${_config.knowledgeBaseId}/query/tags'),
        headers: _getHeaders(),
        body: jsonEncode({
          'tags': tags,
          'limit': limit,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('按标签从云端检索知识条目失败: ${response.statusCode}');
      }
      
      final resultData = jsonDecode(response.body) as List<dynamic>;
      final results = <Knowledge>[];
      
      for (final item in resultData) {
        final knowledgeData = item as Map<String, dynamic>;
        final knowledge = Knowledge.fromMap(knowledgeData);
        results.add(knowledge);
        
        // 存储到内存
        await _memoryStorage.store(knowledge);
      }
      
      return results;
    } catch (e) {
      print('按标签从云端检索知识条目时出错: $e');
      return [];
    }
  }
  
  @override
  Future<List<QueryResult>> search(
    String query, 
    List<double>? queryEmbedding, {
    QueryOptions options = const QueryOptions(),
  }) async {
    await _ensureInitialized();
    
    // 如果有嵌入向量，可以先尝试使用内存中的数据搜索
    if (queryEmbedding != null && queryEmbedding.isNotEmpty) {
      final memoryResults = await _memoryStorage.search(
        query, 
        queryEmbedding, 
        options: options,
      );
      
      if (memoryResults.isNotEmpty) {
        return memoryResults;
      }
    }
    
    try {
      // 从云端搜索
      final requestBody = {
        'query': query,
        'limit': options.limit,
        'threshold': options.threshold,
      };
      
      if (queryEmbedding != null && queryEmbedding.isNotEmpty) {
        requestBody['embedding'] = queryEmbedding;
      }
      
      if (options.tagFilter != null && options.tagFilter!.isNotEmpty) {
        requestBody['tagFilter'] = options.tagFilter;
      }
      
      if (options.minImportance > 0) {
        requestBody['minImportance'] = options.minImportance;
      }
      
      if (options.metadataFilter != null && options.metadataFilter!.isNotEmpty) {
        requestBody['metadataFilter'] = options.metadataFilter;
      }
      
      final response = await _client.post(
        Uri.parse('${_config.apiBaseUrl}/knowledge/${_config.knowledgeBaseId}/search'),
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode != 200) {
        throw Exception('从云端搜索知识条目失败: ${response.statusCode}');
      }
      
      final resultData = jsonDecode(response.body) as List<dynamic>;
      final results = <QueryResult>[];
      
      for (final item in resultData) {
        final resultMap = item as Map<String, dynamic>;
        final knowledgeData = resultMap['knowledge'] as Map<String, dynamic>;
        final similarity = (resultMap['similarity'] as num).toDouble();
        
        final knowledge = Knowledge.fromMap(knowledgeData);
        results.add(QueryResult(knowledge: knowledge, similarity: similarity));
        
        // 存储到内存
        await _memoryStorage.store(knowledge);
      }
      
      return results;
    } catch (e) {
      print('从云端搜索知识条目时出错: $e');
      
      // 回退到内存存储
      return _memoryStorage.search(query, queryEmbedding, options: options);
    }
  }
  
  @override
  Future<void> update(Knowledge knowledge) async {
    await _ensureInitialized();
    
    // 更新内存存储
    await _memoryStorage.update(knowledge);
    
    try {
      // 更新云端
      final response = await _client.put(
        Uri.parse('${_config.apiBaseUrl}/knowledge/${_config.knowledgeBaseId}/entries/${knowledge.id}'),
        headers: _getHeaders(),
        body: jsonEncode(knowledge.toMap()),
      );
      
      if (response.statusCode != 200) {
        throw Exception('更新云端知识条目失败: ${response.statusCode}');
      }
    } catch (e) {
      print('更新云端知识条目时出错: $e');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    await _ensureInitialized();
    
    // 从内存存储中删除
    await _memoryStorage.delete(id);
    
    try {
      // 从云端删除
      final response = await _client.delete(
        Uri.parse('${_config.apiBaseUrl}/knowledge/${_config.knowledgeBaseId}/entries/$id'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('从云端删除知识条目失败: ${response.statusCode}');
      }
    } catch (e) {
      print('从云端删除知识条目时出错: $e');
    }
  }
  
  @override
  Future<void> clear() async {
    await _ensureInitialized();
    
    // 清空内存存储
    await _memoryStorage.clear();
    
    try {
      // 清空云端存储
      final response = await _client.delete(
        Uri.parse('${_config.apiBaseUrl}/knowledge/${_config.knowledgeBaseId}/entries'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('清空云端知识库失败: ${response.statusCode}');
      }
    } catch (e) {
      print('清空云端知识库时出错: $e');
    }
  }
  
  @override
  Future<int> count() async {
    await _ensureInitialized();
    
    try {
      // 获取云端计数
      final response = await _client.get(
        Uri.parse('${_config.apiBaseUrl}/knowledge/${_config.knowledgeBaseId}/count'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode != 200) {
        throw Exception('获取云端知识条目计数失败: ${response.statusCode}');
      }
      
      final countData = jsonDecode(response.body) as Map<String, dynamic>;
      return countData['count'] as int;
    } catch (e) {
      print('获取云端知识条目计数时出错: $e');
      
      // 回退到内存存储
      return _memoryStorage.count();
    }
  }
  
  @override
  Future<List<String>> getAllTags() async {
    await _ensureInitialized();
    
    try {
      // 获取云端标签
      final response = await _client.get(
        Uri.parse('${_config.apiBaseUrl}/knowledge/${_config.knowledgeBaseId}/tags'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode != 200) {
        throw Exception('获取云端标签失败: ${response.statusCode}');
      }
      
      final tagsData = jsonDecode(response.body) as List<dynamic>;
      return tagsData.cast<String>();
    } catch (e) {
      print('获取云端标签时出错: $e');
      
      // 回退到内存存储
      return _memoryStorage.getAllTags();
    }
  }
  
  @override
  Future<Map<String, dynamic>> getStats() async {
    await _ensureInitialized();
    
    try {
      // 获取云端统计信息
      final response = await _client.get(
        Uri.parse('${_config.apiBaseUrl}/knowledge/${_config.knowledgeBaseId}/stats'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode != 200) {
        throw Exception('获取云端统计信息失败: ${response.statusCode}');
      }
      
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('获取云端统计信息时出错: $e');
      
      // 回退到内存存储
      return _memoryStorage.getStats();
    }
  }
  
  @override
  Future<List<double>> generateEmbedding(String text) async {
    try {
      // 使用云服务生成嵌入向量
      final response = await _client.post(
        Uri.parse('${_config.apiBaseUrl}/embeddings'),
        headers: _getHeaders(),
        body: jsonEncode({'text': text}),
      );
      
      if (response.statusCode != 200) {
        throw Exception('生成嵌入向量失败: ${response.statusCode}');
      }
      
      final embeddingData = jsonDecode(response.body) as Map<String, dynamic>;
      final embedding = (embeddingData['embedding'] as List<dynamic>).cast<double>();
      
      return embedding;
    } catch (e) {
      print('生成嵌入向量时出错: $e');
      throw Exception('生成嵌入向量失败: $e');
    }
  }
  
  /// 同步与云端的数据
  Future<void> sync() async {
    await _ensureInitialized();
    
    try {
      // 获取最新的索引
      final indexResponse = await _client.get(
        Uri.parse('${_config.apiBaseUrl}/knowledge/${_config.knowledgeBaseId}/index'),
        headers: _getHeaders(),
      );
      
      if (indexResponse.statusCode != 200) {
        throw Exception('获取知识索引失败: ${indexResponse.statusCode}');
      }
      
      final cloudIds = Set<String>.from(jsonDecode(indexResponse.body) as List<dynamic>);
      
      // 获取本地IDs
      final memoryStats = await _memoryStorage.getStats();
      final localCount = memoryStats['knowledgeCount'] as int;
      
      // 如果本地没有数据，直接加载所有云端数据
      if (localCount == 0) {
        await _loadFromCloud();
        return;
      }
      
      // 否则执行增量同步
      final syncResponse = await _client.post(
        Uri.parse('${_config.apiBaseUrl}/knowledge/${_config.knowledgeBaseId}/sync'),
        headers: _getHeaders(),
        body: jsonEncode({
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      
      if (syncResponse.statusCode != 200) {
        throw Exception('同步知识数据失败: ${syncResponse.statusCode}');
      }
      
      final syncData = jsonDecode(syncResponse.body) as Map<String, dynamic>;
      final updatedEntries = (syncData['updated'] as List<dynamic>).cast<Map<String, dynamic>>();
      final deletedIds = (syncData['deleted'] as List<dynamic>).cast<String>();
      
      // 更新本地数据
      for (final entry in updatedEntries) {
        final knowledge = Knowledge.fromMap(entry);
        await _memoryStorage.store(knowledge);
      }
      
      // 删除本地数据
      for (final id in deletedIds) {
        await _memoryStorage.delete(id);
      }
    } catch (e) {
      print('同步云端数据时出错: $e');
      rethrow;
    }
  }
  
  /// 关闭存储
  Future<void> close() async {
    _client.close();
  }
}

/// 云存储配置提供者
final cloudStorageConfigProvider = Provider<CloudStorageConfig>((ref) {
  // 这需要在应用中实现
  throw UnimplementedError('需要提供云存储配置');
});

/// 云存储提供者
final cloudStorageProvider = Provider<StorageInterface>((ref) {
  final config = ref.watch(cloudStorageConfigProvider);
  return CloudStorage(config);
});