import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'knowledge_base.dart';

/// 节点类型
enum NodeType {
  /// 概念节点
  concept,
  
  /// 事实节点
  fact,
  
  /// 规则节点
  rule,
  
  /// 实体节点
  entity,
  
  /// 属性节点
  attribute,
}

/// 边类型
enum EdgeType {
  /// 是一种关系
  isA,
  
  /// 包含关系
  contains,
  
  /// 属于关系
  belongsTo,
  
  /// 相关关系
  relatesTo,
  
  /// 因果关系
  causes,
  
  /// 对比关系
  contrastedWith,
  
  /// 先决条件关系
  prerequisiteFor,
  
  /// 使用关系
  uses,
  
  /// 示例关系
  exampleOf,
  
  /// 自定义关系
  custom,
}

/// 图节点
class GraphNode {
  /// 节点ID
  final String id;
  
  /// 节点类型
  final NodeType type;
  
  /// 节点标签
  final String label;
  
  /// 节点属性
  final Map<String, dynamic> properties;
  
  /// 知识ID（可选）
  final String? knowledgeId;
  
  /// 构造函数
  const GraphNode({
    required this.id,
    required this.type,
    required this.label,
    this.properties = const {},
    this.knowledgeId,
  });
  
  /// 从Map创建图节点
  factory GraphNode.fromMap(Map<String, dynamic> map) {
    return GraphNode(
      id: map['id'],
      type: NodeType.values.byName(map['type']),
      label: map['label'],
      properties: Map<String, dynamic>.from(map['properties'] ?? {}),
      knowledgeId: map['knowledgeId'],
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'label': label,
      'properties': properties,
      'knowledgeId': knowledgeId,
    };
  }
  
  /// 复制并修改
  GraphNode copyWith({
    NodeType? type,
    String? label,
    Map<String, dynamic>? properties,
    String? knowledgeId,
  }) {
    return GraphNode(
      id: id,
      type: type ?? this.type,
      label: label ?? this.label,
      properties: properties ?? this.properties,
      knowledgeId: knowledgeId ?? this.knowledgeId,
    );
  }
}

/// 图边
class GraphEdge {
  /// 边ID
  final String id;
  
  /// 源节点ID
  final String sourceId;
  
  /// 目标节点ID
  final String targetId;
  
  /// 边类型
  final EdgeType type;
  
  /// 边标签
  final String label;
  
  /// 边属性
  final Map<String, dynamic> properties;
  
  /// 边权重
  final double weight;
  
  /// 构造函数
  const GraphEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.type,
    this.label = '',
    this.properties = const {},
    this.weight = 1.0,
  });
  
  /// 从Map创建图边
  factory GraphEdge.fromMap(Map<String, dynamic> map) {
    return GraphEdge(
      id: map['id'],
      sourceId: map['sourceId'],
      targetId: map['targetId'],
      type: EdgeType.values.byName(map['type']),
      label: map['label'] ?? '',
      properties: Map<String, dynamic>.from(map['properties'] ?? {}),
      weight: map['weight'] ?? 1.0,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceId': sourceId,
      'targetId': targetId,
      'type': type.name,
      'label': label,
      'properties': properties,
      'weight': weight,
    };
  }
  
  /// 复制并修改
  GraphEdge copyWith({
    String? sourceId,
    String? targetId,
    EdgeType? type,
    String? label,
    Map<String, dynamic>? properties,
    double? weight,
  }) {
    return GraphEdge(
      id: id,
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      type: type ?? this.type,
      label: label ?? this.label,
      properties: properties ?? this.properties,
      weight: weight ?? this.weight,
    );
  }
}

/// 知识图谱查询选项
class GraphQueryOptions {
  /// 最大深度
  final int maxDepth;
  
  /// 最大节点数
  final int maxNodes;
  
  /// 节点类型过滤
  final List<NodeType>? nodeTypeFilter;
  
  /// 边类型过滤
  final List<EdgeType>? edgeTypeFilter;
  
  /// 构造函数
  const GraphQueryOptions({
    this.maxDepth = 3,
    this.maxNodes = 100,
    this.nodeTypeFilter,
    this.edgeTypeFilter,
  });
}

/// 知识图谱管理器
class GraphManager {
  /// 节点集合
  final Map<String, GraphNode> _nodes = {};
  
  /// 边集合
  final Map<String, GraphEdge> _edges = {};
  
  /// 邻接表
  final Map<String, List<String>> _adjacencyList = {};
  
  /// 知识库
  final KnowledgeBase? _knowledgeBase;
  
  /// 构造函数
  GraphManager([this._knowledgeBase]);
  
  /// 添加节点
  Future<void> addNode(GraphNode node) async {
    _nodes[node.id] = node;
    _adjacencyList[node.id] ??= [];
  }
  
  /// 添加边
  Future<void> addEdge(GraphEdge edge) async {
    // 确保节点存在
    if (!_nodes.containsKey(edge.sourceId) || !_nodes.containsKey(edge.targetId)) {
      throw Exception('源节点或目标节点不存在');
    }
    
    _edges[edge.id] = edge;
    _adjacencyList[edge.sourceId]!.add(edge.id);
  }
  
  /// 获取节点
  GraphNode? getNode(String id) {
    return _nodes[id];
  }
  
  /// 获取边
  GraphEdge? getEdge(String id) {
    return _edges[id];
  }
  
  /// 获取与节点相关的边
  List<GraphEdge> getEdgesForNode(String nodeId) {
    if (!_adjacencyList.containsKey(nodeId)) {
      return [];
    }
    
    return _adjacencyList[nodeId]!
        .map((edgeId) => _edges[edgeId]!)
        .toList();
  }
  
  /// 获取相邻节点
  List<GraphNode> getNeighbors(String nodeId) {
    if (!_adjacencyList.containsKey(nodeId)) {
      return [];
    }
    
    return _adjacencyList[nodeId]!
        .map((edgeId) => _edges[edgeId]!)
        .map((edge) => _nodes[edge.targetId]!)
        .toList();
  }
  
  /// 更新节点
  Future<void> updateNode(GraphNode node) async {
    if (!_nodes.containsKey(node.id)) {
      throw Exception('节点不存在: ${node.id}');
    }
    
    _nodes[node.id] = node;
  }
  
  /// 更新边
  Future<void> updateEdge(GraphEdge edge) async {
    if (!_edges.containsKey(edge.id)) {
      throw Exception('边不存在: ${edge.id}');
    }
    
    _edges[edge.id] = edge;
  }
  
  /// 删除节点
  Future<void> deleteNode(String id) async {
    if (!_nodes.containsKey(id)) {
      return;
    }
    
    // 删除相关的边
    final edgeIds = [..._adjacencyList[id] ?? []];
    for (final edgeId in edgeIds) {
      await deleteEdge(edgeId);
    }
    
    // 删除指向该节点的边
    final edgesToDelete = _edges.values
        .where((edge) => edge.targetId == id)
        .map((edge) => edge.id)
        .toList();
    
    for (final edgeId in edgesToDelete) {
      await deleteEdge(edgeId);
    }
    
    // 删除节点和邻接表项
    _nodes.remove(id);
    _adjacencyList.remove(id);
  }
  
  /// 删除边
  Future<void> deleteEdge(String id) async {
    if (!_edges.containsKey(id)) {
      return;
    }
    
    final edge = _edges[id]!;
    _edges.remove(id);
    
    // 从邻接表中删除
    _adjacencyList[edge.sourceId]?.remove(id);
  }
  
  /// 获取子图
  Future<Map<String, dynamic>> getSubgraph(
    String startNodeId, {
    GraphQueryOptions options = const GraphQueryOptions(),
  }) async {
    final visitedNodes = <String>{};
    final visitedEdges = <String>{};
    final queue = <_BFSQueueItem>[_BFSQueueItem(startNodeId, 0)];
    
    final resultNodes = <GraphNode>[];
    final resultEdges = <GraphEdge>[];
    
    while (queue.isNotEmpty && resultNodes.length < options.maxNodes) {
      final item = queue.removeAt(0);
      final nodeId = item.nodeId;
      final depth = item.depth;
      
      if (visitedNodes.contains(nodeId) || depth > options.maxDepth) {
        continue;
      }
      
      visitedNodes.add(nodeId);
      
      final node = _nodes[nodeId];
      if (node == null) continue;
      
      // 应用节点类型过滤
      if (options.nodeTypeFilter == null || 
          options.nodeTypeFilter!.contains(node.type)) {
        resultNodes.add(node);
      }
      
      if (depth < options.maxDepth) {
        // 处理出边
        final edgeIds = _adjacencyList[nodeId] ?? [];
        for (final edgeId in edgeIds) {
          final edge = _edges[edgeId];
          if (edge == null || visitedEdges.contains(edgeId)) continue;
          
          // 应用边类型过滤
          if (options.edgeTypeFilter == null || 
              options.edgeTypeFilter!.contains(edge.type)) {
            resultEdges.add(edge);
            visitedEdges.add(edgeId);
            
            // 添加目标节点到队列
            queue.add(_BFSQueueItem(edge.targetId, depth + 1));
          }
        }
      }
    }
    
    return {
      'nodes': resultNodes.map((node) => node.toMap()).toList(),
      'edges': resultEdges.map((edge) => edge.toMap()).toList(),
    };
  }
  
  /// 查找最短路径
  Future<List<Map<String, dynamic>>> findShortestPath(
    String startNodeId,
    String endNodeId,
  ) async {
    final distances = <String, int>{};
    final previous = <String, String?>{};
    final unvisited = <String>{};
    
    // 初始化
    for (final nodeId in _nodes.keys) {
      distances[nodeId] = nodeId == startNodeId ? 0 : 999999;
      previous[nodeId] = null;
      unvisited.add(nodeId);
    }
    
    while (unvisited.isNotEmpty) {
      // 获取距离最小的未访问节点
      String? current;
      int minDistance = 999999;
      
      for (final nodeId in unvisited) {
        if (distances[nodeId]! < minDistance) {
          minDistance = distances[nodeId]!;
          current = nodeId;
        }
      }
      
      // 如果没有可达节点或已找到终点，退出
      if (current == null || current == endNodeId || minDistance == 999999) {
        break;
      }
      
      unvisited.remove(current);
      
      // 更新邻居的距离
      final edgeIds = _adjacencyList[current] ?? [];
      for (final edgeId in edgeIds) {
        final edge = _edges[edgeId];
        if (edge == null) continue;
        
        final neighbor = edge.targetId;
        final weight = (1 / edge.weight).round(); // 权重越大，距离越小
        final newDistance = distances[current]! + weight;
        
        if (newDistance < distances[neighbor]!) {
          distances[neighbor] = newDistance;
          previous[neighbor] = current;
        }
      }
    }
    
    // 构建路径
    final path = <Map<String, dynamic>>[];
    String? current = endNodeId;
    
    // 如果找不到路径
    if (previous[endNodeId] == null && startNodeId != endNodeId) {
      return [];
    }
    
    while (current != null) {
      path.add(_nodes[current]!.toMap());
      
      final prev = previous[current];
      if (prev != null) {
        // 添加边信息
        final edge = _edges.values.firstWhere(
          (e) => e.sourceId == prev && e.targetId == current,
          orElse: () => const GraphEdge(
            id: '', 
            sourceId: '', 
            targetId: '', 
            type: EdgeType.relatesTo,
          ),
        );
        
        if (edge.id.isNotEmpty) {
          path.add(edge.toMap());
        }
      }
      
      current = prev;
    }
    
    return path.reversed.toList();
  }
  
  /// 从知识条目创建节点
  Future<GraphNode> createNodeFromKnowledge(Knowledge knowledge) async {
    final nodeId = 'node_${knowledge.id}';
    
    final node = GraphNode(
      id: nodeId,
      type: _determineNodeType(knowledge),
      label: knowledge.title,
      properties: {
        'content': knowledge.content,
        'tags': knowledge.tags,
        'importance': knowledge.importance,
        'createdAt': knowledge.createdAt.toIso8601String(),
      },
      knowledgeId: knowledge.id,
    );
    
    await addNode(node);
    return node;
  }
  
  /// 确定节点类型
  NodeType _determineNodeType(Knowledge knowledge) {
    // 基于知识的标签和内容确定节点类型
    final tags = knowledge.tags.map((tag) => tag.toLowerCase()).toList();
    
    if (tags.contains('concept') || tags.contains('概念')) {
      return NodeType.concept;
    } else if (tags.contains('fact') || tags.contains('事实')) {
      return NodeType.fact;
    } else if (tags.contains('rule') || tags.contains('规则')) {
      return NodeType.rule;
    } else if (tags.contains('entity') || tags.contains('实体')) {
      return NodeType.entity;
    } else if (tags.contains('attribute') || tags.contains('属性')) {
      return NodeType.attribute;
    }
    
    // 默认为概念节点
    return NodeType.concept;
  }
  
  /// 自动创建知识节点之间的关系
  Future<void> autoGenerateRelationships(
    List<String> knowledgeIds, {
    double similarityThreshold = 0.7,
  }) async {
    if (_knowledgeBase == null) return;
    
    final nodes = <String, GraphNode>{};
    
    // 检索节点或创建新节点
    for (final knowledgeId in knowledgeIds) {
      final knowledge = await _knowledgeBase!.getById(knowledgeId);
      if (knowledge == null) continue;
      
      // 查找现有节点
      GraphNode? node = _nodes.values
          .firstWhere(
            (n) => n.knowledgeId == knowledgeId,
            orElse: () => const GraphNode(
              id: '', 
              type: NodeType.concept, 
              label: '',
            ),
          );
      
      // 如果节点不存在，创建新节点
      if (node.id.isEmpty) {
        node = await createNodeFromKnowledge(knowledge);
      }
      
      nodes[knowledgeId] = node;
    }
    
    // 分析节点之间的关系
    for (final sourceId in nodes.keys) {
      for (final targetId in nodes.keys) {
        if (sourceId == targetId) continue;
        
        final sourceNode = nodes[sourceId]!;
        final targetNode = nodes[targetId]!;
        
        if (_knowledgeBase != null) {
          // 检索源知识和目标知识
          final sourceKnowledge = await _knowledgeBase!.getById(sourceId);
          final targetKnowledge = await _knowledgeBase!.getById(targetId);
          
          if (sourceKnowledge == null || targetKnowledge == null) continue;
          
          // 计算相似度
          final similarity = _calculateKnowledgeSimilarity(
            sourceKnowledge, 
            targetKnowledge,
          );
          
          if (similarity >= similarityThreshold) {
            // 创建关系边
            final edgeId = 'edge_${sourceNode.id}_${targetNode.id}';
            
            // 检查边是否已存在
            if (_edges.values.any((e) => 
                e.sourceId == sourceNode.id && e.targetId == targetNode.id)) {
              continue;
            }
            
            final edge = GraphEdge(
              id: edgeId,
              sourceId: sourceNode.id,
              targetId: targetNode.id,
              type: _determineEdgeType(sourceKnowledge, targetKnowledge),
              label: '相关',
              weight: similarity,
            );
            
            await addEdge(edge);
          }
        }
      }
    }
  }
  
  /// 计算知识之间的相似度
  double _calculateKnowledgeSimilarity(
    Knowledge source,
    Knowledge target,
  ) {
    // 如果有嵌入向量，使用向量相似度
    if (source.embedding != null && target.embedding != null) {
      return _cosineSimilarity(source.embedding!, target.embedding!);
    }
    
    // 基于标签的简单相似度计算
    final sourceTags = source.tags.toSet();
    final targetTags = target.tags.toSet();
    
    if (sourceTags.isEmpty || targetTags.isEmpty) {
      return 0.0;
    }
    
    final intersection = sourceTags.intersection(targetTags).length;
    final union = sourceTags.union(targetTags).length;
    
    return intersection / union;
  }
  
  /// 余弦相似度
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
  
  /// 确定边类型
  EdgeType _determineEdgeType(Knowledge source, Knowledge target) {
    // 基于知识内容和标签确定边类型的逻辑
    // 这是一个简化实现
    
    final sourceTags = source.tags.map((tag) => tag.toLowerCase()).toList();
    final targetTags = target.tags.map((tag) => tag.toLowerCase()).toList();
    
    // 检查是否是父子关系
    if (sourceTags.contains('parent') || targetTags.contains('child')) {
      return EdgeType.contains;
    }
    
    // 检查是否是因果关系
    if (sourceTags.contains('cause') || targetTags.contains('effect')) {
      return EdgeType.causes;
    }
    
    // 默认为相关关系
    return EdgeType.relatesTo;
  }
  
  /// 获取图谱统计信息
  Map<String, dynamic> getStats() {
    return {
      'nodeCount': _nodes.length,
      'edgeCount': _edges.length,
      'nodeTypes': _nodes.values
          .fold<Map<String, int>>(
            {},
            (map, node) {
              final type = node.type.name;
              map[type] = (map[type] ?? 0) + 1;
              return map;
            },
          ),
      'edgeTypes': _edges.values
          .fold<Map<String, int>>(
            {},
            (map, edge) {
              final type = edge.type.name;
              map[type] = (map[type] ?? 0) + 1;
              return map;
            },
          ),
    };
  }
  
  /// 清空图谱
  void clear() {
    _nodes.clear();
    _edges.clear();
    _adjacencyList.clear();
  }
}

/// BFS队列项
class _BFSQueueItem {
  final String nodeId;
  final int depth;
  
  _BFSQueueItem(this.nodeId, this.depth);
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

/// 知识图谱管理器提供者
final graphManagerProvider = Provider<GraphManager>((ref) {
  final knowledgeBase = ref.watch(knowledgeBaseProvider);
  return GraphManager(knowledgeBase);
});

/// 知识库提供者（需要在应用中定义）
final knowledgeBaseProvider = Provider<KnowledgeBase?>((ref) {
  // 这需要在应用中实现
  return null;
}); 