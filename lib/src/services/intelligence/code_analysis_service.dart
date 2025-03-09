import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:isolate';
import '../editor/performance_service.dart';
import '../../core/editor/language_support.dart';
import '../../core/editor/language_manager.dart';
import 'context_awareness_service.dart';

/// 代码分析结果
class CodeAnalysisResult {
  final List<ContextInfo> classes;
  final List<ContextInfo> functions;
  final List<ContextInfo> variables;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const CodeAnalysisResult({
    required this.classes,
    required this.functions,
    required this.variables,
    this.metadata = const {},
    required this.timestamp,
  });
}

/// 代码分析服务
class CodeAnalysisService {
  final LanguageManager _languageManager;
  final PerformanceService _performanceService;
  
  // 缓存分析结果
  final Map<String, CodeAnalysisResult> _analysisCache = {};
  final Map<String, DateTime> _lastAnalysisTime = {};
  
  // 增量分析状态
  final Map<String, String> _previousCode = {};
  
  // 并发控制
  final int _maxConcurrentAnalysis = 3;
  final List<Completer<CodeAnalysisResult>> _pendingAnalysis = [];
  int _runningAnalysis = 0;

  CodeAnalysisService(this._languageManager, this._performanceService);

  /// 分析代码
  Future<CodeAnalysisResult> analyzeCode(
    String code,
    String languageName,
    {bool useCache = true, bool forceFullAnalysis = false}
  ) async {
    // 生成缓存键
    final cacheKey = '${languageName}_${code.hashCode}';
    
    // 检查缓存是否有效
    if (useCache && _isCacheValid(cacheKey) && !forceFullAnalysis) {
      return _analysisCache[cacheKey]!;
    }
    
    // 检查是否可以进行增量分析
    final canUseIncremental = !forceFullAnalysis && 
                             _previousCode.containsKey(cacheKey) &&
                             _calculateSimilarity(_previousCode[cacheKey]!, code) > 0.8;
    
    // 如果并发分析数量已达上限，则排队等待
    if (_runningAnalysis >= _maxConcurrentAnalysis) {
      final completer = Completer<CodeAnalysisResult>();
      _pendingAnalysis.add(completer);
      return completer.future;
    }
    
    _runningAnalysis++;
    
    try {
      // 获取语言支持
      final languageSupport = _languageManager.getLanguageSupport(languageName);
      if (languageSupport == null) {
        throw Exception('不支持的语言: $languageName');
      }
      
      CodeAnalysisResult result;
      
      // 使用性能服务延迟执行长时间操作
      if (canUseIncremental) {
        // 执行增量分析
        result = await _performanceService.deferLongOperation(
          operation: () => _performIncrementalAnalysis(
            code, 
            _previousCode[cacheKey]!, 
            languageSupport,
            _analysisCache[cacheKey]!,
          ),
        );
      } else {
        // 执行完整分析
        result = await _performanceService.deferLongOperation(
          operation: () => _performFullAnalysis(code, languageSupport),
        );
      }
      
      // 更新缓存
      _updateCache(cacheKey, result);
      _previousCode[cacheKey] = code;
      
      return result;
    } finally {
      _runningAnalysis--;
      
      // 处理等待队列中的下一个分析请求
      if (_pendingAnalysis.isNotEmpty) {
        final nextCompleter = _pendingAnalysis.removeAt(0);
        analyzeCode(code, languageName, useCache: useCache, forceFullAnalysis: forceFullAnalysis)
          .then((result) => nextCompleter.complete(result))
          .catchError((error) => nextCompleter.completeError(error));
      }
    }
  }

  /// 执行完整代码分析
  Future<CodeAnalysisResult> _performFullAnalysis(
    String code,
    LanguageSupport languageSupport,
  ) async {
    // 使用隔离区执行分析以避免阻塞主线程
    final result = await _analyzeInIsolate(code, languageSupport.languageName);
    
    return CodeAnalysisResult(
      classes: result['classes'],
      functions: result['functions'],
      variables: result['variables'],
      metadata: {
        'language': languageSupport.languageName,
        'totalSymbols': result['classes'].length + result['functions'].length + result['variables'].length,
        'analysisType': 'full',
      },
      timestamp: DateTime.now(),
    );
  }

  /// 执行增量代码分析
  Future<CodeAnalysisResult> _performIncrementalAnalysis(
    String newCode,
    String oldCode,
    LanguageSupport languageSupport,
    CodeAnalysisResult previousResult,
  ) async {
    // 计算差异
    final diff = _calculateDiff(oldCode, newCode);
    
    // 如果差异太大，执行完整分析
    if (diff.changedLines.length > oldCode.split('\n').length * 0.3) {
      return _performFullAnalysis(newCode, languageSupport);
    }
    
    // 分析受影响的区域
    final affectedRanges = _calculateAffectedRanges(diff, oldCode);
    
    // 复制之前的分析结果
    final classes = List<ContextInfo>.from(previousResult.classes);
    final functions = List<ContextInfo>.from(previousResult.functions);
    final variables = List<ContextInfo>.from(previousResult.variables);
    
    // 移除受影响区域内的符号
    _removeSymbolsInRanges(classes, affectedRanges);
    _removeSymbolsInRanges(functions, affectedRanges);
    _removeSymbolsInRanges(variables, affectedRanges);
    
    // 分析受影响的区域
    for (final range in affectedRanges) {
      final codeSegment = newCode.substring(range.start, range.end);
      final segmentResult = await _analyzeCodeSegment(
        codeSegment, 
        languageSupport.languageName,
        offset: range.start,
      );
      
      classes.addAll(segmentResult['classes']);
      functions.addAll(segmentResult['functions']);
      variables.addAll(segmentResult['variables']);
    }
    
    return CodeAnalysisResult(
      classes: classes,
      functions: functions,
      variables: variables,
      metadata: {
        'language': languageSupport.languageName,
        'totalSymbols': classes.length + functions.length + variables.length,
        'analysisType': 'incremental',
        'changedLines': diff.changedLines.length,
      },
      timestamp: DateTime.now(),
    );
  }

  /// 在隔离区中分析代码
  Future<Map<String, List<ContextInfo>>> _analyzeInIsolate(
    String code,
    String languageName,
  ) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _isolateAnalyzer,
      {
        'code': code,
        'language': languageName,
        'sendPort': receivePort.sendPort,
      },
    );
    
    final result = await receivePort.first as Map<String, dynamic>;
    return {
      'classes': result['classes'] as List<ContextInfo>,
      'functions': result['functions'] as List<ContextInfo>,
      'variables': result['variables'] as List<ContextInfo>,
    };
  }

  /// 隔离区分析器
  static void _isolateAnalyzer(Map<String, dynamic> data) {
    final code = data['code'] as String;
    final language = data['language'] as String;
    final sendPort = data['sendPort'] as SendPort;
    
    // 根据语言选择解析器
    final result = _parseByLanguage(code, language);
    
    sendPort.send(result);
  }

  /// 根据语言选择解析器
  static Map<String, List<ContextInfo>> _parseByLanguage(String code, String language) {
    switch (language) {
      case 'dart':
        return _parseDart(code);
      case 'javascript':
      case 'typescript':
        return _parseJavaScript(code);
      case 'python':
        return _parsePython(code);
      case 'java':
        return _parseJava(code);
      case 'cpp':
        return _parseCpp(code);
      default:
        return _parseGeneric(code);
    }
  }

  /// 分析代码段
  Future<Map<String, List<ContextInfo>>> _analyzeCodeSegment(
    String codeSegment,
    String languageName,
    {int offset = 0}
  ) async {
    final result = _parseByLanguage(codeSegment, languageName);
    
    // 调整位置偏移
    if (offset > 0) {
      for (final cls in result['classes']) {
        _adjustRange(cls.range, offset);
      }
      
      for (final func in result['functions']) {
        _adjustRange(func.range, offset);
      }
      
      for (final variable in result['variables']) {
        _adjustRange(variable.range, offset);
      }
    }
    
    return result;
  }

  /// 调整范围偏移
  static void _adjustRange(ContextRange range, int offset) {
    range.start += offset;
    range.end += offset;
  }

  /// 移除指定范围内的符号
  void _removeSymbolsInRanges(List<ContextInfo> symbols, List<ContextRange> ranges) {
    symbols.removeWhere((symbol) {
      for (final range in ranges) {
        if (_isRangeOverlap(symbol.range, range)) {
          return true;
        }
      }
      return false;
    });
  }

  /// 检查两个范围是否重叠
  bool _isRangeOverlap(ContextRange a, ContextRange b) {
    return (a.start <= b.end && a.end >= b.start);
  }

  /// 计算代码差异
  _CodeDiff _calculateDiff(String oldCode, String newCode) {
    final oldLines = oldCode.split('\n');
    final newLines = newCode.split('\n');
    
    final changedLines = <int>[];
    
    // 简单的行级差异计算
    final minLength = oldLines.length < newLines.length ? oldLines.length : newLines.length;
    
    for (int i = 0; i < minLength; i++) {
      if (oldLines[i] != newLines[i]) {
        changedLines.add(i);
      }
    }
    
    // 如果新代码行数更多，标记额外的行
    if (newLines.length > oldLines.length) {
      for (int i = oldLines.length; i < newLines.length; i++) {
        changedLines.add(i);
      }
    }
    
    return _CodeDiff(changedLines);
  }

  /// 计算受影响的代码范围
  List<ContextRange> _calculateAffectedRanges(
    _CodeDiff diff,
    String code,
  ) {
    final lines = code.split('\n');
    final ranges = <ContextRange>[];
    
    int currentStart = -1;
    int currentLine = -1;
    
    for (final lineNum in diff.changedLines) {
      if (currentStart == -1) {
        // 开始新的范围
        currentStart = _getLineOffset(lines, lineNum);
        currentLine = lineNum;
      } else if (lineNum > currentLine + 1) {
        // 当前行与前一个变更行不连续，结束当前范围并开始新范围
        ranges.add(ContextRange(
          start: currentStart,
          end: _getLineEndOffset(lines, currentLine),
          line: currentLine,
          column: 0,
        ));
        
        currentStart = _getLineOffset(lines, lineNum);
        currentLine = lineNum;
      } else {
        // 连续的变更行，更新当前行
        currentLine = lineNum;
      }
    }
    
    // 添加最后一个范围
    if (currentStart != -1) {
      ranges.add(ContextRange(
        start: currentStart,
        end: _getLineEndOffset(lines, currentLine),
        line: currentLine,
        column: 0,
      ));
    }
    
    return ranges;
  }

  /// 获取行的起始偏移量
  int _getLineOffset(List<String> lines, int lineNum) {
    int offset = 0;
    for (int i = 0; i < lineNum; i++) {
      offset += lines[i].length + 1; // +1 for newline
    }
    return offset;
  }

  /// 获取行的结束偏移量
  int _getLineEndOffset(List<String> lines, int lineNum) {
    int offset = 0;
    for (int i = 0; i <= lineNum; i++) {
      offset += lines[i].length + 1; // +1 for newline
    }
    return offset - 1; // -1 to exclude the last newline
  }

  /// 计算两个字符串的相似度 (0-1)
  double _calculateSimilarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    
    int matchingChars = 0;
    final minLength = a.length < b.length ? a.length : b.length;
    
    for (int i = 0; i < minLength; i++) {
      if (a[i] == b[i]) matchingChars++;
    }
    
    return matchingChars / (a.length > b.length ? a.length : b.length);
  }

  /// 检查缓存是否有效
  bool _isCacheValid(String cacheKey) {
    if (!_analysisCache.containsKey(cacheKey)) return false;
    
    final lastAnalysis = _lastAnalysisTime[cacheKey];
    if (lastAnalysis == null) return false;
    
    // 缓存在10分钟内有效
    return DateTime.now().difference(lastAnalysis) < const Duration(minutes: 10);
  }

  /// 更新缓存
  void _updateCache(String cacheKey, CodeAnalysisResult result) {
    _analysisCache[cacheKey] = result;
    _lastAnalysisTime[cacheKey] = DateTime.now();
    
    // 清理过期缓存
    _cleanCache();
  }

  /// 清理过期缓存
  void _cleanCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _lastAnalysisTime.forEach((key, time) {
      if (now.difference(time) > const Duration(minutes: 30)) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _analysisCache.remove(key);
      _lastAnalysisTime.remove(key);
      _previousCode.remove(key);
    }
  }

  /// 清理所有缓存
  void clearCache() {
    _analysisCache.clear();
    _lastAnalysisTime.clear();
    _previousCode.clear();
  }

  // 语言特定的解析器实现
  static Map<String, List<ContextInfo>> _parseDart(String code) {
    return {
      'classes': _parseDartClasses(code),
      'functions': _parseDartFunctions(code),
      'variables': _parseDartVariables(code),
    };
  }
  
  static Map<String, List<ContextInfo>> _parseJavaScript(String code) {
    return {
      'classes': _parseJavaScriptClasses(code),
      'functions': _parseJavaScriptFunctions(code),
      'variables': _parseJavaScriptVariables(code),
    };
  }
  
  static Map<String, List<ContextInfo>> _parsePython(String code) {
    return {
      'classes': _parsePythonClasses(code),
      'functions': _parsePythonFunctions(code),
      'variables': _parsePythonVariables(code),
    };
  }
  
  static Map<String, List<ContextInfo>> _parseJava(String code) {
    return {
      'classes': _parseJavaClasses(code),
      'functions': _parseJavaMethods(code),
      'variables': _parseJavaVariables(code),
    };
  }
  
  static Map<String, List<ContextInfo>> _parseCpp(String code) {
    return {
      'classes': _parseCppClasses(code),
      'functions': _parseCppFunctions(code),
      'variables': _parseCppVariables(code),
    };
  }
  
  static Map<String, List<ContextInfo>> _parseGeneric(String code) {
    return {
      'classes': [],
      'functions': [],
      'variables': [],
    };
  }
}

/// 代码差异
class _CodeDiff {
  final List<int> changedLines;
  
  _CodeDiff(this.changedLines);
}

/// 代码分析服务提供者
final codeAnalysisServiceProvider = Provider<CodeAnalysisService>((ref) {
  final languageManager = ref.watch(languageManagerProvider);
  final performanceService = ref.watch(performanceServiceProvider);
  return CodeAnalysisService(languageManager, performanceService);
}); 