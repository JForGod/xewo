import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'ml_service.dart';
import 'context_awareness_service.dart';

/// 语义类型
enum SemanticType {
  declaration,  // 声明
  reference,    // 引用
  modification, // 修改
  invocation,   // 调用
  inheritance,  // 继承
  implementation, // 实现
}

/// 语义关系
class SemanticRelation {
  final String sourceId;
  final String targetId;
  final String type;
  final Map<String, dynamic> metadata;

  const SemanticRelation({
    required this.sourceId,
    required this.targetId,
    required this.type,
    this.metadata = const {},
  });
}

/// 语义节点
class SemanticNode {
  final String id;
  final SemanticType type;
  final String name;
  final String scope;
  final Map<String, dynamic> metadata;
  final List<SemanticRelation> relations;

  const SemanticNode({
    required this.id,
    required this.type,
    required this.name,
    required this.scope,
    this.metadata = const {},
    this.relations = const [],
  });
}

/// 语义分析结果
class SemanticAnalysisResult {
  final List<SemanticNode> nodes;
  final List<SemanticRelation> relations;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const SemanticAnalysisResult({
    required this.nodes,
    required this.relations,
    this.metadata = const {},
    required this.timestamp,
  });
}

/// 语义分析服务
class SemanticAnalysisService {
  final MLService _mlService;
  final ContextAwarenessService _contextService;
  
  // 缓存
  final Map<String, SemanticAnalysisResult> _analysisCache = {};
  final Map<String, List<SemanticNode>> _nodeCache = {};
  
  // 分析历史
  final List<SemanticAnalysisResult> _analysisHistory = [];
  final int _maxHistorySize = 50;

  SemanticAnalysisService(this._mlService, this._contextService);

  /// 分析代码语义
  Future<SemanticAnalysisResult> analyzeSemantics(
    String code,
    {bool useCache = true}
  ) async {
    // 检查缓存
    final cacheKey = _generateCacheKey(code);
    if (useCache && _analysisCache.containsKey(cacheKey)) {
      return _analysisCache[cacheKey]!;
    }

    // 获取上下文信息
    final contexts = await _contextService.analyzeContext(code, 0);

    // 提取语义节点
    final nodes = await _extractSemanticNodes(code, contexts);

    // 分析语义关系
    final relations = await _analyzeSemanticRelations(nodes);

    // 使用ML服务进行深度分析
    await _enrichSemanticsWithML(nodes, relations, code);

    // 创建分析结果
    final result = SemanticAnalysisResult(
      nodes: nodes,
      relations: relations,
      metadata: {
        'complexity': _calculateComplexity(nodes, relations),
        'quality_score': await _calculateQualityScore(nodes, relations),
      },
      timestamp: DateTime.now(),
    );

    // 更新缓存和历史
    _updateCache(cacheKey, result);
    _updateHistory(result);

    return result;
  }

  /// 提取语义节点
  Future<List<SemanticNode>> _extractSemanticNodes(
    String code,
    List<ContextInfo> contexts,
  ) async {
    final nodes = <SemanticNode>[];
    
    // 使用ML服务识别语义节点
    final predictions = await _mlService.predictSuggestions(
      code,
      ModelType.classification,
      {'contexts': contexts},
    );
    
    for (final prediction in predictions) {
      if (prediction.confidence > 0.7) {
        final nodeType = _parseSemanticType(prediction.output);
        if (nodeType != null) {
          nodes.add(SemanticNode(
            id: _generateNodeId(),
            type: nodeType,
            name: prediction.metadata['name'] ?? '',
            scope: prediction.metadata['scope'] ?? '',
            metadata: prediction.metadata,
          ));
        }
      }
    }
    
    return nodes;
  }

  /// 分析语义关系
  Future<List<SemanticRelation>> _analyzeSemanticRelations(
    List<SemanticNode> nodes,
  ) async {
    final relations = <SemanticRelation>[];
    
    // 分析节点间的关系
    for (final source in nodes) {
      for (final target in nodes) {
        if (source.id != target.id) {
          final relation = await _detectRelation(source, target);
          if (relation != null) {
            relations.add(relation);
          }
        }
      }
    }
    
    return relations;
  }

  /// 使用ML服务丰富语义信息
  Future<void> _enrichSemanticsWithML(
    List<SemanticNode> nodes,
    List<SemanticRelation> relations,
    String code,
  ) async {
    // 使用ML服务进行深度语义分析
    final predictions = await _mlService.predictSuggestions(
      code,
      ModelType.embedding,
      {
        'nodes': nodes,
        'relations': relations,
      },
    );
    
    // 更新节点和关系的元数据
    for (final prediction in predictions) {
      final metadata = prediction.metadata;
      final targetId = metadata['target_id'];
      
      if (targetId != null) {
        // 更新节点元数据
        final node = nodes.firstWhere(
          (n) => n.id == targetId,
          orElse: () => null,
        );
        if (node != null) {
          node.metadata.addAll(metadata);
        }
        
        // 更新关系元数据
        final relation = relations.firstWhere(
          (r) => r.sourceId == targetId || r.targetId == targetId,
          orElse: () => null,
        );
        if (relation != null) {
          relation.metadata.addAll(metadata);
        }
      }
    }
  }

  /// 检测节点间的关系
  Future<SemanticRelation?> _detectRelation(
    SemanticNode source,
    SemanticNode target,
  ) async {
    // 使用ML服务预测关系
    final predictions = await _mlService.predictSuggestions(
      '${source.name} -> ${target.name}',
      ModelType.classification,
      {
        'source': source,
        'target': target,
      },
    );
    
    if (predictions.isNotEmpty && predictions.first.confidence > 0.7) {
      return SemanticRelation(
        sourceId: source.id,
        targetId: target.id,
        type: predictions.first.output,
        metadata: predictions.first.metadata,
      );
    }
    
    return null;
  }

  /// 计算代码复杂度
  double _calculateComplexity(
    List<SemanticNode> nodes,
    List<SemanticRelation> relations,
  ) {
    // 基于节点数量和关系数量计算复杂度
    return (nodes.length * 0.3 + relations.length * 0.7) / 10;
  }

  /// 计算代码质量分数
  Future<double> _calculateQualityScore(
    List<SemanticNode> nodes,
    List<SemanticRelation> relations,
  ) async {
    // 使用ML服务评估代码质量
    final predictions = await _mlService.predictSuggestions(
      'quality_assessment',
      ModelType.ranking,
      {
        'nodes': nodes,
        'relations': relations,
      },
    );
    
    if (predictions.isNotEmpty) {
      return predictions.first.confidence;
    }
    
    return 0.0;
  }

  /// 生成缓存键
  String _generateCacheKey(String code) {
    return code.hashCode.toString();
  }

  /// 生成节点ID
  String _generateNodeId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  /// 解析语义类型
  SemanticType? _parseSemanticType(String type) {
    try {
      return SemanticType.values.firstWhere(
        (t) => t.toString().split('.').last.toLowerCase() == type.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// 更新缓存
  void _updateCache(String key, SemanticAnalysisResult result) {
    _analysisCache[key] = result;
    
    // 清理过期缓存
    if (_analysisCache.length > 100) {
      final oldestKey = _analysisCache.entries
        .reduce((a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b)
        .key;
      _analysisCache.remove(oldestKey);
    }
  }

  /// 更新历史
  void _updateHistory(SemanticAnalysisResult result) {
    _analysisHistory.insert(0, result);
    if (_analysisHistory.length > _maxHistorySize) {
      _analysisHistory.removeLast();
    }
  }
}

/// 语义分析服务提供者
final semanticAnalysisServiceProvider = Provider<SemanticAnalysisService>((ref) {
  final mlService = ref.watch(mlServiceProvider);
  final contextService = ref.watch(contextAwarenessServiceProvider);
  return SemanticAnalysisService(mlService, contextService);
}); 