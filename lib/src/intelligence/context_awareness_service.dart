class ContextAwarenessService {
  final LanguageSupport _languageSupport;
  final PerformanceService _performanceService;
  final LearningService _learningService;
  
  // 缓存最近的上下文分析结果
  List<ContextInfo> _lastContexts = [];
  DateTime? _lastAnalysisTime;
  
  ContextAwarenessService(
    this._languageSupport,
    this._performanceService,
    this._learningService,
  );

  /// 分析代码上下文
  Future<List<ContextInfo>> analyzeContext(String code, int cursorPosition) async {
    // 如果距离上次分析时间不到100ms，且光标位置在上次分析的范围内，则返回缓存结果
    if (_lastAnalysisTime != null &&
        DateTime.now().difference(_lastAnalysisTime!) < const Duration(milliseconds: 100) &&
        _isPositionInLastContexts(cursorPosition)) {
      return _lastContexts;
    }

    return await _performanceService.deferLongOperation(
      operation: () async {
        final contexts = <ContextInfo>[];
        
        // 使用机器学习模型预测上下文类型
        final contextType = await _predictContextType(code, cursorPosition);
        
        // 基于预测的上下文类型进行分析
        switch (contextType) {
          case ContextType.function:
            final functionContext = await _analyzeFunctionContext(code, cursorPosition);
            if (functionContext != null) {
              contexts.add(functionContext);
            }
            break;
          case ContextType.class_:
            final classContext = await _analyzeClassContext(code, cursorPosition);
            if (classContext != null) {
              contexts.add(classContext);
            }
            break;
          default:
            // 分析当前代码块
            final currentBlock = _extractCurrentBlock(code, cursorPosition);
            if (currentBlock.isNotEmpty) {
              contexts.add(ContextInfo(
                type: ContextType.code,
                content: currentBlock,
                startOffset: cursorPosition - currentBlock.length,
                endOffset: cursorPosition,
                metadata: {'type': 'current_block'},
              ));
            }
        }

        // 分析导入上下文
        final imports = await _analyzeImports(code);
        contexts.addAll(imports);

        // 收集训练数据
        _collectTrainingData(code, cursorPosition, contexts);

        // 更新缓存
        _lastContexts = contexts;
        _lastAnalysisTime = DateTime.now();

        return contexts;
      },
    );
  }

  /// 预测上下文类型
  Future<ContextType> _predictContextType(String code, int cursorPosition) async {
    final features = _extractContextFeatures(code, cursorPosition);
    final prediction = await _learningService.predict(
      ModelType.contextAnalysis,
      features,
    );
    
    return prediction ?? ContextType.code;
  }

  /// 分析函数上下文
  Future<ContextInfo?> _analyzeFunctionContext(String code, int cursorPosition) async {
    final functionMatch = RegExp(r'(\w+)\s+(\w+)\s*\((.*?)\)\s*\{')
        .firstMatch(code.substring(0, cursorPosition));
    
    if (functionMatch != null) {
      final returnType = functionMatch.group(1);
      final functionName = functionMatch.group(2);
      final parameters = functionMatch.group(3);
      
      return ContextInfo(
        type: ContextType.function,
        content: functionMatch.group(0)!,
        startOffset: functionMatch.start,
        endOffset: functionMatch.end,
        metadata: {
          'returnType': returnType,
          'functionName': functionName,
          'parameters': parameters,
        },
      );
    }
    
    return null;
  }

  /// 分析类上下文
  Future<ContextInfo?> _analyzeClassContext(String code, int cursorPosition) async {
    final classMatch = RegExp(r'class\s+(\w+)(?:\s+extends\s+(\w+))?\s*\{')
        .firstMatch(code.substring(0, cursorPosition));
    
    if (classMatch != null) {
      final className = classMatch.group(1);
      final superClass = classMatch.group(2);
      
      return ContextInfo(
        type: ContextType.class_,
        content: classMatch.group(0)!,
        startOffset: classMatch.start,
        endOffset: classMatch.end,
        metadata: {
          'className': className,
          'superClass': superClass,
        },
      );
    }
    
    return null;
  }

  /// 分析导入语句
  Future<List<ContextInfo>> _analyzeImports(String code) async {
    final imports = <ContextInfo>[];
    final importMatches = RegExp(r'import\s+[\'"]([^\'"]+)[\'"]').allMatches(code);
    
    for (final match in importMatches) {
      imports.add(ContextInfo(
        type: ContextType.import_,
        content: match.group(0)!,
        startOffset: match.start,
        endOffset: match.end,
        metadata: {
          'path': match.group(1),
        },
      ));
    }
    
    return imports;
  }

  /// 提取上下文特征
  Map<String, dynamic> _extractContextFeatures(String code, int cursorPosition) {
    return {
      'prefixLength': cursorPosition,
      'totalLength': code.length,
      'hasFunction': code.contains(RegExp(r'\w+\s+\w+\s*\(')),
      'hasClass': code.contains(RegExp(r'class\s+\w+')),
      'hasImport': code.contains(RegExp(r'import\s+[\'"]')),
      'indentationLevel': _calculateIndentation(code, cursorPosition),
    };
  }

  /// 计算缩进级别
  int _calculateIndentation(String code, int cursorPosition) {
    final lastNewline = code.lastIndexOf('\n', cursorPosition - 1);
    if (lastNewline == -1) return 0;
    
    var indentation = 0;
    var pos = lastNewline + 1;
    while (pos < cursorPosition && code[pos] == ' ') {
      indentation++;
      pos++;
    }
    
    return indentation ~/ 2; // 假设使用2空格缩进
  }

  /// 收集训练数据
  void _collectTrainingData(
    String code,
    int cursorPosition,
    List<ContextInfo> contexts,
  ) {
    final features = _extractContextFeatures(code, cursorPosition);
    final contextType = contexts.isNotEmpty ? contexts.first.type : ContextType.code;
    
    _learningService.collectData(LearningData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ModelType.contextAnalysis,
      features: features,
      label: contextType,
      timestamp: DateTime.now(),
    ));
  }
} 