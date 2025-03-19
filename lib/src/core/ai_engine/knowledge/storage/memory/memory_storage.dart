import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../knowledge_base.dart';
import '../storage_interface.dart';

/// 内存存储实现
class MemoryStorage implements StorageInterface {
  /// 知识条目映射表
  final Map<String, Knowledge> _knowledgeMap = {};
  
  /// 按标签分组的索引
  final Map<String, Set<String>> _tagIndex = {};
  
  /// 向量索引
  final Map<String, List<double>> _vectorIndex = {};
  
  @override
  Future<void> initialize() async {
    // 内存存储不需要初始化
    return;
  }
  
  @override
  Future<String> store(Knowledge knowledge) async {
    // 确保每个知识条目都有ID
    final id = knowledge.id.isEmpty ? _generateId() : knowledge.id;
    final updatedKnowledge = knowledge.copyWith(id: id);
    
    // 存储知识条目
    _knowledgeMap[id] = updatedKnowledge;
    
    // 更新标签索引
    for (final tag in updatedKnowledge.tags) {
      _tagIndex.putIfAbsent(tag, () => {}).add(id);
    }
    
    // 更新向量索引
    if (updatedKnowledge.embedding != null) {
      _vectorIndex[id] = updatedKnowledge.embedding!;
    }
    
    return id;
  }
  
  @override
  Future<Knowledge?> retrieve(String id) async {
    return _knowledgeMap[id];
  }
  
  @override
  Future<List<Knowledge>> retrieveByTags(List<String> tags, {int limit = 10}) async {
    if (tags.isEmpty) {
      return [];
    }
    
    // 找到匹配所有标签的知识条目ID
    final matchingIds = <String>{};
    
    for (int i = 0; i < tags.length; i++) {
      final tag = tags[i];
      final idsWithTag = _tagIndex[tag] ?? {};
      
      if (i == 0) {
        matchingIds.addAll(idsWithTag);
      } else {
        matchingIds.retainAll(idsWithTag);
      }
      
      if (matchingIds.isEmpty) {
        break;
      }
    }
    
    // 检索匹配的知识条目
    final matchingKnowledge = matchingIds
        .map((id) => _knowledgeMap[id]!)
        .toList();
    
    // 按重要性排序并限制结果数量
    matchingKnowledge.sort((a, b) => b.importance.compareTo(a.importance));
    
    if (matchingKnowledge.length > limit) {
      return matchingKnowledge.sublist(0, limit);
    }
    
    return matchingKnowledge;
  }
  
  @override
  Future<List<QueryResult>> search(
    String query, 
    List<double>? queryEmbedding, {
    QueryOptions options = const QueryOptions(),
  }) async {
    final results = <QueryResult>[];
    
    if (queryEmbedding != null && queryEmbedding.isNotEmpty) {
      // 基于向量相似度搜索
      for (final entry in _vectorIndex.entries) {
        final id = entry.key;
        final embedding = entry.value;
        final knowledge = _knowledgeMap[id];
        
        if (knowledge == null) continue;
        
        // 应用标签过滤器
        if (options.tagFilter != null && options.tagFilter!.isNotEmpty) {
          bool hasAllTags = true;
          for (final tag in options.tagFilter!) {
            if (!knowledge.tags.contains(tag)) {
              hasAllTags = false;
              break;
            }
          }
          if (!hasAllTags) continue;
        }
        
        // 应用重要性过滤器
        if (knowledge.importance < options.minImportance) {
          continue;
        }
        
        // 应用元数据过滤器
        if (options.metadataFilter != null && options.metadataFilter!.isNotEmpty) {
          bool metadataMatches = true;
          for (final entry in options.metadataFilter!.entries) {
            if (knowledge.metadata[entry.key] != entry.value) {
              metadataMatches = false;
              break;
            }
          }
          if (!metadataMatches) continue;
        }
        
        // 计算向量相似度
        final similarity = _cosineSimilarity(queryEmbedding, embedding);
        
        // 应用相似度阈值
        if (similarity >= options.threshold) {
          results.add(QueryResult(knowledge: knowledge, similarity: similarity));
        }
      }
      
      // 按相似度排序
      results.sort((a, b) => b.similarity.compareTo(a.similarity));
    } else {
      // 基于关键词的简单搜索（如果没有提供查询嵌入）
      final lowerQuery = query.toLowerCase();
      
      for (final knowledge in _knowledgeMap.values) {
        // 应用标签过滤器
        if (options.tagFilter != null && options.tagFilter!.isNotEmpty) {
          bool hasAllTags = true;
          for (final tag in options.tagFilter!) {
            if (!knowledge.tags.contains(tag)) {
              hasAllTags = false;
              break;
            }
          }
          if (!hasAllTags) continue;
        }
        
        // 应用重要性过滤器
        if (knowledge.importance < options.minImportance) {
          continue;
        }
        
        // 应用元数据过滤器
        if (options.metadataFilter != null && options.metadataFilter!.isNotEmpty) {
          bool metadataMatches = true;
          for (final entry in options.metadataFilter!.entries) {
            if (knowledge.metadata[entry.key] != entry.value) {
              metadataMatches = false;
              break;
            }
          }
          if (!metadataMatches) continue;
        }
        
        // 简单文本匹配
        final titleMatch = knowledge.title.toLowerCase().contains(lowerQuery);
        final contentMatch = knowledge.content.toLowerCase().contains(lowerQuery);
        
        if (titleMatch || contentMatch) {
          // 简单相似度计算：标题匹配优先级更高
          final similarity = titleMatch ? 0.8 : 0.5;
          results.add(QueryResult(knowledge: knowledge, similarity: similarity));
        }
      }
      
      // 按相似度和重要性排序
      results.sort((a, b) {
        final similarityDiff = b.similarity.compareTo(a.similarity);
        if (similarityDiff != 0) return similarityDiff;
        return b.knowledge.importance.compareTo(a.knowledge.importance);
      });
    }
    
    // 限制结果数量
    if (results.length > options.limit) {
      return results.sublist(0, options.limit);
    }
    
    return results;
  }
  
  @override
  Future<void> update(Knowledge knowledge) async {
    if (!_knowledgeMap.containsKey(knowledge.id)) {
      throw Exception('知识条目不存在: ${knowledge.id}');
    }
    
    final oldKnowledge = _knowledgeMap[knowledge.id]!;
    
    // 从旧标签中移除
    for (final tag in oldKnowledge.tags) {
      _tagIndex[tag]?.remove(knowledge.id);
      if (_tagIndex[tag]?.isEmpty ?? false) {
        _tagIndex.remove(tag);
      }
    }
    
    // 添加到新标签
    for (final tag in knowledge.tags) {
      _tagIndex.putIfAbsent(tag, () => {}).add(knowledge.id);
    }
    
    // 更新向量索引
    if (knowledge.embedding != null) {
      _vectorIndex[knowledge.id] = knowledge.embedding!;
    } else {
      _vectorIndex.remove(knowledge.id);
    }
    
    // 更新知识条目
    _knowledgeMap[knowledge.id] = knowledge;
  }
  
  @override
  Future<void> delete(String id) async {
    if (!_knowledgeMap.containsKey(id)) {
      return;
    }
    
    final knowledge = _knowledgeMap[id]!;
    
    // 从标签索引中移除
    for (final tag in knowledge.tags) {
      _tagIndex[tag]?.remove(id);
      if (_tagIndex[tag]?.isEmpty ?? false) {
        _tagIndex.remove(tag);
      }
    }
    
    // 从向量索引中移除
    _vectorIndex.remove(id);
    
    // 从映射表中移除
    _knowledgeMap.remove(id);
  }
  
  @override
  Future<void> clear() async {
    _knowledgeMap.clear();
    _tagIndex.clear();
    _vectorIndex.clear();
  }
  
  @override
  Future<int> count() async {
    return _knowledgeMap.length;
  }
  
  @override
  Future<List<String>> getAllTags() async {
    return _tagIndex.keys.toList();
  }
  
  @override
  Future<Map<String, dynamic>> getStats() async {
    final tagCounts = <String, int>{};
    
    for (final entry in _tagIndex.entries) {
      tagCounts[entry.key] = entry.value.length;
    }
    
    return {
      'knowledgeCount': _knowledgeMap.length,
      'tagCount': _tagIndex.length,
      'tagStats': tagCounts,
      'vectorCount': _vectorIndex.length,
    };
  }
  
  @override
  Future<List<double>> generateEmbedding(String text) async {
    throw UnimplementedError('内存存储不支持生成嵌入向量');
  }
  
  /// 生成唯一ID
  String _generateId() {
    return 'k_${DateTime.now().millisecondsSinceEpoch}_${_knowledgeMap.length}';
  }
  
  /// 计算余弦相似度
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('向量长度不一致');
    }
    
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    normA = sqrt(normA);
    normB = sqrt(normB);
    
    if (normA == 0 || normB == 0) {
      return 0.0;
    }
    
    return dotProduct / (normA * normB);
  }
  
  /// 计算平方根
  double sqrt(double x) {
    if (x <= 0) return 0;
    
    double guess = x / 2;
    double result = guess;
    
    for (int i = 0; i < 10; i++) {
      if (result * result == x) break;
      
      result = 0.5 * (result + x / result);
    }
    
    return result;
  }
}

/// 内存存储提供者
final memoryStorageProvider = Provider<StorageInterface>((ref) {
  return MemoryStorage();
}); 