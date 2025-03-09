import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../editor/language_support.dart';
import '../editor/performance_service.dart';
import '../core/logger_service.dart';
import 'dart:io';
import 'package:logging/logging.dart';

import 'parsers/dart_parser.dart';
import 'parsers/javascript_parser.dart';
import 'parsers/python_parser.dart';
import 'parsers/cpp_parser.dart';
import 'parsers/language_parser.dart';

/// 上下文类型
enum ContextType {
  function,    // 函数上下文
  class_,      // 类上下文
  variable,    // 变量上下文
  statement,   // 语句上下文
  expression,  // 表达式上下文
  block,       // 代码块上下文
  file,        // 文件上下文
  project,     // 项目上下文
  import,      // 导入上下文
  comment,     // 注释上下文
  other,       // 其他上下文
}

/// 上下文范围
class ContextRange {
  final int start;
  final int end;
  final int line;
  final int column;

  const ContextRange({
    required this.start,
    required this.end,
    required this.line,
    required this.column,
  });

  /// 从JSON创建
  factory ContextRange.fromJson(Map<String, dynamic> json) {
    return ContextRange(
      start: json['start'] as int,
      end: json['end'] as int,
      line: json['line'] as int,
      column: json['column'] as int,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      'line': line,
      'column': column,
    };
  }
}

/// 上下文信息
class ContextInfo {
  final String id;
  final ContextType type;
  final String name;
  final ContextRange range;
  final Map<String, dynamic> metadata;
  final List<String> dependencies;
  final List<ContextInfo> children;
  final DateTime analyzedAt;

  const ContextInfo({
    required this.id,
    required this.type,
    required this.name,
    required this.range,
    this.metadata = const {},
    this.dependencies = const [],
    this.children = const [],
    required this.analyzedAt,
  });

  /// 从JSON创建
  factory ContextInfo.fromJson(Map<String, dynamic> json) {
    return ContextInfo(
      id: json['id'] as String,
      type: ContextType.values.firstWhere(
        (e) => e.toString() == 'ContextType.${json['type']}',
      ),
      name: json['name'] as String,
      range: ContextRange.fromJson(json['range'] as Map<String, dynamic>),
      metadata: json['metadata'] as Map<String, dynamic>,
      dependencies: (json['dependencies'] as List<dynamic>).cast<String>(),
      children: (json['children'] as List<dynamic>)
          .map((e) => ContextInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'name': name,
      'range': range.toJson(),
      'metadata': metadata,
      'dependencies': dependencies,
      'children': children.map((e) => e.toJson()).toList(),
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }
}

/// 智能建议模型
class Suggestion {
  final String title;
  final String description;
  final String code;
  final double confidence;
  final Map<String, dynamic> metadata;

  const Suggestion({
    required this.title,
    required this.description,
    required this.code,
    required this.confidence,
    this.metadata = const {},
  });
}

/// 上下文感知服务提供者
final contextAwarenessServiceProvider = Provider<ContextAwarenessService>((ref) {
  final logger = ref.watch(loggerServiceProvider);
  final performanceService = ref.watch(performanceServiceProvider);
  final languageSupport = ref.watch(languageSupportProvider);
  return ContextAwarenessService(logger, performanceService, languageSupport);
});

/// 上下文感知服务
class ContextAwarenessService {
  final LoggerService _logger;
  final PerformanceService _performanceService;
  final LanguageSupport _languageSupport;
  final Logger _log = Logger('ContextAwarenessService');
  
  // 上下文缓存
  final Map<String, List<ContextInfo>> _contextCache = {};
  
  // 文件上下文缓存
  final Map<String, List<ContextInfo>> _fileContextCache = {};
  
  // 导入缓存
  final Map<String, List<String>> _importCache = {};
  
  // 文件内容缓存
  final Map<String, String> _fileContentCache = {};
  
  // 依赖图
  final Map<String, Set<String>> _dependencyGraph = {};
  
  // 上下文历史
  final List<ContextInfo> _contextHistory = [];
  final int _maxHistorySize = 100;
  
  // 最后分析时间
  final Map<String, DateTime> _lastAnalysisTime = {};

  // 语言解析器
  final Map<String, LanguageParser> _parsers = {
    '.dart': DartParser(),
    '.js': JavaScriptParser(),
    '.jsx': JavaScriptParser(),
    '.ts': JavaScriptParser(),
    '.tsx': JavaScriptParser(),
    '.py': PythonParser(),
    '.cpp': CppParser(),
    '.cc': CppParser(),
    '.cxx': CppParser(),
    '.h': CppParser(),
    '.hpp': CppParser(),
    '.hxx': CppParser(),
  };
  
  ContextAwarenessService(
    this._logger, 
    this._performanceService, 
    this._languageSupport,
  );

  /// 分析代码上下文
  Future<List<ContextInfo>> analyzeContext(
    String code,
    int cursorPosition,
  ) async {
    // 生成缓存键
    final cacheKey = '${code}_$cursorPosition';
    
    // 检查缓存是否有效
    if (_isContextCacheValid(cacheKey)) {
      return _contextCache[cacheKey]!;
    }
    
    final contexts = <ContextInfo>[];
    
    // 解析代码结构
    final structure = await _parseCodeStructure(code);
    
    // 分析当前位置的上下文
    contexts.addAll(_analyzeCurrentContext(structure, cursorPosition));
    
    // 分析依赖关系
    _analyzeDependencies(contexts);
    
    // 更新缓存
    _updateContextCache(cacheKey, contexts);
    
    // 更新历史
    _updateContextHistory(contexts);
    
    return contexts;
  }

  /// 获取相关上下文
  List<ContextInfo> getRelatedContexts(ContextInfo context) {
    final relatedContexts = <ContextInfo>[];
    
    // 获取直接依赖
    final directDependencies = _dependencyGraph[context.id] ?? {};
    for (final depId in directDependencies) {
      final depContext = _findContextById(depId);
      if (depContext != null) {
        relatedContexts.add(depContext);
      }
    }
    
    // 获取历史相关上下文
    relatedContexts.addAll(_findHistoricalRelatedContexts(context));
    
    return relatedContexts;
  }

  /// 清除缓存
  void clearCache() {
    _contextCache.clear();
    _importCache.clear();
    _fileContentCache.clear();
    _logger.info('Context awareness cache cleared');
  }

  /// 检查缓存是否有效
  bool _isContextCacheValid(String cacheKey) {
    if (!_contextCache.containsKey(cacheKey)) {
      return false;
    }
    
    // 检查缓存是否过期
    final lastAnalysis = _lastAnalysisTime[cacheKey];
    if (lastAnalysis == null) {
      return false;
    }
    
    // 缓存有效期为5分钟
    final now = DateTime.now();
    return now.difference(lastAnalysis).inMinutes < 5;
  }

  /// 解析代码结构
  Future<List<ContextInfo>> _parseCodeStructure(String code) async {
    final contexts = <ContextInfo>[];
    
    // 根据文件扩展名选择解析器
    final extension = _languageSupport.getLanguageFromCode(code);
    final parser = _parsers[extension];
    
    if (parser != null) {
      // 解析导入
      final imports = await parser.parseImports(code);
      contexts.addAll(imports);
      
      // 解析类
      final classes = await parser.parseClasses(code);
      contexts.addAll(classes);
      
      // 解析函数
      final functions = await parser.parseFunctions(code);
      contexts.addAll(functions);
      
      // 解析变量
      final variables = await parser.parseVariables(code);
      contexts.addAll(variables);
    } else {
      _log.warning('No parser available for extension: $extension');
    }
    
    return contexts;
  }

  /// 分析当前位置的上下文
  List<ContextInfo> _analyzeCurrentContext(
    List<ContextInfo> structure,
    int cursorPosition,
  ) {
    final currentContexts = <ContextInfo>[];
    
    for (final context in structure) {
      if (_isPositionInRange(cursorPosition, context.range)) {
        currentContexts.add(context);
        
        // 递归分析子上下文
        for (final child in context.children) {
          if (_isPositionInRange(cursorPosition, child.range)) {
            currentContexts.add(child);
          }
        }
      }
    }
    
    return currentContexts;
  }

  /// 分析依赖关系
  void _analyzeDependencies(List<ContextInfo> contexts) {
    for (final context in contexts) {
      final dependencies = <String>{};
      
      // 分析代码依赖
      for (final dep in context.dependencies) {
        final depContext = contexts.firstWhere(
          (c) => c.name == dep,
          orElse: () => ContextInfo(
            id: 'unknown_${DateTime.now().millisecondsSinceEpoch}',
            type: ContextType.variable,
            name: dep,
            range: ContextRange(
              start: 0,
              end: 0,
              line: 0,
              column: 0,
            ),
            analyzedAt: DateTime.now(),
          ),
        );
        dependencies.add(depContext.id);
      }
      
      // 更新依赖图
      _dependencyGraph[context.id] = dependencies;
    }
  }

  /// 更新上下文缓存
  void _updateContextCache(String cacheKey, List<ContextInfo> contexts) {
    _contextCache[cacheKey] = contexts;
    _lastAnalysisTime[cacheKey] = DateTime.now();
  }

  /// 更新上下文历史
  void _updateContextHistory(List<ContextInfo> contexts) {
    _contextHistory.addAll(contexts);
    
    // 限制历史记录大小
    if (_contextHistory.length > _maxHistorySize) {
      _contextHistory.removeRange(0, _contextHistory.length - _maxHistorySize);
    }
  }

  /// 查找历史相关上下文
  List<ContextInfo> _findHistoricalRelatedContexts(ContextInfo context) {
    return _contextHistory.where((c) =>
      c.type == context.type &&
      c.name == context.name &&
      c.id != context.id
    ).toList();
  }

  /// 查找指定ID的上下文
  ContextInfo? _findContextById(String id) {
    for (final contexts in _contextCache.values) {
      for (final context in contexts) {
        if (context.id == id) return context;
      }
    }
    return null;
  }

  /// 检查位置是否在范围内
  bool _isPositionInRange(int position, ContextRange range) {
    return position >= range.start && position <= range.end;
  }

  /// 获取文件内容
  Future<String> _getFileContent(String filePath) async {
    if (_fileContentCache.containsKey(filePath)) {
      return _fileContentCache[filePath]!;
    }
    
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }
      
      final content = await file.readAsString();
      _fileContentCache[filePath] = content;
      return content;
    } catch (e) {
      _logger.error('Failed to read file: $e');
      rethrow;
    }
  }

  /// 获取文件语言
  String? _getFileLanguage(String filePath) {
    final extension = filePath.substring(filePath.lastIndexOf('.'));
    
    switch (extension) {
      case '.dart':
        return 'dart';
      case '.js':
      case '.jsx':
        return 'javascript';
      case '.ts':
      case '.tsx':
        return 'typescript';
      case '.py':
        return 'python';
      case '.sql':
        return 'sql';
      case '.json':
        return 'json';
      case '.html':
      case '.htm':
        return 'html';
      case '.css':
        return 'css';
      case '.md':
        return 'markdown';
      default:
        return null;
    }
  }

  /// 获取文件上下文
  Future<List<ContextInfo>> getFileContext(String filePath) async {
    if (_fileContextCache.containsKey(filePath)) {
      return _fileContextCache[filePath]!;
    }
    
    try {
      final content = await _getFileContent(filePath);
      final language = _getFileLanguage(filePath);
      
      if (language == null) {
        return [];
      }
      
      // 分析文件内容
      final contextInfo = await analyzeContext(content, 0);
      
      _fileContextCache[filePath] = contextInfo;
      return contextInfo;
    } catch (e) {
      _logger.error('Failed to get file context: $e');
      return [];
    }
  }

  /// 获取文件导入
  Future<List<String>> getFileImports(String filePath) async {
    if (_importCache.containsKey(filePath)) {
      return _importCache[filePath]!;
    }
    
    try {
      final content = await _getFileContent(filePath);
      final extension = filePath.substring(filePath.lastIndexOf('.'));
      final parser = _parsers[extension];
      
      if (parser != null) {
        final imports = await parser.parseImports(content);
        _importCache[filePath] = imports.map((i) => i.name).toList();
        return _importCache[filePath]!;
      }
      
      return [];
    } catch (e) {
      _logger.error('Failed to get file imports: $e');
      return [];
    }
  }
} 