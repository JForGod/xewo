import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

/// 知识条目
class Knowledge {
  /// 唯一标识符
  final String id;
  
  /// 标题
  final String title;
  
  /// 内容
  final String content;
  
  /// 标签
  final List<String> tags;
  
  /// 来源
  final String source;
  
  /// 重要性 (0.0-1.0)
  final double importance;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 最后更新时间
  final DateTime updatedAt;
  
  /// 元数据
  final Map<String, dynamic> metadata;
  
  /// 嵌入向量
  final List<double>? embedding;
  
  /// 构造函数
  Knowledge({
    required this.id,
    required this.title,
    required this.content,
    this.tags = const [],
    this.source = '',
    this.importance = 0.5,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.metadata = const {},
    this.embedding,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
  
  /// 从Map创建知识
  factory Knowledge.fromMap(Map<String, dynamic> map) {
    return Knowledge(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      tags: List<String>.from(map['tags'] ?? []),
      source: map['source'] ?? '',
      importance: map['importance'] ?? 0.5,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      embedding: map['embedding'] != null 
          ? List<double>.from(map['embedding']) 
          : null,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'tags': tags,
      'source': source,
      'importance': importance,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
      'embedding': embedding,
    };
  }
  
  /// 复制并修改
  Knowledge copyWith({
    String? title,
    String? content,
    List<String>? tags,
    String? source,
    double? importance,
    Map<String, dynamic>? metadata,
    List<double>? embedding,
  }) {
    return Knowledge(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      source: source ?? this.source,
      importance: importance ?? this.importance,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      metadata: metadata ?? this.metadata,
      embedding: embedding ?? this.embedding,
    );
  }
}

/// 查询选项
class QueryOptions {
  /// 最大结果数
  final int limit;
  
  /// 相似度阈值 (0.0-1.0)
  final double threshold;
  
  /// 标签过滤
  final List<String>? tagFilter;
  
  /// 重要性最小值
  final double? minImportance;
  
  /// 元数据过滤
  final Map<String, dynamic>? metadataFilter;
  
  /// 构造函数
  const QueryOptions({
    this.limit = 10,
    this.threshold = 0.7,
    this.tagFilter,
    this.minImportance,
    this.metadataFilter,
  });
}

/// 查询结果
class QueryResult {
  /// 知识条目
  final Knowledge knowledge;
  
  /// 相似度 (0.0-1.0)
  final double similarity;
  
  /// 构造函数
  const QueryResult({
    required this.knowledge,
    required this.similarity,
  });
}

/// 知识库基类
abstract class KnowledgeBase {
  /// 初始化知识库
  Future<void> initialize();
  
  /// 存储知识
  Future<void> store(Knowledge knowledge);
  
  /// 批量存储知识
  Future<void> storeBatch(List<Knowledge> knowledgeList);
  
  /// 根据查询检索知识
  Future<List<QueryResult>> retrieve(
    String query, {
    QueryOptions? options,
  });
  
  /// 根据ID获取知识
  Future<Knowledge?> getById(String id);
  
  /// 根据标签获取知识
  Future<List<Knowledge>> getByTags(List<String> tags);
  
  /// 更新知识
  Future<void> update(Knowledge knowledge);
  
  /// 删除知识
  Future<void> delete(String id);
  
  /// 清空知识库
  Future<void> clear();
  
  /// 获取知识库统计信息
  Future<Map<String, dynamic>> getStats();
  
  /// 关闭知识库
  Future<void> close();
  
  /// 生成知识嵌入
  Future<List<double>> generateEmbedding(String text);
  
  /// 计算向量相似度
  double calculateSimilarity(List<double> a, List<double> b);
} 