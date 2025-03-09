import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'ml_service.dart';
import 'context_awareness_service.dart';
import 'semantic_analysis_service.dart';

/// 建议类型
enum SuggestionType {
  completion,    // 代码补全
  refactoring,   // 重构建议
  optimization,  // 优化建议
  documentation, // 文档建议
  fix,          // 错误修复
  pattern,      // 设计模式
}

/// 建议项
class Suggestion {
  final String id;
  final SuggestionType type;
  final String text;
  final String detail;
  final double confidence;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const Suggestion({
    required this.id,
    required this.type,
    required this.text,
    required this.detail,
    required this.confidence,
    this.metadata = const {},
    required this.timestamp,
  });
}

/// 建议上下文
class SuggestionContext {
  final String code;
  final int cursorPosition;
  final List<ContextInfo> contexts;
  final SemanticAnalysisResult semantics;
  final Map<String, dynamic> metadata;

  const SuggestionContext({
    required this.code,
    required this.cursorPosition,
    required this.contexts,
    required this.semantics,
    this.metadata = const {},
  });
}

/// 建议服务
class SuggestionService {
  final MLService _mlService;
  final ContextAwarenessService _contextService;
  final SemanticAnalysisService _semanticService;
  
  // 缓存
  final Map<String, List<Suggestion>> _suggestionCache = {};
  final Map<String, DateTime> _lastUpdateTime = {};
  
  // 历史记录
  final List<Suggestion> _suggestionHistory = [];
  final int _maxHistorySize = 100;
  
  // 配置
  final Duration _cacheTimeout = const Duration(minutes: 5);
  final int _maxCacheSize = 1000;
  final double _confidenceThreshold = 0.7;

  SuggestionService(
    this._mlService,
    this._contextService,
    this._semanticService,
  );

  /// 生成建议
  Future<List<Suggestion>> generateSuggestions(
    String code,
    int cursorPosition,
    {bool useCache = true}
  ) async {
    // 检查缓存
    final cacheKey = _generateCacheKey(code, cursorPosition);
    if (useCache && _isCacheValid(cacheKey)) {
      return _suggestionCache[cacheKey] ?? [];
    }

    // 获取上下文信息
    final contexts = await _contextService.analyzeContext(
      code,
      cursorPosition,
      useCache: useCache,
    );

    // 获取语义分析结果
    final semantics = await _semanticService.analyzeSemantics(
      code,
      useCache: useCache,
    );

    // 创建建议上下文
    final context = SuggestionContext(
      code: code,
      cursorPosition: cursorPosition,
      contexts: contexts,
      semantics: semantics,
    );

    // 生成各类型建议
    final suggestions = <Suggestion>[];
    
    // 代码补全建议
    suggestions.addAll(await _generateCompletions(context));
    
    // 重构建议
    suggestions.addAll(await _generateRefactorings(context));
    
    // 优化建议
    suggestions.addAll(await _generateOptimizations(context));
    
    // 文档建议
    suggestions.addAll(await _generateDocumentation(context));
    
    // 错误修复建议
    suggestions.addAll(await _generateFixes(context));
    
    // 设计模式建议
    suggestions.addAll(await _generatePatterns(context));

    // 使用ML服务优化建议
    await _enrichSuggestionsWithML(suggestions, context);

    // 过滤和排序建议
    final filteredSuggestions = _filterAndRankSuggestions(suggestions);

    // 更新缓存
    _updateCache(cacheKey, filteredSuggestions);
    
    // 更新历史
    _updateHistory(filteredSuggestions);

    return filteredSuggestions;
  }

  /// 生成代码补全建议
  Future<List<Suggestion>> _generateCompletions(SuggestionContext context) async {
    final predictions = await _mlService.predictSuggestions(
      context.code.substring(0, context.cursorPosition),
      ModelType.suggestion,
      {'context': context},
    );
    
    return predictions
      .where((p) => p.confidence >= _confidenceThreshold)
      .map((p) => Suggestion(
        id: _generateSuggestionId(),
        type: SuggestionType.completion,
        text: p.output,
        detail: p.metadata['detail'] ?? '',
        confidence: p.confidence,
        metadata: p.metadata,
        timestamp: DateTime.now(),
      ))
      .toList();
  }

  /// 生成重构建议
  Future<List<Suggestion>> _generateRefactorings(SuggestionContext context) async {
    final predictions = await _mlService.predictSuggestions(
      context.code,
      ModelType.classification,
      {
        'type': 'refactoring',
        'context': context,
      },
    );
    
    return predictions
      .where((p) => p.confidence >= _confidenceThreshold)
      .map((p) => Suggestion(
        id: _generateSuggestionId(),
        type: SuggestionType.refactoring,
        text: p.output,
        detail: p.metadata['detail'] ?? '',
        confidence: p.confidence,
        metadata: p.metadata,
        timestamp: DateTime.now(),
      ))
      .toList();
  }

  /// 生成优化建议
  Future<List<Suggestion>> _generateOptimizations(SuggestionContext context) async {
    final predictions = await _mlService.predictSuggestions(
      context.code,
      ModelType.classification,
      {
        'type': 'optimization',
        'context': context,
      },
    );
    
    return predictions
      .where((p) => p.confidence >= _confidenceThreshold)
      .map((p) => Suggestion(
        id: _generateSuggestionId(),
        type: SuggestionType.optimization,
        text: p.output,
        detail: p.metadata['detail'] ?? '',
        confidence: p.confidence,
        metadata: p.metadata,
        timestamp: DateTime.now(),
      ))
      .toList();
  }

  /// 生成文档建议
  Future<List<Suggestion>> _generateDocumentation(SuggestionContext context) async {
    final predictions = await _mlService.predictSuggestions(
      context.code,
      ModelType.classification,
      {
        'type': 'documentation',
        'context': context,
      },
    );
    
    return predictions
      .where((p) => p.confidence >= _confidenceThreshold)
      .map((p) => Suggestion(
        id: _generateSuggestionId(),
        type: SuggestionType.documentation,
        text: p.output,
        detail: p.metadata['detail'] ?? '',
        confidence: p.confidence,
        metadata: p.metadata,
        timestamp: DateTime.now(),
      ))
      .toList();
  }

  /// 生成错误修复建议
  Future<List<Suggestion>> _generateFixes(SuggestionContext context) async {
    final predictions = await _mlService.predictSuggestions(
      context.code,
      ModelType.classification,
      {
        'type': 'fix',
        'context': context,
      },
    );
    
    return predictions
      .where((p) => p.confidence >= _confidenceThreshold)
      .map((p) => Suggestion(
        id: _generateSuggestionId(),
        type: SuggestionType.fix,
        text: p.output,
        detail: p.metadata['detail'] ?? '',
        confidence: p.confidence,
        metadata: p.metadata,
        timestamp: DateTime.now(),
      ))
      .toList();
  }

  /// 生成设计模式建议
  Future<List<Suggestion>> _generatePatterns(SuggestionContext context) async {
    final predictions = await _mlService.predictSuggestions(
      context.code,
      ModelType.classification,
      {
        'type': 'pattern',
        'context': context,
      },
    );
    
    return predictions
      .where((p) => p.confidence >= _confidenceThreshold)
      .map((p) => Suggestion(
        id: _generateSuggestionId(),
        type: SuggestionType.pattern,
        text: p.output,
        detail: p.metadata['detail'] ?? '',
        confidence: p.confidence,
        metadata: p.metadata,
        timestamp: DateTime.now(),
      ))
      .toList();
  }

  /// 使用ML服务优化建议
  Future<void> _enrichSuggestionsWithML(
    List<Suggestion> suggestions,
    SuggestionContext context,
  ) async {
    final predictions = await _mlService.predictSuggestions(
      context.code,
      ModelType.ranking,
      {
        'suggestions': suggestions,
        'context': context,
      },
    );
    
    // 更新建议的元数据和置信度
    for (final prediction in predictions) {
      final suggestionId = prediction.metadata['suggestion_id'];
      if (suggestionId != null) {
        final suggestion = suggestions.firstWhere(
          (s) => s.id == suggestionId,
          orElse: () => null,
        );
        if (suggestion != null) {
          suggestion.metadata.addAll(prediction.metadata);
          suggestion.metadata['ml_confidence'] = prediction.confidence;
        }
      }
    }
  }

  /// 过滤和排序建议
  List<Suggestion> _filterAndRankSuggestions(List<Suggestion> suggestions) {
    // 过滤低置信度建议
    final filtered = suggestions
      .where((s) => s.confidence >= _confidenceThreshold)
      .toList();
    
    // 按置信度排序
    filtered.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    return filtered;
  }

  /// 生成缓存键
  String _generateCacheKey(String code, int cursorPosition) {
    return '${code.hashCode}_$cursorPosition';
  }

  /// 生成建议ID
  String _generateSuggestionId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  /// 检查缓存是否有效
  bool _isCacheValid(String key) {
    final lastUpdate = _lastUpdateTime[key];
    if (lastUpdate == null) return false;
    
    return DateTime.now().difference(lastUpdate) < _cacheTimeout;
  }

  /// 更新缓存
  void _updateCache(String key, List<Suggestion> suggestions) {
    _suggestionCache[key] = suggestions;
    _lastUpdateTime[key] = DateTime.now();
    
    // 清理过期缓存
    if (_suggestionCache.length > _maxCacheSize) {
      final oldestKey = _lastUpdateTime.entries
        .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
        .key;
      _suggestionCache.remove(oldestKey);
      _lastUpdateTime.remove(oldestKey);
    }
  }

  /// 更新历史
  void _updateHistory(List<Suggestion> suggestions) {
    _suggestionHistory.insertAll(0, suggestions);
    while (_suggestionHistory.length > _maxHistorySize) {
      _suggestionHistory.removeLast();
    }
  }
}

/// 建议服务提供者
final suggestionServiceProvider = Provider<SuggestionService>((ref) {
  final mlService = ref.watch(mlServiceProvider);
  final contextService = ref.watch(contextAwarenessServiceProvider);
  final semanticService = ref.watch(semanticAnalysisServiceProvider);
  return SuggestionService(mlService, contextService, semanticService);
}); 